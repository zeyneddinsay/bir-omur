import '../models/models.dart';

/// Aksiyon menüsünün kategorileri.
enum ActionCategory { okulIs, iliskiler, para, saglik, memleket, eglence }

/// Aksiyon menüsündeki bir seçenek. Adı ve açıklaması arayüzde [id] ile
/// ARB dosyasından gelir.
class LifeAction {
  const LifeAction({
    required this.id,
    required this.category,
    required this.effect,
    this.cost = 0,
    this.minAge = 0,
    this.maxAge,
  });

  final String id;
  final ActionCategory category;
  final Effect effect;

  /// TL. Para yetmiyorsa aksiyon yapılamaz.
  final int cost;
  final int minAge;
  final int? maxAge;

  bool isAvailableAt(int age) =>
      age >= minAge && (maxAge == null || age <= maxAge!);

  bool canAfford(Character c) => cost <= 0 || c.stats.money >= cost;
}

/// F0'ın basit aksiyon listesi ve yıllık hak kuralları.
abstract final class ActionCatalog {
  /// Genç yetişkinlikte bu bayrak varsa öğrenci sayılır (4 hak).
  static const String studentFlag = 'universite_ogrencisi';

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
        money: 10000,
        stats: {StatKind.health: -2, StatKind.happiness: -2},
      ),
    ),
    LifeAction(
      id: 'aileyle_vakit',
      category: ActionCategory.iliskiler,
      effect: Effect(stats: {StatKind.family: 5}),
    ),
    LifeAction(
      id: 'arkadaslarla_bulus',
      category: ActionCategory.iliskiler,
      minAge: 7,
      effect: Effect(stats: {StatKind.happiness: 4, StatKind.reputation: 1}),
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
      id: 'memleket_ziyareti',
      category: ActionCategory.memleket,
      minAge: 19,
      cost: 5000,
      effect: Effect(stats: {StatKind.family: 4, StatKind.happiness: 3}),
    ),
    LifeAction(
      id: 'tatil',
      category: ActionCategory.eglence,
      minAge: 19,
      cost: 25000,
      effect: Effect(stats: {StatKind.happiness: 10, StatKind.health: 2}),
    ),
    LifeAction(
      id: 'birikim_yap',
      category: ActionCategory.para,
      minAge: 19,
      effect: Effect(money: 3000, stats: {StatKind.happiness: -1}),
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
      if (a.isAvailableAt(c.age)) a,
  ];

  /// Yıllık aksiyon hakkı: çocuk 2, öğrenci 4, çalışan 2, emekli 4.
  static int allowanceFor(Character c) => switch (c.stage) {
    LifeStage.bebek || LifeStage.ilkokul => 2,
    LifeStage.ortaokul || LifeStage.lise => 4,
    LifeStage.genc => c.hasFlag(studentFlag) ? 4 : 2,
    LifeStage.yetiskin || LifeStage.olgun => 2,
    LifeStage.yasli => 4,
  };
}
