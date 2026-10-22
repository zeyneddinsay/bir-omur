import 'dart:math';

import '../models/models.dart';
import 'relationships.dart';

/// Yıl günlüğüne düşen, çevreden bir haber.
enum NewsKind {
  /// Küçük kardeş doğdu.
  kardesDogdu,

  /// Yeni okul kademesi: yeni sınıf, yeni öğretmen.
  yeniSinif,
  evlendi,
  tasindi,
  isBuldu,
  emekliOldu,
  vefat,
}

/// Bir kişi hakkında bir haber. Metni arayüz kurar.
class PersonNews {
  const PersonNews(this.kind, this.personId, {this.detail});

  final NewsKind kind;
  final String personId;

  /// Habere göre ek bilgi: yeni şehir, meslek kimliği ya da okul evresi.
  final String? detail;

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'person': personId,
    'detail': ?detail,
  };

  factory PersonNews.fromJson(Map<String, dynamic> json) => PersonNews(
    NewsKind.values.byName(json['kind'] as String),
    json['person'] as String,
    detail: json['detail'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is PersonNews &&
      other.kind == kind &&
      other.personId == personId &&
      other.detail == detail;

  @override
  int get hashCode => Object.hash(kind, personId, detail);
}

/// Çevredeki herkesin yılı: yaşlanma, kendi hayatı (evlenme, taşınma, iş,
/// emeklilik, vefat), okul sınıfları ve arşiv.
///
/// Kişinin kendi yılı seninle olan çubukları değiştirmez; yalnızca haber
/// üretir. Yaşlanmadan ([YearTick]) sonra, yeni yaş için çalışır.
class PeopleTick {
  PeopleTick(this.random, this.families, {required this.cities});

  final Random random;
  final FamilyBook families;
  final List<String> cities;

  /// Aynı anda en fazla bu kadar aktif kişi; fazlası arşive düşer. Anne,
  /// baba, kardeş, eş ve çocuk sayılmaz, arşive de düşmez.
  static const int maxActive = 40;

  /// Bu yaşa kadar anne, baba ve kardeşlerle aynı evde yaşanır; aynı evde
  /// yaşayanlarla ilişki soğumaz. (D2'de evden çıkma kararı gelir.)
  static const int householdUntil = 18;

  /// Anne ve baba bu yaştan önce vefat etmez (oyuncunun yaşı).
  static const int parentsSafeUntil = 18;

  /// Bu yaştan genç kişiler vefat etmez.
  static const int deathMinAge = 50;

  /// Okul kademelerinin başladığı yaşlar ve evre kimlikleri.
  static const Map<int, String> schoolStarts = {
    7: 'ilkokul',
    11: 'ortaokul',
    15: 'lise',
  };

  static const int classmatesPerClass = 5;

  /// Önceki sınıftan bir arkadaşın yeni kademede de aynı sınıfta olma
  /// olasılığı (aynı mahalle, aynı okul).
  static const double stayInClassChance = 0.3;

  /// Ailenin çekirdeği: soğuma ve arşiv kuralları bunlara uygulanmaz.
  static const Set<Kinship> coreKin = {
    Kinship.anne,
    Kinship.baba,
    Kinship.kardes,
    Kinship.es,
    Kinship.cocuk,
  };

  /// Haber, kişi akrabaysa ya da çubuklardan biri bu değere ulaştıysa
  /// günlüğe düşer.
  static const int newsRelevance = 40;

  late PeopleBook _book;
  late int _now;
  late List<PersonNews> _news;

  (Character, List<PersonNews>) apply(Character c) {
    _book = c.people;
    _now = c.age;
    _news = [];

    _births();
    _household(c);
    for (final p in _book.active(_now).toList()) {
      _ownYear(p, c);
    }
    final stage = schoolStarts[_now];
    if (stage != null) _newClass(c, stage);
    _archive();

    return (c.copyWith(people: _book), List.unmodifiable(_news));
  }

  void _births() {
    for (final p in _book.all) {
      if (p.kin == Kinship.kardes && p.bornAt == _now) {
        _news.add(PersonNews(NewsKind.kardesDogdu, p.id));
      }
    }
  }

  void _household(Character c) {
    if (_now >= householdUntil) return;
    for (final p in _book.active(_now).toList()) {
      if (p.kin == Kinship.anne ||
          p.kin == Kinship.baba ||
          p.kin == Kinship.kardes) {
        _book = _book.update(Relationships.touch(p, _now));
      }
    }
  }

  void _ownYear(Person original, Character c) {
    var p = _book[original.id]!;
    final age = p.ageAt(_now);
    if (age < 0) return;

    // Sağlık yaşla azalır.
    if (age >= 60) {
      final loss = _between(1, 3) + (age >= 75 ? _between(1, 3) : 0);
      p = p.copyWith(health: max(0, p.health - loss));
    }

    if (_dies(p, age)) {
      _book = _book.update(p.copyWith(diedAt: _now));
      _news.add(PersonNews(NewsKind.vefat, p.id));
      return;
    }

    if (p.occupation != null && p.occupation != 'emekli' && age >= 65) {
      p = p.copyWith(occupation: 'emekli');
      _report(p, NewsKind.emekliOldu);
    } else if (p.occupation == null && age >= 22 && random.nextDouble() < 0.3) {
      final job = _jobFor(p, c);
      p = p.copyWith(occupation: job);
      _report(p, NewsKind.isBuldu, detail: job);
    }

    // Anne, baba, eş ve çocuğun evliliği kendi olaylarıyla gelir.
    const ownMarriage = {Kinship.anne, Kinship.baba, Kinship.es, Kinship.cocuk};
    if (p.marital == MaritalStatus.bekar &&
        age >= 22 &&
        age <= 40 &&
        !ownMarriage.contains(p.kin) &&
        random.nextDouble() < 0.08) {
      p = p.copyWith(marital: MaritalStatus.evli);
      _report(p, NewsKind.evlendi);
    }

    if (age >= 20 &&
        !_livesWithPlayer(p) &&
        random.nextDouble() < 0.02 &&
        cities.length > 1) {
      final others = cities.where((city) => city != p.city).toList();
      final city = others[random.nextInt(others.length)];
      p = p.copyWith(city: city);
      _report(p, NewsKind.tasindi, detail: city);
    }

    if (random.nextDouble() < 0.03) {
      final levels = WealthLevel.values;
      final step = random.nextBool() ? 1 : -1;
      final index = (p.wealth.index + step).clamp(0, levels.length - 1);
      p = p.copyWith(wealth: levels[index]);
    }

    _book = _book.update(p);
  }

  bool _livesWithPlayer(Person p) =>
      _now < householdUntil &&
      (p.kin == Kinship.anne ||
          p.kin == Kinship.baba ||
          p.kin == Kinship.kardes);

  bool _dies(Person p, int age) {
    if (age < deathMinAge) return false;
    if ((p.kin == Kinship.anne || p.kin == Kinship.baba) &&
        _now < parentsSafeUntil) {
      return false;
    }
    var chance = switch (age) {
      < 65 => 0.01,
      < 75 => 0.03,
      < 85 => 0.07,
      _ => 0.15,
    };
    if (p.health < 30) chance *= 2;
    if (p.health == 0) chance = 1;
    return random.nextDouble() < chance;
  }

  String _jobFor(Person p, Character c) {
    final profile = c.familyProfile == null
        ? null
        : families.profileById(c.familyProfile!);
    final pool = (profile?.relativeJobs ?? families.occupations.keys.toList())
        .where((j) => j != 'emekli' && j != 'bakkal')
        .where((j) => p.gender == Gender.kadin || j != 'ev_hanimi')
        .toList();
    if (pool.isEmpty) return 'memur';
    return pool[random.nextInt(pool.length)];
  }

  void _report(Person p, NewsKind kind, {String? detail}) {
    final relevant =
        p.kin != null ||
        Relationships.closeness(p, _now) >= newsRelevance ||
        Relationships.hostility(p, _now) >= newsRelevance;
    if (relevant) _news.add(PersonNews(kind, p.id, detail: detail));
  }

  void _newClass(Character c, String stage) {
    const schoolRoles = {
      RoleKind.sinifArkadasi,
      RoleKind.siraArkadasi,
      RoleKind.ogretmen,
    };
    var stayed = 0;
    for (final p in _book.all.toList()) {
      if (!p.roles.any((r) => r.active && schoolRoles.contains(r.kind))) {
        continue;
      }
      final keeps =
          p.isAlive &&
          !p.archived &&
          p.hasRole(RoleKind.sinifArkadasi) &&
          stayed < classmatesPerClass - 1 &&
          random.nextDouble() < stayInClassChance;
      if (keeps) {
        stayed++;
        // Sıra arkadaşlığı yeni sınıfta yeniden belirlenir.
        _book = _book.update(
          p.copyWith(
            roles: [
              for (final r in p.roles)
                r.kind == RoleKind.siraArkadasi ? r.ended() : r,
            ],
          ),
        );
      } else {
        _book = _book.update(
          p.copyWith(
            roles: [
              for (final r in p.roles)
                schoolRoles.contains(r.kind) && r.active ? r.ended() : r,
            ],
          ),
        );
      }
    }

    // Sıra arkadaşı yeni gelir; kalan yerler yeni sınıf arkadaşlarıyla dolar.
    _addSchoolPerson(
      c,
      ageGap: _classmateGap(),
      roles: const [
        PersonRole(RoleKind.sinifArkadasi),
        PersonRole(RoleKind.siraArkadasi),
      ],
      base: 20,
    );
    for (var i = stayed + 1; i < classmatesPerClass; i++) {
      _addSchoolPerson(
        c,
        ageGap: _classmateGap(),
        roles: const [PersonRole(RoleKind.sinifArkadasi)],
        base: 10,
      );
    }
    _addSchoolPerson(
      c,
      // Öğretmen 26–60 yaşında; yaşı oyuncunun yaşından bağımsız.
      ageGap: _between(26, 60) - _now,
      roles: const [PersonRole(RoleKind.ogretmen)],
      base: 25,
      occupation: 'ogretmen',
    );
    _news.add(PersonNews(NewsKind.yeniSinif, _book.all.last.id, detail: stage));
  }

  /// Sınıf arkadaşının oyuncudan yaş farkı: çoğu aynı yıl doğumlu.
  int _classmateGap() {
    final roll = random.nextDouble();
    if (roll < 0.1) return 1;
    if (roll < 0.2) return -1;
    return 0;
  }

  /// [ageGap]: oyuncudan kaç yaş büyük (eksi: küçük).
  void _addSchoolPerson(
    Character c, {
    required int ageGap,
    required List<PersonRole> roles,
    required int base,
    String? occupation,
  }) {
    final gender = Gender.values[random.nextInt(Gender.values.length)];
    final names = families.namesFor(gender, NameEra.forAgeGap(ageGap));
    final name = names[random.nextInt(names.length)];
    final surname = families.surnames[random.nextInt(families.surnames.length)];
    final traits = <Trait>{};
    final target = random.nextDouble() < 0.7 ? 2 : 1;
    while (traits.length < target) {
      final t = Trait.values[random.nextInt(Trait.values.length)];
      if (traits.every((other) => Trait.compatible(t, other))) traits.add(t);
    }
    final wealth = _classmateWealth();
    final seed = random.nextInt(1 << 30);
    final (next, _) = _book.add(
      (id) => Person(
        id: id,
        name: name,
        surname: surname,
        gender: gender,
        bornAt: -ageGap,
        city: c.hometown,
        origin: Origin.okul,
        metAt: _now,
        base: base,
        portraitSeed: seed,
        bond: Bond.tanidik,
        roles: roles,
        traits: traits,
        wealth: wealth,
        marital: occupation == null
            ? MaritalStatus.bekar
            : (random.nextDouble() < 0.7
                  ? MaritalStatus.evli
                  : MaritalStatus.bekar),
        occupation: occupation,
        health: _between(80, 98),
        lastContactAt: _now,
      ),
    );
    _book = next;
  }

  WealthLevel _classmateWealth() {
    final roll = random.nextInt(100);
    if (roll < 30) return WealthLevel.dar;
    if (roll < 85) return WealthLevel.orta;
    if (roll < 97) return WealthLevel.rahat;
    return WealthLevel.zengin;
  }

  /// Aktif kişi sınırı aşılırsa en uzun süredir dokunulmayanlar arşive
  /// düşer; önce rolü bitmiş olanlar.
  void _archive() {
    final active = _book.active(_now).toList();
    final candidates = active.where((p) => !coreKin.contains(p.kin)).toList();
    var excess = active.length - maxActive;
    if (excess <= 0) return;
    candidates.sort((a, b) {
      final roleA = a.roles.any((r) => r.active) ? 1 : 0;
      final roleB = b.roles.any((r) => r.active) ? 1 : 0;
      if (roleA != roleB) return roleA - roleB;
      final contact = a.lastContactAt.compareTo(b.lastContactAt);
      if (contact != 0) return contact;
      return a.id.compareTo(b.id);
    });
    for (final p in candidates) {
      if (excess <= 0) break;
      _book = _book.update(p.copyWith(archived: true));
      excess--;
    }
  }

  int _between(int min, int max) => min + random.nextInt(max - min + 1);
}
