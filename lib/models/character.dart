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

  /// Kalıcı izler: `ev_sahibi`, `askerligini_yapti` gibi.
  final Set<String> flags;

  final List<CardRecord> history;
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
      isAlive: isAlive ?? this.isAlive,
    );
  }

  Character withRecord(CardRecord record) =>
      copyWith(history: [...history, record]);
}
