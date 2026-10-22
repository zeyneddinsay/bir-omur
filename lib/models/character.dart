import 'assets.dart';
import 'career.dart';
import 'life_counters.dart';
import 'life_stage.dart';
import 'money_ledger.dart';
import 'people_book.dart';
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

/// Doğulan ailenin maddi durumu. Gizli değildir; ekranda görünür.
enum FamilyBackground {
  varlikli('varlikli', adulthoodSupport: 400000),
  orta('orta', adulthoodSupport: 100000),
  dar('dar', adulthoodSupport: 0);

  const FamilyBackground(this.id, {required this.adulthoodSupport});

  final String id;

  /// 18 yaşına girerken ailenin verdiği destek (TL).
  final int adulthoodSupport;

  static FamilyBackground? fromId(String id) {
    for (final b in values) {
      if (b.id == id) return b;
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
    this.people = const {},
  });

  final int age;
  final String cardId;
  final ChoiceSide side;

  /// Seçenekte zar yoksa null.
  final bool? rollSucceeded;

  /// Olayın rol yuvalarına bağlanan kişiler: yuva adı → kişi kimliği.
  final Map<String, String> people;

  Map<String, Object> toJson() => {
    'age': age,
    'card': cardId,
    'side': side.name,
    'roll': ?rollSucceeded,
    if (people.isNotEmpty) 'people': people,
  };

  factory CardRecord.fromJson(Map<String, dynamic> json) => CardRecord(
    age: json['age'] as int,
    cardId: json['card'] as String,
    side: ChoiceSide.values.byName(json['side'] as String),
    rollSucceeded: json['roll'] as bool?,
    people: {
      ...?(json['people'] as Map<String, dynamic>?)?.cast<String, String>(),
    },
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
    this.background = FamilyBackground.orta,
    this.surname = '',
    this.familyProfile,
    PeopleBook? people,
    Set<String> flags = const {},
    List<CardRecord> history = const [],
    this.assets = Assets.none,
    this.job,
    this.lastJob,
    this.pension = 0,
    this.counters = LifeCounters.zero,
    this.isAlive = true,
    List<MoneyEntry> ledger = const [],
  }) : assert(age >= 0),
       ledger = List.unmodifiable(ledger),
       assert(luck >= 0 && luck <= 100),
       flags = Set.unmodifiable(flags),
       history = List.unmodifiable(history),
       people = people ?? PeopleBook.empty();

  final String name;
  final Gender gender;
  final int age;
  final Stats stats;

  /// Bu yılın ve geçen yılın para hareketleri, kaynaklarıyla (Varlıklar
  /// sekmesi). Daha eskileri tutulmaz.
  final List<MoneyEntry> ledger;

  // Gizli değerler
  final Temperament temperament;

  /// 0–100. Zarlarda göstergeye eklenir.
  final int luck;
  final String hometown;
  final String team;
  final FamilyBackground background;

  /// Ailenin soyadı; eski kayıtlarda boş.
  final String surname;

  /// Doğulan aile profilinin kimliği (`fabrikator`); eski kayıtlarda null.
  final String? familyProfile;

  /// Hayattaki bütün kişiler.
  final PeopleBook people;

  /// Kalıcı izler: `kiraci`, `askerligini_yapti` gibi.
  final Set<String> flags;

  final List<CardRecord> history;

  /// Altın, ev, araba, kira ve kredi. Nakit para [stats] içindedir.
  final Assets assets;

  /// Şu anki iş; işsizse ya da emekliyse null.
  final Job? job;

  /// Bırakılan ya da emekli olunan son iş; özet ve albüm için.
  final Job? lastJob;

  /// Şu anki ya da en son iş.
  Job? get careerJob => job ?? lastJob;

  /// Yıllık emekli aylığı (TL); emekli değilse 0.
  final int pension;

  bool get isRetired => pension > 0;

  /// Ömür boyu sayaçlar (hayatın sayıları).
  final LifeCounters counters;
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
    Job? lastJob,
    int? pension,
    PeopleBook? people,
    LifeCounters? counters,
    bool? isAlive,
    List<MoneyEntry>? ledger,
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
      background: background,
      surname: surname,
      familyProfile: familyProfile,
      people: people ?? this.people,
      flags: flags ?? this.flags,
      history: history ?? this.history,
      assets: assets ?? this.assets,
      job: clearJob ? null : (job ?? this.job),
      lastJob: lastJob ?? (clearJob ? this.job ?? this.lastJob : this.lastJob),
      pension: pension ?? this.pension,
      counters: counters ?? this.counters,
      isAlive: isAlive ?? this.isAlive,
      ledger: ledger ?? this.ledger,
    );
  }

  /// Para hareketlerini ekler; iki yıldan eski kayıtları atar.
  Character withLedger(Iterable<MoneyEntry> entries) {
    final kept = [
      for (final e in [...ledger, ...entries])
        if (e.amount != 0 && e.age >= age - 1) e,
    ];
    return copyWith(ledger: kept);
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
    'background': background.id,
    'surname': surname,
    'family': ?familyProfile,
    'people': people.toJson(),
    'flags': (flags.toList()..sort()),
    'history': [for (final r in history) r.toJson()],
    'assets': assets.toJson(),
    'job': ?job?.toJson(),
    'lastJob': ?lastJob?.toJson(),
    'pension': pension,
    'counters': counters.toJson(),
    'alive': isAlive,
    if (ledger.isNotEmpty) 'ledger': [for (final e in ledger) e.toJson()],
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
      background: byId(FamilyBackground.fromId, 'background'),
      surname: json['surname'] as String? ?? '',
      familyProfile: json['family'] as String?,
      people: json['people'] == null
          ? null
          : PeopleBook.fromJson(json['people'] as Map<String, dynamic>),
      flags: {...(json['flags'] as List).cast<String>()},
      history: [
        for (final r in json['history'] as List)
          CardRecord.fromJson(r as Map<String, dynamic>),
      ],
      assets: Assets.fromJson(json['assets'] as Map<String, dynamic>),
      job: json['job'] == null
          ? null
          : Job.fromJson(json['job'] as Map<String, dynamic>),
      lastJob: json['lastJob'] == null
          ? null
          : Job.fromJson(json['lastJob'] as Map<String, dynamic>),
      pension: json['pension'] as int,
      counters: LifeCounters.fromJson(
        json['counters'] as Map<String, dynamic>?,
      ),
      isAlive: json['alive'] as bool,
      ledger: [
        for (final e in json['ledger'] as List? ?? const [])
          MoneyEntry.fromJson(e as Map<String, dynamic>),
      ],
    );
  }
}
