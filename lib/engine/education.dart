import 'dart:math';

import '../models/models.dart';
import 'cities.dart';
import 'person_factory.dart';
import 'relationships.dart';

/// Bir üniversite bölümü. Adı arayüzde `dept_<id>` ile ARB'den gelir.
class Department {
  const Department({
    required this.id,
    required this.baseScore,
    required this.careers,
    this.years = 4,
    this.open = false,
  });

  final String id;

  /// Orta şehirdeki taban puan; büyükşehirde yüksek, küçük şehirde düşük.
  final int baseScore;

  /// Diplomanın açtığı meslekler.
  final Set<String> careers;
  final int years;

  /// Açıköğretim: her yerden, taban puanı düşük, taşınmadan okunur.
  final bool open;

  int scoreIn(String city) =>
      baseScore +
      switch (Cities.typeOf(city)) {
        CityType.buyuk => 25,
        CityType.orta => 0,
        CityType.kucuk => -20,
      };
}

/// YKS sonrasında seçilebilecek yollar.
enum TercihKind {
  /// Bir bölüme yerleşmek (bölüm ve şehir seçilir).
  bolum,

  /// Bir yıl daha hazırlanıp seneye yeniden girmek.
  mezunaKal,

  /// Okumadan çalışmaya başlamak.
  calis,

  /// Bir ustanın yanına çırak girmek.
  cirak,
}

/// Okul öncesinden mezuniyete eğitim kuralları (canlı doküman, "Eğitim
/// yolu").
abstract final class EducationRules {
  /// LGS'de iyi puan alan (kartın açtığı bayrak) Anadolu ya da fen lisesine.
  static const String goodSchoolFlag = 'iyi_lise';

  /// Lise seçiminde meslek lisesini seçen (kartın açtığı bayrak).
  static const String vocationalFlag = 'meslek_lisesi';

  /// YKS sabahı sakin kalıp iyi geçiren (kartın açtığı bayrak); puan artar.
  static const String goodExamFlag = 'yks_iyi_gecti';

  /// YKS sonucu açıklandı, tercih bekliyor; yaşlanmadan önce seçilmeli.
  static const String pendingFlag = 'tercih_bekliyor';

  /// Mezuna kalmış; seneye YKS'ye yeniden girer.
  static const String retakeFlag = 'mezuna_kaldi';

  /// Motorun eğitimden türettiği bayraklar.
  static const Set<String> derivedFlags = {
    'universite_ogrencisi',
    'universite_mezunu',
    pendingFlag,
    retakeFlag,
  };

  static const int highSchoolAge = 15;
  static const int yksAge = 18;

  /// Burs: dar aileye KYK, yüksek puana başarı bursu (yıllık, 2026).
  static const int needScholarship = 42000;
  static const int meritScholarship = 100000;
  static const int meritScore = 420;

  /// Alttan ders yüzünden en fazla bu kadar yıl uzar.
  static const int maxExtraYears = 2;

  static const List<Department> departments = [
    Department(
      id: 'bilgisayar',
      baseScore: 390,
      careers: {'yazilimci', 'plaza'},
    ),
    Department(id: 'iktisat', baseScore: 330, careers: {'plaza', 'memur'}),
    Department(id: 'hemsirelik', baseScore: 320, careers: {'hemsire'}),
    Department(id: 'isletme', baseScore: 300, careers: {'plaza', 'memur'}),
    Department(id: 'kamu_yonetimi', baseScore: 280, careers: {'memur'}),
    Department(id: 'tarih', baseScore: 250, careers: {'memur'}),
    Department(
      id: 'acikogretim',
      baseScore: 150,
      careers: {'memur', 'plaza'},
      open: true,
    ),
  ];

  static Department? department(String? id) {
    for (final d in departments) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// 15 yaşında lise türü: LGS'de iyi puan → Anadolu (bilgisi yüksekse fen);
  /// meslek lisesini seçen → meslek; diğerleri mahalledeki lise.
  static Character assignHighSchool(Character c) {
    if (c.age != highSchoolAge || c.education.highSchool != null) return c;
    final HighSchool school;
    if (c.hasFlag(goodSchoolFlag)) {
      school = c.stats.knowledge >= 45 ? HighSchool.fen : HighSchool.anadolu;
    } else if (c.hasFlag(vocationalFlag)) {
      school = HighSchool.meslek;
    } else {
      school = HighSchool.duz;
    }
    return c.copyWith(education: c.education.copyWith(highSchool: school));
  }

  /// YKS puanı (100–500): bilgi, lise, sınav sabahı ve şans.
  static int yksScore(Character c, Random random) {
    final school = switch (c.education.highSchool) {
      HighSchool.fen => 40,
      HighSchool.anadolu => 20,
      HighSchool.meslek => -20,
      _ => 0,
    };
    final exam = c.hasFlag(goodExamFlag) ? 15 : 0;
    // Mezuna kalan bir yıl daha hazırlanmıştır.
    final retake = c.education.yksAttempts > 0 ? 15 : 0;
    final luck = (c.luck - 50) ~/ 5;
    final noise = random.nextInt(61) - 30;
    return (100 + c.stats.knowledge * 3 + school + exam + retake + luck + noise)
        .clamp(100, 500);
  }

  /// YKS yılı mı: 18 yaşında (ya da mezuna kalmışsa ertesi yıl), okumuyor ve
  /// henüz tercih yapmamış.
  static bool takesYksNow(Character c) {
    final e = c.education;
    if (e.isStudent || e.isGraduate || e.apprentice) return false;
    if (c.age == yksAge && e.yksAttempts == 0) return true;
    return c.hasFlag(retakeFlag) && c.age > yksAge;
  }

  /// Kartlar bittikten sonra çağrılır: YKS yılıysa puanı hesaplar, tercih
  /// bekler.
  static Character sitYks(Character c, Random random) {
    if (!takesYksNow(c) || c.hasFlag(pendingFlag)) return c;
    final score = yksScore(c, random);
    return syncFlags(
      c.copyWith(
        education: c.education.copyWith(
          yksScore: score,
          yksAttempts: c.education.yksAttempts + 1,
        ),
        flags: {...c.flags, pendingFlag}
          ..remove(retakeFlag)
          ..remove(goodExamFlag),
      ),
    );
  }

  /// Puanın yettiği bölüm ve şehirler; açıköğretim her zaman açık
  /// (memlekette okunur).
  static List<(Department, String)> placements(Character c) {
    final score = c.education.yksScore;
    if (score == null) return const [];
    return [
      for (final d in departments)
        if (d.open) ...[
          if (score >= d.baseScore) (d, c.city),
        ] else
          for (final city in Cities.all)
            if (score >= d.scoreIn(city)) (d, city),
    ];
  }

  /// Bir bölüme yerleşir. Başka şehirde okuyacaksa yurda taşınır; sınıf
  /// arkadaşları (ve yurtta oda arkadaşı) çevreye girer.
  static Character enroll(
    Character c,
    Department d,
    String city,
    PersonFactory f,
  ) {
    final score = c.education.yksScore ?? 0;
    final scholarship = score >= meritScore
        ? meritScholarship
        : (c.background == FamilyBackground.dar ? needScholarship : 0);
    var next = c.copyWith(
      education: c.education.copyWith(
        department: d.id,
        uniCity: d.open ? c.city : city,
        uniStartAge: c.age,
        uniYears: d.years,
        scholarship: scholarship,
        openEducation: d.open,
      ),
      flags: {...c.flags}..remove(pendingFlag),
    );
    if (!d.open && city != c.city) {
      next = next.copyWith(city: city, home: HomeKind.yurt);
    }
    if (!d.open) next = _addClassmates(next, f);
    return syncFlags(next);
  }

  /// Yerleşmeden devam: mezuna kalmak, çalışmak ya da çıraklık.
  static Character decline(Character c, TercihKind kind) {
    final flags = {...c.flags}..remove(pendingFlag);
    if (kind == TercihKind.mezunaKal) flags.add(retakeFlag);
    return syncFlags(
      c.copyWith(
        flags: flags,
        education: kind == TercihKind.cirak
            ? c.education.copyWith(apprentice: true)
            : c.education,
      ),
    );
  }

  /// Üniversitenin yılı (yaşlanınca): dersler geçilir ya da biri alttan
  /// kalır; süre dolunca mezun olunur. Döndürdüğü not günlüğe yazılır.
  static (Character, EducationNote?) yearOfStudy(Character c, Random random) {
    final e = c.education;
    if (!e.isStudent) return (c, null);
    final graduation = e.expectedGraduation!;
    if (c.age >= graduation) return (graduate(c), EducationNote.mezunOldu);
    if (c.age == e.uniStartAge) return (c, null);
    final passChance = 0.55 + c.stats.knowledge / 200;
    if (e.extraYears < maxExtraYears && random.nextDouble() > passChance) {
      return (
        c.copyWith(education: e.copyWith(extraYears: e.extraYears + 1)),
        EducationNote.dersKaldi,
      );
    }
    return (c, null);
  }

  /// Mezun eder. Yurtta kalan, anne ya da babası varsa onların yanına
  /// döner; yoksa okuduğu şehirde kiraya çıkar.
  static Character graduate(Character c) {
    var next = endSchoolRoles(
      c.copyWith(education: c.education.copyWith(graduatedAt: c.age)),
      origin: Origin.universite,
    );
    if (next.home == HomeKind.yurt) {
      final parent = next.people
          .bornBy(next.age)
          .where(
            (p) =>
                p.isAlive && (p.kin == Kinship.anne || p.kin == Kinship.baba),
          )
          .firstOrNull;
      next = parent == null
          ? next.copyWith(home: HomeKind.kira)
          : next.copyWith(city: parent.city, home: HomeKind.aile);
    }
    return syncFlags(next);
  }

  /// Okul bitince (19 yaşında lise, mezuniyette üniversite) sınıf, sıra
  /// arkadaşı, öğretmen ve oda arkadaşı rolleri biter; kişiler "eski" olur.
  static Character endSchoolRoles(Character c, {required Origin origin}) {
    const school = {
      RoleKind.sinifArkadasi,
      RoleKind.siraArkadasi,
      RoleKind.ogretmen,
      RoleKind.odaArkadasi,
    };
    var book = c.people;
    for (final p in book.all.toList()) {
      if (p.origin != origin) continue;
      if (!p.roles.any((r) => r.active && school.contains(r.kind))) continue;
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles) school.contains(r.kind) ? r.ended() : r,
          ],
        ),
      );
    }
    return identical(book, c.people) ? c : c.copyWith(people: book);
  }

  /// Eğitimden türeyen bayrakları günceller.
  static Character syncFlags(Character c) {
    final e = c.education;
    final flags = {...c.flags};
    void set(String flag, bool on) => on ? flags.add(flag) : flags.remove(flag);
    set('universite_ogrencisi', e.isStudent);
    set('universite_mezunu', e.isGraduate && !e.openEducation);
    if (flags.length == c.flags.length && flags.containsAll(c.flags)) return c;
    return c.copyWith(flags: flags);
  }

  /// Bu yılın burs ödemesi (öğrenciyken).
  static int scholarshipFor(Character c) =>
      c.education.isStudent ? c.education.scholarship : 0;

  static Character _addClassmates(Character c, PersonFactory f) {
    var book = c.people;
    final city = c.education.uniCity ?? c.city;
    for (var i = 0; i < 5; i++) {
      (book, _) = f.add(
        book,
        now: c.age,
        age: c.age + f.between(-1, 2),
        city: city,
        origin: Origin.universite,
        base: i == 0 ? 25 : 12,
        roles: const [PersonRole(RoleKind.sinifArkadasi)],
        marital: MaritalStatus.bekar,
      );
    }
    if (c.home == HomeKind.yurt) {
      (book, _) = f.add(
        book,
        now: c.age,
        age: c.age + f.between(0, 1),
        city: city,
        origin: Origin.universite,
        base: 20,
        gender: c.gender,
        roles: const [PersonRole(RoleKind.odaArkadasi)],
        marital: MaritalStatus.bekar,
      );
    }
    // Liseden kalan sınıf ve sıra arkadaşlığı rolleri biter.
    return endSchoolRoles(c.copyWith(people: book), origin: Origin.okul);
  }

  /// Anne ve babayla ortalama yakınlık (harçlık için).
  static int parentCloseness(Character c) {
    final parents = [
      for (final p in c.people.bornBy(c.age))
        if (p.isAlive && (p.kin == Kinship.anne || p.kin == Kinship.baba)) p,
    ];
    if (parents.isEmpty) return 0;
    return parents.fold(0, (s, p) => s + Relationships.closeness(p, c.age)) ~/
        parents.length;
  }
}

/// Eğitim yılının günlüğe düşen notu.
enum EducationNote { dersKaldi, mezunOldu }
