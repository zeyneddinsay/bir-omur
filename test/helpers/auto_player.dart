import 'dart:math';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';

/// Bir hayatı baştan sona rastgele seçimlerle oynayan test oyuncusu.
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
      switch (state.phase) {
        case YearPhase.cards:
          final card = state.currentCard!;
          final sides = [
            ChoiceSide.left,
            ChoiceSide.right,
            if (card.up != null) ChoiceSide.up,
          ];
          state = engine.choose(sides[_random.nextInt(sides.length)]);
        case YearPhase.actions:
          final enabled = [
            for (final (action, ok) in engine.availableActions())
              if (ok) action,
          ];
          if (enabled.isNotEmpty && _random.nextInt(4) > 0) {
            state = engine.doAction(
              enabled[_random.nextInt(enabled.length)].id,
            );
          } else {
            state = engine.advanceYear();
          }
        case YearPhase.dead:
          break;
      }
      onStep?.call(state);
    }
    return state;
  }
}
