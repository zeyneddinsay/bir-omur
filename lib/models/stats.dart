/// Ekranda görünen 0–100 aralığındaki göstergeler.
///
/// [key] kart JSON'undaki etki adıdır.
enum StatKind {
  health('health'),
  happiness('happiness'),
  knowledge('knowledge'),
  reputation('reputation'),
  family('family');

  const StatKind(this.key);

  final String key;

  static StatKind? fromKey(String key) {
    for (final kind in values) {
      if (kind.key == key) return kind;
    }
    return null;
  }
}

/// Karakterin göstergeleri ve parası. Değişmezdir.
///
/// Göstergeler her zaman 0–100 arasındadır; para TL cinsindendir ve üst
/// sınırı yoktur. Borç olabildiği için para eksiye inebilir.
class Stats {
  const Stats({
    required this.health,
    required this.happiness,
    required this.knowledge,
    required this.reputation,
    required this.family,
    required this.money,
  }) : assert(health >= min && health <= max),
       assert(happiness >= min && happiness <= max),
       assert(knowledge >= min && knowledge <= max),
       assert(reputation >= min && reputation <= max),
       assert(family >= min && family <= max);

  static const int min = 0;
  static const int max = 100;

  final int health;
  final int happiness;
  final int knowledge;
  final int reputation;
  final int family;
  final int money;

  int operator [](StatKind kind) => switch (kind) {
    StatKind.health => health,
    StatKind.happiness => happiness,
    StatKind.knowledge => knowledge,
    StatKind.reputation => reputation,
    StatKind.family => family,
  };

  /// [kind] göstergesine [delta] ekler; sonuç 0–100 aralığına sıkıştırılır.
  Stats withDelta(StatKind kind, int delta) {
    final value = (this[kind] + delta).clamp(min, max);
    return switch (kind) {
      StatKind.health => copyWith(health: value),
      StatKind.happiness => copyWith(happiness: value),
      StatKind.knowledge => copyWith(knowledge: value),
      StatKind.reputation => copyWith(reputation: value),
      StatKind.family => copyWith(family: value),
    };
  }

  Stats withMoneyDelta(int delta) => copyWith(money: money + delta);

  Stats copyWith({
    int? health,
    int? happiness,
    int? knowledge,
    int? reputation,
    int? family,
    int? money,
  }) {
    return Stats(
      health: health ?? this.health,
      happiness: happiness ?? this.happiness,
      knowledge: knowledge ?? this.knowledge,
      reputation: reputation ?? this.reputation,
      family: family ?? this.family,
      money: money ?? this.money,
    );
  }

  Map<String, Object> toJson() => {
    for (final kind in StatKind.values) kind.key: this[kind],
    'money': money,
  };

  /// Kayıttan okunan değerler aralık dışındaysa sıkıştırılır.
  factory Stats.fromJson(Map<String, dynamic> json) {
    int stat(StatKind kind) => (json[kind.key] as int).clamp(min, max);
    return Stats(
      health: stat(StatKind.health),
      happiness: stat(StatKind.happiness),
      knowledge: stat(StatKind.knowledge),
      reputation: stat(StatKind.reputation),
      family: stat(StatKind.family),
      money: json['money'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Stats &&
      other.health == health &&
      other.happiness == happiness &&
      other.knowledge == knowledge &&
      other.reputation == reputation &&
      other.family == family &&
      other.money == money;

  @override
  int get hashCode =>
      Object.hash(health, happiness, knowledge, reputation, family, money);

  @override
  String toString() =>
      'Stats(S:$health M:$happiness B:$knowledge İ:$reputation '
      'A:$family Para:$money)';
}
