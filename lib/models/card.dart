import 'character.dart';
import 'effect.dart';
import 'event_role.dart';
import 'json_reader.dart';
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
    this.careers = const [],
    this.business,
    this.minTier,
    this.min = const {},
    this.max = const {},
    this.familyProfiles = const [],
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

  /// Boş değilse işi bunlardan biri olmalı (kamu ya da ofis işleri gibi).
  final List<String> careers;

  /// İşletme türü ([anyCareer] her işletme, [noCareer] işletmesi yok).
  /// `yazilim`, büyütülmüş `yazilim_ekip` işletmesini de kapsar.
  final String? business;

  bool hasBusiness(Character c) => switch (business) {
    null => true,
    noCareer => c.businesses.isEmpty,
    anyCareer => c.businesses.isNotEmpty,
    final id => c.businesses.any((b) => matchesBusiness(b.type, id)),
  };

  static bool matchesBusiness(String type, String id) =>
      type == id || type.startsWith('${id}_');

  /// Değer en az bu kadar olmalı (dahil).
  final Map<String, int> min;

  /// Değer bundan küçük olmalı (hariç). Örnek: `"max": {"money": 5000}`
  /// "Para < 5.000" demektir.
  final Map<String, int> max;

  /// Boş değilse oyuncunun doğduğu aile profili bunlardan biri olmalı
  /// (`fabrikator`, `isci`…).
  final List<String> familyProfiles;

  bool isMetBy(Character c) {
    if (familyProfiles.isNotEmpty &&
        !familyProfiles.contains(c.familyProfile)) {
      return false;
    }
    if (!flags.every(c.hasFlag)) return false;
    if (notFlags.any(c.hasFlag)) return false;
    if (gender != null && c.gender != gender) return false;
    if (temperament != null && c.temperament != temperament) return false;
    if (background != null && c.background != background) return false;
    if (!_careerMatches(c)) return false;
    if (careers.isNotEmpty && !careers.contains(c.job?.careerId)) return false;
    if (!hasBusiness(c)) return false;
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
      'careers',
      'business',
      'minTier',
      'min',
      'max',
      'familyProfile',
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
      careers: r.optionalStringList('careers'),
      business: r.optionalString('business'),
      minTier: r.optionalInt('minTier'),
      min: _thresholds(r.optionalObject('min')),
      max: _thresholds(r.optionalObject('max')),
      familyProfiles: r.optionalStringList('familyProfile'),
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

/// Olayın türü. Seçici her türe farklı davranır.
enum EventType {
  /// Hayatın dönüm noktası (sınav, askerlik): şartı sağlanınca mutlaka
  /// gelir, yıllık olay sınırına takılmaz.
  donemec,

  /// Belirli bir kişiyle (rol yuvası) yaşanan olay.
  kisi,

  /// Okul, iş yeri ya da mahalle gibi bir yerde geçen olay.
  yer,

  /// Tesadüf: yolda, otobüste, sırada biriyle karşılaşma. Yılda en fazla 1.
  tesaduf,

  /// Kimseye ya da yere bağlı olmayan genel olay.
  genel,

  /// Yalnızca önceki bir seçimin planladığı devam olayı; desteden çekilmez.
  iplik;

  static EventType? fromId(String id) => values.asNameMap()[id];
}

/// Tema etiketi: aynı yıl aynı temadan iki olay gelmez (dönemeçler hariç).
enum EventTheme {
  aile('aile'),
  okul('okul'),
  ask('ask'),
  isHayati('is'),
  para('para'),
  mahalle('mahalle'),
  saglik('saglik'),
  genel('genel');

  const EventTheme(this.id);

  final String id;

  static EventTheme? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Olayın tekrar kuralı: hayatta bir kez ya da en az [cooldown] yıl arayla.
class Repeat {
  const Repeat.once() : once = true, cooldown = 0, maxTimes = 1;

  const Repeat.every(this.cooldown, {this.maxTimes})
    : once = false,
      assert(cooldown >= 1);

  final bool once;

  /// Tekrar için geçmesi gereken yıl ([once] ise 0).
  final int cooldown;

  /// Bir hayatta en fazla kaç kez gelir; null ise sınırsız.
  final int? maxTimes;

  /// JSON: `"repeat": "once"` ya da `"repeat": {"cooldown": 3, "max": 4}`
  /// (`max` isteğe bağlı: hayat boyu en fazla kaç kez).
  factory Repeat.fromJson(Object? value, String path) {
    if (value == 'once') return const Repeat.once();
    if (value is Map<String, dynamic>) {
      final r = JsonReader(value, path)
        ..rejectUnknownKeys(const {'cooldown', 'max'});
      final years = r.requireInt('cooldown');
      if (years < 1) {
        throw CardFormatException('$path.cooldown', 'en az 1 olmalı');
      }
      final max = r.optionalInt('max');
      if (max != null && max < 2) {
        throw CardFormatException(
          '$path.max',
          'en az 2 olmalı (1 için "once")',
        );
      }
      return Repeat.every(years, maxTimes: max);
    }
    throw CardFormatException(path, '"once" ya da {"cooldown": N} olmalı');
  }
}

/// Bir olay. Flutter'ın `Card` widget'ıyla karışmasın diye adı
/// `EventCard`'dır. Şema: docs/GDD.md "Kart veri formatı" ve canlı
/// dokümanın "Hikâye motoru" bölümü.
class EventCard {
  const EventCard({
    required this.id,
    required this.type,
    required this.theme,
    required this.minAge,
    required this.maxAge,
    required this.repeat,
    required this.text,
    required this.left,
    required this.right,
    this.up,
    this.rarity = Rarity.siradan,
    this.conditions = Conditions.none,
    this.roles = const [],
    this.speaker,
    this.closing,
  });

  final String id;
  final EventType type;
  final EventTheme theme;

  /// Oyuncunun yaşı (dahil).
  final int minAge;
  final int maxAge;
  final Rarity rarity;
  final Repeat repeat;

  /// Oyuncunun sağlaması gereken koşullar.
  final Conditions conditions;

  /// Olayın ihtiyaç duyduğu kişiler, yazıldıkları sırayla bağlanır.
  final List<RoleSlot> roles;

  /// Konuşan rol yuvası (portresi kartta görünür); anlatıcıysa null.
  final String? speaker;

  /// Metin; rol yuvaları `{kerem.ad}` gibi kullanılır.
  final String text;
  final Choice left;
  final Choice right;

  /// Nadir olaylardaki üçüncü seçenek (yukarı kaydırma).
  final Choice? up;

  /// İplikte: taşınan kişi vefat ettiyse ya da çevreden ayrıldıysa olay
  /// gelmez, bu cümle yıl günlüğüne yazılır.
  final String? closing;

  bool get mandatory => type == EventType.donemec;
  bool get chainOnly => type == EventType.iplik;
  bool get once => repeat.once;
  int get cooldown => repeat.cooldown;

  List<Choice> get choices => [left, right, ?up];

  Choice choice(ChoiceSide side) => switch (side) {
    ChoiceSide.left => left,
    ChoiceSide.right => right,
    ChoiceSide.up =>
      up ?? (throw StateError('$id kartında yukarı seçeneği yok')),
  };

  RoleSlot? role(String name) {
    for (final r in roles) {
      if (r.name == name) return r;
    }
    return null;
  }

  bool isInAgeRange(int age) => age >= minAge && age <= maxAge;

  static const Set<String> knownKeys = {
    'id',
    'type',
    'theme',
    'minAge',
    'maxAge',
    'rarity',
    'repeat',
    'conditions',
    'roles',
    'speaker',
    'text',
    'left',
    'right',
    'up',
    'closing',
  };

  /// Rol yuvası adları: küçük harf, Türkçe harfler ve alt çizgi.
  static final RegExp roleNamePattern = RegExp(r'^[a-zçğıöşü_]+$');

  /// Metinlerde oyuncunun kendisi için ayrılmış ad.
  static const String playerSlot = 'oyuncu';

  factory EventCard.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final r = JsonReader(json, rawId is String ? rawId : '<kimliksiz kart>');
    r.rejectUnknownKeys(knownKeys);

    final typeId = r.requireString('type');
    final type =
        EventType.fromId(typeId) ??
        (throw CardFormatException(
          '${r.path}.type',
          'bilinmeyen tür "$typeId"',
        ));
    final themeId = r.requireString('theme');
    final theme =
        EventTheme.fromId(themeId) ??
        (throw CardFormatException(
          '${r.path}.theme',
          'bilinmeyen tema "$themeId"',
        ));

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
    if (!r.has('repeat')) {
      throw CardFormatException('${r.path}.repeat', 'tekrar kuralı yazılmalı');
    }
    final repeat = Repeat.fromJson(json['repeat'], '${r.path}.repeat');

    final rolesReader = r.optionalObject('roles');
    final roles = <RoleSlot>[
      if (rolesReader != null)
        for (final name in rolesReader.json.keys)
          if (!roleNamePattern.hasMatch(name) || name == playerSlot)
            throw CardFormatException(
              '${rolesReader.path}.$name',
              'geçersiz rol adı (küçük harf, "$playerSlot" ayrılmış)',
            )
          else
            RoleSlot.fromJson(name, rolesReader.requireObject(name)),
    ];

    final speaker = r.optionalString('speaker');
    if (speaker != null && !roles.any((s) => s.name == speaker)) {
      throw CardFormatException(
        '${r.path}.speaker',
        '"$speaker" diye bir rol yuvası yok',
      );
    }

    final conditions = r.optionalObject('conditions');
    final up = r.optionalObject('up');
    return EventCard(
      id: r.requireString('id'),
      type: type,
      theme: theme,
      minAge: minAge,
      maxAge: maxAge,
      rarity: rarity,
      repeat: repeat,
      conditions: conditions == null
          ? Conditions.none
          : Conditions.fromJson(conditions),
      roles: List.unmodifiable(roles),
      speaker: speaker,
      text: r.requireString('text'),
      left: Choice.fromJson(r.requireObject('left')),
      right: Choice.fromJson(r.requireObject('right')),
      up: up == null ? null : Choice.fromJson(up),
      closing: r.optionalString('closing'),
    );
  }
}
