import 'dart:math';

import '../models/models.dart';

/// Doğumda kurulan aile ve mahalle.
class FamilyResult {
  const FamilyResult({
    required this.profile,
    required this.background,
    required this.surname,
    required this.people,
  });

  final FamilyProfile profile;

  /// Eski ekonominin aile durumu (D2'de kalkar).
  final FamilyBackground background;
  final String surname;
  final PeopleBook people;
}

/// Doğulan aileyi ve mahalleyi tohumlu rastgelelikle üretir: anne ve baba
/// (ya da yalnız ebeveyn), 0–3 kardeş, hayattaki dede ve nineler, 1–2 akraba,
/// komşu teyze ve bakkal.
class FamilyGenerator {
  FamilyGenerator(this.random, this.book, {required this.cities});

  final Random random;
  final FamilyBook book;

  /// Akrabaların yaşayabileceği şehirler.
  final List<String> cities;

  /// Yakınlık tabanları.
  static const int motherBase = 70;
  static const int fatherBase = 65;
  static const int singleParentBase = 75;
  static const int siblingBase = 55;
  static const int grandparentBase = 60;
  static const int relativeBase = 40;
  static const int neighborBase = 30;
  static const int grocerBase = 25;

  /// Annenin oyuncuyu doğurduğundaki en düşük yaşı ve kardeş doğurabileceği
  /// en yüksek yaş.
  static const int motherMinAge = 19;
  static const int motherMaxAge = 42;

  /// Dedenin ya da ninenin hayatta olabileceği en yüksek yaş (doğumda).
  static const int grandparentMaxAge = 82;

  late PeopleBook _book;
  late String _city;

  FamilyResult generate({required String hometown}) {
    _book = PeopleBook.empty();
    _city = hometown;
    final profile = _pickProfile();
    final background = _pick(profile.backgrounds);
    final surname = _pick(book.surnames);
    final maternalSurname = _otherSurname(surname);

    final fatherAge = _between(profile.fatherAgeMin, profile.fatherAgeMax);
    final motherAge = max(motherMinAge, fatherAge - _between(0, 6));

    final single = profile.singleParent;
    final hasMother =
        single == null || _weighted([single.mother, single.father]) == 0;
    final hasFather = single == null || !hasMother;

    if (hasMother) {
      _add(
        kin: Kinship.anne,
        gender: Gender.kadin,
        age: motherAge,
        surname: surname,
        occupation: _pick(profile.motherJobs),
        base: single == null ? motherBase : singleParentBase,
        health: _between(80, 95),
        wealth: profile.wealth,
        marital: single == null ? MaritalStatus.evli : MaritalStatus.bekar,
      );
    }
    if (hasFather) {
      _add(
        kin: Kinship.baba,
        gender: Gender.erkek,
        age: fatherAge,
        surname: surname,
        occupation: _pick(_maleJobs(profile.fatherJobs)),
        base: single == null ? fatherBase : singleParentBase,
        health: _between(80, 95),
        wealth: profile.wealth,
        marital: single == null ? MaritalStatus.evli : MaritalStatus.bekar,
      );
    }

    _addSiblings(profile, surname, motherAge);
    if (hasFather) {
      _addGrandparents(Side.baba, fatherAge, surname, profile);
    }
    if (hasMother) {
      _addGrandparents(Side.anne, motherAge, maternalSurname, profile);
    }
    _addRelatives(
      profile,
      surname: surname,
      maternalSurname: maternalSurname,
      fatherAge: hasFather ? fatherAge : null,
      motherAge: hasMother ? motherAge : null,
    );
    _addNeighbors();

    return FamilyResult(
      profile: profile,
      background: background,
      surname: surname,
      people: _book,
    );
  }

  void _addSiblings(FamilyProfile profile, String surname, int motherAge) {
    final count = _weighted(profile.siblingWeights);
    final taken = <int>{0};
    for (var i = 0; i < count; i++) {
      // Büyük kardeş: anne en az 19 yaşındayken doğmuş olmalı.
      final maxOlder = min(9, motherAge - motherMinAge);
      // Küçük kardeş: anne en fazla 42 yaşında doğurur.
      final maxYounger = min(7, motherMaxAge - motherAge);
      final options = [
        for (var gap = 1; gap <= maxOlder; gap++) -gap,
        for (var gap = 2; gap <= maxYounger; gap++) gap,
      ].where((b) => !taken.contains(b)).toList();
      if (options.isEmpty) break;
      final bornAt = _pick(options);
      taken.add(bornAt);
      final gender = _pick(Gender.values);
      _add(
        kin: Kinship.kardes,
        gender: gender,
        age: -bornAt,
        surname: surname,
        occupation: null,
        base: siblingBase,
        health: _between(85, 98),
        wealth: profile.wealth,
        metAt: max(0, bornAt),
      );
    }
  }

  void _addGrandparents(
    Side side,
    int parentAge,
    String surname,
    FamilyProfile profile,
  ) {
    final city = side == Side.baba || random.nextDouble() < 0.6
        ? _city
        : _pick(cities);
    final grandfatherAge = parentAge + _between(24, 34);
    final grandmotherAge = max(
      parentAge + motherMinAge,
      grandfatherAge - _between(0, 6),
    );
    final alive = [
      (Kinship.dede, Gender.erkek, grandfatherAge),
      (Kinship.nine, Gender.kadin, grandmotherAge),
    ].where((g) => _survives(g.$3)).toList();
    for (final (kin, gender, age) in alive) {
      _add(
        kin: kin,
        side: side,
        gender: gender,
        age: age,
        surname: surname,
        occupation: kin == Kinship.dede
            ? (profile.id == 'ciftci' ? 'ciftci' : 'emekli')
            : 'ev_hanimi',
        base: grandparentBase,
        health: _between(40, 75),
        wealth: profile.wealth,
        marital: alive.length == 2 ? MaritalStatus.evli : MaritalStatus.dul,
        city: city,
      );
    }
  }

  bool _survives(int age) {
    if (age > grandparentMaxAge) return false;
    final chance = age < 65 ? 0.95 : (age <= 72 ? 0.8 : 0.55);
    return random.nextDouble() < chance;
  }

  void _addRelatives(
    FamilyProfile profile, {
    required String surname,
    required String maternalSurname,
    required int? fatherAge,
    required int? motherAge,
  }) {
    final candidates = [
      if (fatherAge != null) ...[
        (Kinship.amca, Gender.erkek, fatherAge, surname, Side.baba),
        (Kinship.hala, Gender.kadin, fatherAge, null, Side.baba),
      ],
      if (motherAge != null) ...[
        (Kinship.dayi, Gender.erkek, motherAge, maternalSurname, Side.anne),
        (Kinship.teyze, Gender.kadin, motherAge, null, Side.anne),
      ],
    ];
    final count = min(candidates.length, _between(1, 2));
    for (var i = 0; i < count; i++) {
      final (kin, gender, parentAge, fixedSurname, side) = candidates.removeAt(
        random.nextInt(candidates.length),
      );
      final gap = _between(1, 10) * (random.nextBool() ? 1 : -1);
      final jobs = gender == Gender.erkek
          ? _maleJobs(profile.relativeJobs)
          : profile.relativeJobs;
      _add(
        kin: kin,
        side: side,
        gender: gender,
        age: max(20, parentAge + gap),
        // Evli kadın akraba eşinin soyadını taşır.
        surname: fixedSurname ?? _pick(book.surnames),
        occupation: _pick(jobs),
        base: relativeBase,
        health: _between(70, 95),
        wealth: profile.wealth,
        marital: random.nextDouble() < 0.75
            ? MaritalStatus.evli
            : MaritalStatus.bekar,
        city: random.nextDouble() < 0.7 ? _city : _pick(cities),
      );
    }
  }

  void _addNeighbors() {
    _add(
      kin: null,
      gender: Gender.kadin,
      age: _between(45, 62),
      surname: _pick(book.surnames),
      occupation: random.nextBool() ? 'ev_hanimi' : 'emekli',
      base: neighborBase,
      health: _between(65, 90),
      wealth: WealthLevel.orta,
      marital: MaritalStatus.evli,
      origin: Origin.mahalle,
      bond: Bond.tanidik,
      role: RoleKind.komsu,
      requiredTrait: Trait.dedikoducu,
    );
    _add(
      kin: null,
      gender: Gender.erkek,
      age: _between(48, 66),
      surname: _pick(book.surnames),
      occupation: 'bakkal',
      base: grocerBase,
      health: _between(65, 90),
      wealth: WealthLevel.orta,
      marital: MaritalStatus.evli,
      origin: Origin.mahalle,
      bond: Bond.tanidik,
      role: RoleKind.bakkal,
    );
  }

  void _add({
    required Kinship? kin,
    required Gender gender,
    required int age,
    required String surname,
    required String? occupation,
    required int base,
    required int health,
    required WealthLevel wealth,
    MaritalStatus marital = MaritalStatus.bekar,
    Side? side,
    String? city,
    int metAt = 0,
    Origin origin = Origin.aile,
    Bond? bond,
    RoleKind? role,
    Trait? requiredTrait,
  }) {
    final name = _pick(book.namesFor(gender, NameEra.forAgeGap(age)));
    final traits = _pickTraits(requiredTrait);
    final seed = random.nextInt(1 << 30);
    final (next, _) = _book.add(
      (id) => Person(
        id: id,
        name: name,
        surname: surname,
        gender: gender,
        bornAt: -age,
        city: city ?? _city,
        origin: origin,
        metAt: metAt,
        base: base,
        portraitSeed: seed,
        kin: kin,
        side: side,
        bond: bond,
        roles: [if (role != null) PersonRole(role)],
        traits: traits,
        wealth: wealth,
        marital: marital,
        occupation: occupation,
        health: health,
        lastContactAt: metAt,
      ),
    );
    _book = next;
  }

  /// 1 ya da 2 uyumlu özellik; [required] verilirse o hep içinde.
  Set<Trait> _pickTraits(Trait? required) {
    final traits = <Trait>{?required};
    final target = random.nextDouble() < 0.7 ? 2 : 1;
    while (traits.length < target) {
      final t = _pick(Trait.values);
      if (traits.every((other) => Trait.compatible(t, other))) traits.add(t);
    }
    return traits;
  }

  /// Ev hanımlığı yalnızca kadın kişilere verilir.
  List<String> _maleJobs(List<String> jobs) {
    final filtered = jobs.where((j) => j != 'ev_hanimi').toList();
    return filtered.isEmpty ? const ['emekli'] : filtered;
  }

  String _otherSurname(String surname) {
    final others = book.surnames.where((s) => s != surname).toList();
    return others.isEmpty ? surname : _pick(others);
  }

  FamilyProfile _pickProfile() =>
      book.profiles[_weighted([for (final p in book.profiles) p.weight])];

  int _weighted(List<int> weights) {
    final total = weights.fold(0, (s, w) => s + w);
    var roll = random.nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return i;
    }
    return weights.length - 1;
  }

  T _pick<T>(List<T> items) => items[random.nextInt(items.length)];

  int _between(int min, int max) => min + random.nextInt(max - min + 1);
}
