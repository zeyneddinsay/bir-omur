import 'dart:convert';

import 'character.dart';
import 'json_reader.dart';
import 'person.dart';

/// Bir adın hangi kuşakta yaygın olduğu. Dede-nine kuşağına "Defne",
/// oyuncunun kuşağına "Hatice" düşmesin diye.
enum NameEra {
  eski,
  orta,
  yeni,

  /// Her kuşakta kullanılır.
  her;

  /// Oyuncudan [yearsOlder] yaş büyük birinin kuşağı.
  static NameEra forAgeGap(int yearsOlder) {
    if (yearsOlder >= 40) return NameEra.eski;
    if (yearsOlder >= 15) return NameEra.orta;
    return NameEra.yeni;
  }
}

class NameEntry {
  const NameEntry(this.name, this.era);

  final String name;
  final NameEra era;
}

/// Doğulan ailenin tarifi (assets/families.json).
class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.name,
    required this.weight,
    required this.backgrounds,
    required this.wealth,
    required this.expectation,
    required this.fatherJobs,
    required this.motherJobs,
    required this.relativeJobs,
    required this.siblingWeights,
    required this.fatherAgeMin,
    required this.fatherAgeMax,
    this.singleParent,
  });

  final String id;

  /// Arayüzde görünen ad: "Fabrikatör".
  final String name;
  final int weight;

  /// Eski ekonominin aile durumu; listeden biri seçilir. D2'de kalkar.
  final List<FamilyBackground> backgrounds;
  final WealthLevel wealth;

  /// Ailenin senden beklentisi; olaylar buna bakar (`isin_basina`).
  final String expectation;
  final List<String> fatherJobs;
  final List<String> motherJobs;
  final List<String> relativeJobs;

  /// 0, 1, 2, 3 kardeş olasılık ağırlıkları.
  final List<int> siblingWeights;
  final int fatherAgeMin;
  final int fatherAgeMax;

  /// Yalnız ebeveyn profilinde annenin ve babanın ağırlığı; değilse null.
  final ({int mother, int father})? singleParent;

  factory FamilyProfile.fromJson(JsonReader r) {
    r.rejectUnknownKeys(const {
      'id',
      'name',
      'weight',
      'background',
      'wealth',
      'expectation',
      'fatherJobs',
      'motherJobs',
      'relativeJobs',
      'siblings',
      'fatherAge',
      'singleParent',
    });
    final id = r.requireString('id');
    final backgrounds = [
      for (final b in r.requireStringList('background'))
        FamilyBackground.fromId(b) ??
            (throw CardFormatException(
              '${r.path}.background',
              'bilinmeyen aile durumu "$b"',
            )),
    ];
    final wealthId = r.requireString('wealth');
    final wealth = WealthLevel.values.asNameMap()[wealthId];
    if (wealth == null) {
      throw CardFormatException(
        '${r.path}.wealth',
        'bilinmeyen servet "$wealthId"',
      );
    }
    final siblings = r.requireIntList('siblings');
    if (siblings.length != 4 ||
        siblings.any((w) => w < 0) ||
        siblings.every((w) => w == 0)) {
      throw CardFormatException(
        '${r.path}.siblings',
        '0–3 kardeş için 4 ağırlık gerekir',
      );
    }
    final fatherAge = r.requireIntList('fatherAge');
    if (fatherAge.length != 2 ||
        fatherAge[0] < 18 ||
        fatherAge[1] < fatherAge[0]) {
      throw CardFormatException('${r.path}.fatherAge', 'geçersiz yaş aralığı');
    }
    final weight = r.requireInt('weight');
    if (weight <= 0) {
      throw CardFormatException('${r.path}.weight', 'sıfırdan büyük olmalı');
    }
    final single = r.optionalObject('singleParent');
    ({int mother, int father})? singleParent;
    if (single != null) {
      single.rejectUnknownKeys(const {'anne', 'baba'});
      singleParent = (
        mother: single.requireInt('anne'),
        father: single.requireInt('baba'),
      );
    }
    return FamilyProfile(
      id: id,
      name: r.requireString('name'),
      weight: weight,
      backgrounds: List.unmodifiable(backgrounds),
      wealth: wealth,
      expectation: r.requireString('expectation'),
      fatherJobs: r.requireStringList('fatherJobs'),
      motherJobs: r.requireStringList('motherJobs'),
      relativeJobs: r.requireStringList('relativeJobs'),
      siblingWeights: siblings,
      fatherAgeMin: fatherAge[0],
      fatherAgeMax: fatherAge[1],
      singleParent: singleParent,
    );
  }
}

/// Aile profilleri, meslek adları, ad ve soyad listeleri.
class FamilyBook {
  FamilyBook({
    required List<FamilyProfile> profiles,
    required Map<String, String> occupations,
    required List<NameEntry> maleNames,
    required List<NameEntry> femaleNames,
    required List<String> surnames,
  }) : profiles = List.unmodifiable(profiles),
       occupations = Map.unmodifiable(occupations),
       maleNames = List.unmodifiable(maleNames),
       femaleNames = List.unmodifiable(femaleNames),
       surnames = List.unmodifiable(surnames) {
    final ids = <String>{};
    for (final p in profiles) {
      if (!ids.add(p.id)) {
        throw CardFormatException('families.${p.id}', 'tekrar eden profil');
      }
      for (final job in [...p.fatherJobs, ...p.motherJobs, ...p.relativeJobs]) {
        if (!occupations.containsKey(job)) {
          throw CardFormatException(
            'families.${p.id}',
            'bilinmeyen meslek "$job"',
          );
        }
      }
    }
    for (final era in NameEra.values.where((e) => e != NameEra.her)) {
      for (final (label, list) in [
        ('male', maleNames),
        ('female', femaleNames),
      ]) {
        if (!list.any((n) => n.era == era || n.era == NameEra.her)) {
          throw CardFormatException(
            'names.$label',
            '${era.name} kuşağında ad yok',
          );
        }
      }
    }
  }

  final List<FamilyProfile> profiles;

  /// Meslek kimliği → görünen ad.
  final Map<String, String> occupations;
  final List<NameEntry> maleNames;
  final List<NameEntry> femaleNames;
  final List<String> surnames;

  FamilyProfile? profileById(String id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Ad listede yalnızca bir cinsiyette geçiyorsa o cinsiyet; iki listede
  /// de yoksa ya da ikisinde de varsa null. Doğumda "Rastgele" seçilmişken
  /// "Ali" adlı birinin kız doğmaması için.
  Gender? genderOfName(String name) {
    final key = _lower(name.trim());
    if (key.isEmpty) return null;
    bool inList(List<NameEntry> list) => list.any((n) => _lower(n.name) == key);
    return switch ((inList(maleNames), inList(femaleNames))) {
      (true, false) => Gender.erkek,
      (false, true) => Gender.kadin,
      _ => null,
    };
  }

  /// Türkçe küçük harf: "I" → "ı", "İ" → "i".
  static String _lower(String s) =>
      s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

  /// [gender] ve [era] için uygun adlar ("her" kuşaktakiler dahil).
  List<String> namesFor(Gender gender, NameEra era) => [
    for (final n in gender == Gender.erkek ? maleNames : femaleNames)
      if (n.era == era || n.era == NameEra.her) n.name,
  ];

  factory FamilyBook.parse({
    required String familiesSource,
    required String namesSource,
  }) {
    final families = JsonReader(
      jsonDecode(familiesSource) as Map<String, dynamic>,
      'families',
    )..rejectUnknownKeys(const {'_aciklama', 'profiles', 'occupations'});
    final names = JsonReader(
      jsonDecode(namesSource) as Map<String, dynamic>,
      'names',
    )..rejectUnknownKeys(const {'_aciklama', 'male', 'female', 'surnames'});

    List<NameEntry> readNames(String key) => [
      for (final r in names.requireObjectList(key))
        () {
          r.rejectUnknownKeys(const {'name', 'era'});
          final eraId = r.requireString('era');
          final era = NameEra.values.asNameMap()[eraId];
          if (era == null) {
            throw CardFormatException(
              '${r.path}.era',
              'bilinmeyen kuşak "$eraId"',
            );
          }
          return NameEntry(r.requireString('name'), era);
        }(),
    ];

    final occupations = families.requireObject('occupations');
    return FamilyBook(
      profiles: [
        for (final r in families.requireObjectList('profiles'))
          FamilyProfile.fromJson(r),
      ],
      occupations: {
        for (final key in occupations.json.keys)
          key: occupations.requireString(key),
      },
      maleNames: readNames('male'),
      femaleNames: readNames('female'),
      surnames: names.requireStringList('surnames'),
    );
  }

  /// İçerik yüklenmeden motoru kuran testler için küçük bir aile kitabı.
  /// Oyun her zaman `assets/families.json` ve `assets/names.json` kullanır.
  static final FamilyBook minimal = FamilyBook(
    profiles: const [
      FamilyProfile(
        id: 'memur',
        name: 'Memur',
        weight: 1,
        backgrounds: [FamilyBackground.orta],
        wealth: WealthLevel.orta,
        expectation: 'devlet_kapisi',
        fatherJobs: ['memur'],
        motherJobs: ['ogretmen'],
        relativeJobs: ['memur'],
        siblingWeights: [1, 1, 0, 0],
        fatherAgeMin: 26,
        fatherAgeMax: 34,
      ),
    ],
    occupations: const {
      'memur': 'Memur',
      'ogretmen': 'Öğretmen',
      'ev_hanimi': 'Ev hanımı',
      'bakkal': 'Bakkal',
      'emekli': 'Emekli',
    },
    maleNames: const [NameEntry('Ali', NameEra.her)],
    femaleNames: const [NameEntry('Ayşe', NameEra.her)],
    surnames: const ['Yılmaz', 'Kaya'],
  );
}
