import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/test_character.dart';

Character _apply(Character c, Effect e) => EffectResolver.applyEffect(c, e);

void main() {
  group('varlık etkileri', () {
    test('altın eklenir, eldekinden fazlası düşülemez', () {
      final c = _apply(testCharacter(), const Effect(gold: 50));
      expect(c.assets.goldGrams, 50);
      expect(_apply(c, const Effect(gold: -80)).assets.goldGrams, 0);
    });

    test('yeni araba değeriyle eklenir, satılan araba değerini götürür', () {
      var c = _apply(testCharacter(), const Effect(car: 2));
      expect(c.assets.cars, 2);
      expect(c.assets.carValue, 2 * Economy.newCarValue);
      c = _apply(c, const Effect(car: -1));
      expect(c.assets.cars, 1);
      expect(c.assets.carValue, Economy.newCarValue);
    });

    test('kira zammı kirayı kalıcı artırır', () {
      final c = _apply(testCharacter(), const Effect(rentChange: 24000));
      expect(c.assets.rent, Assets.defaultRent + 24000);
    });

    test('kredi faiziyle eşit taksitlere bölünür', () {
      final c = _apply(
        testCharacter(),
        const Effect(loan: LoanTerms(amount: 1000000, years: 10)),
      );
      expect(c.assets.loanYearsLeft, 10);
      expect(c.assets.loanPayment, 130000);
      expect(c.assets.remainingLoan, 1300000);
    });

    test('ikinci kredi kalan borca eklenir', () {
      var c = _apply(
        testCharacter(),
        const Effect(loan: LoanTerms(amount: 100000, years: 2)),
      );
      c = _apply(c, const Effect(loan: LoanTerms(amount: 100000, years: 4)));
      expect(c.assets.loanYearsLeft, 4);
      expect(c.assets.remainingLoan, closeTo(260000, 4));
    });
  });

  group('türetilen bayraklar', () {
    test('ev alınca ev sahibi olunur ve kiracılık biter', () {
      final renter = Economy.syncDerivedFlags(
        testCharacter(money: 2000000, home: HomeKind.kira),
      );
      expect(renter.hasFlag(Economy.renterFlag), isTrue);
      final c = Housing.buyHouse(renter);
      expect(c.home, HomeKind.kendiEvi);
      expect(c.hasFlag(Economy.homeOwnerFlag), isTrue);
      expect(c.hasFlag(Economy.renterFlag), isFalse);
      expect(c.stats.money, 2000000 - Housing.housePayment(renter));
      expect(c.assets.hasLoan, isTrue);
    });

    test('ev elden çıkınca ev sahipliği biter', () {
      final owner = _apply(testCharacter(), const Effect(house: 1));
      final c = _apply(owner, const Effect(house: -1));
      expect(c.hasFlag(Economy.homeOwnerFlag), isFalse);
    });

    test('altın ve araba bayrakları varlığa göre açılır', () {
      final c = _apply(testCharacter(), const Effect(gold: 1, car: 1));
      expect(c.hasFlag(Economy.goldOwnerFlag), isTrue);
      expect(c.hasFlag(Economy.carOwnerFlag), isTrue);
    });
  });

  group('EconomyTick', () {
    test('enflasyon aralıkta ve nakit yarısı kadar erir', () {
      for (var seed = 0; seed < 50; seed++) {
        final (c, market, report) = EconomyTick(SeededRandom(seed))
            .apply(testCharacter(money: 1000000), Market.initial);
        expect(report.inflation, inInclusiveRange(0.15, 0.45));
        expect(market.inflation, report.inflation);
        expect(report.cashEroded, (1000000 * report.inflation / 2).round());
        expect(c.stats.money, 1000000 - report.cashEroded);
      }
    });

    test('çocuğun kumbarası erimez; 18 yaşında erimeye başlar', () {
      final (kid, _, kidReport) = EconomyTick(SeededRandom(3))
          .apply(testCharacter(age: 12, money: 5000), Market.initial);
      expect(kidReport.cashEroded, 0);
      expect(kid.stats.money, 5000);
      final (_, _, adultReport) = EconomyTick(SeededRandom(3))
          .apply(testCharacter(age: 18, money: 5000), Market.initial);
      expect(adultReport.cashEroded, greaterThan(0));
    });

    test('faiz borcun en fazla 1 milyonuna işler', () {
      final (c, _, report) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: -20000000), Market.initial);
      expect(report.debtInterest, 150000);
      expect(c.stats.money, -20150000);
    });

    test('borç erimez ama faiz işler', () {
      final (c, _, report) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: -50000), Market.initial);
      expect(report.cashEroded, 0);
      expect(report.debtInterest, 7500);
      expect(c.stats.money, -57500);
    });

    test('kira ve yaşam gideri yalnızca evden çıkmış olandan alınır', () {
      final (renter, _, r1) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: 0, home: HomeKind.kira), Market.initial);
      expect(r1.rentPaid, Assets.defaultRent);
      expect(r1.livingCost, Economy.livingCost);
      expect(renter.stats.money, -Assets.defaultRent - Economy.livingCost);

      final (sharer, _, r3) = EconomyTick(SeededRandom(1)).apply(
        testCharacter(money: 0, home: HomeKind.evArkadasi),
        Market.initial,
      );
      expect(r3.rentPaid, Assets.defaultRent ~/ 2);
      expect(sharer.stats.money, -Assets.defaultRent ~/ 2 - Economy.livingCost);

      final (_, _, r4) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: 0, home: HomeKind.yurt), Market.initial);
      expect(r4.rentPaid, 0);
      expect(r4.livingCost, Economy.dormCost);

      final (other, _, r2) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: 0), Market.initial);
      expect(r2.rentPaid, 0);
      expect(other.stats.money, 0);
    });

    test('kredi taksidi ödenir ve süre bitince kredi kapanır', () {
      var c = testCharacter(
        money: 0,
        assets: const Assets(loanPayment: 50000, loanYearsLeft: 2),
      );
      final tick = EconomyTick(SeededRandom(1));
      var market = Market.initial;
      (c, market, _) = tick.apply(c, market);
      expect(c.stats.money, -50000);
      expect(c.assets.loanYearsLeft, 1);
      (c, market, _) = tick.apply(c, market);
      // İkinci yıl: taksit ve geçen yılın eksisinin faizi (%15).
      expect(c.stats.money, -107500);
      expect(c.assets.hasLoan, isFalse);
      expect(c.assets.loanPayment, 0);
      (c, market, _) = tick.apply(c, market);
      // Kredi bitti; eksiye yalnızca faiz işler.
      expect(c.stats.money, -123625);
    });

    test('araba masraf çıkarır, eskir ve keyif verir', () {
      final (c, _, report) = EconomyTick(SeededRandom(1)).apply(
        testCharacter(
          money: 0,
          happiness: 50,
          reputation: 50,
          assets: const Assets(cars: 1, carValue: 600000),
        ),
        Market.initial,
      );
      expect(report.carCost, Economy.carYearlyCost);
      expect(c.stats.money, -Economy.carYearlyCost);
      expect(c.assets.carValue, 570000);
      expect(c.stats.happiness, 52);
      expect(c.stats.reputation, 51);
    });

    test('altın fiyatı %-15 ile %+15 arasında oynar', () {
      for (var seed = 0; seed < 50; seed++) {
        final (_, market, report) = EconomyTick(SeededRandom(seed))
            .apply(testCharacter(), Market.initial);
        expect(report.goldPriceChange, inInclusiveRange(-0.15, 0.15));
        expect(
          market.goldPrice,
          inInclusiveRange(
            (Economy.initialGoldPrice * 0.85).floor(),
            (Economy.initialGoldPrice * 1.15).ceil(),
          ),
        );
      }
    });

    test('altın 80 yılda değerini korur: çok düşmez, uçmaz', () {
      final finals = <int>[];
      for (var seed = 0; seed < 300; seed++) {
        final random = SeededRandom(seed);
        var market = Market.initial;
        for (var year = 0; year < 80; year++) {
          (_, market, _) = EconomyTick(random).apply(testCharacter(), market);
        }
        finals.add(market.goldPrice);
      }
      finals.sort();
      printOnFailure('en düşük ${finals.first}, en yüksek ${finals.last}');
      // Hayatların %95'inde fiyat başlangıcın yarısı ile iki katı arasında.
      final inside = finals
          .where(
            (p) =>
                p >= Economy.initialGoldPrice / 2 &&
                p <= Economy.initialGoldPrice * 2,
          )
          .length;
      expect(inside / finals.length, greaterThan(0.95));
    });
  });

  test('net servet varlıkları toplar, kalan krediyi düşer', () {
    final c = testCharacter(
      money: 100000,
      assets: const Assets(
        goldGrams: 10,
        houses: 1,
        houseValue: 3000000,
        carValue: 400000,
        loanPayment: 50000,
        loanYearsLeft: 4,
      ),
    );
    expect(
      Economy.netWorth(c, const Market(goldPrice: 3000)),
      100000 + 30000 + 3000000 + 400000 - 200000,
    );
  });

  group('altın aksiyonları', () {
    final buy = ActionCatalog.byId('altin_al')!;
    final sell = ActionCatalog.byId('altin_sat')!;
    const market = Market(goldPrice: 3200);

    test('alım o yılın fiyatıyla ödenir', () {
      expect(buy.moneyChange(market), -32000);
      expect(buy.canAfford(testCharacter(money: 31999), market), isFalse);
      expect(buy.canAfford(testCharacter(money: 32000), market), isTrue);
    });

    test('satış için elde yeterli altın olmalı', () {
      expect(sell.moneyChange(market), 32000);
      expect(sell.canAfford(testCharacter(money: 0), market), isFalse);
      final rich = testCharacter(money: 0, assets: const Assets(goldGrams: 10));
      expect(sell.canAfford(rich, market), isTrue);
    });

    test('motorda alıp satmak altını ve nakdi değiştirir', () {
      final engine = LifeEngine(deck: EventDeck([]), seed: 1);
      engine.startLife();
      while (engine.state.character.age < 19) {
        engine.advanceYear();
      }
      final before = engine.state.character;
      final price = engine.market.goldPrice;
      final after = engine.doAction('altin_al').character;
      expect(after.assets.goldGrams, before.assets.goldGrams + 10);
      expect(after.stats.money, before.stats.money - 10 * price);
      expect(after.hasFlag(Economy.goldOwnerFlag), isTrue);
    });
  });

  test('yaşlanma ekonomiyi işletir ve piyasayı ilerletir', () {
    // 18 yaş desteği kirayı karşılayan bir hayat: ev arkadaşıyla kiraya
    // çıkar (gelir şartı).
    late LifeEngine engine;
    for (var seed = 0; ; seed++) {
      expect(seed, lessThan(300), reason: 'kira gücü olan hayat bulunamadı');
      engine = LifeEngine(
        deck: EventDeck(const []),
        seed: seed,
        families: realFamilies(),
      )..startLife();
      expect(engine.lastEconomy, isNull);
      while (engine.state.character.age < 18) {
        engine.advanceYear();
      }
      final ok = engine.availableActions().any(
        (a) => a.$1.id == 'ev_arkadasi' && a.$2,
      );
      if (ok) break;
    }
    final c = engine.doAction('ev_arkadasi').character;
    expect(c.home, HomeKind.evArkadasi);
    engine.advanceYear();
    final report = engine.lastEconomy!;
    expect(report.rentPaid, Economy.rentFor(c.city) ~/ 2);
    expect(report.livingCost, Economy.livingCost);
    expect(engine.market.inflation, report.inflation);
    expect(engine.market.goldPrice, isNot(Economy.initialGoldPrice));
  });
}
