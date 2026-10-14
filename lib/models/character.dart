import 'assets.dart';
import 'career.dart';
import 'life_stage.dart';
import 'stats.dart';

enum Gender {
  erkek('erkek'),
  kadin('kadin');

  const Gender(this.id);

  final String id;

  static Gender? fromId(String id) {
    for (final g in values) {
      if (g.id == id) return g;
    }
    return null;
  }
}

/// Doğumda rastgele atanan gizli mizaç.
enum Temperament {
  sakin('sakin'),
  asabi('asabi'),
  hayalperest('hayalperest'),
  hesapci('hesapci');

  const Temperament(this.id);

  final String id;

  static Temperament? fromId(String id) {
    for (final t in values) {
      if (t.id == id) return t;
    }
    return null;
  }
}

/// Seçilen kart seçeneğinin yönü.
enum ChoiceSide { left, right, up }

/// Bir yaşta görülen kart ve yapılan seçim. Hem once/cooldown kuralları
/// hem de hayat özeti bu kayıtlardan beslenir.
class CardRecord {
  const CardRecord({
    required this.age,
    required this.cardId,
    required this.side,
    this.rollSucceeded,
  });

  final int age;
  final String cardId;
  final ChoiceSide side;

  /// Seçenekte zar yoksa null.
  final bool? rollSucceeded;

  Map<String, Object> toJson() => {
    'age': age,
    'card': cardId,
    'side': side.name,
    'roll': ?rollSucceeded,
  };

  factory CardRecord.fromJson(Map<String, dynamic> json) => CardRecord(
    age: json['age'] as int,
    cardId: json['card'] as String,
    side: ChoiceSide.values.byName(json['side'] as String),
    rollSucceeded: json['roll'] as bool?,
  );
}

/// Oyuncunun yaşadığı hayatın o anki durumu. Değişmezdir; her değişiklik
/// [copyWith] ile yeni bir kopya üretir.
class Character {
  Character({
    required this.name,
    required this.gender,
    required this.age,
    required this.stats,
    required this.temperament,
    required this.luck,
    required this.hometown,
    required this.team,
    Set<String> flags = const {},
    List<CardRecord> history = const [],
    this.assets = Assets.none,
    this.job,
    this.pension = 0,
    this.isAlive = true,
  }) : assert(age >= 0),
       assert(luck >= 0 && luck <= 100),
       flags = Set.unmodifiable(flags),
       history = List.unmodifiable(history);

  final String name;
  final Gender gender;
  final int age;
  final Stats stats;

  // Gizli değerler
  final Temperament temperament;

  /// 0–100. Zarlarda göstergeye eklenir.
  final int luck;
  final String hometown;
  final String team;

  /// Kalıcı izler: `kiraci`, `askerligini_yapti` gibi.
  final Set<String> flags;

  final List<CardRecord> history;

  /// Altın, ev, araba, kira ve kredi. Nakit para [stats] içindedir.
  final Assets assets;

  /// Şu anki iş; işsizse ya da emekliyse null.
  final Job? job;

  /// Yıllık emekli aylığı (TL); emekli değilse 0.
  final int pension;

  bool get isRetired => pension > 0;
  final bool isAlive;

  LifeStage get stage => LifeStage.forAge(age);

  bool hasFlag(String flag) => flags.contains(flag);

  bool hasSeen(String cardId) => history.any((r) => r.cardId == cardId);

  /// Kartın en son görüldüğü yaş; hiç görülmediyse null.
  int? lastSeenAge(String cardId) {
    for (final record in history.reversed) {
      if (record.cardId == cardId) return record.age;
    }
    return null;
  }

  Character copyWith({
    String? name,
    int? age,
    Stats? stats,
    Set<String>? flags,
    List<CardRecord>? history,
    Assets? assets,
    Job? job,
    bool clearJob = false,
    int? pension,
    bool? isAlive,
  }) {
    return Character(
      name: name ?? this.name,
      gender: gender,
      age: age ?? this.age,
      stats: stats ?? this.stats,
      temperament: temperament,
      luck: luck,
      hometown: hometown,
      team: team,
      flags: flags ?? this.flags,
      history: history ?? this.history,
      assets: assets ?? this.assets,
      job: clearJob ? null : (job ?? this.job),
      pension: pension ?? this.pension,
      isAlive: isAlive ?? this.isAlive,
    );
  }

  Character withRecord(CardRecord record) =>
      copyWith(history: [...history, record]);

  Map<String, Object> toJson() => {
    'name': name,
    'gender': gender.id,
    'age': age,
    'stats': stats.toJson(),
    'temperament': temperament.id,
    'luck': luck,
    'hometown': hometown,
    'team': team,
    'flags': (flags.toList()..sort()),
    'history': [for (final r in history) r.toJson()],
    'assets': assets.toJson(),
    'job': ?job?.toJson(),
    'pension': pension,
    'alive': isAlive,
  };

  factory Character.fromJson(Map<String, dynamic> json) {
    T byId<T>(T? Function(String) parse, String key) {
      final id = json[key] as String;
      return parse(id) ?? (throw FormatException('bilinmeyen $key: $id'));
    }

    return Character(
      name: json['name'] as String,
      gender: byId(Gender.fromId, 'gender'),
      age: json['age'] as int,
      stats: Stats.fromJson(json['stats'] as Map<String, dynamic>),
      temperament: byId(Temperament.fromId, 'temperament'),
      luck: json['luck'] as int,
      hometown: json['hometown'] as String,
      team: json['team'] as String,
      flags: {...(json['flags'] as List).cast<String>()},
      history: [
        for (final r in json['history'] as List)
          CardRecord.fromJson(r as Map<String, dynamic>),
      ],
      assets: Assets.fromJson(json['assets'] as Map<String, dynamic>),
      job: json['job'] == null
          ? null
          : Job.fromJson(json['job'] as Map<String, dynamic>),
      pension: json['pension'] as int,
      isAlive: json['alive'] as bool,
    );
  }
}
