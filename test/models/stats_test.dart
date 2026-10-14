import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_character.dart';

void main() {
  group('Stats', () {
    const stats = Stats(
      health: 90,
      happiness: 5,
      knowledge: 50,
      reputation: 50,
      family: 50,
      money: 1000,
    );

    test('göstergeler 0–100 aralığına sıkıştırılır', () {
      expect(stats.withDelta(StatKind.health, 30).health, 96);
      expect(stats.withDelta(StatKind.happiness, -30).happiness, 0);
      expect(stats.withDelta(StatKind.knowledge, 7).knowledge, 57);
    });

    test('zirveye yaklaştıkça kazanç azalır, kayıp azalmaz', () {
      Stats at(int v) => stats.copyWith(knowledge: v);
      expect(at(40).withDelta(StatKind.knowledge, 10).knowledge, 50);
      expect(at(50).withDelta(StatKind.knowledge, 10).knowledge, 60);
      expect(at(75).withDelta(StatKind.knowledge, 10).knowledge, 80);
      expect(at(90).withDelta(StatKind.knowledge, 10).knowledge, 92);
      expect(at(99).withDelta(StatKind.knowledge, 10).knowledge, 99);
      expect(at(90).withDelta(StatKind.knowledge, -30).knowledge, 60);
    });

    test('yalnızca istenen gösterge değişir', () {
      final changed = stats.withDelta(StatKind.family, 10);
      expect(changed, stats.copyWith(family: 60));
    });

    test('para sınırsızdır ve eksiye inebilir', () {
      expect(stats.withMoneyDelta(1000000).money, 1001000);
      expect(stats.withMoneyDelta(-5000).money, -4000);
    });

    test('etki adları JSON anahtarlarıyla eşleşir', () {
      for (final kind in StatKind.values) {
        expect(StatKind.fromKey(kind.key), kind);
      }
      expect(StatKind.fromKey('money'), isNull);
    });
  });

  group('LifeStage', () {
    test('her yaş doğru evreye düşer', () {
      const expected = {
        0: LifeStage.bebek,
        6: LifeStage.bebek,
        7: LifeStage.ilkokul,
        10: LifeStage.ilkokul,
        11: LifeStage.ortaokul,
        14: LifeStage.ortaokul,
        15: LifeStage.lise,
        18: LifeStage.lise,
        19: LifeStage.genc,
        29: LifeStage.genc,
        30: LifeStage.yetiskin,
        49: LifeStage.yetiskin,
        50: LifeStage.olgun,
        64: LifeStage.olgun,
        65: LifeStage.yasli,
        120: LifeStage.yasli,
      };
      expected.forEach((age, stage) {
        expect(LifeStage.forAge(age), stage, reason: '$age yaş');
      });
    });

    test('evreler boşluksuz ve çakışmasız sıralanır', () {
      for (var i = 1; i < LifeStage.values.length; i++) {
        expect(LifeStage.values[i].minAge, LifeStage.values[i - 1].maxAge! + 1);
      }
    });
  });

  group('Character', () {
    test('kart geçmişinden son görülme yaşını bulur', () {
      final c = testCharacter(
        history: const [
          CardRecord(age: 20, cardId: 'a', side: ChoiceSide.left),
          CardRecord(age: 23, cardId: 'b', side: ChoiceSide.right),
          CardRecord(age: 24, cardId: 'a', side: ChoiceSide.right),
        ],
      );
      expect(c.lastSeenAge('a'), 24);
      expect(c.lastSeenAge('b'), 23);
      expect(c.lastSeenAge('c'), isNull);
      expect(c.hasSeen('b'), isTrue);
    });

    test('bayraklar ve geçmiş dışarıdan değiştirilemez', () {
      final c = testCharacter(flags: {'kiraci'});
      expect(() => c.flags.add('ev_sahibi'), throwsUnsupportedError);
      expect(
        () => c.history.add(
          const CardRecord(age: 1, cardId: 'x', side: ChoiceSide.left),
        ),
        throwsUnsupportedError,
      );
    });

    test('copyWith gizli değerleri korur', () {
      final c = testCharacter(luck: 77, temperament: Temperament.asabi);
      final older = c.copyWith(age: c.age + 1);
      expect(older.age, 26);
      expect(older.luck, 77);
      expect(older.temperament, Temperament.asabi);
      expect(older.stage, LifeStage.genc);
    });
  });
}
