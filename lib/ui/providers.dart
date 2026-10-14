import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/asset_content_source.dart';
import '../content/content_loader.dart';
import '../engine/engine.dart';
import '../models/models.dart';

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

/// O an oynanan hayat; doğum ekranındayken null.
final lifeProvider = NotifierProvider<LifeController, LifeState?>(
  LifeController.new,
);

/// Motoru arayüze bağlar. Oyun mantığı burada değil, motordadır.
class LifeController extends Notifier<LifeState?> {
  LifeEngine? _engine;

  @override
  LifeState? build() => null;

  LifeEngine get engine =>
      _engine ?? (throw StateError('Henüz bir hayat başlamadı'));

  /// Tohum verilmezse rastgele seçilir; ölüm ekranında gösterilir.
  void startLife(EventDeck deck, {String? name, Gender? gender, int? seed}) {
    final engine = LifeEngine(
      deck: deck,
      seed: seed ?? ref.read(seedGeneratorProvider)(),
    );
    _engine = engine;
    state = engine.startLife(name: name, gender: gender);
  }

  void choose(ChoiceSide side) => state = engine.choose(side);

  void doAction(String actionId) => state = engine.doAction(actionId);

  void advanceYear() => state = engine.advanceYear();

  /// Doğum ekranına döner.
  void reset() {
    _engine = null;
    state = null;
  }
}
