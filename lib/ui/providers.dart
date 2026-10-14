import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/asset_content_source.dart';
import '../content/content_loader.dart';
import '../engine/engine.dart';
import '../engine/life_record.dart';
import '../models/models.dart';
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

/// Gerçek saat; testler sabitler.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Yarım kalan hayatın kaydı; doğum ekranı "Devam et" için bakar.
final savedLifeProvider = FutureProvider<Map<String, dynamic>?>(
  (ref) => ref.watch(saveStoreProvider).loadCurrentLife(),
  retry: (_, _) => null,
);

/// O an oynanan hayat; doğum ekranındayken null.
final lifeProvider = NotifierProvider<LifeController, LifeState?>(
  LifeController.new,
);

/// Motoru arayüze bağlar ve her karardan sonra kaydeder. Oyun mantığı
/// burada değil, motordadır.
class LifeController extends Notifier<LifeState?> {
  LifeEngine? _engine;

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
      seed: seed ?? ref.read(seedGeneratorProvider)(),
    );
    _engine = engine;
    _update(engine.startLife(name: name, gender: gender));
  }

  /// Kaydedilmiş hayatı sürdürür. Kayıt bozuksa ya da artık okunamıyorsa
  /// silinir ve false döner; oyuncu yeni bir hayata başlar.
  bool resume(GameContent content, Map<String, dynamic> snapshot) {
    try {
      final engine = LifeEngine.restore(
        deck: content.deck,
        careers: content.careers,
        snapshot: snapshot,
      );
      _engine = engine;
      state = engine.state;
      return true;
    } on Object {
      _write(_store.clearCurrentLife);
      ref.invalidate(savedLifeProvider);
      return false;
    }
  }

  void choose(ChoiceSide side) => _update(engine.choose(side));

  void doAction(String actionId) => _update(engine.doAction(actionId));

  void advanceYear() => _update(engine.advanceYear());

  /// Doğum ekranına döner; yarım hayat kaydı silinir.
  void reset() {
    _engine = null;
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
    _write(_store.clearCurrentLife);
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
