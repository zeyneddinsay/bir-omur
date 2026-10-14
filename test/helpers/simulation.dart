import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auto_player.dart';

/// Bir hayatı oynatır ve her adımda değişmezleri denetler.
LifeState simulateLife(EventDeck deck, int seed) {
  final engine = LifeEngine(deck: deck, seed: seed);
  var lastAge = 0;
  return AutoPlayer(seed).play(
    engine,
    onStep: (state) {
      final c = state.character;
      final s = c.stats;
      for (final kind in StatKind.values) {
        expect(
          s[kind],
          inInclusiveRange(Stats.min, Stats.max),
          reason: '$kind, tohum $seed',
        );
      }
      expect(
        c.age,
        inInclusiveRange(lastAge, lastAge + 1),
        reason: 'yaş atlamaz',
      );
      expect(c.age, lessThanOrEqualTo(DeathCheck.maxAge));
      expect(state.actionsLeft, greaterThanOrEqualTo(0));
      switch (state.phase) {
        case YearPhase.cards:
          expect(state.pendingCards, isNotEmpty);
        case YearPhase.actions:
          expect(state.pendingCards, isEmpty);
        case YearPhase.dead:
          expect(state.summary, isNotNull);
          expect(c.isAlive, isFalse);
      }
      lastAge = c.age;
    },
  );
}
