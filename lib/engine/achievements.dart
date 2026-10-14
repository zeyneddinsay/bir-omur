import '../models/json_reader.dart';
import '../models/models.dart';
import 'summary_builder.dart';

/// Hayatlar arasında biriken bir rozet. İçerik olarak
/// `assets/achievements.json` dosyasından gelir.
class Achievement {
  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.requirement,
    this.rarity = Rarity.siradan,
  });

  final String id;

  /// Ekranda görünen ad ve açıklama (Türkçe içerik, kart metinleri gibi).
  final String name;
  final String description;
  final Rarity rarity;
  final AchievementRequirement requirement;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final r = JsonReader(json, rawId is String ? rawId : '<kimliksiz rozet>');
    r.rejectUnknownKeys(const {
      'id',
      'name',
      'description',
      'rarity',
      'requires',
    });
    final rarityId = r.optionalString('rarity') ?? Rarity.siradan.id;
    final rarity = Rarity.fromId(rarityId);
    if (rarity == null) {
      throw CardFormatException(
        '${r.path}.rarity',
        'bilinmeyen nadirlik "$rarityId"',
      );
    }
    return Achievement(
      id: r.requireString('id'),
      name: r.requireString('name'),
      description: r.requireString('description'),
      rarity: rarity,
      requirement: AchievementRequirement.fromJson(r.requireObject('requires')),
    );
  }
}

/// Bir rozetin şartı; hepsi birlikte sağlanmalı. Ölüm anındaki hayata
/// bakılır.
class AchievementRequirement {
  const AchievementRequirement({
    this.conditions = Conditions.none,
    this.minDeathAge,
    this.minCounters = const {},
    this.maxCounters = const {},
    this.nickname,
    this.lastCareer,
    this.minLastTier,
    this.seenCards = const [],
  });

  /// Kart koşullarıyla aynı biçim: bayraklar, gösterge ve varlık eşikleri…
  final Conditions conditions;
  final int? minDeathAge;

  /// Hayatın sayıları için alt (dahil) ve üst (hariç) sınırlar.
  final Map<String, int> minCounters;
  final Map<String, int> maxCounters;
  final Nickname? nickname;

  /// Son iş (emeklilikte bırakılan dahil) ve en az kademesi.
  final String? lastCareer;
  final int? minLastTier;

  /// Hayatta görülmüş olması gereken kartlar.
  final List<String> seenCards;

  static const Set<String> counterKeys = {
    'moves',
    'rentPaid',
    'goldReceived',
    'promotions',
    'yearsWorked',
    'lifetimeIncome',
    'debtSpells',
  };

  static int counterValue(LifeCounters k, String key) => switch (key) {
    'moves' => k.moves,
    'rentPaid' => k.rentPaid,
    'goldReceived' => k.goldReceived,
    'promotions' => k.promotions,
    'yearsWorked' => k.yearsWorked,
    'lifetimeIncome' => k.lifetimeIncome,
    'debtSpells' => k.debtSpells,
    _ => throw StateError('bilinmeyen sayaç: $key'),
  };

  bool isMetBy(LifeSummary summary) {
    final c = summary.character;
    if (!conditions.isMetBy(c)) return false;
    if (minDeathAge != null && summary.deathAge < minDeathAge!) return false;
    for (final MapEntry(:key, :value) in minCounters.entries) {
      if (counterValue(c.counters, key) < value) return false;
    }
    for (final MapEntry(:key, :value) in maxCounters.entries) {
      if (counterValue(c.counters, key) >= value) return false;
    }
    if (nickname != null && summary.nickname != nickname) return false;
    final job = c.careerJob;
    if (lastCareer != null && job?.careerId != lastCareer) return false;
    if (minLastTier != null && (job == null || job.tier < minLastTier!)) {
      return false;
    }
    return seenCards.every(c.hasSeen);
  }

  factory AchievementRequirement.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {
      'conditions',
      'minDeathAge',
      'counters',
      'nickname',
      'lastCareer',
      'minLastTier',
      'seenCards',
    });
    final conditions = r.optionalObject('conditions');
    Map<String, int> counters(JsonReader? cr) {
      if (cr == null) return const {};
      cr.rejectUnknownKeys(counterKeys);
      return Map.unmodifiable({
        for (final key in cr.json.keys) key: cr.requireInt(key),
      });
    }

    final countersReader = r.optionalObject('counters');
    countersReader?.rejectUnknownKeys(const {'min', 'max'});
    final nicknameId = r.optionalString('nickname');
    Nickname? nickname;
    if (nicknameId != null) {
      nickname = Nickname.values.asNameMap()[nicknameId];
      if (nickname == null) {
        throw CardFormatException(
          '${r.path}.nickname',
          'bilinmeyen lakap "$nicknameId"',
        );
      }
    }
    return AchievementRequirement(
      conditions: conditions == null
          ? Conditions.none
          : Conditions.fromJson(conditions),
      minDeathAge: r.optionalInt('minDeathAge'),
      minCounters: counters(countersReader?.optionalObject('min')),
      maxCounters: counters(countersReader?.optionalObject('max')),
      nickname: nickname,
      lastCareer: r.optionalString('lastCareer'),
      minLastTier: r.optionalInt('minLastTier'),
      seenCards: r.optionalStringList('seenCards'),
    );
  }
}

/// Oyundaki rozetler ve ölümde kazanılanların hesabı.
class AchievementBook {
  AchievementBook(Iterable<Achievement> achievements)
    : all = List.unmodifiable(achievements);

  static final AchievementBook empty = AchievementBook(const []);

  final List<Achievement> all;

  Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Bu hayatın kazandığı rozetler.
  List<Achievement> earnedBy(LifeSummary summary) => [
    for (final a in all)
      if (a.requirement.isMetBy(summary)) a,
  ];
}

/// Bir rozetin hayatlar boyunca kaç kez ve ilk ne zaman kazanıldığı.
class AchievementProgress {
  const AchievementProgress({required this.count, required this.firstEarnedAt});

  final int count;
  final DateTime firstEarnedAt;

  AchievementProgress earnedAgain() =>
      AchievementProgress(count: count + 1, firstEarnedAt: firstEarnedAt);

  Map<String, Object> toJson() => {
    'count': count,
    'first': firstEarnedAt.toIso8601String(),
  };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        count: json['count'] as int,
        firstEarnedAt: DateTime.parse(json['first'] as String),
      );
}
