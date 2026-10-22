import 'dart:math';

import '../models/models.dart';

/// Hayata sonradan giren kişileri üretir: ev sahibi, ev arkadaşı, yeni
/// komşu, bakkal, iş arkadaşı, üniversite ve bölük arkadaşı. Ad, kuşağına
/// göre [FamilyBook]'tan seçilir.
class PersonFactory {
  PersonFactory(this.random, this.families);

  final Random random;
  final FamilyBook families;

  /// Yeni bir kişi ekler; kitabın yeni hâlini ve kişiyi döndürür.
  ///
  /// [age]: kişinin şimdiki yaşı. [now]: oyuncunun yaşı.
  (PeopleBook, Person) add(
    PeopleBook book, {
    required int now,
    required int age,
    required String city,
    required Origin origin,
    required int base,
    List<PersonRole> roles = const [],
    Gender? gender,
    String? occupation,
    WealthLevel? wealth,
    Trait? requiredTrait,
    MaritalStatus? marital,
    Bond bond = Bond.tanidik,
  }) {
    final g = gender ?? Gender.values[random.nextInt(Gender.values.length)];
    final names = families.namesFor(g, NameEra.forAgeGap(age - now));
    final name = names[random.nextInt(names.length)];
    final surname = families.surnames[random.nextInt(families.surnames.length)];
    final traits = <Trait>{?requiredTrait};
    final target = random.nextDouble() < 0.7 ? 2 : 1;
    while (traits.length < target) {
      final t = Trait.values[random.nextInt(Trait.values.length)];
      if (traits.every((other) => Trait.compatible(t, other))) traits.add(t);
    }
    final seed = random.nextInt(1 << 30);
    return book.add(
      (id) => Person(
        id: id,
        name: name,
        surname: surname,
        gender: g,
        bornAt: now - age,
        city: city,
        origin: origin,
        metAt: now,
        base: base,
        portraitSeed: seed,
        bond: bond,
        roles: roles,
        traits: traits,
        wealth: wealth ?? _wealth(),
        marital:
            marital ??
            (age >= 25 && random.nextDouble() < 0.6
                ? MaritalStatus.evli
                : MaritalStatus.bekar),
        occupation: occupation,
        health: 70 + random.nextInt(28),
        lastContactAt: now,
      ),
    );
  }

  WealthLevel _wealth() {
    final roll = random.nextInt(100);
    if (roll < 30) return WealthLevel.dar;
    if (roll < 85) return WealthLevel.orta;
    if (roll < 97) return WealthLevel.rahat;
    return WealthLevel.zengin;
  }

  int between(int min, int max) => min + random.nextInt(max - min + 1);
}
