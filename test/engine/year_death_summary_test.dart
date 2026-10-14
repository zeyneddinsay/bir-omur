import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

void main() {
  group('YearTick', () {
    const tick = YearTick();

    test('yaşı artırır; gelir CareerTick işidir', () {
      final next = tick.apply(testCharacter(age: 29, money: 0));
      expect(next.age, 30);
      expect(next.stats.money, 0);
    });

    test('gençlikte sağlık hafifçe toparlanır, yaşlılıkta azalır', () {
      expect(tick.apply(testCharacter(age: 20)).stats.health, 51);
      expect(tick.apply(testCharacter(age: 40)).stats.health, 50);
      expect(tick.apply(testCharacter(age: 64)).stats.health, 48);
      expect(tick.apply(testCharacter(age: 85)).stats.health, 47);
    });

    test(
      'insan alışır: mutluluk her yıl uzaklığının onda biri kadar 60a kayar',
      () {
        expect(tick.apply(testCharacter(happiness: 95)).stats.happiness, 91);
        expect(tick.apply(testCharacter(happiness: 0)).stats.happiness, 6);
        expect(tick.apply(testCharacter(happiness: 60)).stats.happiness, 60);
      },
    );

    test(
      'mahalle unutur: itibar her yıl uzaklığının onda biri kadar 50ye kayar',
      () {
        expect(tick.apply(testCharacter(reputation: 90)).stats.reputation, 86);
        expect(tick.apply(testCharacter(reputation: 10)).stats.reputation, 14);
        expect(tick.apply(testCharacter(reputation: 50)).stats.reputation, 50);
      },
    );

    test('çocuklukta aile bağı soğumaz, yetişkinlikte soğur', () {
      expect(tick.apply(testCharacter(age: 10)).stats.family, 50);
      expect(tick.apply(testCharacter(age: 30)).stats.family, 49);
    });

    test('mutluluk 0 olunca bunalım başlar, toparlanınca biter', () {
      final low = YearTick.updateHardshipFlags(testCharacter(happiness: 0));
      expect(low.hasFlag(EngineFlags.bunalim), isTrue);

      final stillLow = YearTick.updateHardshipFlags(
        testCharacter(happiness: 20, flags: {EngineFlags.bunalim}),
      );
      expect(stillLow.hasFlag(EngineFlags.bunalim), isTrue);

      final recovered = YearTick.updateHardshipFlags(
        testCharacter(
          happiness: EngineFlags.bunalimExit,
          flags: {EngineFlags.bunalim},
        ),
      );
      expect(recovered.hasFlag(EngineFlags.bunalim), isFalse);
    });

    test('para 0 ya da altındaysa borçlu olunur', () {
      expect(
        YearTick.updateHardshipFlags(testCharacter(money: 0))
            .hasFlag(EngineFlags.borclu),
        isTrue,
      );
      expect(
        YearTick.updateHardshipFlags(
          testCharacter(money: 1, flags: {EngineFlags.borclu}),
        ).hasFlag(EngineFlags.borclu),
        isFalse,
      );
    });

    test('çocuklarda zor dönem bayrağı açılmaz', () {
      final child = YearTick.updateHardshipFlags(
        testCharacter(age: 10, money: 0, happiness: 0),
      );
      expect(child.flags, isEmpty);
    });
  });

  group('DeathCheck', () {
    test('sağlık 0 ise ölüm kesindir', () {
      for (var seed = 0; seed < 20; seed++) {
        expect(
          DeathCheck(Random(seed)).check(testCharacter(health: 0)),
          DeathCause.health,
        );
      }
    });

    test('mutluluk ve para 0 olsa da genç ve sağlıklı karakter ölmez', () {
      final c = testCharacter(
        age: 30,
        health: 80,
        happiness: 0,
        money: -100000,
      );
      expect(DeathCheck.probability(c), lessThan(0.001));
    });

    test('ihtimal yaşla ve düşük sağlıkla artar', () {
      expect(
        DeathCheck.probability(testCharacter(age: 80)),
        greaterThan(DeathCheck.probability(testCharacter(age: 40))),
      );
      expect(
        DeathCheck.probability(testCharacter(age: 40, health: 5)),
        greaterThan(DeathCheck.probability(testCharacter(age: 40, health: 60))),
      );
    });

    test('çocuklar yaşa bağlı ihtimalle ölmez, sağlık 0 ise ölür', () {
      for (var age = 0; age < DeathCheck.adultAge; age++) {
        expect(DeathCheck.probability(testCharacter(age: age, health: 5)), 0);
      }
      expect(
        DeathCheck(SeededRandom(1)).check(testCharacter(age: 10, health: 0)),
        DeathCause.health,
      );
    });

    test('üst yaş sınırında herkes ölür', () {
      expect(DeathCheck.probability(testCharacter(age: DeathCheck.maxAge)), 1);
    });
  });

  group('SummaryBuilder', () {
    final deck = EventDeck([
      testCard('a'),
      testCard('n', rarity: 'nadir'),
      testCard('e', rarity: 'efsane'),
    ]);

    CardRecord seen(String id, int age) =>
        CardRecord(age: age, cardId: id, side: ChoiceSide.left);

    test('en büyük an en nadir karttır', () {
      final c = testCharacter(
        history: [seen('a', 3), seen('n', 10), seen('e', 40), seen('n', 50)],
      );
      final summary = SummaryBuilder(deck)
          .build(c, DeathCause.natural, Market.initial);
      expect(summary.biggestMoment!.cardId, 'e');
      expect(summary.cardsSeen, 4);
    });

    test('nadir kart yoksa en büyük an boştur', () {
      final c = testCharacter(history: [seen('a', 3)]);
      expect(
        SummaryBuilder(deck)
            .build(c, DeathCause.natural, Market.initial)
            .biggestMoment,
        isNull,
      );
    });

    Nickname nick(Character c) => SummaryBuilder.nicknameFor(c, Market.initial);

    test('özel durumlar önce gelir: asırlık, zengin, borçlu', () {
      expect(nick(testCharacter(age: 97, money: -10)), Nickname.asirlikCinar);
      expect(
        nick(
          testCharacter(money: SummaryBuilder.richThreshold, reputation: 99),
        ),
        Nickname.mahalleninZengini,
      );
      expect(
        nick(testCharacter(money: -10, family: 99)),
        Nickname.borcYigidinKamcisi,
      );
    });

    test('en belirgin özellik kazanır', () {
      expect(
        nick(testCharacter(family: 95, reputation: 85)),
        Nickname.bayramlarinBasKosesi,
      );
      expect(
        nick(testCharacter(family: 82, knowledge: 90)),
        Nickname.mahalleninProfesoru,
      );
      expect(nick(testCharacter(happiness: 88)), Nickname.hepGulen);
    });

    test('ev sahipliği küçük bir pay sayılır', () {
      const house = Assets(houses: 1);
      expect(
        nick(testCharacter(assets: house, reputation: 82)),
        Nickname.evSahibi,
      );
      expect(
        nick(testCharacter(assets: house, reputation: 90)),
        Nickname.sozuDinlenen,
      );
      expect(
        nick(testCharacter(assets: house, flags: {SummaryBuilder.soldierFlag})),
        Nickname.evSahibi,
      );
      expect(
        nick(testCharacter(flags: {SummaryBuilder.soldierFlag})),
        Nickname.bizimBolukte,
      );
      expect(nick(testCharacter()), Nickname.mahalleninBildikYuzu);
    });
  });

  group('ActionCatalog', () {
    test('yıllık hak evreye göre: çocuk 2, öğrenci 4, çalışan 2, emekli 4', () {
      expect(ActionCatalog.allowanceFor(testCharacter(age: 5)), 2);
      expect(ActionCatalog.allowanceFor(testCharacter(age: 16)), 4);
      expect(ActionCatalog.allowanceFor(testCharacter(age: 25)), 2);
      expect(
        ActionCatalog.allowanceFor(
          testCharacter(age: 21, flags: {ActionCatalog.studentFlag}),
        ),
        4,
      );
      expect(ActionCatalog.allowanceFor(testCharacter(age: 40)), 2);
      expect(
        ActionCatalog.allowanceFor(testCharacter(age: 70, pension: 140000)),
        4,
      );
      expect(
        ActionCatalog.allowanceFor(testCharacter(age: 60, pension: 140000)),
        4,
        reason: 'erken emekli',
      );
    });

    test('ücretli aksiyonlar: spor 500 TL, tatil 25.000 TL', () {
      expect(ActionCatalog.byId('spor')!.cost, 500);
      expect(ActionCatalog.byId('tatil')!.cost, 25000);
      expect(
        ActionCatalog.byId('tatil')!
            .canAfford(testCharacter(money: 24999), Market.initial),
        isFalse,
      );
    });

    test('aksiyon kimlikleri tekrar etmez', () {
      final ids = ActionCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('her yaşta en az bir ücretsiz aksiyon vardır', () {
      for (var age = 0; age <= DeathCheck.maxAge; age++) {
        final c = testCharacter(age: age, money: 0);
        expect(
          ActionCatalog.availableFor(c).any((a) => a.cost == 0),
          isTrue,
          reason: '$age yaş',
        );
      }
    });
  });
}
