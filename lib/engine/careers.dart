import 'dart:math';

import '../models/models.dart';
import 'cities.dart';
import 'life_action.dart';
import 'relationships.dart';

/// Oyundaki meslekler. İçerikten yüklenir; boş da olabilir.
class CareerBook {
  CareerBook(Iterable<Career> careers)
    : _byId = {for (final c in careers) c.id: c} {
    if (_byId.length != careers.length) {
      throw ArgumentError('Tekrar eden meslek kimliği var');
    }
  }

  static final CareerBook empty = CareerBook(const []);

  final Map<String, Career> _byId;

  Iterable<Career> get all => _byId.values;

  Career? byId(String id) => _byId[id];

  Career require(String id) =>
      _byId[id] ?? (throw StateError('Meslek bulunamadı: $id'));

  /// İşin kademe maaşı ve zammı (şehir çarpanı hariç; emekli aylığı için).
  int salaryOf(Job job) =>
      (require(job.careerId).tier(job.tier).salary * (1 + job.raise)).round();
}

/// Bir yılın iş dökümü; arayüz terfiyi ve emekliliği bildirir.
class CareerReport {
  const CareerReport({
    required this.income,
    this.source = MoneySource.maas,
    this.severance = 0,
    this.promoted = false,
    this.retired = false,
    this.fired = false,
  });

  final int income;

  /// Gelirin kaynağı: maaş, emekli aylığı, harçlık, ara işler.
  final MoneySource source;

  /// Kovulunca ödenen kıdem tazminatı.
  final int severance;
  final bool promoted;
  final bool retired;

  /// Performansı dibe vurduğu için kovuldu.
  final bool fired;
}

/// Gelir, meslek ve emeklilik kuralları. Tutarlar bugünün TL'siyle.
abstract final class Careers {
  /// Bu yaşta çalışan herkes emekli olur.
  static const int retireAge = 65;

  /// Emekli aylığı son maaşın bu oranıdır; en az [minPension] (2026: yıllık
  /// yaklaşık 240 bin).
  static const double pensionShare = 0.6;
  static const int minPension = 240000;

  /// Emekli aylığı için en az bu kadar yıl çalışmış olmak gerekir.
  static const int pensionMinYears = 15;

  /// Emekli aylığı olmayan 65 yaş üstüne devletin yıllık aylığı.
  static const int oldAgeAllowance = 60000;

  /// Lisede ailenin verdiği yıllık cep harçlığı (dar aile vermez).
  static const int highSchoolAllowance = 6000;

  /// Üniversitede ailenin yıllık harçlığı (2026). Ebeveynle yakınlık
  /// 50'nin altındaysa yarıya iner; anne ve baba yoksa verilmez.
  static const Map<FamilyBackground, int> studentAllowance = {
    FamilyBackground.varlikli: 150000,
    FamilyBackground.orta: 60000,
    FamilyBackground.dar: 0,
  };
  static const int factoryStudentAllowance = 300000;

  /// Emekli aylığı bağlanınca açılan bayrak. Kartlar bakabilir, değiştiremez.
  static const String retiredFlag = 'emekli';

  /// Bir kart seçeneğinin işe etkisini uygular.
  static Character applyChange(
    Character c,
    CareerChange change,
    CareerBook book,
  ) {
    switch (change) {
      case JoinCareer(:final careerId, :final tier):
        final career = book.require(careerId);
        return leaveJob(c).copyWith(
          job: Job(careerId: careerId, tier: min(tier, career.maxTier)),
        );
      case PromoteCareer(:final steps):
        final job = c.job;
        if (job == null) return c;
        final maxTier = book.require(job.careerId).maxTier;
        final tier = (job.tier + steps).clamp(1, maxTier);
        if (tier == job.tier) return c;
        return c.copyWith(
          job: job.copyWith(tier: tier, yearsInTier: 0),
          counters: tier > job.tier
              ? c.counters.copyWith(promotions: c.counters.promotions + 1)
              : null,
        );
      case QuitCareer():
        return leaveJob(c);
      case RetireCareer():
        return retire(c, book);
    }
  }

  /// Emekli aylığı hakkı var mı: en az [pensionMinYears] yıl çalışmış.
  static bool canRetire(Character c) =>
      c.counters.yearsWorked >= pensionMinYears;

  /// Emekli eder: son işin (bırakılmış olsa da) maaşının %60'ı, en az taban
  /// aylık. Hakkı yoksa yalnızca işi bırakır.
  static Character retire(Character c, CareerBook book) {
    if (c.isRetired) return c;
    if (!canRetire(c)) return leaveJob(c);
    final job = c.careerJob;
    final lastSalary = job == null ? 0 : book.salaryOf(job);
    final pension = max(minPension, (lastSalary * pensionShare).round());
    return leaveJob(c).copyWith(pension: pension);
  }

  /// Performansın altında kalan yılın sonunda kovulur.
  static const int firingPerformance = 20;

  /// Tempoya göre performansın yıllık değişimi.
  static int tempoPerformance(Tempo tempo) => switch (tempo) {
    Tempo.rahat => -8,
    Tempo.normal => 2,
    Tempo.yukle => 10,
  };

  /// Yılın performansı: tempo, bilgi ve biraz şans.
  static int nextPerformance(Character c, Job job, Random random) {
    final knowledge = ((c.stats.knowledge - 50) / 10).round();
    final noise = random.nextInt(11) - 5;
    return (job.performance + tempoPerformance(job.tempo) + knowledge + noise)
        .clamp(0, 100);
  }

  /// Tempo bedeni ve keyfi etkiler: yüklemek sağlığı, rahat çalışmak
  /// keyfi.
  static Character tempoEffect(Character c, Tempo tempo) => switch (tempo) {
    Tempo.yukle => c.copyWith(stats: c.stats.withDelta(StatKind.health, -2)),
    Tempo.rahat => c.copyWith(stats: c.stats.withDelta(StatKind.happiness, 1)),
    Tempo.normal => c,
  };

  /// Yılın maaşı: kademe, zam, şehir ve (oynak meslekte) çarpan.
  static int salaryFor(
    Character c,
    Job job,
    Career career, {
    double factor = 1,
  }) =>
      (career.tier(job.tier).salary *
              (1 + job.raise) *
              factor *
              (career.isPublic ? 1 : Cities.typeOf(c.city).salary))
          .round();

  /// İşten ayrılır (istifa, kovulma, emeklilik): patron ve iş arkadaşı
  /// rolleri biter, kişiler "eski iş arkadaşı" olur.
  static Character leaveJob(Character c) {
    if (c.job == null) return c;
    const work = {
      RoleKind.patron,
      RoleKind.amir,
      RoleKind.usta,
      RoleKind.mudur,
      RoleKind.isArkadasi,
    };
    // İşletmenin müdürü ve çalışanları işten ayrılınca kalır.
    final ownStaff = {
      for (final b in c.businesses) ...[...b.staff, ?b.managerId],
    };
    var book = c.people;
    for (final p in book.all.toList()) {
      if (ownStaff.contains(p.id)) continue;
      if (!p.roles.any((r) => r.active && work.contains(r.kind))) continue;
      book = book.update(
        p.copyWith(
          roles: [
            for (final r in p.roles) work.contains(r.kind) ? r.ended() : r,
          ],
        ),
      );
    }
    return c.copyWith(clearJob: true, people: book);
  }

  /// [baseIncome] gelirinin kaynağı.
  static MoneySource baseIncomeSource(Character c) =>
      c.age >= retireAge ? MoneySource.yasliAyligi : MoneySource.harclik;

  /// Bir yılın geliri, iş ve emeklilik dışındaki durumlarda: lisede cep
  /// harçlığı, üniversitede ailenin harçlığı, 65 yaştan sonra yaşlılık
  /// aylığı. İşsiz yetişkine kendiliğinden gelir yoktur; ara işler bir
  /// aksiyondur.
  static int baseIncome(Character c) {
    if (c.age >= retireAge) return oldAgeAllowance;
    if (c.stage == LifeStage.lise) {
      return c.background == FamilyBackground.dar ? 0 : highSchoolAllowance;
    }
    if (c.hasFlag(ActionCatalog.studentFlag)) return allowanceFor(c);
    return 0;
  }

  /// Üniversite harçlığı: aile durumuna ve anne-babayla yakınlığa göre.
  static int allowanceFor(Character c) {
    final parents = [
      for (final p in c.people.bornBy(c.age))
        if (p.isAlive && (p.kin == Kinship.anne || p.kin == Kinship.baba)) p,
    ];
    if (parents.isEmpty) return 0;
    final base = c.familyProfile == 'fabrikator'
        ? factoryStudentAllowance
        : studentAllowance[c.background]!;
    final closeness =
        parents.fold(0, (s, p) => s + Relationships.closeness(p, c.age)) /
        parents.length;
    return closeness < 50 ? base ~/ 2 : base;
  }
}

/// Yılın işi: maaş (ya da aylık), performans, tempo, kovulma ve yaş
/// gelince emeklilik. Terfi ve zam oyuncunun isteğiyledir ([JobMarket]).
/// Yaşlanmadan (YearTick) sonra, yeni yaş için çalışır.
class CareerTick {
  const CareerTick(this.random, this.book);

  final Random random;
  final CareerBook book;

  (Character, CareerReport) apply(Character c) {
    var retired = false;
    var fired = false;

    if (!c.isRetired && c.age >= Careers.retireAge) {
      c = Careers.retire(c, book);
      retired = c.isRetired;
    }

    var income = 0;
    var source = MoneySource.maas;
    var worked = false;
    var severance = 0;
    if (c.isRetired) {
      income = c.pension;
      source = MoneySource.emekliAyligi;
    } else if (c.job != null && c.hasFlag('askerde')) {
      // Askerdeki yıl iş askıda: maaş, kıdem ve performans işlemez.
    } else if (c.job case final job?) {
      final career = book.require(job.careerId);
      final performance = Careers.nextPerformance(c, job, random);
      if (!career.isPublic &&
          performance < Careers.firingPerformance &&
          job.yearsInTier >= 1) {
        // Performansı dibe vuran yıl ortasında kovulur: yarım yılın maaşı ve
        // kademedeki her yıl için bir aylık kıdem tazminatı.
        final yearly = Careers.salaryFor(c, job, career);
        income = yearly ~/ 2;
        severance = yearly ~/ 12 * job.yearsInTier;
        worked = true;
        c = Careers.leaveJob(c);
        fired = true;
      } else {
        final variance = career.incomeVariance;
        final factor = variance == 0
            ? 1.0
            : 1 +
                  variance * (2 * random.nextDouble() - 1) +
                  (performance - 50) / 200;
        final next = job.copyWith(
          performance: performance,
          yearsInTier: job.yearsInTier + 1,
        );
        income = Careers.salaryFor(c, next, career, factor: factor);
        worked = true;
        c = c.copyWith(job: next);
        c = Careers.tempoEffect(c, next.tempo);
      }
    } else {
      income = Careers.baseIncome(c);
      source = Careers.baseIncomeSource(c);
    }

    // Ömür boyu kazanç yalnızca maaş ve emekli aylığıdır; harçlık sayılmaz.
    final earned = worked || c.isRetired ? income : 0;
    final counters = c.counters;
    c = c.copyWith(
      stats: c.stats.withMoneyDelta(income + severance),
      counters: counters.copyWith(
        yearsWorked: counters.yearsWorked + (worked ? 1 : 0),
        lifetimeIncome: counters.lifetimeIncome + earned,
      ),
    );
    return (
      c,
      CareerReport(
        income: income,
        source: source,
        severance: severance,
        retired: retired,
        fired: fired,
      ),
    );
  }
}
