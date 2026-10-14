import 'assets.dart';
import 'career.dart';
import 'json_reader.dart';
import 'stats.dart';

/// Bir seçimin karaktere etkisi: göstergeler, para, varlıklar, bayraklar
/// ve ileri bir yıla planlanan zincir kartı.
class Effect {
  const Effect({
    this.stats = const {},
    this.money = 0,
    this.gold = 0,
    this.house = 0,
    this.car = 0,
    this.rentChange = 0,
    this.rentReset = false,
    this.loan,
    this.career,
    this.addFlags = const [],
    this.removeFlags = const [],
    this.schedule,
  });

  static const Effect none = Effect();

  static const String moneyKey = 'money';
  static const String goldKey = 'gold';
  static const String houseKey = 'house';
  static const String carKey = 'car';
  static const String rentChangeKey = 'rentChange';
  static const String rentResetKey = 'rentReset';
  static const String loanKey = 'loan';
  static const String careerKey = 'career';
  static const String addFlagsKey = 'addFlags';
  static const String removeFlagsKey = 'removeFlags';
  static const String scheduleKey = 'schedule';

  /// Kart JSON'unda bir etki nesnesinin alabileceği bütün anahtarlar.
  static final Set<String> knownKeys = {
    for (final kind in StatKind.values) kind.key,
    moneyKey,
    goldKey,
    houseKey,
    carKey,
    rentChangeKey,
    rentResetKey,
    loanKey,
    careerKey,
    addFlagsKey,
    removeFlagsKey,
    scheduleKey,
  };

  final Map<StatKind, int> stats;
  final int money;

  /// Altın, gram olarak. Eksi değer satış değil kayıptır (örnek: takı
  /// takmak); eldekinden fazlası düşülemez.
  final int gold;

  /// Eklenen ya da elden çıkan ev ve araba sayısı. Fiyatı ayrıca [money]
  /// ya da [loan] ile yazılır.
  final int house;
  final int car;

  /// Yıllık kiraya eklenen tutar (kira zammı).
  final int rentChange;

  /// Taşınınca kira piyasa değerine ([Assets.defaultRent]) döner.
  final bool rentReset;
  final LoanTerms? loan;

  /// İşe girme, terfi, istifa ya da emeklilik.
  final CareerChange? career;
  final List<String> addFlags;
  final List<String> removeFlags;
  final ScheduledEvent? schedule;

  bool get isEmpty =>
      stats.isEmpty &&
      money == 0 &&
      gold == 0 &&
      house == 0 &&
      car == 0 &&
      rentChange == 0 &&
      !rentReset &&
      loan == null &&
      career == null &&
      addFlags.isEmpty &&
      removeFlags.isEmpty &&
      schedule == null;

  factory Effect.fromJson(JsonReader r) {
    r.rejectUnknownKeys(knownKeys);
    final stats = <StatKind, int>{};
    for (final kind in StatKind.values) {
      final delta = r.optionalInt(kind.key);
      if (delta != null) stats[kind] = delta;
    }
    final schedule = r.optionalObject(scheduleKey);
    final loan = r.optionalObject(loanKey);
    final career = r.optionalObject(careerKey);
    return Effect(
      stats: Map.unmodifiable(stats),
      money: r.optionalInt(moneyKey) ?? 0,
      gold: r.optionalInt(goldKey) ?? 0,
      house: r.optionalInt(houseKey) ?? 0,
      car: r.optionalInt(carKey) ?? 0,
      rentChange: r.optionalInt(rentChangeKey) ?? 0,
      rentReset: r.optionalBool(rentResetKey),
      loan: loan == null ? null : LoanTerms.fromJson(loan),
      career: career == null ? null : CareerChange.fromJson(career),
      addFlags: r.optionalStringList(addFlagsKey),
      removeFlags: r.optionalStringList(removeFlagsKey),
      schedule: schedule == null ? null : ScheduledEvent.fromJson(schedule),
    );
  }
}

/// Kredi: [amount] TL bugün ele geçer gibi düşünülür ama nakde eklenmez;
/// ev ya da araba için kullanılır. Faiziyle birlikte [years] yıl boyunca
/// eşit taksitle ödenir.
class LoanTerms {
  const LoanTerms({required this.amount, required this.years})
    : assert(amount > 0 && years > 0);

  final int amount;
  final int years;

  /// Toplam geri ödeme, anaparanın bu katıdır (kurgusal sabit faiz).
  static const double totalCostFactor = 1.3;

  int get yearlyPayment => (amount * totalCostFactor / years).round();

  factory LoanTerms.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'amount', 'years'});
    final amount = r.requireInt('amount');
    final years = r.requireInt('years');
    if (amount <= 0) {
      throw CardFormatException('${r.path}.amount', 'sıfırdan büyük olmalı');
    }
    if (years < 1 || years > 40) {
      throw CardFormatException('${r.path}.years', '1–40 arasında olmalı');
    }
    return LoanTerms(amount: amount, years: years);
  }
}

/// Bir seçimin yıllar sonra getireceği devam kartı.
class ScheduledEvent {
  const ScheduledEvent({required this.cardId, required this.inYears})
    : assert(inYears >= 1);

  final String cardId;

  /// Kaç yıl sonra gelecek. En az 1.
  final int inYears;

  factory ScheduledEvent.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'event', 'inYears'});
    final inYears = r.requireInt('inYears');
    if (inYears < 1) {
      throw CardFormatException('${r.path}.inYears', 'en az 1 olmalı');
    }
    return ScheduledEvent(cardId: r.requireString('event'), inYears: inYears);
  }
}

/// Zarın hangi değere bakarak atılacağı.
enum RollStat {
  luck('luck'),
  health('health'),
  happiness('happiness'),
  knowledge('knowledge'),
  reputation('reputation'),
  family('family');

  const RollStat(this.key);

  final String key;

  /// Şans dışındaki her zar bir göstergeye karşılık gelir.
  StatKind? get statKind => StatKind.fromKey(key);

  static RollStat? fromKey(String key) {
    for (final stat in values) {
      if (stat.key == key) return stat;
    }
    return null;
  }
}

/// Şans zarı: [stat] değeri ve zar birlikte [threshold] eşiğini geçerse
/// seçenek başarılı sayılır. Hesap motordaki EffectResolver'dadır.
class Roll {
  const Roll({required this.stat, required this.threshold});

  final RollStat stat;

  /// 0–100 arası eşik.
  final int threshold;

  factory Roll.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'stat', 'threshold'});
    final key = r.requireString('stat');
    final stat = RollStat.fromKey(key);
    if (stat == null) {
      throw CardFormatException(
        '${r.path}.stat',
        'bilinmeyen zar değeri "$key"',
      );
    }
    final threshold = r.requireInt('threshold');
    if (threshold < 0 || threshold > 100) {
      throw CardFormatException('${r.path}.threshold', '0–100 arasında olmalı');
    }
    return Roll(stat: stat, threshold: threshold);
  }
}
