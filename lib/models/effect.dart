import 'json_reader.dart';
import 'stats.dart';

/// Bir seçimin karaktere etkisi: göstergeler, para, bayraklar ve
/// ileri bir yıla planlanan zincir kartı.
class Effect {
  const Effect({
    this.stats = const {},
    this.money = 0,
    this.addFlags = const [],
    this.removeFlags = const [],
    this.schedule,
  });

  static const Effect none = Effect();

  static const String moneyKey = 'money';
  static const String addFlagsKey = 'addFlags';
  static const String removeFlagsKey = 'removeFlags';
  static const String scheduleKey = 'schedule';

  /// Kart JSON'unda bir etki nesnesinin alabileceği bütün anahtarlar.
  static final Set<String> knownKeys = {
    for (final kind in StatKind.values) kind.key,
    moneyKey,
    addFlagsKey,
    removeFlagsKey,
    scheduleKey,
  };

  final Map<StatKind, int> stats;
  final int money;
  final List<String> addFlags;
  final List<String> removeFlags;
  final ScheduledEvent? schedule;

  bool get isEmpty =>
      stats.isEmpty &&
      money == 0 &&
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
    return Effect(
      stats: Map.unmodifiable(stats),
      money: r.optionalInt(moneyKey) ?? 0,
      addFlags: r.optionalStringList(addFlagsKey),
      removeFlags: r.optionalStringList(removeFlagsKey),
      schedule: schedule == null ? null : ScheduledEvent.fromJson(schedule),
    );
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
