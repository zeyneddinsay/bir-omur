import '../models/models.dart';
import 'business.dart';
import 'economy.dart';
import 'housing.dart';
import 'jobs.dart';
import 'romance.dart';

/// Bir aksiyonun neden yapılamadığı; arayüz sebebi gösterir.
enum ActionBlocked {
  /// Bu yılın vakti yetmiyor.
  vakit,
  para,

  /// Bu yıl zaten yapıldı.
  buYil,

  /// Bu yaşta ve durumda başvurulabilecek bir iş yok.
  isYok,

  /// Peşin alınamıyor ve taksit düzenli gelirin yarısını aşıyor.
  kredi,

  /// Gelir kira ve yaşam giderini karşılamıyor.
  gelir,
}

/// Aksiyon menüsünün kategorileri.
enum ActionCategory { okulIs, para, saglik, eglence }

/// Etkisi sabit bir [Effect] ile yazılamayan aksiyonlar: ev, araba ve
/// kiralık hayat kararları. Motor [Housing] ile uygular.
enum ActionSpecial {
  evdenCik,
  evArkadasi,
  aileyeDon,
  evAl,
  evSat,
  arabaAl,
  arabaSat,

  /// KPSS'ye girer: geçerse memur ilanları açılır.
  kpss,

  /// Yazılım kursu: yazılımcı ilanlarını açar.
  yazilimKursu,

  /// Biriyle tanış: ilgi duyulan cinsiyetten, yaşı uygun, bekâr biri
  /// çevreye girer.
  tanis,
}

/// Aksiyon menüsündeki bir seçenek. Adı ve açıklaması arayüzde [id] ile
/// ARB dosyasından gelir.
class LifeAction {
  const LifeAction({
    required this.id,
    required this.category,
    this.effect = Effect.none,
    this.cost = 0,
    this.goldGrams = 0,
    this.requiresJob = false,
    this.studentsOnly = false,
    this.jobless = false,
    this.idleOnly = false,
    this.special,
    this.minAge = 0,
    this.maxAge,
    this.timeCost = 1,
  });

  final String id;
  final ActionCategory category;
  final Effect effect;

  /// Sabit ücret (TL).
  final int cost;

  /// Altın alım (artı) ya da satımı (eksi), gram. Tutarı o yılın altın
  /// fiyatından hesaplanır.
  final int goldGrams;

  /// Yalnızca bir işi olana açık (fazla mesai).
  final bool requiresJob;

  /// Yalnızca okuldaki ya da üniversitedeki öğrenciye açık (ders çalış).
  final bool studentsOnly;

  /// Yalnızca bir işi olmayanlar (yarı zamanlı iş).
  final bool jobless;

  /// Yalnızca işi olmayan, okumayan ve emekli olmayan yetişkine açık
  /// (ara işler).
  final bool idleOnly;

  /// Ev, araba ve kira kararları; null ise etkisi [effect].
  final ActionSpecial? special;
  final int minAge;
  final int? maxAge;

  /// Harcadığı vakit; büyük işler (tatil, taşınma) 2.
  final int timeCost;

  /// Yaşa ve duruma göre bu karakter yapabilir mi.
  bool isAvailableFor(Character c) {
    if (!isAvailableAt(c.age)) return false;
    // Altını olmayana "altın sat" görünmez.
    if (goldGrams < 0 && c.assets.goldGrams < -goldGrams) return false;
    if (requiresJob && c.job == null) return false;
    if (studentsOnly && !ActionCatalog.isStudent(c)) return false;
    if (jobless && c.job != null) return false;
    if (idleOnly && !ActionCatalog.isIdleAdult(c)) return false;
    if (special case final s?) return _specialAvailable(s, c);
    return true;
  }

  static bool _specialAvailable(ActionSpecial s, Character c) {
    final a = c.assets;
    return switch (s) {
      ActionSpecial.evdenCik => c.home == HomeKind.aile,
      ActionSpecial.evArkadasi =>
        (c.home == HomeKind.aile || c.home == HomeKind.kira) &&
            Romance.spouse(c) == null,
      ActionSpecial.aileyeDon => c.home.paysRent && Housing.hasParentInCity(c),
      ActionSpecial.evAl => a.houses == 0,
      ActionSpecial.evSat => a.houses > 0,
      ActionSpecial.arabaAl =>
        a.cars == 0 && c.hasFlag(ActionCatalog.licenseFlag),
      ActionSpecial.arabaSat => a.cars > 0,
      ActionSpecial.kpss => JobMarket.canSitKpss(c),
      ActionSpecial.yazilimKursu => JobMarket.canTakeCodingCourse(c),
      ActionSpecial.tanis => Romance.isSingle(c) && !Romance.mourning(c),
    };
  }

  bool isAvailableAt(int age) =>
      age >= minAge && (maxAge == null || age <= maxAge!);

  /// Aksiyonun nakde etkisi: ücret ve altın alımı eksi; altın satışı ve
  /// kazanç (fazla mesai, ara işler) artı. Ev ve araba aksiyonlarında
  /// peşinat, depozito ya da satış bedeli.
  int moneyChangeFor(Character c, Market market) => switch (special) {
    ActionSpecial.evdenCik => -Housing.moveInCost(c.city),
    ActionSpecial.evArkadasi => -Housing.shareMoveInCost(c.city),
    ActionSpecial.aileyeDon => 0,
    ActionSpecial.evAl => -Housing.housePayment(c),
    ActionSpecial.evSat => Housing.houseSaleProceeds(c),
    ActionSpecial.arabaAl => -Housing.carPayment(c),
    ActionSpecial.arabaSat => Housing.carSaleValue(c),
    ActionSpecial.kpss => 0,
    ActionSpecial.yazilimKursu => -JobMarket.codingCourseCost,
    ActionSpecial.tanis => -Romance.meetCost,
    null => moneyChange(market),
  };

  /// Sabit tutarlı aksiyonların nakde etkisi.
  int moneyChange(Market market) =>
      effect.money - cost - goldGrams * market.goldPrice;

  /// Para (ya da satılacak altın) yetiyor mu.
  bool canAfford(Character c, Market market) {
    if (goldGrams < 0 && c.assets.goldGrams < -goldGrams) return false;
    final change = moneyChangeFor(c, market);
    return change >= 0 || c.stats.money >= -change;
  }

  /// Sabit tutarlı aksiyonun tam etkisi: ücret, altın ve kendi etkisi.
  Effect totalEffect(Market market) => Effect(
    stats: effect.stats,
    money: moneyChange(market),
    gold: effect.gold + goldGrams,
  );
}

/// Aksiyon listesi ve yıllık vakit kuralları.
abstract final class ActionCatalog {
  /// Genç yetişkinlikte bu bayrak varsa öğrenci sayılır.
  static const String studentFlag = 'universite_ogrencisi';

  /// Araba almak için ehliyet gerekir.
  static const String licenseFlag = 'ehliyet_var';

  /// Altın aksiyonlarında bir seferde alınıp satılan gram.
  static const int goldLot = 10;

  /// Okul çağında (7–18) ya da üniversitede.
  static bool isStudent(Character c) =>
      (c.age >= 7 && c.age <= 18) || c.hasFlag(studentFlag);

  /// İşi olmayan, okumayan, emekli olmayan yetişkin (19–64).
  static bool isIdleAdult(Character c) =>
      c.age >= 19 &&
      c.age < 65 &&
      c.job == null &&
      !c.isRetired &&
      !c.hasFlag(studentFlag);

  /// Ara işlerin bir yıllık kazancı (2026: asgari ücretin yaklaşık %60'ı).
  static const int oddJobIncome = 200000;

  /// Öğrencinin yarı zamanlı işinden yıllık kazanç (kafe, kargo).
  static const int partTimeIncome = 150000;

  static const List<LifeAction> all = [
    LifeAction(
      id: 'oyun_oyna',
      category: ActionCategory.eglence,
      maxAge: 12,
      effect: Effect(stats: {StatKind.happiness: 5}),
    ),
    LifeAction(
      id: 'ders_calis',
      category: ActionCategory.okulIs,
      minAge: 7,
      studentsOnly: true,
      effect: Effect(stats: {StatKind.knowledge: 5, StatKind.happiness: -1}),
    ),
    LifeAction(
      id: 'fazla_mesai',
      category: ActionCategory.okulIs,
      minAge: 19,
      maxAge: 64,
      requiresJob: true,
      effect: Effect(
        money: 66000,
        stats: {StatKind.health: -2, StatKind.happiness: -2},
      ),
    ),
    LifeAction(
      id: 'ara_is',
      category: ActionCategory.okulIs,
      minAge: 19,
      idleOnly: true,
      timeCost: 2,
      effect: Effect(
        money: oddJobIncome,
        stats: {StatKind.health: -1, StatKind.happiness: -1},
      ),
    ),
    LifeAction(
      id: 'yarim_zamanli',
      category: ActionCategory.okulIs,
      minAge: 18,
      studentsOnly: true,
      jobless: true,
      timeCost: 2,
      effect: Effect(
        money: partTimeIncome,
        stats: {StatKind.health: -1, StatKind.knowledge: -1},
      ),
    ),
    LifeAction(
      id: 'kitap_oku',
      category: ActionCategory.okulIs,
      minAge: 12,
      effect: Effect(stats: {StatKind.knowledge: 3, StatKind.happiness: 1}),
    ),
    LifeAction(
      id: 'spor',
      category: ActionCategory.saglik,
      minAge: 15,
      cost: 18000,
      effect: Effect(stats: {StatKind.health: 4, StatKind.happiness: 1}),
    ),
    LifeAction(
      id: 'doktor_kontrolu',
      category: ActionCategory.saglik,
      minAge: 19,
      cost: 6500,
      effect: Effect(stats: {StatKind.health: 6}),
    ),
    LifeAction(
      id: 'yuruyus',
      category: ActionCategory.saglik,
      minAge: 50,
      effect: Effect(stats: {StatKind.health: 2, StatKind.happiness: 1}),
    ),
    LifeAction(
      id: 'tatil',
      category: ActionCategory.eglence,
      minAge: 19,
      cost: 80000,
      timeCost: 2,
      effect: Effect(stats: {StatKind.happiness: 10, StatKind.health: 2}),
    ),
    LifeAction(
      id: 'kpss',
      category: ActionCategory.okulIs,
      minAge: 21,
      maxAge: 40,
      timeCost: 2,
      special: ActionSpecial.kpss,
    ),
    LifeAction(
      id: 'yazilim_kursu',
      category: ActionCategory.okulIs,
      minAge: 18,
      timeCost: 2,
      special: ActionSpecial.yazilimKursu,
    ),
    LifeAction(
      id: 'tanis',
      category: ActionCategory.eglence,
      minAge: Romance.minAge,
      special: ActionSpecial.tanis,
    ),
    LifeAction(
      id: 'altin_al',
      category: ActionCategory.para,
      minAge: 19,
      goldGrams: ActionCatalog.goldLot,
    ),
    LifeAction(
      id: 'altin_sat',
      category: ActionCategory.para,
      minAge: 19,
      goldGrams: -ActionCatalog.goldLot,
    ),
    LifeAction(
      id: 'evden_cik',
      category: ActionCategory.para,
      minAge: Housing.minAge,
      special: ActionSpecial.evdenCik,
    ),
    LifeAction(
      id: 'ev_arkadasi',
      category: ActionCategory.para,
      minAge: Housing.minAge,
      special: ActionSpecial.evArkadasi,
    ),
    LifeAction(
      id: 'aileye_don',
      category: ActionCategory.para,
      minAge: Housing.minAge,
      special: ActionSpecial.aileyeDon,
    ),
    LifeAction(
      id: 'ev_al',
      category: ActionCategory.para,
      minAge: 20,
      special: ActionSpecial.evAl,
    ),
    LifeAction(
      id: 'ev_sat',
      category: ActionCategory.para,
      minAge: 20,
      special: ActionSpecial.evSat,
    ),
    LifeAction(
      id: 'araba_al',
      category: ActionCategory.para,
      minAge: 18,
      special: ActionSpecial.arabaAl,
    ),
    LifeAction(
      id: 'araba_sat',
      category: ActionCategory.para,
      minAge: 18,
      special: ActionSpecial.arabaSat,
    ),
  ];

  static LifeAction? byId(String id) {
    for (final action in all) {
      if (action.id == id) return action;
    }
    return null;
  }

  static List<LifeAction> availableFor(Character c) => [
    for (final a in all)
      if (a.isAvailableFor(c)) a,
  ];

  /// Bu yaştan önce yıllar yalnızca olaylarla geçer; kararları aile verir.
  static const int firstTimeAge = 6;

  /// Yıllık vakit (karar: 22 Ekim 2026). Her aksiyon ve etkileşim
  /// [LifeAction.timeCost] kadar vakit harcar; kalan vakit sonraki yıla
  /// geçmez.
  ///
  /// | Durum | Vakit |
  /// | 0–5 yaş | 0 |
  /// | 6–10 yaş | 2 |
  /// | öğrenci (11–18, üniversite) | 5 |
  /// | maaşlı çalışan | 3 |
  /// | işsiz | 5 |
  /// | emekli (erken emekli dahil) | 6 |
  ///
  /// Yarı zamanlı iş, fazla mesai ve kendi işi D2 ve D3'te eklenir.
  static int timeFor(Character c) {
    if (c.age < firstTimeAge) return 0;
    // Askerdeki yıl: vakit yok.
    if (c.hasFlag('askerde')) return 0;
    // Kendi işinin başında: 2; iş ve işletme birlikte: 1 (yaşa bakmaz).
    if (c.businesses.any((b) => BusinessRules.isPresent(c, b))) {
      return c.job != null ? 1 : 2;
    }
    if (c.isRetired || c.age >= 65) return 6;
    if (c.age <= 10) return 2;
    // İş okuldan önce gelir: çalışan açıköğretimli ve çırak 3 alır.
    if (c.job != null) return 3 - JobMarket.timePenalty(c);
    return 5;
  }
}
