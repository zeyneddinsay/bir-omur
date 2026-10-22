import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/services/hive_save_store.dart';
import 'package:bir_omur/services/save_store.dart';
import 'package:bir_omur/ui/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/auto_player.dart';
import '../helpers/test_character.dart';

Achievement _a(Map<String, dynamic> requires, {String id = 'r'}) =>
    Achievement.fromJson({
      'id': id,
      'name': 'Rozet',
      'description': 'Açıklama',
      'requires': requires,
    });

LifeSummary _summary(
  Character c, {
  Nickname nickname = Nickname.mahalleninBildikYuzu,
}) => LifeSummary(
  character: c,
  cause: DeathCause.natural,
  nickname: nickname,
  cardsSeen: c.history.length,
  netWorth: 0,
);

void main() {
  group('rozet şartları', () {
    test('kart koşulları ölüm anındaki karaktere bakar', () {
      final a = _a({
        'conditions': {
          'flags': ['asker_anilari'],
          'min': {'family': 90},
        },
      });
      expect(
        a.requirement.isMetBy(
          _summary(testCharacter(family: 92, flags: {'asker_anilari'})),
        ),
        isTrue,
      );
      expect(
        a.requirement.isMetBy(_summary(testCharacter(family: 92))),
        isFalse,
      );
    });

    test('ölüm yaşı ve sayaç sınırları', () {
      final a = _a({
        'minDeathAge': 70,
        'counters': {
          'max': {'moves': 1},
          'min': {'yearsWorked': 30},
        },
      });
      Character c({int age = 75, int moves = 0, int years = 35}) =>
          testCharacter(age: age).copyWith(
            counters: LifeCounters(moves: moves, yearsWorked: years),
          );
      expect(a.requirement.isMetBy(_summary(c())), isTrue);
      expect(a.requirement.isMetBy(_summary(c(age: 69))), isFalse);
      expect(a.requirement.isMetBy(_summary(c(moves: 1))), isFalse);
      expect(a.requirement.isMetBy(_summary(c(years: 29))), isFalse);
    });

    test('lakap, son meslek ve kademe, görülmüş kart', () {
      final a = _a({
        'nickname': 'hepGulen',
        'lastCareer': 'memur',
        'minLastTier': 4,
        'seenCards': ['k1'],
      });
      final c = testCharacter(
        history: const [
          CardRecord(age: 30, cardId: 'k1', side: ChoiceSide.left),
        ],
      ).copyWith(lastJob: const Job(careerId: 'memur', tier: 5));
      expect(
        a.requirement.isMetBy(_summary(c, nickname: Nickname.hepGulen)),
        isTrue,
      );
      expect(a.requirement.isMetBy(_summary(c)), isFalse, reason: 'lakap');
      expect(
        a.requirement.isMetBy(
          _summary(
            c.copyWith(lastJob: const Job(careerId: 'memur', tier: 3)),
            nickname: Nickname.hepGulen,
          ),
        ),
        isFalse,
        reason: 'kademe',
      );
    });

    test('bilinmeyen alan ve lakap reddedilir', () {
      expect(() => _a({'yas': 3}), throwsA(isA<CardFormatException>()));
      expect(
        () => _a({'nickname': 'efsane'}),
        throwsA(isA<CardFormatException>()),
      );
      expect(
        () => _a({
          'counters': {
            'min': {'kiraci': 1},
          },
        }),
        throwsA(isA<CardFormatException>()),
      );
    });
  });

  group('card_lint rozet denetimi', () {
    final registry = ContentRegistry(
      flags: {
        'iyi_lise': '',
        'meslek_lisesi': '',
        'yks_iyi_gecti': '',
        'ehliyet_var': '',
        'asker_anilari': '',
        'tasindi': '',
      },
    );

    CardCheckResult check(List<Object> achievements) =>
        CardValidator(registry)
            .check(const {}, achievementsSource: jsonEncode(achievements));

    test('bilinmeyen bayrak, meslek, kart ve tekrar eden kimlik', () {
      final result = check([
        {
          'id': 'a',
          'name': 'A',
          'description': 'd',
          'requires': {
            'conditions': {
              'flags': ['uydurma'],
            },
            'lastCareer': 'doktor',
            'seenCards': ['yok'],
          },
        },
        {'id': 'a', 'name': 'A', 'description': 'd', 'requires': {}},
      ]);
      expect(result.errors.map((e) => e.message), [
        contains('"uydurma"'),
        contains('"doktor"'),
        contains('"yok"'),
        contains('tekrar eden'),
      ]);
    });

    test('gerçek rozet dosyası temiz ve her rozet ulaşılabilir türde', () {
      final content = loadRealContent();
      final book = content.achievements!;
      // "Zincirin Sahibi" D3 işletmeleriyle dönecek.
      expect(book.all.length, greaterThanOrEqualTo(14));
      expect(book.all.map((a) => a.id).toSet(), hasLength(book.all.length));
    });
  });

  group('rozet kaydı', () {
    final content = loadRealContent();

    test(
      'ölümde rozetler kaydedilir; ikinci kez kazanılan yeni sayılmaz',
      () async {
        final store = MemorySaveStore();
        Future<(Set<String>, Map<String, AchievementProgress>)> playOne(
          int seed,
        ) async {
          final container = ProviderContainer(
            overrides: [
              saveStoreProvider.overrideWithValue(store),
              seedGeneratorProvider.overrideWithValue(() => seed),
            ],
          );
          addTearDown(container.dispose);
          final controller = container.read(lifeProvider.notifier);
          controller.startLife(content);
          final player = AutoPlayer(seed);
          while (!container.read(lifeProvider)!.isOver) {
            final engine = controller.engine;
            final s = engine.state;
            if (s.phase == YearPhase.cards) {
              controller.choose(player.pickSide(s.currentEvent!.card));
            } else {
              final action = player.pickAction(engine);
              action == null
                  ? controller.advanceYear()
                  : controller.doAction(action);
            }
          }
          await controller.flush();
          return (
            container.read(newBadgesProvider),
            await store.loadAchievements(),
          );
        }

        final (fresh1, progress1) = await playOne(3);
        expect(
          progress1,
          isNotEmpty,
          reason: 'bu tohumda en az bir rozet kazanılmalı',
        );
        expect(fresh1, progress1.keys.toSet());
        expect(progress1.values.every((p) => p.count == 1), isTrue);

        final (fresh2, progress2) = await playOne(3);
        expect(fresh2, isEmpty, reason: 'aynı hayat aynı rozetleri verir');
        for (final id in progress1.keys) {
          expect(progress2[id]!.count, 2);
        }
      },
    );

    test('Hive rozet kaydı gidiş-dönüş', () async {
      final dir = await Directory.systemTemp.createTemp('bir_omur_rozet_');
      Hive.init(dir.path);
      addTearDown(() async {
        await Hive.close();
        await dir.delete(recursive: true);
      });
      var store = await HiveSaveStore.open();
      await store.saveAchievements({
        'gocebe': AchievementProgress(
          count: 2,
          firstEarnedAt: DateTime.utc(2026, 10, 14),
        ),
      });
      await store.close();
      store = await HiveSaveStore.open();
      final loaded = await store.loadAchievements();
      expect(loaded['gocebe']!.count, 2);
      expect(loaded['gocebe']!.firstEarnedAt, DateTime.utc(2026, 10, 14));
    });
  });
}
