import '../models/models.dart';

/// Bir işletme türü (canlı doküman, "Kendi işin"; 2026 rakamları). Adı
/// arayüzde `business_<id>` ile ARB'den gelir.
///
/// Kâr = ciro × çarpanlar × şube − (sabit gider + çalışan maaşları) × şube.
/// Çarpanlar: itibar (0,7–1,3), ekonomi (0,85 / 1 / 1,1), yönetim
/// (başında 1,1, müdürde 0,95; emek işinde müdür 0,6), fiyat (0,9 / 1 /
/// 1,1), rakip (her biri −0,1) ve yılın şansı ([volatility]).
class BusinessType {
  const BusinessType({
    required this.id,
    required this.setupCost,
    required this.fixedCost,
    required this.revenue,
    required this.volatility,
    this.staffPerBranch = 0,
    this.staffWage = 340000,
    this.minAge = 18,
    this.laborBound = false,
    this.maxBranches = 3,
    this.upgradeTo,
  });

  final String id;

  /// Kuruluş bedeli (tek şube).
  final int setupCost;

  /// Şube başına yıllık sabit gider (dükkân kirası dahil).
  final int fixedCost;

  /// Şube başına, bütün çarpanlar 1 iken yıllık ciro.
  final int revenue;

  /// Yılın şansının oynama payı (cironun oranı).
  final double volatility;

  /// Şube başına çalışan sayısı ve yıllık maaşı.
  final int staffPerBranch;
  final int staffWage;
  final int minAge;

  /// Emek işi (simit, berber): başında durulmazsa ciro çok düşer.
  final bool laborBound;
  final int maxBranches;

  /// Büyütünce dönüştüğü tür (tek kişilik yazılım → ekipli yazılım).
  final String? upgradeTo;

  int get wages => staffPerBranch * staffWage;
}

abstract final class BusinessTypes {
  static const List<BusinessType> all = [
    BusinessType(
      id: 'simit',
      setupCost: 130000,
      fixedCost: 70000,
      revenue: 220000,
      volatility: 0.15,
      minAge: 16,
      laborBound: true,
      maxBranches: 1,
    ),
    BusinessType(
      id: 'berber',
      setupCost: 1000000,
      fixedCost: 400000,
      revenue: 1250000,
      volatility: 0.2,
      staffPerBranch: 1,
      laborBound: true,
    ),
    BusinessType(
      id: 'oto_yikama',
      setupCost: 1500000,
      fixedCost: 500000,
      revenue: 1400000,
      volatility: 0.45,
      staffPerBranch: 1,
    ),
    BusinessType(
      id: 'yazilim',
      setupCost: 700000,
      fixedCost: 300000,
      revenue: 1100000,
      volatility: 0.9,
      maxBranches: 1,
      upgradeTo: 'yazilim_ekip',
    ),
    BusinessType(
      id: 'yazilim_ekip',
      setupCost: 5000000,
      fixedCost: 1000000,
      revenue: 5500000,
      volatility: 0.7,
      staffPerBranch: 4,
      staffWage: 750000,
      maxBranches: 1,
    ),
  ];

  static BusinessType? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static BusinessType require(String id) =>
      byId(id) ?? (throw StateError('İşletme türü yok: $id'));

  /// Doğrudan açılabilen türler (ekipli yazılım yalnızca büyüterek).
  static List<BusinessType> get openable => [
    for (final t in all)
      if (t.id != 'yazilim_ekip') t,
  ];

  /// Bu türü açmak için ön şart: yazılım için yazılımcı olarak çalışmış ya
  /// da bilgisayar mezunu olmak.
  static bool qualifies(Character c, BusinessType t) {
    if (c.age < t.minAge) return false;
    if (t.id == 'yazilim') {
      final job = c.careerJob;
      return (job != null && job.careerId == 'yazilimci') ||
          (c.education.isGraduate && c.education.department == 'bilgisayar');
    }
    return true;
  }
}
