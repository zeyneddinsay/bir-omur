import 'dart:math';

import '../models/models.dart';
import 'careers.dart';

/// Hayat boyunca değişen piyasa: altın fiyatı ve son yılın enflasyonu.
/// Değişmezdir; kayda girer.
class Market {
  const Market({required this.goldPrice, this.inflation = 0});

  static const Market initial = Market(goldPrice: Economy.initialGoldPrice);

  /// Bir gram altının bugünkü fiyatı (TL).
  final int goldPrice;

  /// Son yılın enflasyonu (0,15 = %15). İlk yıl 0.
  final double inflation;

  Map<String, Object> toJson() => {'gold': goldPrice, 'inflation': inflation};

  factory Market.fromJson(Map<String, dynamic> json) => Market(
    goldPrice: json['gold'] as int,
    inflation: (json['inflation'] as num).toDouble(),
  );
}

/// Bir yılın ekonomik dökümü; arayüz "bu yıl ne oldu" diye gösterir.
class EconomyReport {
  const EconomyReport({
    required this.inflation,
    this.cashEroded = 0,
    this.rentPaid = 0,
    this.loanPaid = 0,
    this.carCost = 0,
    this.goldPriceChange = 0,
  });

  final double inflation;
  final int cashEroded;
  final int rentPaid;
  final int loanPaid;
  final int carCost;
  final double goldPriceChange;
}

/// Ekonomi kuralları ve sabitleri. Tutarlar bugünün TL'siyle.
abstract final class Economy {
  static const double minInflation = 0.15;
  static const double maxInflation = 0.45;

  /// Nakit, yılın enflasyonunun bu oranı kadar erir (%30 enflasyon → %15).
  static const double cashErosionShare = 0.5;

  static const int initialGoldPrice = 3000;
  static const double goldMinChange = -0.15;
  static const double goldMaxChange = 0.25;

  /// Evin bugünkü değeri; reel olarak sabit kalır.
  static const int houseValue = 1500000;

  static const int newCarValue = 600000;
  static const double carYearlyDepreciation = 0.05;
  static const int carYearlyCost = 15000;

  /// Araba sahibine her yıl küçük bir keyif ve itibar verir.
  static const Effect carYearlyBonus = Effect(
    stats: {StatKind.happiness: 2, StatKind.reputation: 1},
  );

  /// Varlıklardan türetilen bayraklar. Kartlar bunlara koşul olarak
  /// bakabilir ama ekleyip kaldıramaz; motor her değişiklikten sonra
  /// varlıklara göre düzeltir.
  static const String homeOwnerFlag = 'ev_sahibi';
  static const String carOwnerFlag = 'araba_var';
  static const String goldOwnerFlag = 'altin_var';
  static const String renterFlag = 'kiraci';

  static const Set<String> derivedFlags = {
    homeOwnerFlag,
    carOwnerFlag,
    goldOwnerFlag,
    Careers.retiredFlag,
  };

  /// Nakit, altın, ev ve arabanın toplamından kalan kredi borcu düşülür.
  static int netWorth(Character c, Market market) {
    final a = c.assets;
    return c.stats.money +
        a.goldGrams * market.goldPrice +
        a.houses * houseValue +
        a.carValue -
        a.remainingLoan;
  }

  /// Bir etkinin varlık kısmını uygular: altın, ev, araba, kira, kredi.
  /// Göstergeler, para ve bayraklar EffectResolver'dadır.
  static Character applyAssetEffect(Character c, Effect effect) {
    if (effect.gold == 0 &&
        effect.house == 0 &&
        effect.car == 0 &&
        effect.rentChange == 0 &&
        !effect.rentReset &&
        effect.loan == null) {
      return c;
    }
    var a = c.assets;
    a = a.copyWith(
      goldGrams: max(0, a.goldGrams + effect.gold),
      houses: max(0, a.houses + effect.house),
      rent: max(
        0,
        (effect.rentReset ? Assets.defaultRent : a.rent) + effect.rentChange,
      ),
    );
    if (effect.car > 0) {
      a = a.copyWith(
        cars: a.cars + effect.car,
        carValue: a.carValue + effect.car * newCarValue,
      );
    } else if (effect.car < 0 && a.cars > 0) {
      final sold = min(-effect.car, a.cars);
      final valueEach = a.carValue ~/ a.cars;
      a = a.copyWith(
        cars: a.cars - sold,
        carValue: a.carValue - sold * valueEach,
      );
    }
    if (effect.loan case final loan?) {
      // Yeni kredi eskisinin kalanına eklenir; süre en uzun olanı alır.
      final years = max(loan.years, a.loanYearsLeft);
      final total = a.remainingLoan + loan.yearlyPayment * loan.years;
      a = a.copyWith(
        loanYearsLeft: years,
        loanPayment: (total / years).round(),
      );
    }
    return c.copyWith(assets: a);
  }

  /// Türetilen bayrakları varlıklarla ve emeklilikle uyumlu hâle getirir. Ev sahibi
  /// kiracı sayılmaz.
  static Character syncDerivedFlags(Character c) {
    final a = c.assets;
    final flags = {...c.flags};
    void set(String flag, bool on) => on ? flags.add(flag) : flags.remove(flag);
    set(homeOwnerFlag, a.houses > 0);
    set(carOwnerFlag, a.cars > 0);
    set(goldOwnerFlag, a.goldGrams > 0);
    set(Careers.retiredFlag, c.isRetired);
    if (a.houses > 0) flags.remove(renterFlag);
    if (flags.length == c.flags.length && flags.containsAll(c.flags)) return c;
    return c.copyWith(flags: flags);
  }
}

/// Yılın ekonomisi: enflasyon nakdi eritir, altın dalgalanır, araba eskir,
/// kira ve kredi taksidi ödenir. Yaşlanmadan (YearTick) önce çalışır; yılın
/// geliri erimeden sonra eklenir.
class EconomyTick {
  const EconomyTick(this.random);

  final Random random;

  (Character, Market, EconomyReport) apply(Character c, Market market) {
    final inflation =
        Economy.minInflation +
        random.nextDouble() * (Economy.maxInflation - Economy.minInflation);
    final goldChange =
        Economy.goldMinChange +
        random.nextDouble() * (Economy.goldMaxChange - Economy.goldMinChange);
    final nextMarket = Market(
      goldPrice: max(1, (market.goldPrice * (1 + goldChange)).round()),
      inflation: inflation,
    );

    var money = c.stats.money;
    final eroded = money > 0
        ? (money * inflation * Economy.cashErosionShare).round()
        : 0;
    money -= eroded;

    var a = c.assets;
    final rentPaid = c.hasFlag(Economy.renterFlag) && a.houses == 0
        ? a.rent
        : 0;
    money -= rentPaid;

    var loanPaid = 0;
    if (a.hasLoan) {
      loanPaid = a.loanPayment;
      final yearsLeft = a.loanYearsLeft - 1;
      a = a.copyWith(
        loanYearsLeft: yearsLeft,
        loanPayment: yearsLeft == 0 ? 0 : a.loanPayment,
      );
      money -= loanPaid;
    }

    final carCost = a.cars * Economy.carYearlyCost;
    money -= carCost;
    a = a.copyWith(
      carValue: (a.carValue * (1 - Economy.carYearlyDepreciation)).round(),
    );

    var stats = c.stats.copyWith(money: money);
    if (a.cars > 0) {
      Economy.carYearlyBonus.stats.forEach(
        (kind, delta) => stats = stats.withDelta(kind, delta),
      );
    }

    return (
      c.copyWith(stats: stats, assets: a),
      nextMarket,
      EconomyReport(
        inflation: inflation,
        cashEroded: eroded,
        rentPaid: rentPaid,
        loanPaid: loanPaid,
        carCost: carCost,
        goldPriceChange: goldChange,
      ),
    );
  }
}
