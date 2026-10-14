import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
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
      final c = _apply(
        testCharacter(flags: {'kiraci'}),
        const Effect(house: 1),
      );
      expect(c.hasFlag(Economy.homeOwnerFlag), isTrue);
      expect(c.hasFlag(Economy.renterFlag), isFalse);
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

    test('borç erimez', () {
      final (c, _, report) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: -50000), Market.initial);
      expect(report.cashEroded, 0);
      expect(c.stats.money, -50000);
    });

    test('kira yalnızca kiracıdan alınır', () {
      final (renter, _, r1) = EconomyTick(SeededRandom(1))
          .apply(testCharacter(money: 0, flags: {'kiraci'}), Market.initial);
      expect(r1.rentPaid, Assets.defaultRent);
      expect(renter.stats.money, -Assets.defaultRent);

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
      expect(c.stats.money, -100000);
      expect(c.assets.hasLoan, isFalse);
      expect(c.assets.loanPayment, 0);
      (c, market, _) = tick.apply(c, market);
      expect(c.stats.money, -100000);
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
        expect(market.goldPrice, inInclusiveRange(2550, 3450));
      }
    });
  });

  test('net servet varlıkları toplar, kalan krediyi düşer', () {
    final c = testCharacter(
      money: 100000,
      assets: const Assets(
        goldGrams: 10,
        houses: 1,
        carValue: 400000,
        loanPayment: 50000,
        loanYearsLeft: 4,
      ),
    );
    expect(
      Economy.netWorth(c, const Market(goldPrice: 3000)),
      100000 + 30000 + Economy.houseValue + 400000 - 200000,
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
    final engine = LifeEngine(
      deck: EventDeck([
        testCard(
          'kirala',
          maxAge: 0,
          left: {
            'label': 'Sol',
            'effects': {
              'addFlags': ['kiraci'],
            },
          },
        ),
      ]),
      seed: 4,
    );
    engine.startLife();
    engine.choose(ChoiceSide.left);
    expect(engine.lastEconomy, isNull);
    engine.advanceYear();
    final report = engine.lastEconomy!;
    expect(report.rentPaid, Assets.defaultRent);
    expect(engine.market.inflation, report.inflation);
    expect(engine.market.goldPrice, isNot(Economy.initialGoldPrice));
  });
}
