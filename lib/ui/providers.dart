import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/asset_content_source.dart';
import '../content/content_loader.dart';
import '../engine/engine.dart';
import '../engine/life_record.dart';
import '../models/models.dart';
import '../services/analytics_service.dart';
import '../services/feedback_service.dart';
import '../services/save_store.dart';
import '../services/share_service.dart';

/// Kart destesi ve kayıt. Hatalı kart dosyası tekrar denemekle düzelmez,
/// bu yüzden yeniden deneme kapalıdır.
final contentProvider = FutureProvider<GameContent>(
  (ref) => loadContentFromAssets(rootBundle),
  retry: (_, _) => null,
);

/// Yeni hayatın tohumunu üretir. Testler sabit tohumla değiştirir.
final seedGeneratorProvider = Provider<int Function()>(
  (ref) =>
      () => Random().nextInt(1 << 31),
);

/// Yerel kayıt. `main` Hive'ı açıp bunu değiştirir; varsayılanı bellektir.
final saveStoreProvider = Provider<SaveStore>((ref) => MemorySaveStore());

/// Paylaşım menüsü; testler sahte bir servisle değiştirir.
final shareServiceProvider = Provider<ShareService>(
  (ref) => const SharePlusService(),
);

/// Ses ve titreşim tercihi; açılışta kayıttan okunur.
final settingsProvider = NotifierProvider<SettingsController, GameSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<GameSettings> {
  @override
  GameSettings build() {
    _load();
    return GameSettings.defaults;
  }

  Future<void> _load() async {
    final saved = await ref.read(saveStoreProvider).loadSettings();
    state = saved;
    ref.read(settingsLoadedProvider.notifier).markLoaded();
    _applyAnalytics(saved);
  }

  void setSound(bool on) => _save(state.copyWith(sound: on));

  void setHaptics(bool on) => _save(state.copyWith(haptics: on));

  /// Kullanım verisi onayı; analitik hemen açılır ya da kapanır.
  void setAnalyticsConsent(bool consent) {
    final next = state.copyWith(analyticsConsent: consent);
    _save(next);
    _applyAnalytics(next);
  }

  void _applyAnalytics(GameSettings settings) => ref
      .read(analyticsServiceProvider)
      .setCollectionEnabled(settings.analyticsEnabled);

  void _save(GameSettings next) {
    state = next;
    ref.read(saveStoreProvider).saveSettings(next);
  }
}

/// Ayarlar kayıttan okundu mu; onay sorusu ancak ondan sonra sorulur.
final settingsLoadedProvider = NotifierProvider<SettingsLoaded, bool>(
  SettingsLoaded.new,
);

class SettingsLoaded extends Notifier<bool> {
  @override
  bool build() => false;

  void markLoaded() => state = true;
}

/// Kullanım verisi; `main` Firebase açılırsa değiştirir, yoksa hiçbir şey
/// göndermez.
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalytics(),
);

/// Ses ve titreşim; testler sahte bir servisle değiştirir.
final feedbackServiceProvider = Provider<FeedbackService>(
  (ref) => DeviceFeedbackService(() => ref.read(settingsProvider)),
);

/// Gerçek saat; testler sabitler.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Yarım kalan hayatın kaydı; doğum ekranı "Devam et" için bakar.
final savedLifeProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) => ref.watch(saveStoreProvider).loadCurrentLife(),
  retry: (_, _) => null,
);

/// O an oynanan hayat; doğum ekranındayken null.
/// Biten hayatlar (albüm); en yenisi sonda.
final albumProvider = FutureProvider<List<LifeRecord>>(
  (ref) => ref.watch(saveStoreProvider).loadAlbum(),
  retry: (_, _) => null,
);

/// Kazanılmış rozetler: kimlik → ilerleme.
final badgeProgressProvider = FutureProvider<Map<String, AchievementProgress>>(
  (ref) => ref.watch(saveStoreProvider).loadAchievements(),
  retry: (_, _) => null,
);

/// Son biten hayatta ilk kez kazanılan rozetler; ölüm ekranı "Yeni!" der.
final newBadgesProvider = NotifierProvider<NewBadges, Set<String>>(
  NewBadges.new,
);

class NewBadges extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void set(Set<String> ids) => state = ids;
}

/// Son yapılan aksiyon ve öncesindeki karakter: arayüz ne olduğunu ve
/// göstergelerde neyin değiştiğini gösterir. Yeni yılda ya da kartta silinir.
typedef ActionResult = ({String actionId, Character before, Character after});

final lastActionProvider = NotifierProvider<LastAction, ActionResult?>(
  LastAction.new,
);

class LastAction extends Notifier<ActionResult?> {
  @override
  ActionResult? build() => null;

  void set(ActionResult? result) => state = result;
}

final lifeProvider = NotifierProvider<LifeController, LifeState?>(
  LifeController.new,
);

/// Motoru arayüze bağlar ve her karardan sonra kaydeder. Oyun mantığı
/// burada değil, motordadır.
class LifeController extends Notifier<LifeState?> {
  LifeEngine? _engine;
  GameContent? _content;
  DateTime? _lifeStartedAt;

  /// Bu oturumda hayatın başladığı ya da sürdürüldüğü an; süre ölçümü için.
  DateTime? get lifeStartedAt => _lifeStartedAt;

  void _log(String event, Map<String, Object> parameters) =>
      ref.read(analyticsServiceProvider).logEvent(event, parameters);

  /// Kayıtlar sırayla yazılsın diye zincirlenir.
  Future<void> _pendingWrites = Future.value();

  @override
  LifeState? build() => null;

  LifeEngine get engine =>
      _engine ?? (throw StateError('Henüz bir hayat başlamadı'));

  SaveStore get _store => ref.read(saveStoreProvider);

  /// Tohum verilmezse rastgele seçilir; ölüm ekranında gösterilir.
  void startLife(
    GameContent content, {
    String? name,
    Gender? gender,
    int? seed,
  }) {
    final engine = LifeEngine(
      deck: content.deck,
      careers: content.careers,
      families: content.families,
      interactions: content.interactions,
      seed: seed ?? ref.read(seedGeneratorProvider)(),
    );
    _engine = engine;
    _content = content;
    _update(engine.startLife(name: name, gender: gender));
    _lifeStartedAt = ref.read(clockProvider)();
    final c = engine.state.character;
    _log(AnalyticsEvents.lifeStart, {
      'background': c.background.id,
      'gender': c.gender.id,
    });
  }

  /// Kaydedilmiş hayatı sürdürür. Kayıt bozuksa ya da artık okunamıyorsa
  /// silinir ve false döner; oyuncu yeni bir hayata başlar.
  bool resume(GameContent content, Map<String, dynamic> snapshot) {
    try {
      final engine = LifeEngine.restore(
        deck: content.deck,
        careers: content.careers,
        families: content.families,
        interactions: content.interactions,
        snapshot: snapshot,
      );
      _engine = engine;
      _content = content;
      state = engine.state;
      _lifeStartedAt = ref.read(clockProvider)();
      _log(AnalyticsEvents.lifeResume, {'age': engine.state.character.age});
      return true;
    } on Object {
      _write(_store.clearCurrentLife);
      ref.invalidate(savedLifeProvider);
      return false;
    }
  }

  void choose(ChoiceSide side) {
    ref.read(lastActionProvider.notifier).set(null);
    _update(engine.choose(side));
  }

  void doAction(String actionId) {
    final before = engine.state.character;
    _update(engine.doAction(actionId));
    ref.read(lastActionProvider.notifier).set((
      actionId: actionId,
      before: before,
      after: engine.state.character,
    ));
  }

  void advanceYear() {
    ref.read(lastActionProvider.notifier).set(null);
    _update(engine.advanceYear());
  }

  /// YKS tercihi: bir bölüme yerleşir.
  void enroll(String department, String city) =>
      _update(engine.enroll(department, city));

  /// YKS tercihi: yerleşmeden başka bir yol.
  void declineTercih(TercihKind kind) => _update(engine.declineTercih(kind));

  /// İlana başvurur ve mülakata girer.
  void applyFor(JobListing listing, ChoiceSide side, {String? referenceId}) =>
      _update(engine.applyFor(listing, side, referenceId: referenceId));

  void requestPromotion() => _update(engine.requestPromotion());

  void requestRaise() => _update(engine.requestRaise());

  void quitJob() => _update(engine.quitJob());

  void retireEarly() => _update(engine.retireEarly());

  void setTempo(Tempo tempo) => _update(engine.setTempo(tempo));

  void openBusiness(String type) => _update(engine.openBusiness(type));

  void setBusinessPresent(String id, bool present) =>
      _update(engine.setBusinessPresent(id, present));

  void setBusinessPrice(String id, PriceLevel price) =>
      _update(engine.setBusinessPrice(id, price));

  void advertiseBusiness(String id) => _update(engine.advertiseBusiness(id));

  void expandBusiness(String id) => _update(engine.expandBusiness(id));

  void takePartner(String id, String personId) =>
      _update(engine.takePartner(id, personId));

  void hireKnown(String id, String personId) =>
      _update(engine.hireKnown(id, personId));

  void disposeBusiness(String id, {required bool sell}) =>
      _update(engine.disposeBusiness(id, sell: sell));

  /// Başka şehre taşınır (Varlıklar sekmesi).
  void moveTo(String city, {bool withFamily = false}) =>
      _update(engine.moveTo(city, withFamily: withFamily));

  /// İnsanlar sekmesinden bir kişiyle etkileşim (Ara dahil).
  void interact(InteractionRequest request) =>
      _update(engine.interact(request));

  /// Sürdürülemeyen (eski sürüm) yarım hayat kaydını siler.
  void discardSavedLife() {
    _write(_store.clearCurrentLife);
    ref.invalidate(savedLifeProvider);
  }

  /// Doğum ekranına döner; yarım hayat kaydı silinir.
  void reset() {
    _engine = null;
    ref.read(lastActionProvider.notifier).set(null);
    ref.read(newBadgesProvider.notifier).set(const {});
    state = null;
    _write(_store.clearCurrentLife);
    ref.invalidate(savedLifeProvider);
  }

  /// Bekleyen bütün kayıtların yazılmasını bekler (testler için).
  Future<void> flush() => _pendingWrites;

  void _update(LifeState next) {
    final wasOver = state?.isOver ?? false;
    state = next;
    if (!next.isOver) {
      final snapshot = engine.toSnapshot();
      _write(() => _store.saveCurrentLife(snapshot));
      return;
    }
    if (wasOver) return;
    // Biten hayat albüme geçer; "Devam et" ile açılacak bir şey kalmaz.
    final record = LifeRecord.fromSummary(
      next.summary!,
      seed: engine.seed,
      endedAt: ref.read(clockProvider)(),
      careerId: next.character.careerJob?.careerId,
      careerTier: next.character.careerJob?.tier,
    );
    _write(() => _store.addToAlbum(record));
    _write(() => _recordAchievements(next.summary!, record.endedAt));
    _write(() async {
      ref.invalidate(albumProvider);
      ref.invalidate(badgeProgressProvider);
    });
    _write(_store.clearCurrentLife);
  }

  /// Rozetleri hesaplar, ilerlemeyi kaydeder ve ilk kez kazanılanları
  /// bildirir.
  Future<void> _recordAchievements(LifeSummary summary, DateTime at) async {
    final book = _content?.achievements;
    if (book == null) return;
    final earned = book.earnedBy(summary);
    final progress = await _store.loadAchievements();
    final fresh = <String>{};
    for (final a in earned) {
      final before = progress[a.id];
      if (before == null) {
        fresh.add(a.id);
        progress[a.id] = AchievementProgress(count: 1, firstEarnedAt: at);
      } else {
        progress[a.id] = before.earnedAgain();
      }
    }
    await _store.saveAchievements(progress);
    ref.read(newBadgesProvider.notifier).set(fresh);
  }

  /// Bir yazma hatası sonrakileri durdurmasın; hata raporlanır, sıra sürer.
  void _write(Future<void> Function() write) {
    _pendingWrites = _pendingWrites
        .then((_) => write())
        .catchError(
          (Object error, StackTrace stack) => FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'kayıt',
            ),
          ),
        );
  }
}
