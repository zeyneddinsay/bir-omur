/// Hayatın 8 evresi. [id] kart JSON'undaki `stage` değeridir.
enum LifeStage {
  bebek('bebek', 0, 2),
  cocukluk('cocukluk', 3, 6),
  ilkokul('ilkokul', 7, 10),
  ortaokul('ortaokul', 11, 14),
  lise('lise', 15, 18),
  genc('genc', 19, 29),
  yetiskin('yetiskin', 30, 49),
  olgun('olgun', 50, 64),
  yasli('yasli', 65, null);

  const LifeStage(this.id, this.minAge, this.maxAge);

  final String id;
  final int minAge;

  /// Son evrenin üst sınırı yoktur.
  final int? maxAge;

  bool contains(int age) => age >= minAge && (maxAge == null || age <= maxAge!);

  static LifeStage forAge(int age) {
    if (age < 0) throw ArgumentError.value(age, 'age', 'eksi olamaz');
    return values.firstWhere((stage) => stage.contains(age));
  }

  static LifeStage? fromId(String id) {
    for (final stage in values) {
      if (stage.id == id) return stage;
    }
    return null;
  }
}
