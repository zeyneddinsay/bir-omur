import 'character.dart';
import 'effect.dart';
import 'json_reader.dart';
import 'life_stage.dart';
import 'stats.dart';

/// Kartın nadirliği ve desteden çekilme ağırlığı.
enum Rarity {
  siradan('siradan', 10),
  nadir('nadir', 3),
  efsane('efsane', 1);

  const Rarity(this.id, this.weight);

  final String id;
  final int weight;

  static Rarity? fromId(String id) {
    for (final r in values) {
      if (r.id == id) return r;
    }
    return null;
  }
}

/// Kartın gelebilmesi için karakterin sağlaması gereken koşullar.
class Conditions {
  const Conditions({
    this.flags = const [],
    this.notFlags = const [],
    this.gender,
    this.temperament,
    this.background,
    this.career,
    this.minTier,
    this.min = const {},
    this.max = const {},
  });

  static const Conditions none = Conditions();

  static const String moneyKey = 'money';
  static const String luckKey = 'luck';
  static const String goldKey = 'gold';
  static const String houseKey = 'house';
  static const String carKey = 'car';

  /// `min` ve `max` içinde kullanılabilecek değer adları.
  static final Set<String> thresholdKeys = {
    for (final kind in StatKind.values) kind.key,
    moneyKey,
    luckKey,
    goldKey,
    houseKey,
    carKey,
  };

  /// Hepsi bulunmalı.
  final List<String> flags;

  /// Hiçbiri bulunmamalı.
  final List<String> notFlags;
  final Gender? gender;
  final Temperament? temperament;
  final FamilyBackground? background;

  /// Meslek kimliği; ayrıca [noCareer] (işsiz) ya da [anyCareer] (bir işi
  /// olan).
  final String? career;

  /// İşteki kademe en az bu olmalı (1'den başlar). Bir işi olmayı gerektirir.
  final int? minTier;

  static const String noCareer = 'none';
  static const String anyCareer = 'any';

  /// Değer en az bu kadar olmalı (dahil).
  final Map<String, int> min;

  /// Değer bundan küçük olmalı (hariç). Örnek: `"max": {"money": 5000}`
  /// "Para < 5.000" demektir.
  final Map<String, int> max;

  bool isMetBy(Character c) {
    if (!flags.every(c.hasFlag)) return false;
    if (notFlags.any(c.hasFlag)) return false;
    if (gender != null && c.gender != gender) return false;
    if (temperament != null && c.temperament != temperament) return false;
    if (background != null && c.background != background) return false;
    if (!_careerMatches(c)) return false;
    for (final entry in min.entries) {
      if (_valueOf(c, entry.key) < entry.value) return false;
    }
    for (final entry in max.entries) {
      if (_valueOf(c, entry.key) >= entry.value) return false;
    }
    return true;
  }

  bool _careerMatches(Character c) {
    final job = c.job;
    switch (career) {
      case null:
        break;
      case noCareer:
        if (job != null) return false;
      case anyCareer:
        if (job == null) return false;
      case final id:
        if (job?.careerId != id) return false;
    }
    if (minTier case final tier?) {
      if (job == null || job.tier < tier) return false;
    }
    return true;
  }

  static int _valueOf(Character c, String key) {
    if (key == moneyKey) return c.stats.money;
    if (key == luckKey) return c.luck;
    if (key == goldKey) return c.assets.goldGrams;
    if (key == houseKey) return c.assets.houses;
    if (key == carKey) return c.assets.cars;
    final kind = StatKind.fromKey(key);
    if (kind == null) throw StateError('bilinmeyen koşul değeri: $key');
    return c.stats[kind];
  }

  factory Conditions.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {
      'flags',
      'notFlags',
      'gender',
      'temperament',
      'background',
      'career',
      'minTier',
      'min',
      'max',
    });

    Gender? gender;
    final genderId = r.optionalString('gender');
    if (genderId != null) {
      gender = Gender.fromId(genderId);
      if (gender == null) {
        throw CardFormatException(
          '${r.path}.gender',
          'bilinmeyen cinsiyet "$genderId"',
        );
      }
    }

    Temperament? temperament;
    final temperamentId = r.optionalString('temperament');
    if (temperamentId != null) {
      temperament = Temperament.fromId(temperamentId);
      if (temperament == null) {
        throw CardFormatException(
          '${r.path}.temperament',
          'bilinmeyen mizaç "$temperamentId"',
        );
      }
    }
    FamilyBackground? background;
    final backgroundId = r.optionalString('background');
    if (backgroundId != null) {
      background = FamilyBackground.fromId(backgroundId);
      if (background == null) {
        throw CardFormatException(
          '${r.path}.background',
          'bilinmeyen aile durumu "$backgroundId"',
        );
      }
    }

    return Conditions(
      flags: r.optionalStringList('flags'),
      notFlags: r.optionalStringList('notFlags'),
      gender: gender,
      temperament: temperament,
      background: background,
      career: r.optionalString('career'),
      minTier: r.optionalInt('minTier'),
      min: _thresholds(r.optionalObject('min')),
      max: _thresholds(r.optionalObject('max')),
    );
  }

  static Map<String, int> _thresholds(JsonReader? r) {
    if (r == null) return const {};
    r.rejectUnknownKeys(thresholdKeys);
    return Map.unmodifiable({
      for (final key in r.json.keys) key: r.requireInt(key),
    });
  }
}

/// Kartın bir seçeneği. Zarsız seçenekte yalnızca [effects] uygulanır;
/// zarlı seçenekte önce [effects], sonra zarın sonucuna göre [success]
/// ya da [fail] uygulanır.
class Choice {
  const Choice({
    required this.label,
    this.effects = Effect.none,
    this.roll,
    this.success,
    this.fail,
  }) : assert(
         (roll == null) == (success == null) &&
             (roll == null) == (fail == null),
       );

  final String label;
  final Effect effects;
  final Roll? roll;
  final Effect? success;
  final Effect? fail;

  bool get hasRoll => roll != null;

  /// Bu seçeneğin uygulayabileceği bütün etkiler (doğrulama için).
  Iterable<Effect> get allEffects => [effects, ?success, ?fail];

  factory Choice.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {'label', 'effects', 'roll', 'success', 'fail'});
    final effects = r.optionalObject('effects');
    final roll = r.optionalObject('roll');
    if (roll == null) {
      for (final key in const ['success', 'fail']) {
        if (r.has(key)) {
          throw CardFormatException(
            '${r.path}.$key',
            'zar (roll) olmadan kullanılamaz',
          );
        }
      }
    }
    return Choice(
      label: r.requireString('label'),
      effects: effects == null ? Effect.none : Effect.fromJson(effects),
      roll: roll == null ? null : Roll.fromJson(roll),
      success: roll == null
          ? null
          : Effect.fromJson(r.requireObject('success')),
      fail: roll == null ? null : Effect.fromJson(r.requireObject('fail')),
    );
  }
}

/// Bir olay kartı. Flutter'ın `Card` widget'ıyla karışmasın diye adı
/// `EventCard`'dır.
class EventCard {
  const EventCard({
    required this.id,
    required this.stage,
    required this.minAge,
    required this.maxAge,
    required this.text,
    required this.left,
    required this.right,
    this.up,
    this.rarity = Rarity.siradan,
    this.once = false,
    this.cooldown = 0,
    this.mandatory = false,
    this.chainOnly = false,
    this.conditions = Conditions.none,
    this.speaker,
  });

  final String id;
  final LifeStage stage;
  final int minAge;
  final int maxAge;
  final Rarity rarity;

  /// Hayatta bir kez gelir.
  final bool once;

  /// Tekrar gelmesi için en az kaç yıl geçmeli. 0 ise her yıl gelebilir.
  final int cooldown;

  /// Koşul sağlanınca her zaman gelir (sınav, askerlik, emeklilik).
  final bool mandatory;

  /// Desteden çekilmez; yalnızca bir zincir (schedule) ile gelir.
  final bool chainOnly;
  final Conditions conditions;
  final String? speaker;
  final String text;
  final Choice left;
  final Choice right;

  /// Nadir kartlardaki üçüncü seçenek (yukarı kaydırma).
  final Choice? up;

  List<Choice> get choices => [left, right, ?up];

  Choice choice(ChoiceSide side) => switch (side) {
    ChoiceSide.left => left,
    ChoiceSide.right => right,
    ChoiceSide.up =>
      up ?? (throw StateError('$id kartında yukarı seçeneği yok')),
  };

  bool isInAgeRange(int age) => age >= minAge && age <= maxAge;

  static const Set<String> knownKeys = {
    'id',
    'stage',
    'minAge',
    'maxAge',
    'rarity',
    'once',
    'cooldown',
    'mandatory',
    'chainOnly',
    'conditions',
    'speaker',
    'text',
    'left',
    'right',
    'up',
  };

  factory EventCard.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final r = JsonReader(json, rawId is String ? rawId : '<kimliksiz kart>');
    r.rejectUnknownKeys(knownKeys);

    final stageId = r.requireString('stage');
    final stage = LifeStage.fromId(stageId);
    if (stage == null) {
      throw CardFormatException(
        '${r.path}.stage',
        'bilinmeyen evre "$stageId"',
      );
    }

    final rarityId = r.optionalString('rarity') ?? Rarity.siradan.id;
    final rarity = Rarity.fromId(rarityId);
    if (rarity == null) {
      throw CardFormatException(
        '${r.path}.rarity',
        'bilinmeyen nadirlik "$rarityId"',
      );
    }

    final minAge = r.requireInt('minAge');
    final maxAge = r.requireInt('maxAge');
    if (minAge < 0 || maxAge < minAge) {
      throw CardFormatException(
        '${r.path}.minAge',
        'yaş aralığı geçersiz ($minAge–$maxAge)',
      );
    }

    final cooldown = r.optionalInt('cooldown') ?? 0;
    if (cooldown < 0) {
      throw CardFormatException('${r.path}.cooldown', 'eksi olamaz');
    }

    final conditions = r.optionalObject('conditions');
    final up = r.optionalObject('up');
    return EventCard(
      id: r.requireString('id'),
      stage: stage,
      minAge: minAge,
      maxAge: maxAge,
      rarity: rarity,
      once: r.optionalBool('once'),
      cooldown: cooldown,
      mandatory: r.optionalBool('mandatory'),
      chainOnly: r.optionalBool('chainOnly'),
      conditions: conditions == null
          ? Conditions.none
          : Conditions.fromJson(conditions),
      speaker: r.optionalString('speaker'),
      text: r.requireString('text'),
      left: Choice.fromJson(r.requireObject('left')),
      right: Choice.fromJson(r.requireObject('right')),
      up: up == null ? null : Choice.fromJson(up),
    );
  }
}
