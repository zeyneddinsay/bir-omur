import 'dart:math';

import '../models/models.dart';
import 'life_action.dart';

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

  /// İşin bu yılki taban maaşı.
  int salaryOf(Job job) => require(job.careerId).tier(job.tier).salary;
}

/// Bir yılın iş dökümü; arayüz terfiyi ve emekliliği bildirir.
class CareerReport {
  const CareerReport({
    required this.income,
    this.promoted = false,
    this.retired = false,
  });

  final int income;
  final bool promoted;
  final bool retired;
}

/// Gelir, meslek ve emeklilik kuralları. Tutarlar bugünün TL'siyle.
abstract final class Careers {
  /// Bu yaşta çalışan herkes emekli olur.
  static const int retireAge = 65;

  /// Emekli aylığı son maaşın bu oranıdır; en az [minPension].
  static const double pensionShare = 0.6;
  static const int minPension = 140000;

  /// İşsiz yetişkinin ara işlerden geliri.
  static const int unemployedIncome = 100000;

  /// Üniversite öğrencisinin burs ve harçlığı.
  static const int studentIncome = 30000;
  static const int highSchoolIncome = 2000;

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
        return c.copyWith(
          job: Job(careerId: careerId, tier: min(tier, career.maxTier)),
        );
      case PromoteCareer(:final steps):
        final job = c.job;
        if (job == null) return c;
        final maxTier = book.require(job.careerId).maxTier;
        final tier = (job.tier + steps).clamp(1, maxTier);
        if (tier == job.tier) return c;
        return c.copyWith(job: job.copyWith(tier: tier, yearsInTier: 0));
      case QuitCareer():
        return c.copyWith(clearJob: true);
      case RetireCareer():
        return retire(c, book);
    }
  }

  /// Emekli eder: işi varsa son maaşın %60'ı, yoksa en az aylık.
  static Character retire(Character c, CareerBook book) {
    if (c.isRetired) return c;
    final job = c.job;
    final lastSalary = job == null ? 0 : book.salaryOf(job);
    final pension = max(minPension, (lastSalary * pensionShare).round());
    return c.copyWith(clearJob: true, pension: pension);
  }

  /// Bir yılın geliri, iş ve emeklilik dışındaki durumlarda.
  static int baseIncome(Character c) {
    final stage = c.stage;
    if (stage.index < LifeStage.lise.index) return 0;
    if (stage == LifeStage.lise) return highSchoolIncome;
    if (c.hasFlag(ActionCatalog.studentFlag)) return studentIncome;
    return unemployedIncome;
  }
}

/// Yılın işi: maaş (ya da aylık), terfi denemesi ve yaş gelince emeklilik.
/// Yaşlanmadan (YearTick) sonra, yeni yaş için çalışır.
class CareerTick {
  const CareerTick(this.random, this.book);

  final Random random;
  final CareerBook book;

  (Character, CareerReport) apply(Character c) {
    var promoted = false;
    var retired = false;

    if (!c.isRetired && c.age >= Careers.retireAge) {
      c = Careers.retire(c, book);
      retired = true;
    }

    final int income;
    if (c.isRetired) {
      income = c.pension;
    } else if (c.job case final job?) {
      final career = book.require(job.careerId);
      final variance = career.incomeVariance;
      final factor = variance == 0
          ? 1.0
          : 1 + variance * (2 * random.nextDouble() - 1);
      income = (career.tier(job.tier).salary * factor).round();
      (c, promoted) = _tryPromotion(c, career, job);
    } else {
      income = Careers.baseIncome(c);
    }

    c = c.copyWith(stats: c.stats.withMoneyDelta(income));
    return (
      c,
      CareerReport(income: income, promoted: promoted, retired: retired),
    );
  }

  (Character, bool) _tryPromotion(Character c, Career career, Job job) {
    final years = job.yearsInTier + 1;
    final promotion = career.tier(job.tier).promotion;
    if (promotion != null &&
        years >= promotion.minYears &&
        promotion.requires.isMetBy(c) &&
        random.nextDouble() < promotion.chance) {
      return (
        c.copyWith(
          job: job.copyWith(tier: job.tier + 1, yearsInTier: 0),
          stats: c.stats.withMoneyDelta(-promotion.cost),
        ),
        true,
      );
    }
    return (c.copyWith(job: job.copyWith(yearsInTier: years)), false);
  }
}

/// "İş ara" aksiyonunun sonucu; arayüz bildirir. Kaydedilmez.
class JobSearchResult {
  const JobSearchResult(this.careerId);

  /// Girilen meslek; bu yıl iş çıkmadıysa null.
  final String? careerId;

  bool get found => careerId != null;
}

/// İş arama: başvurusu açık meslekler en yüksek giriş maaşından başlayarak
/// denenir; ilk tutan zarda o mesleğin 1. kademesine girilir.
(Character, JobSearchResult) searchJob(
  Character c,
  CareerBook book,
  bool Function(Roll roll) rollSucceeds,
) {
  final open = [
    for (final career in book.all)
      if (career.jobSearch case final js? when js.isOpenTo(c)) (career, js),
  ]..sort((a, b) => b.$1.tier(1).salary.compareTo(a.$1.tier(1).salary));
  for (final (career, js) in open) {
    if (rollSucceeds(js.roll)) {
      return (
        Careers.applyChange(c, JoinCareer(career.id), book),
        JobSearchResult(career.id),
      );
    }
  }
  return (c, const JobSearchResult(null));
}
