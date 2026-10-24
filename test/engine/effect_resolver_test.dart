import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

void main() {
  group('EffectResolver.applyEffect', () {
    test('göstergeleri, parayı ve bayrakları uygular', () {
      final c = testCharacter(happiness: 95, money: 1000, flags: {'kiraci'});
      final next = EffectResolver.applyEffect(
        c,
        const Effect(
          stats: {StatKind.happiness: 10, StatKind.health: -5},
          money: -3000,
          addFlags: ['ehliyet_var'],
          removeFlags: ['kiraci'],
        ),
      );
      // 95 iken +10, zirvede azalan kazançla +1 olarak işler.
      expect(next.stats.happiness, 96);
      expect(next.stats.health, 45);
      expect(next.stats.money, -2000);
      expect(next.flags, {'ehliyet_var'});
    });

    test('endRoles: istifa eden iş arkadaşı çevrede kalır, rolü biter', () {
      final c = withPeople(testCharacter(age: 30), [
        testPerson('p1', roles: const [PersonRole(RoleKind.isArkadasi)]),
      ]);
      final next = EffectResolver.applyPeopleEffect(
        c,
        const Effect(
          people: {
            'is': PersonEffect(endRoles: [RoleKind.isArkadasi]),
          },
        ),
        {'is': 'p1'},
      );
      final p = next.people['p1']!;
      expect(p.archived, isFalse);
      expect(p.roles.single.kind, RoleKind.isArkadasi);
      expect(p.roles.single.active, isFalse);
    });

    test('boş etki karakteri değiştirmez', () {
      final c = testCharacter();
      expect(identical(EffectResolver.applyEffect(c, Effect.none), c), isTrue);
    });
  });

  group('EffectResolver.resolve', () {
    final card = testCard(
      'pazarlik',
      left: {
        'label': 'Taşınırım',
        'effects': {
          'money': -15000,
          'addFlags': ['ehliyet_var'],
        },
      },
      right: {
        'label': 'Pazarlık',
        'effects': {'happiness': -1},
        'roll': {'stat': 'luck', 'threshold': 50},
        'success': {'money': -3000},
        'fail': {
          'money': -8000,
          'schedule': {'event': 'ihtar', 'inYears': 1},
        },
      },
    );

    test('zarsız seçenek etkileri uygular ve geçmişe yazar', () {
      final resolver = EffectResolver(Random(1));
      final outcome = resolver.resolve(
        testCharacter(),
        PendingEvent(card),
        ChoiceSide.left,
      );
      expect(outcome.rollSucceeded, isNull);
      expect(outcome.character.stats.money, 10000 - 15000);
      expect(outcome.character.hasFlag('ehliyet_var'), isTrue);
      expect(outcome.character.history.single.cardId, 'pazarlik');
      expect(outcome.character.history.single.side, ChoiceSide.left);
      expect(outcome.scheduled, isEmpty);
    });

    test('zarlı seçenekte temel etki her zaman, dal zara göre uygulanır', () {
      var successes = 0;
      for (var seed = 0; seed < 200; seed++) {
        final outcome = EffectResolver(Random(seed))
            .resolve(testCharacter(), PendingEvent(card), ChoiceSide.right);
        expect(outcome.character.stats.happiness, 49);
        if (outcome.rollSucceeded!) {
          successes++;
          expect(outcome.character.stats.money, 7000);
          expect(outcome.scheduled, isEmpty);
        } else {
          expect(outcome.character.stats.money, 2000);
          expect(outcome.scheduled.single.event.cardId, 'ihtar');
        }
        expect(
          outcome.character.history.single.rollSucceeded,
          outcome.rollSucceeded,
        );
      }
      // Şans 50, eşik 50: kabaca yarı yarıya.
      expect(successes, inInclusiveRange(70, 130));
    });

    test('yüksek değer zarı kolaylaştırır', () {
      int countSuccesses(int luck) {
        var n = 0;
        for (var seed = 0; seed < 300; seed++) {
          final resolver = EffectResolver(Random(seed));
          if (resolver.rollSucceeds(
            testCharacter(luck: luck),
            const Roll(stat: RollStat.luck, threshold: 50),
          )) {
            n++;
          }
        }
        return n;
      }

      expect(countSuccesses(90), greaterThan(countSuccesses(10)));
      expect(countSuccesses(100), 300);
    });

    test('ihtimal hesabı atılan zarla tutarlı; kaba ihtimal üç basamak', () {
      const luckRoll = Roll(stat: RollStat.luck, threshold: 50);
      // Şans zarında ihtimal kabaca şansın kendisi.
      expect(
        EffectResolver.rollChance(testCharacter(luck: 20), luckRoll),
        closeTo(0.21, 0.01),
      );
      expect(EffectResolver.rollChance(testCharacter(luck: 100), luckRoll), 1);
      // Bilgi zarında şans küçük bir pay ekler.
      const knowledgeRoll = Roll(stat: RollStat.knowledge, threshold: 50);
      final lucky = EffectResolver.rollChance(
        testCharacter(knowledge: 70, luck: 100),
        knowledgeRoll,
      );
      final unlucky = EffectResolver.rollChance(
        testCharacter(knowledge: 70, luck: 0),
        knowledgeRoll,
      );
      expect(lucky, greaterThan(unlucky));
      expect(lucky - unlucky, closeTo(0.2, 0.02));
      // Tohumlu atışların oranı hesaplanan ihtimale yakın.
      final c = testCharacter(knowledge: 40, luck: 60);
      var hits = 0;
      for (var seed = 0; seed < 2000; seed++) {
        if (EffectResolver(Random(seed)).rollSucceeds(c, knowledgeRoll)) {
          hits++;
        }
      }
      expect(
        hits / 2000,
        closeTo(EffectResolver.rollChance(c, knowledgeRoll), 0.04),
      );
      expect(RollOdds.of(0.8), RollOdds.yuksek);
      expect(RollOdds.of(0.5), RollOdds.orta);
      expect(RollOdds.of(0.2), RollOdds.dusuk);
    });

    test('aynı tohum aynı zarı atar', () {
      final a = EffectResolver(Random(42))
          .resolve(testCharacter(), PendingEvent(card), ChoiceSide.right);
      final b = EffectResolver(Random(42))
          .resolve(testCharacter(), PendingEvent(card), ChoiceSide.right);
      expect(a.rollSucceeded, b.rollSucceeded);
      expect(a.character.stats, b.character.stats);
    });
  });
}
