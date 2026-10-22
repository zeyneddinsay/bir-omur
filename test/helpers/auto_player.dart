import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';

/// Bir hayatı rastgele seçimlerle oynayan test oyuncusu.
///
/// Her adımdan sonra [onStep] çağrılır; testler değişmezleri orada denetler.
/// [maxSteps] sonsuz döngüye karşı sigortadır.
class AutoPlayer {
  AutoPlayer(int seed) : _random = Random(seed);

  final Random _random;

  static const int maxSteps = 20000;

  LifeState play(LifeEngine engine, {void Function(LifeState state)? onStep}) {
    var state = engine.startLife();
    onStep?.call(state);
    var steps = 0;
    while (!state.isOver) {
      if (++steps > maxSteps) {
        throw StateError('Hayat $maxSteps adımda bitmedi (sonsuz döngü?)');
      }
      state = step(engine);
      onStep?.call(state);
    }
    return state;
  }

  /// Tek bir oyuncu hamlesi: kart seç, aksiyon yap ya da yaşlan.
  LifeState step(LifeEngine engine) {
    final state = engine.state;
    switch (state.phase) {
      case YearPhase.cards:
        return engine.choose(pickSide(state.currentEvent!.card));
      case YearPhase.actions:
        // Yılların yarısında önce biriyle etkileşir (Ara dahil).
        final people = engine.possibleInteractions();
        if (people.isNotEmpty && _random.nextBool()) {
          return engine.interact(people[_random.nextInt(people.length)]);
        }
        final action = pickAction(engine);
        return action == null ? engine.advanceYear() : engine.doAction(action);
      case YearPhase.dead:
        return state;
    }
  }

  ChoiceSide pickSide(EventCard card) {
    final sides = [
      ChoiceSide.left,
      ChoiceSide.right,
      if (card.up != null) ChoiceSide.up,
    ];
    return sides[_random.nextInt(sides.length)];
  }

  /// Yapılacak aksiyonun kimliği; null ise yaşlanma zamanı.
  String? pickAction(LifeEngine engine) {
    final enabled = [
      for (final (action, ok) in engine.availableActions())
        if (ok) action,
    ];
    if (enabled.isEmpty || _random.nextInt(4) == 0) return null;
    return enabled[_random.nextInt(enabled.length)].id;
  }
}
