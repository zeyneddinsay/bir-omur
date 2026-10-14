import 'card.dart';
import 'json_reader.dart';

/// Bir meslek: kademeleri, maaşları ve terfi şartları. İçerik olarak
/// `assets/careers/<id>.json` dosyasından gelir.
class Career {
  const Career({
    required this.id,
    required this.name,
    required this.tiers,
    this.incomeVariance = 0,
  });

  final String id;

  /// Ekranda görünen meslek adı (Türkçe içerik, kart metinleri gibi).
  final String name;

  /// 1. kademeden son kademeye.
  final List<CareerTier> tiers;

  /// Gelirin yıldan yıla oynama payı: 0,5 ise maaş ×0,5 ile ×1,5 arası.
  final double incomeVariance;

  int get maxTier => tiers.length;

  /// [tier] 1'den başlar.
  CareerTier tier(int tier) => tiers[tier - 1];

  factory Career.fromJson(Map<String, dynamic> json, {required String file}) {
    final r = JsonReader(json, file);
    r.rejectUnknownKeys(const {'id', 'name', 'incomeVariance', 'tiers'});
    final rawTiers = json['tiers'];
    if (rawTiers is! List || rawTiers.isEmpty) {
      throw CardFormatException('$file.tiers', 'en az bir kademe olmalı');
    }
    final variance = (json['incomeVariance'] ?? 0) as num;
    if (variance < 0 || variance >= 1) {
      throw CardFormatException(
        '$file.incomeVariance',
        '0 ile 1 arasında olmalı',
      );
    }
    final tiers = <CareerTier>[];
    for (var i = 0; i < rawTiers.length; i++) {
      final raw = rawTiers[i];
      if (raw is! Map<String, dynamic>) {
        throw CardFormatException('$file.tiers[$i]', 'nesne bekleniyordu');
      }
      final isLast = i == rawTiers.length - 1;
      tiers.add(
        CareerTier.fromJson(JsonReader(raw, '$file.tiers[$i]'), isLast: isLast),
      );
    }
    return Career(
      id: r.requireString('id'),
      name: r.requireString('name'),
      tiers: List.unmodifiable(tiers),
      incomeVariance: variance.toDouble(),
    );
  }
}

class CareerTier {
  const CareerTier({required this.name, required this.salary, this.promotion});

  final String name;

  /// Yıllık gelir (TL), kira dışı geçim düşülmüş.
  final int salary;

  /// Bir üst kademeye geçiş; son kademede null.
  final Promotion? promotion;

  factory CareerTier.fromJson(JsonReader r, {required bool isLast}) {
    r.rejectUnknownKeys(const {'name', 'salary', 'promotion'});
    final salary = r.requireInt('salary');
    if (salary < 0) {
      throw CardFormatException('${r.path}.salary', 'eksi olamaz');
    }
    final promotion = r.optionalObject('promotion');
    if (isLast && promotion != null) {
      throw CardFormatException(
        '${r.path}.promotion',
        'son kademede terfi olmaz',
      );
    }
    if (!isLast && promotion == null) {
      throw CardFormatException(
        '${r.path}.promotion',
        'eksik; son kademe değil',
      );
    }
    return CareerTier(
      name: r.requireString('name'),
      salary: salary,
      promotion: promotion == null ? null : Promotion.fromJson(promotion),
    );
  }
}

/// Terfi: kademede en az [minYears] yıl, [requires] koşulları ve her yıl
/// [chance] ihtimal. Terfide [cost] TL ödenir (esnafın yeni dükkânı gibi).
class Promotion {
  const Promotion({
    required this.minYears,
    required this.chance,
    this.requires = Conditions.none,
    this.cost = 0,
  });

  final int minYears;
  final double chance;
  final Conditions requires;
  final int cost;

  factory Promotion.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'minYears', 'chance', 'requires', 'cost'});
    final chance = r.json['chance'];
    if (chance is! num || chance <= 0 || chance > 1) {
      throw CardFormatException('${r.path}.chance', '0 ile 1 arasında olmalı');
    }
    final minYears = r.requireInt('minYears');
    if (minYears < 1) {
      throw CardFormatException('${r.path}.minYears', 'en az 1');
    }
    final requires = r.optionalObject('requires');
    final cost = r.optionalInt('cost') ?? 0;
    if (cost < 0) throw CardFormatException('${r.path}.cost', 'eksi olamaz');
    return Promotion(
      minYears: minYears,
      chance: chance.toDouble(),
      requires: requires == null
          ? Conditions.none
          : Conditions.fromJson(requires),
      cost: cost,
    );
  }
}

/// Karakterin o anki işi.
class Job {
  const Job({required this.careerId, required this.tier, this.yearsInTier = 0})
    : assert(tier >= 1);

  final String careerId;

  /// 1'den başlar.
  final int tier;
  final int yearsInTier;

  Job copyWith({int? tier, int? yearsInTier}) => Job(
    careerId: careerId,
    tier: tier ?? this.tier,
    yearsInTier: yearsInTier ?? this.yearsInTier,
  );

  Map<String, Object> toJson() => {
    'career': careerId,
    'tier': tier,
    'years': yearsInTier,
  };

  factory Job.fromJson(Map<String, dynamic> json) => Job(
    careerId: json['career'] as String,
    tier: json['tier'] as int,
    yearsInTier: json['years'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is Job &&
      other.careerId == careerId &&
      other.tier == tier &&
      other.yearsInTier == yearsInTier;

  @override
  int get hashCode => Object.hash(careerId, tier, yearsInTier);
}

/// Bir kart seçeneğinin işe etkisi.
sealed class CareerChange {
  const CareerChange();

  factory CareerChange.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'join', 'tier', 'quit', 'promote', 'retire'});
    final actions = ['join', 'quit', 'promote', 'retire'].where(r.has).toList();
    if (actions.length != 1) {
      throw CardFormatException(
        r.path,
        'join, quit, promote ya da retire anahtarlarından tam biri olmalı',
      );
    }
    if (r.has('tier') && actions.single != 'join') {
      throw CardFormatException(
        '${r.path}.tier',
        'yalnızca join ile kullanılır',
      );
    }
    switch (actions.single) {
      case 'join':
        final tier = r.optionalInt('tier') ?? 1;
        if (tier < 1) throw CardFormatException('${r.path}.tier', 'en az 1');
        return JoinCareer(r.requireString('join'), tier: tier);
      case 'promote':
        final steps = r.requireInt('promote');
        if (steps == 0) {
          throw CardFormatException('${r.path}.promote', '0 olamaz');
        }
        return PromoteCareer(steps);
      case 'quit':
        if (r.json['quit'] != true) {
          throw CardFormatException('${r.path}.quit', 'true olmalı');
        }
        return const QuitCareer();
      default:
        if (r.json['retire'] != true) {
          throw CardFormatException('${r.path}.retire', 'true olmalı');
        }
        return const RetireCareer();
    }
  }
}

/// Mesleğe girer. Zaten bir işi varsa eskisi bırakılır.
class JoinCareer extends CareerChange {
  const JoinCareer(this.careerId, {this.tier = 1});

  final String careerId;
  final int tier;
}

/// Kademe atlar (eksi değer kademe düşürür); son ve ilk kademede durur.
class PromoteCareer extends CareerChange {
  const PromoteCareer(this.steps);

  final int steps;
}

/// İşi bırakır; emekli aylığı bağlanmaz.
class QuitCareer extends CareerChange {
  const QuitCareer();
}

/// Emekli olur; işi varsa son maaşa göre aylık bağlanır.
class RetireCareer extends CareerChange {
  const RetireCareer();
}
