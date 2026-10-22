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
  /// Dünya küçük kuralı: bu ihtimalle yeni biri yerine uygun bir tanıdık
  /// (eski sınıf, bölük ya da iş arkadaşı, mahalleden biri) rolü alır.
  static const double worldSmallChance = 0.35;

  /// Romantik ya da eski evlilik bağı olan tanıdık rol almaz.
  static const Set<Bond> romanticBonds = {
    Bond.flort,
    Bond.sevgili,
    Bond.nisanli,
    Bond.eskiEs,
  };

  /// Yere bağlı roller: bunlardan birini süren tanıdık yeni rol almaz.
  static const Set<RoleKind> placeRoles = {
    RoleKind.patron,
    RoleKind.amir,
    RoleKind.usta,
    RoleKind.mudur,
    RoleKind.isArkadasi,
    RoleKind.calisan,
    RoleKind.ortak,
    RoleKind.rakip,
    RoleKind.komsu,
    RoleKind.bakkal,
    RoleKind.muhtar,
    RoleKind.evSahibi,
    RoleKind.evArkadasi,
    RoleKind.kiraci,
  };

  /// Yeni bir rol için önce tanıdıklara bakar ([worldSmallChance]): aynı
  /// şehirde, yaşı uyan, akraba ya da sevgili olmayan, süren hiçbir rolü
  /// olmayan, bu rolü daha önce üstlenmemiş ve mesleği uyan (ya da mesleği
  /// olmayan) biri rolü alır (arşivdeyse çevreye döner). Serveti değişmez.
  /// Yoksa yeni kişi gelir.
  (PeopleBook, Person) addOrReuse(
    PeopleBook book, {
    required int now,
    required int minAge,
    required int maxAge,
    required String city,
    required Origin origin,
    required int base,
    required List<PersonRole> roles,
    String? occupation,
    WealthLevel? wealth,
    Gender? gender,
  }) {
    if (random.nextDouble() < worldSmallChance) {
      final known = [
        for (final p in book.bornBy(now))
          if (p.isAlive &&
              p.kin == null &&
              p.city == city &&
              p.ageAt(now) >= minAge &&
              p.ageAt(now) <= maxAge &&
              (gender == null || p.gender == gender) &&
              !romanticBonds.contains(p.bond) &&
              !p.roles.any((r) => r.active) &&
              !roles.any((r) => p.hasRole(r.kind, activeOnly: false)) &&
              (p.occupation == null || p.occupation == occupation))
            p,
      ];
      if (known.isNotEmpty) {
        final p = known[random.nextInt(known.length)];
        final reused = p.copyWith(
          roles: [...p.roles, ...roles],
          archived: false,
          occupation: occupation,
        );
        return (book.update(reused), reused);
      }
    }
    return add(
      book,
      now: now,
      age: between(minAge, maxAge),
      city: city,
      origin: origin,
      base: base,
      roles: roles,
      occupation: occupation,
      wealth: wealth,
      gender: gender,
    );
  }

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
