import 'dart:math';

import '../models/models.dart';
import 'careers.dart';
import 'cities.dart';
import 'education.dart';
import 'person_factory.dart';
import 'relationships.dart';

/// Bir iş ilanı. Her yıl oyuncunun şehrine göre yeniden çıkar; kayda
/// girer.
class JobListing {
  const JobListing({
    required this.careerId,
    required this.tier,
    required this.company,
    required this.ad,
    required this.interview,
  });

  final String careerId;
  final int tier;
  final String company;

  /// İlanın bir cümlelik mizahı (meslek dosyasından).
  final String ad;

  /// Mülakatta sorulacak sorunun sırası (meslek dosyasındaki listede).
  final int interview;

  Map<String, Object> toJson() => {
    'career': careerId,
    'tier': tier,
    'company': company,
    'ad': ad,
    'interview': interview,
  };

  factory JobListing.fromJson(Map<String, dynamic> json) => JobListing(
    careerId: json['career'] as String,
    tier: json['tier'] as int,
    company: json['company'] as String,
    ad: json['ad'] as String,
    interview: json['interview'] as int,
  );

  @override
  bool operator ==(Object other) =>
      other is JobListing &&
      other.careerId == careerId &&
      other.tier == tier &&
      other.company == company &&
      other.ad == ad &&
      other.interview == interview;

  @override
  int get hashCode => Object.hash(careerId, tier, company, ad, interview);
}

/// Bir ilana neden başvurulamadığı.
enum ListingBlocked {
  /// Bölümü, belgesi ya da meslek lisesi yok.
  sart,

  /// Yaşı tutmuyor.
  yas,

  /// Tam zamanlı öğrenci.
  ogrenci,

  /// Zaten bu şirkette çalışıyor.
  ayniSirket,

  /// Bu ilana bu yıl başvurdu.
  basvuruldu,

  /// Bu yılın vakti bitti.
  vakit,

  /// Üst pozisyon: bu meslekte deneyimi yok.
  deneyim,

  /// Emekli.
  emekli,

  /// Askerde.
  askerde,
}

/// Mülakatın sonucu.
enum InterviewResult { alindi, torpilleAlindi, olmadi }

/// Terfi ya da zam neden istenemez.
enum RequestBlocked {
  isYok,

  /// Son kademede.
  sonKademe,

  /// Kademede yeterince durmadı.
  erken,

  /// Diploma ya da belge şartı.
  sart,
  performans,

  /// Terfinin bedeli (dükkân, ortaklık payı) için para yok.
  para,

  /// Bu kademede zam tavanı doldu.
  tavan,

  /// Bu yıl soruldu.
  buYil,

  /// Vakit yok ya da yıl kartları sürüyor.
  vakit,
}

/// Terfi ya da zam isteğinin sonucu.
enum RequestResult { evet, hayir, zamaniDegil }

/// İş piyasası ve iş yeri kuralları (canlı doküman, "Çalışma hayatı").
abstract final class JobMarket {
  /// KPSS'yi geçen (memur ilanları için).
  static const String kpssFlag = 'kpss_gecti';

  /// Yazılım kursunu bitiren (yazılımcı ilanları için).
  static const String codingFlag = 'yazilim_kursu';

  /// Üniversitede staj yapan (kartın açtığı bayrak); mülakatta +8.
  static const String internshipFlag = 'staj_yapti';

  /// Şehir türüne göre yıllık ilan sayısı.
  static int listingCount(CityType type) => switch (type) {
    CityType.buyuk => 6,
    CityType.orta => 4,
    CityType.kucuk => 3,
  };

  /// Üst pozisyon ilanı için aynı meslekte en az bu kadar yıl.
  static const int seniorYears = 3;

  /// Bu yılın ilanları: oyuncunun şehrinde, 18 yaşından sonra.
  static List<JobListing> listingsFor(
    Character c,
    CareerBook book,
    Random random,
  ) {
    // Lise bitmeden (YKS yılı dahil) tam zamanlı ilan yok.
    if (c.age <= EducationRules.yksAge || c.isRetired) return const [];
    final type = Cities.typeOf(c.city);
    final pool = [
      for (final career in book.all)
        if (career.listing case final l? when l.cityTypes.contains(type.name))
          (career, l),
    ];
    if (pool.isEmpty) return const [];
    final total = pool.fold(0, (s, p) => s + p.$2.weight);
    final listings = <JobListing>[];
    final used = <String>{};
    for (var i = 0; i < listingCount(type) && used.length < 40; i++) {
      var roll = random.nextInt(total);
      var pick = pool.last;
      for (final p in pool) {
        roll -= p.$2.weight;
        if (roll < 0) {
          pick = p;
          break;
        }
      }
      final (career, info) = pick;
      final company = info.companies[random.nextInt(info.companies.length)];
      final key = '${career.id}|$company';
      if (!used.add(key)) continue;
      final senior = career.maxTier > 1 && random.nextDouble() < 0.25;
      listings.add(
        JobListing(
          careerId: career.id,
          tier: senior ? 2 : 1,
          company: company,
          ad: info.ads[random.nextInt(info.ads.length)],
          interview: career.interviews.isEmpty
              ? 0
              : random.nextInt(career.interviews.length),
        ),
      );
    }
    return listings;
  }

  /// Mesleğe giriş yolu tutuyor mu (bölüm, belge, meslek lisesi).
  static bool meetsEntry(Character c, Career career) {
    final e = career.entry;
    if (!e.requires.isMetBy(c)) return false;
    if (!e.hasPath) return true;
    final education = c.education;
    final diploma =
        education.isGraduate && e.departments.contains(education.department);
    final flag = e.flags.any(c.hasFlag);
    final vocational =
        e.vocational &&
        (education.highSchool == HighSchool.meslek || education.apprentice);
    return diploma || flag || vocational;
  }

  /// İlana başvurulabilir mi; değilse sebebi.
  static ListingBlocked? blocked(
    Character c,
    JobListing listing,
    CareerBook book, {
    required int timeLeft,
    required Set<String> applied,
  }) {
    final career = book.byId(listing.careerId);
    if (career == null) return ListingBlocked.sart;
    if (c.isRetired) return ListingBlocked.emekli;
    if (c.hasFlag('askerde')) return ListingBlocked.askerde;
    if (c.age < career.entry.minAge ||
        (career.entry.maxAge != null && c.age > career.entry.maxAge!)) {
      return ListingBlocked.yas;
    }
    if (c.education.isStudent && !c.education.openEducation) {
      return ListingBlocked.ogrenci;
    }
    if (!meetsEntry(c, career)) return ListingBlocked.sart;
    if (listing.tier > 1 && !hasExperience(c, career.id)) {
      return ListingBlocked.deneyim;
    }
    if (c.job?.company == listing.company) return ListingBlocked.ayniSirket;
    if (applied.contains(key(listing))) return ListingBlocked.basvuruldu;
    if (timeLeft < 1) return ListingBlocked.vakit;
    return null;
  }

  /// Aynı meslekte en az [seniorYears] yıl çalıştı mı (şu anki ya da son iş).
  static bool hasExperience(Character c, String careerId) {
    final job = c.careerJob;
    if (job == null || job.careerId != careerId) return false;
    return job.tier >= 2 || job.yearsInTier >= seniorYears;
  }

  static String key(JobListing l) => '${l.careerId}|${l.company}';

  /// Bu ilan için torpil yapabilecek tanıdıklar: o meslekte çalışan, sana
  /// yakın ve kırgın olmayan.
  static List<Person> references(
    Character c,
    JobListing listing,
    CareerBook book,
  ) {
    final career = book.byId(listing.careerId);
    // Kamuda torpil yok: girişi KPSS belirler.
    if (career == null || career.isPublic || career.occupations.isEmpty) {
      return const [];
    }
    return [
      for (final p in c.people.active(c.age))
        if (career.occupations.contains(p.occupation) &&
            Relationships.closeness(p, c.age) >= 40 &&
            Relationships.hostility(p, c.age) < 50)
          p,
    ];
  }

  /// Mülakat: cevabın baktığı değer ve zar; üst pozisyon daha zor. Torpil
  /// eşiği düşürür (yakın biri, 60+, daha çok); kimse doğrudan alınmaz.
  /// Torpille geçen "torpilli" sayılır.
  static InterviewResult interview(
    Character c,
    JobListing listing,
    CareerBook book,
    InterviewAnswer answer,
    Random random, {
    Person? reference,
  }) {
    final career = book.require(listing.careerId);
    final referenceBonus = reference == null
        ? 0
        : Relationships.closeness(reference, c.age) >= 60
        ? 20
        : 10;
    final threshold =
        career.entry.interviewThreshold +
        (listing.tier - 1) * 10 -
        referenceBonus;
    final kind = answer.stat.statKind;
    final value = kind == null ? c.luck : c.stats[kind];
    final luckBonus = kind == null ? 0 : (c.luck - 50) / 10;
    final reputation = (c.stats.reputation - 50) / 10;
    final internship = c.hasFlag(internshipFlag) ? 8 : 0;
    final dice = random.nextInt(101);
    if ((value + dice) / 2 + luckBonus + reputation + internship < threshold) {
      return InterviewResult.olmadi;
    }
    return reference == null
        ? InterviewResult.alindi
        : InterviewResult.torpilleAlindi;
  }

  /// İşe girer: eski işten ayrılır, patron ve üç iş arkadaşı kişi olarak
  /// gelir. Torpille girenin itibarı biraz düşer ("torpilli").
  static Character hire(
    Character c,
    JobListing listing,
    CareerBook book,
    PersonFactory f, {
    Person? reference,
  }) {
    var next = Careers.leaveJob(c);
    final job = Job(
      careerId: listing.careerId,
      tier: listing.tier,
      company: listing.company,
    );
    var people = next.people;
    // Patron çalışma çağında (en fazla 62); dünya küçük: tanıdık çıkabilir.
    (people, _) = f.addOrReuse(
      people,
      now: c.age,
      minAge: min(max(30, c.age + 3), 55),
      maxAge: min(max(45, c.age + 20), 62),
      city: c.city,
      origin: Origin.isYeri,
      base: 15,
      roles: [
        PersonRole(RoleKind.values.byName(book.require(listing.careerId).boss)),
      ],
      wealth: WealthLevel.rahat,
      occupation: _occupationFor(book, listing.careerId),
    );
    for (var i = 0; i < 3; i++) {
      (people, _) = f.add(
        people,
        now: c.age,
        age: max(19, c.age + f.between(-5, 12)),
        city: c.city,
        origin: Origin.isYeri,
        base: i == 0 ? 20 : 12,
        roles: const [PersonRole(RoleKind.isArkadasi)],
        occupation: _occupationFor(book, listing.careerId),
      );
    }
    if (reference != null) {
      people = people.update(
        Relationships.addMemory(
          reference,
          Memory(
            kind: 'ise_aracilik',
            label: 'İşe girmesine aracı oldum',
            age: c.age,
            tone: MemoryTone.olumlu,
            severity: 2,
          ),
          now: c.age,
        ),
      );
    }
    next = next.copyWith(job: job, people: people);
    if (reference != null) {
      next = next.copyWith(
        stats: next.stats.withDelta(StatKind.reputation, -3),
      );
    }
    return next;
  }

  /// Kişiler `occupation` alanında meslek dosyasındaki ilk eşleşen
  /// kişisel mesleği taşır (yoksa meslek kimliği).
  static String? _occupationFor(CareerBook book, String careerId) {
    final occupations = book.byId(careerId)?.occupations ?? const {};
    return occupations.isEmpty ? null : occupations.first;
  }

  /// Terfi ya da zam neden istenemez (arayüz gösterir); null ise
  /// istenebilir.
  static RequestBlocked? promotionBlocked(Character c, CareerBook book) {
    final job = c.job;
    if (job == null) return RequestBlocked.isYok;
    final promotion = book.require(job.careerId).tier(job.tier).promotion;
    if (promotion == null) return RequestBlocked.sonKademe;
    if (job.yearsInTier < promotion.minYears) return RequestBlocked.erken;
    if (!promotion.requires.isMetBy(c)) return RequestBlocked.sart;
    if (job.performance < promotion.minPerformance) {
      return RequestBlocked.performans;
    }
    if (c.stats.money < promotion.cost) return RequestBlocked.para;
    return null;
  }

  /// Terfiye kalan yıl (kademede beklenecek).
  static int yearsToPromotion(Character c, CareerBook book) {
    final job = c.job!;
    final promotion = book.require(job.careerId).tier(job.tier).promotion;
    return promotion == null ? 0 : max(0, promotion.minYears - job.yearsInTier);
  }

  static RequestBlocked? raiseBlocked(Character c) {
    final job = c.job;
    if (job == null) return RequestBlocked.isYok;
    if (job.raise >= maxRaise) return RequestBlocked.tavan;
    if (job.performance < raiseMinPerformance) return RequestBlocked.performans;
    return null;
  }

  /// Terfi şansı en fazla bu kadar: performans ne olursa olsun garanti yok.
  static const double maxPromotionChance = 0.85;

  /// Terfi iste: kademede yeterince durduysa, şartlar ve performans
  /// tutuyorsa zar. Yılda bir kez.
  static (Character, RequestResult) requestPromotion(
    Character c,
    CareerBook book,
    Random random,
  ) {
    final job = c.job!;
    final career = book.require(job.careerId);
    final promotion = career.tier(job.tier).promotion;
    final asked = c.copyWith(job: job.copyWith(promotionAskedAt: c.age));
    if (promotion == null || promotionBlocked(c, book) != null) {
      return (asked, RequestResult.zamaniDegil);
    }
    final chance = min(
      maxPromotionChance,
      promotion.chance +
          (job.performance - promotion.minPerformance) / 100 +
          (c.luck - 50) / 500,
    );
    if (random.nextDouble() >= chance) {
      return (
        asked.copyWith(
          job: asked.job!.copyWith(performance: max(0, job.performance - 3)),
        ),
        RequestResult.hayir,
      );
    }
    return (
      asked.copyWith(
        job: asked.job!.copyWith(tier: job.tier + 1, yearsInTier: 0, raise: 0),
        stats: c.stats.withMoneyDelta(-promotion.cost),
        counters: c.counters.copyWith(promotions: c.counters.promotions + 1),
      ),
      RequestResult.evet,
    );
  }

  /// Zam başına oran ve kademede en fazla toplam zam.
  static const double raiseStep = 0.1;
  static const double maxRaise = 0.3;
  static const int raiseMinPerformance = 60;

  /// Zam iste: performans 60+ ve kademede %30'u aşmadıysa zar. Yılda bir.
  static (Character, RequestResult) requestRaise(Character c, Random random) {
    final job = c.job!;
    final asked = c.copyWith(job: job.copyWith(raiseAskedAt: c.age));
    if (raiseBlocked(c) != null) return (asked, RequestResult.zamaniDegil);
    final chance = 0.4 + (job.performance - raiseMinPerformance) / 100;
    if (random.nextDouble() >= chance) {
      return (
        asked.copyWith(
          job: asked.job!.copyWith(performance: max(0, job.performance - 2)),
        ),
        RequestResult.hayir,
      );
    }
    return (
      asked.copyWith(job: asked.job!.copyWith(raise: job.raise + raiseStep)),
      RequestResult.evet,
    );
  }

  /// Erken emeklilik: 25 yıl çalışmış ve 55 yaşında.
  static bool canRetireEarly(Character c) =>
      c.job != null && c.age >= 55 && c.counters.yearsWorked >= 25;

  /// KPSS: üniversite mezunu (açıköğretim dahil), 40 yaşına kadar.
  static bool canSitKpss(Character c) =>
      c.education.isGraduate && c.age <= 40 && !c.hasFlag(kpssFlag);

  /// KPSS'de başarı eşiği (bilgi zarı).
  static const int kpssThreshold = 55;

  static bool sitKpss(Character c, Random random) {
    final dice = random.nextInt(101);
    return (c.stats.knowledge + dice) / 2 + (c.luck - 50) / 10 >= kpssThreshold;
  }

  /// Yazılım kursu: 18 yaştan sonra, bir kez; yazılımcı ilanlarını açar.
  static bool canTakeCodingCourse(Character c) =>
      c.age >= 18 && !c.hasFlag(codingFlag);

  static const int codingCourseCost = 50000;

  /// Yüklenen çalışanın vakti 1 azalır.
  static int timePenalty(Character c) => c.job?.tempo == Tempo.yukle ? 1 : 0;

  /// Bayrak açılır (KPSS, kurs).
  static Character withFlag(Character c, String flag) =>
      c.copyWith(flags: {...c.flags, flag});
}
