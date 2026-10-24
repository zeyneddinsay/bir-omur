import 'dart:math';

import '../models/models.dart';
import 'business.dart';
import 'careers.dart';
import 'cities.dart';

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
    this.livingCost = 0,
    this.childCost = 0,
    this.spouseIncome = 0,
    this.debtInterest = 0,
    this.goldPriceChange = 0,
  });

  final double inflation;
  final int cashEroded;
  final int rentPaid;
  final int loanPaid;
  final int carCost;

  /// Ev dışında yaşamanın yıllık gideri (yurt, kira evi, kendi evin).
  final int livingCost;

  /// Evdeki çocukların gideri ve çalışan eşin hanenin bütçesine kattığı.
  final int childCost;
  final int spouseIncome;

  /// Eksi bakiyenin yıllık faizi.
  final int debtInterest;
  final double goldPriceChange;
}

/// Ekonomi kuralları ve sabitleri. Tutarlar bugünün TL'siyle.
abstract final class Economy {
  static const double minInflation = 0.15;
  static const double maxInflation = 0.45;

  /// Nakit, yılın enflasyonunun bu oranı kadar erir (%30 enflasyon → %15).
  static const double cashErosionShare = 0.5;

  /// Bu yaştan önce nakit enflasyonla erimez (çocuğun kumbarası).
  static const int erosionMinAge = 18;

  static const int initialGoldPrice = 6500;
  static const double goldMinChange = -0.15;
  static const double goldMaxChange = 0.15;

  /// Altın fiyatının başlangıç değerine dönme gücü (log fark başına).
  static const double goldReversion = 0.12;

  /// Evin bugünkü değeri (orta şehir); reel olarak sabit kalır. 2026
  /// Türkiye ortalaması yaklaşık 5 milyon.
  static const int houseValue = 5000000;

  static const int newCarValue = 1800000;
  static const double carYearlyDepreciation = 0.05;
  static const int carYearlyCost = 50000;

  /// Kira, şehrin taban kirasının bu katını geçmez; zamlar bugünün
  /// parasıyla sınırsız büyümesin.
  static const int maxRentFactor = 2;

  /// Şehrin taban yıllık kirası (100 m², 2026: orta şehir 330 bin).
  /// Bir evin bu şehirdeki fiyatı.
  static int houseValueIn(String city) =>
      (houseValue * Cities.typeOf(city).rent).round();

  static int rentFor(String city) =>
      (Assets.defaultRent * Cities.typeOf(city).rent).round();

  static int maxRentFor(String city) => maxRentFactor * rentFor(city);

  /// Ev dışında yaşamanın yıllık gideri (yemek, fatura, ulaşım).
  static const int livingCost = 150000;

  /// Yurdun yıllık gideri.
  static const int dormCost = 60000;

  /// Nerede yaşandığına göre yıllık yaşam gideri.
  /// Eksi bakiyenin yıllık faizi.
  static const double debtInterestRate = 0.15;

  /// Faizin işlediği borcun üst sınırı (yıllık faiz en fazla 150 bin).
  static const int interestBearingDebtCap = 1000000;

  /// Emeklinin yaşam gideri daha düşüktür.
  static const int retiredLivingCost = 100000;

  /// Evdeki (18 yaşından küçük) çocuk başına yıllık gider.
  static const int childYearlyCost = 100000;

  /// Çalışan eşin hanenin bütçesine kattığı (kendi gideri düşülmüş).
  static const int spouseNetIncome = 300000;

  /// Çalışmayan eşin gideri.
  static const int spouseCost = 150000;

  static int childCostOf(Character c) =>
      c.people.all
          .where(
            (p) =>
                p.isAlive &&
                p.kin == Kinship.cocuk &&
                p.bornAt <= c.age &&
                p.ageAt(c.age) < 19,
          )
          .length *
      childYearlyCost;

  /// Eşin hane bütçesine etkisi: çalışıyorsa artı, çalışmıyorsa eksi.
  static int spouseIncomeOf(Character c) {
    final spouse = c.people.all
        .where((p) => p.kin == Kinship.es && p.isAlive)
        .firstOrNull;
    if (spouse == null) return 0;
    // Emekli eşin aylığı kendi giderini karşılar.
    if (spouse.occupation == 'emekli' || spouse.ageAt(c.age) >= 65) return 0;
    const idle = {null, 'ev_hanimi', 'ogrenci'};
    return idle.contains(spouse.occupation) ? -spouseCost : spouseNetIncome;
  }

  /// Oyuncunun bu yılki yaşam gideri: aile evinde anne ya da baba yoksa
  /// (vefat, taşınma) gider kendisine kalır, kira yoktur.
  static int livingCostOf(Character c) {
    final base = c.home == HomeKind.aile && c.age > 18 && _parentsGone(c)
        ? livingCost
        : livingCostFor(c.home);
    return c.isRetired && base > retiredLivingCost ? retiredLivingCost : base;
  }

  /// Anne ve baba biliniyor ama hiçbiri oyuncunun şehrinde yaşamıyor.
  static bool _parentsGone(Character c) =>
      c.people.all.any((p) => p.kin == Kinship.anne || p.kin == Kinship.baba) &&
      !parentInCity(c);

  /// Oyuncunun şehrinde yaşayan anne ya da babası var mı.
  static bool parentInCity(Character c) => c.people
      .bornBy(c.age)
      .any(
        (p) =>
            p.isAlive &&
            (p.kin == Kinship.anne || p.kin == Kinship.baba) &&
            p.city == c.city,
      );

  static int livingCostFor(HomeKind home) => switch (home) {
    HomeKind.aile || HomeKind.cocukYaninda => 0,
    HomeKind.yurt => dormCost,
    _ => livingCost,
  };

  /// Bu yıl ödenecek kira: kirada tamamı, ev arkadaşıyla yarısı.
  static int rentDue(Character c) => switch (c.home) {
    HomeKind.kira => c.assets.rent,
    HomeKind.evArkadasi => c.assets.rent ~/ 2,
    _ => 0,
  };

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

  /// En az bir kez taşınmış (taşınma sayacından türetilir).
  static const String movedFlag = 'tasindi';

  /// Bu yıl ya da geçen yıl başka şehre taşındı (hoş geldin olayları).
  static const String newlyMovedFlag = 'yeni_tasindi';

  /// Bu yıl ya da geçen yıl emekli oldu (emekliliğin ilk sabahı).
  static const String newlyRetiredFlag = 'yeni_emekli';

  static const Set<String> derivedFlags = {
    homeOwnerFlag,
    renterFlag,
    movedFlag,
    newlyMovedFlag,
    newlyRetiredFlag,
    carOwnerFlag,
    goldOwnerFlag,
    Careers.retiredFlag,
  };

  /// Nakit, altın, ev, araba ve işletmelerin (satış ya da kapanış değeri,
  /// ortağın payı düşülmüş) toplamından kalan kredi borcu düşülür.
  static int netWorth(Character c, Market market) {
    final a = c.assets;
    return c.stats.money +
        a.goldGrams * market.goldPrice +
        a.houseValue +
        a.carValue -
        a.remainingLoan +
        c.businesses.fold(
          0,
          (sum, b) =>
              sum + BusinessRules.exitValue(b, sell: BusinessRules.canSell(b)),
        );
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
      houseValue: effect.house > 0
          ? a.houseValue + effect.house * houseValueIn(c.city)
          : a.houses == 0
          ? 0
          : a.houseValue -
                min(-effect.house, a.houses) * (a.houseValue ~/ a.houses),
      rent: ((effect.rentReset ? rentFor(c.city) : a.rent) + effect.rentChange)
          .clamp(0, maxRentFor(c.city)),
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
    set(renterFlag, c.home.paysRent);
    set(movedFlag, c.counters.moves > 0);
    final moved = c.counters.lastMoveAt;
    set(newlyMovedFlag, moved != null && c.age - moved <= 1);
    final retired = c.counters.retiredAt;
    set(newlyRetiredFlag, retired != null && c.age - retired <= 1);
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
    // Altın gerçek değerini korur: yıllık oynaklık ±%15, ama fiyat başlangıç
    // değerinden uzaklaştıkça geri çekilir (yoksa 40 yılda %75 düşebiliyordu;
    // nakdi eriyen oyuncuya altın tuzak olurdu).
    final reversion =
        Economy.goldReversion *
        log(Economy.initialGoldPrice / max(1, market.goldPrice));
    final goldChange =
        (Economy.goldMinChange +
                random.nextDouble() *
                    (Economy.goldMaxChange - Economy.goldMinChange) +
                reversion)
            .clamp(Economy.goldMinChange, Economy.goldMaxChange);
    final nextMarket = Market(
      goldPrice: max(1, (market.goldPrice * (1 + goldChange)).round()),
      inflation: inflation,
    );

    var money = c.stats.money;
    // Çocuğun kumbarası erimez (karar, 23 Ekim 2026): 18 yaşına kadar
    // enflasyon nakde dokunmaz.
    final eroded = money > 0 && c.age >= Economy.erosionMinAge
        ? (money * inflation * Economy.cashErosionShare).round()
        : 0;
    money -= eroded;
    // Borç bedava değil: eksi bakiyeye faiz işler. Faiz borcun en fazla
    // [Economy.interestBearingDebtCap] kadarına işler; gelirsiz yaşlılıkta
    // borç katlanarak yüz milyonlara çıkmaz.
    final debtInterest = money < 0
        ? (min(-money, Economy.interestBearingDebtCap) *
                  Economy.debtInterestRate)
              .round()
        : 0;
    money -= debtInterest;

    var a = c.assets;
    final rentPaid = Economy.rentDue(c);
    money -= rentPaid;
    // Askerdeki yıl yaşam gideri yok (kira sürer).
    final livingCost = c.hasFlag('askerde') ? 0 : Economy.livingCostOf(c);
    money -= livingCost;
    final childCost = Economy.childCostOf(c);
    money -= childCost;
    final spouseIncome = Economy.spouseIncomeOf(c);
    money += spouseIncome;

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
      c.copyWith(
        stats: stats,
        assets: a,
        counters: c.counters.copyWith(rentPaid: c.counters.rentPaid + rentPaid),
      ),
      nextMarket,
      EconomyReport(
        inflation: inflation,
        cashEroded: eroded,
        rentPaid: rentPaid,
        loanPaid: loanPaid,
        carCost: carCost,
        livingCost: livingCost,
        childCost: childCost,
        spouseIncome: spouseIncome,
        debtInterest: debtInterest,
        goldPriceChange: goldChange,
      ),
    );
  }
}
