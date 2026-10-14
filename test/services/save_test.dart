import 'dart:io';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/engine/life_record.dart';
import 'package:bir_omur/services/hive_save_store.dart';
import 'package:bir_omur/services/save_store.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/auto_player.dart';

LifeRecord _record(String name) => LifeRecord(
  name: name,
  gender: 'kadin',
  hometown: 'Rize',
  team: 'Karadeniz Fırtınası',
  background: 'dar',
  deathAge: 81,
  cause: 'natural',
  nickname: 'hepGulen',
  netWorth: 1200000,
  cardsSeen: 70,
  seed: 9,
  endedAt: DateTime.utc(2026, 10, 14),
  careerId: 'memur',
  careerTier: 3,
);

void main() {
  group('HiveSaveStore', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('bir_omur_hive_');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('hayat kaydı yazılır, kapatıp açınca okunur, silinir', () async {
      var store = await HiveSaveStore.open();
      expect(await store.loadCurrentLife(), isNull);
      await store.saveCurrentLife({
        'version': 1,
        'character': {'name': 'Ali'},
      });
      await store.close();

      store = await HiveSaveStore.open();
      final loaded = await store.loadCurrentLife();
      expect(loaded!['character'], {'name': 'Ali'});
      await store.clearCurrentLife();
      expect(await store.loadCurrentLife(), isNull);
    });

    test('albüm sırayla birikir, bozuk kayıt atlanır', () async {
      final store = await HiveSaveStore.open();
      await store.addToAlbum(_record('Ayşe'));
      await Hive.box<String>(HiveSaveStore.albumBoxName).add('{bozuk');
      await store.addToAlbum(_record('Fatma'));

      final album = await store.loadAlbum();
      expect(album.map((r) => r.name), ['Ayşe', 'Fatma']);
      expect(album.first.careerTier, 3);
      expect(album.first.endedAt, DateTime.utc(2026, 10, 14));
    });
  });

  group('LifeController kayıt', () {
    final content = loadRealContent();

    ProviderContainer containerWith(SaveStore store) {
      final container = ProviderContainer(
        overrides: [
          saveStoreProvider.overrideWithValue(store),
          seedGeneratorProvider.overrideWithValue(() => 21),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 14)),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('her karar kaydedilir; yeni oturum kaldığı yerden sürer', () async {
      final store = MemorySaveStore();
      final first = containerWith(store);
      final controller = first.read(lifeProvider.notifier);
      controller.startLife(content, name: 'Elif');
      final player = _ControllerPlayer(controller, 21);
      for (var i = 0; i < 60; i++) {
        player.step();
      }
      await controller.flush();
      final before = first.read(lifeProvider)!;

      final second = containerWith(store);
      final saved = await second.read(savedLifeProvider.future);
      expect(saved, isNotNull);
      expect(
        second.read(lifeProvider.notifier).resume(content, saved!),
        isTrue,
      );
      final after = second.read(lifeProvider)!;
      expect(after.character.toJson(), before.character.toJson());
      expect(after.phase, before.phase);
      expect(
        after.pendingCards.map((c) => c.id),
        before.pendingCards.map((c) => c.id),
      );
    });

    test('ölüm albüme bir kez yazılır ve yarım kaydı siler', () async {
      final store = MemorySaveStore();
      final container = containerWith(store);
      final controller = container.read(lifeProvider.notifier);
      controller.startLife(content, name: 'Can');
      final player = _ControllerPlayer(controller, 21);
      while (!container.read(lifeProvider)!.isOver) {
        player.step();
      }
      await controller.flush();

      final album = await store.loadAlbum();
      expect(album, hasLength(1));
      expect(album.single.name, 'Can');
      expect(album.single.seed, 21);
      expect(
        album.single.deathAge,
        container.read(lifeProvider)!.summary!.deathAge,
      );
      expect(await store.loadCurrentLife(), isNull);

      controller.reset();
      await controller.flush();
      expect(await store.loadAlbum(), hasLength(1));
    });

    test('bozuk kayıt açılmaz ve silinir', () async {
      final store = MemorySaveStore();
      await store.saveCurrentLife({'version': 99});
      final container = containerWith(store);
      final controller = container.read(lifeProvider.notifier);
      expect(controller.resume(content, {'version': 99}), isFalse);
      expect(container.read(lifeProvider), isNull);
      await controller.flush();
      expect(await store.loadCurrentLife(), isNull);
    });
  });
}

/// Hamleleri denetleyici üzerinden yapan oyuncu; böylece kayıt tetiklenir.
class _ControllerPlayer {
  _ControllerPlayer(this.controller, int seed) : _player = AutoPlayer(seed);

  final LifeController controller;
  final AutoPlayer _player;

  void step() {
    // AutoPlayer'ın kararını, kaydı tetikleyen denetleyiciye aktar.
    final engine = controller.engine;
    final state = engine.state;
    switch (state.phase) {
      case YearPhase.cards:
        controller.choose(_player.pickSide(state.currentCard!));
      case YearPhase.actions:
        final action = _player.pickAction(engine);
        if (action != null) {
          controller.doAction(action);
        } else {
          controller.advanceYear();
        }
      case YearPhase.dead:
        break;
    }
  }
}
