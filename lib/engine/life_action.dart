import '../models/models.dart';
import 'economy.dart';

/// Aksiyon menüsünün kategorileri.
enum ActionCategory { okulIs, para, saglik, eglence }

/// Aksiyon menüsündeki bir seçenek. Adı ve açıklaması arayüzde [id] ile
/// ARB dosyasından gelir.
class LifeAction {
  const LifeAction({
    required this.id,
    required this.category,
    this.effect = Effect.none,
    this.cost = 0,
    this.goldGrams = 0,
    this.searchesJob = false,
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

  /// "İş ara": işsiz, emekli ya da öğrenci olmayan yetişkine açık.
  final bool searchesJob;
  final int minAge;
  final int? maxAge;

  /// Harcadığı vakit; büyük işler (tatil) 2.
  final int timeCost;

  /// Yaşa ve (iş arama için) duruma göre bu karakter yapabilir mi.
  bool isAvailableFor(Character c) {
    if (!isAvailableAt(c.age)) return false;
    if (!searchesJob) return true;
    return c.job == null &&
        !c.isRetired &&
        !c.hasFlag(ActionCatalog.studentFlag);
  }

  bool isAvailableAt(int age) =>
      age >= minAge && (maxAge == null || age <= maxAge!);

  /// Aksiyonun nakde etkisi: ücret ve altın alımı eksi, altın satışı artı.
  int moneyChange(Market market) => -cost - goldGrams * market.goldPrice;

  /// Para (ya da satılacak altın) yetiyor mu.
  bool canAfford(Character c, Market market) {
    if (goldGrams < 0 && c.assets.goldGrams < -goldGrams) return false;
    final change = moneyChange(market);
    return change >= 0 || c.stats.money >= -change;
  }

  /// Aksiyonun tam etkisi: ücret, altın ve kendi etkisi.
  Effect totalEffect(Market market) => Effect(
    stats: effect.stats,
    money: effect.money + moneyChange(market),
    gold: effect.gold + goldGrams,
  );
}

/// F0'ın basit aksiyon listesi ve yıllık hak kuralları.
abstract final class ActionCatalog {
  /// Genç yetişkinlikte bu bayrak varsa öğrenci sayılır (4 hak).
  static const String studentFlag = 'universite_ogrencisi';

  /// Altın aksiyonlarında bir seferde alınıp satılan gram.
  static const int goldLot = 10;

  static const String jobSearchId = 'is_ara';

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
      maxAge: 29,
      effect: Effect(stats: {StatKind.knowledge: 5, StatKind.happiness: -1}),
    ),
    LifeAction(
      id: 'fazla_mesai',
      category: ActionCategory.okulIs,
      minAge: 19,
      maxAge: 64,
      effect: Effect(
        money: 20000,
        stats: {StatKind.health: -2, StatKind.happiness: -2},
      ),
    ),
    LifeAction(
      id: 'kitap_oku',
      category: ActionCategory.okulIs,
      minAge: 30,
      effect: Effect(stats: {StatKind.knowledge: 3, StatKind.happiness: 1}),
    ),
    LifeAction(
      id: 'spor',
      category: ActionCategory.saglik,
      minAge: 15,
      cost: 500,
      effect: Effect(stats: {StatKind.health: 4, StatKind.happiness: 1}),
    ),
    LifeAction(
      id: 'doktor_kontrolu',
      category: ActionCategory.saglik,
      minAge: 19,
      cost: 2000,
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
      cost: 25000,
      timeCost: 2,
      effect: Effect(stats: {StatKind.happiness: 10, StatKind.health: 2}),
    ),
    LifeAction(
      id: ActionCatalog.jobSearchId,
      category: ActionCategory.okulIs,
      minAge: 19,
      maxAge: 60,
      searchesJob: true,
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
    if (c.isRetired) return 6;
    if (c.age <= 10) return 2;
    if (c.age <= 18 || c.hasFlag(studentFlag)) return 5;
    if (c.job != null) return 3;
    return 5;
  }
}
