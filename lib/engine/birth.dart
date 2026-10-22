import 'dart:math';

import '../models/models.dart';
import 'family_generator.dart';

/// Yeni doğan karakteri ve ailesini tohumlu rastgelelikle üretir.
///
/// Ad ve aile verisi [FamilyBook]'tan (assets/names.json,
/// assets/families.json) gelir. Şehir ve takım listeleri koddadır; takımlar
/// kurgusaldır.
class BirthGenerator {
  BirthGenerator(this.random, {FamilyBook? families})
    : families = families ?? FamilyBook.minimal;

  final Random random;
  final FamilyBook families;

  static const List<String> hometowns = [
    'İstanbul',
    'Ankara',
    'İzmir',
    'Bursa',
    'Trabzon',
    'Konya',
    'Adana',
    'Erzurum',
    'Kastamonu',
    'Eskişehir',
    'Gaziantep',
    'Samsun',
    'Malatya',
    'Denizli',
    'Sivas',
    'Rize',
    'Kayseri',
    'Antalya',
    'Mardin',
    'Edirne',
  ];

  static const List<String> teams = [
    'Boğaziçi Martıları',
    'Anadolu Kartalları',
    'Karadeniz Fırtınası',
    'Ege Yıldızları',
  ];

  /// "Rastgele" seçildiğinde: ad, ad listesinde tek bir cinsiyete aitse o
  /// cinsiyet ("Ali" kız doğmaz). Zar yine de atılır ki tohumun akışı
  /// değişmesin.
  Gender _randomGender(String? name) {
    final rolled = _pick(Gender.values);
    if (name == null) return rolled;
    return families.genderOfName(name) ?? rolled;
  }

  Character generate({String? name, Gender? gender}) {
    final trimmed = name?.trim();
    final Gender g = gender ?? _randomGender(trimmed);
    final hometown = _pick(hometowns);
    final family = FamilyGenerator(
      random,
      families,
      cities: hometowns,
    ).generate(hometown: hometown);
    final background = family.background;
    var stats = Stats(
      health: _between(70, 95),
      happiness: _between(60, 85),
      knowledge: _between(0, 10),
      reputation: _between(45, 60),
      family: _between(60, 90),
      money: 0,
    );
    backgroundStart(background)
        .forEach((kind, delta) => stats = stats.withDelta(kind, delta));
    return Character(
      name: (trimmed == null || trimmed.isEmpty)
          ? _pick(families.namesFor(g, NameEra.yeni))
          : trimmed,
      gender: g,
      age: 0,
      stats: stats,
      temperament: _pick(Temperament.values),
      luck: _between(0, 100),
      hometown: hometown,
      team: _pick(teams),
      background: background,
      surname: family.surname,
      familyProfile: family.profile.id,
      people: family.people,
    );
  }

  /// Aile durumunun doğumdaki etkisi: varlıklı ailede iyi okul, dar
  /// gelirli ailede daha sıkı bağ ama daha az keyif.
  static Map<StatKind, int> backgroundStart(FamilyBackground b) => switch (b) {
    FamilyBackground.varlikli => {StatKind.happiness: 5, StatKind.knowledge: 5},
    FamilyBackground.orta => const {},
    FamilyBackground.dar => {StatKind.family: 5, StatKind.happiness: -5},
  };

  T _pick<T>(List<T> items) => items[random.nextInt(items.length)];

  int _between(int min, int max) => min + random.nextInt(max - min + 1);
}
