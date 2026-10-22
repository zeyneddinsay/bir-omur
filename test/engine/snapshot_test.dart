import 'dart:convert';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/auto_player.dart';
import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

/// Kaydı gerçek bir dosyadaki gibi metne çevirip geri okur.
Map<String, dynamic> _throughJson(Map<String, Object?> snapshot) =>
    jsonDecode(jsonEncode(snapshot)) as Map<String, dynamic>;

String _fingerprint(LifeState s) {
  final c = s.character;
  return [
    c.age,
    c.stats,
    c.flags.toList()..sort(),
    c.history
        .map((r) => '${r.age}:${r.cardId}:${r.side.name}:${r.rollSucceeded}')
        .join(','),
    s.phase,
    s.summary?.cause,
    s.summary?.nickname,
  ].join('|');
}

void main() {
  group('Character JSON', () {
    test('gidiş-dönüş aynı karakteri verir', () {
      final c = testCharacter(
        age: 33,
        money: -1200,
        luck: 81,
        job: const Job(careerId: 'memur', tier: 2, yearsInTier: 3),
        gender: Gender.kadin,
        temperament: Temperament.hayalperest,
        flags: {'kiraci', 'evli'},
        history: const [
          CardRecord(age: 30, cardId: 'a', side: ChoiceSide.up),
          CardRecord(
            age: 31,
            cardId: 'b',
            side: ChoiceSide.right,
            rollSucceeded: false,
          ),
        ],
      );
      final back = Character.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back.toJson(), c.toJson());
      expect(back.stats, c.stats);
      expect(back.job, c.job);
      expect(back.history[1].rollSucceeded, isFalse);
      expect(back.history[0].rollSucceeded, isNull);
    });

    test('bilinmeyen mizaç kaydı reddedilir', () {
      final json = testCharacter().toJson()..['temperament'] = 'sinirli';
      expect(() => Character.fromJson(json), throwsFormatException);
    });
  });

  group('LifeEngine kayıt', () {
    final content = loadRealContent();
    final deck = content.deck;
    final careers = content.careers;

    test('hayatın ortasında kaydedip yüklemek sonucu değiştirmez', () {
      for (final seed in [3, 11, 58]) {
        for (final splitAt in [1, 40, 150]) {
          // Kesintisiz hayat.
          final straight = LifeEngine(deck: deck, seed: seed, careers: careers);
          final straightPlayer = AutoPlayer(seed);
          straight.startLife();
          while (!straight.state.isOver) {
            straightPlayer.step(straight);
          }

          // Aynı hayat, splitAt adımda kaydedilip yeni bir motorda sürdürülür.
          var engine = LifeEngine(deck: deck, seed: seed, careers: careers);
          final player = AutoPlayer(seed);
          engine.startLife();
          for (var i = 0; i < splitAt && !engine.state.isOver; i++) {
            player.step(engine);
          }
          engine = LifeEngine.restore(
            deck: deck,
            careers: careers,
            snapshot: _throughJson(engine.toSnapshot()),
          );
          while (!engine.state.isOver) {
            player.step(engine);
          }

          expect(
            _fingerprint(engine.state),
            _fingerprint(straight.state),
            reason: 'tohum $seed, $splitAt. adımda kayıt',
          );
        }
      }
    });

    test('ölmüş hayat özetiyle birlikte geri yüklenir', () {
      final engine = LifeEngine(deck: deck, seed: 5, careers: careers);
      AutoPlayer(5).play(engine);
      final restored = LifeEngine.restore(
        deck: deck,
        careers: careers,
        snapshot: _throughJson(engine.toSnapshot()),
      );
      expect(restored.state.isOver, isTrue);
      expect(restored.state.summary!.cause, engine.state.summary!.cause);
      expect(restored.state.summary!.nickname, engine.state.summary!.nickname);
      expect(
        restored.state.summary!.biggestMoment?.cardId,
        engine.state.summary!.biggestMoment?.cardId,
      );
    });

    test('aksiyon aşamasında kalan hak ve yapılanlar korunur', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      engine.startLife();
      while (engine.state.character.age < ActionCatalog.firstTimeAge) {
        engine.advanceYear();
      }
      engine.doAction('oyun_oyna');
      final restored = LifeEngine.restore(
        deck: EventDeck([]),
        snapshot: _throughJson(engine.toSnapshot()),
      );
      expect(restored.state.phase, YearPhase.actions);
      expect(restored.state.timeLeft, 1);
      expect(restored.state.actionsUsed, {'oyun_oyna'});
      expect(() => restored.doAction('oyun_oyna'), throwsStateError);
    });

    test('kart dosyasından silinen bekleyen kart atlanır', () {
      final oldDeck = EventDeck([testCard('eski', maxAge: 0)]);
      final engine = LifeEngine(deck: oldDeck, seed: 1);
      engine.startLife();
      expect(engine.state.currentEvent!.card.id, 'eski');

      final restored = LifeEngine.restore(
        deck: EventDeck([]),
        snapshot: _throughJson(engine.toSnapshot()),
      );
      expect(restored.state.phase, YearPhase.actions);
      expect(restored.state.timeLeft, 0);
    });

    test('zincir sırası kayıtla taşınır', () {
      final chainDeck = EventDeck([
        testCard(
          'borc_ver',
          maxAge: 0,
          left: {
            'label': 'Ver',
            'effects': {
              'schedule': {'event': 'borc_geri', 'inYears': 2},
            },
          },
        ),
        testCard('borc_geri', chainOnly: true),
      ]);
      final engine = LifeEngine(deck: chainDeck, seed: 1);
      engine.startLife();
      engine.choose(ChoiceSide.left);
      final restored = LifeEngine.restore(
        deck: chainDeck,
        snapshot: _throughJson(engine.toSnapshot()),
      );
      restored.advanceYear();
      restored.advanceYear();
      expect(restored.state.currentEvent!.card.id, 'borc_geri');
    });

    test('bilinmeyen kayıt sürümü reddedilir', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1)..startLife();
      final snapshot = _throughJson(engine.toSnapshot())..['version'] = 99;
      expect(
        () => LifeEngine.restore(deck: EventDeck([]), snapshot: snapshot),
        throwsFormatException,
      );
    });
  });
}
