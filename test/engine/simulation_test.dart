import 'package:bir_omur/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/simulation.dart';
import '../helpers/test_cards.dart';

void main() {
  final deck = EventDeck(simulationDeck());

  test('100 hayat çökmeden, geçerli göstergelerle ve sonlu biter', () {
    final deathAges = <int>[];
    final causes = <DeathCause, int>{};
    for (var seed = 0; seed < 100; seed++) {
      final end = simulateLife(deck, seed);
      deathAges.add(end.summary!.deathAge);
      causes.update(end.summary!.cause, (n) => n + 1, ifAbsent: () => 1);
    }
    deathAges.sort();
    final mean = deathAges.reduce((a, b) => a + b) / deathAges.length;
    // Denge değil, aklı başındalık kontrolü: hayatlar ne hemen bitiyor
    // ne de sınıra dayanıyor.
    expect(mean, inInclusiveRange(30, 100));
    printOnFailure('ölüm yaşları: $deathAges, sebepler: $causes');
  });

  test('aynı tohum aynı hayatı üretir', () {
    for (final seed in [7, 42, 2026]) {
      final a = simulateLife(deck, seed).character;
      final b = simulateLife(deck, seed).character;
      expect(a.age, b.age);
      expect(a.name, b.name);
      expect(a.hometown, b.hometown);
      expect(a.stats, b.stats);
      expect(a.flags, b.flags);
      expect(
        a.history.map(
          (r) => '${r.age}:${r.cardId}:${r.side}:${r.rollSucceeded}',
        ),
        b.history.map(
          (r) => '${r.age}:${r.cardId}:${r.side}:${r.rollSucceeded}',
        ),
      );
    }
  });

  test('farklı tohumlar farklı hayatlar üretir', () {
    final ages = {
      for (var seed = 0; seed < 20; seed++)
        simulateLife(deck, seed).character.age,
    };
    expect(ages.length, greaterThan(5));
  });

  test('zincir, zorunlu ve zor dönem kartları gerçekten gelir', () {
    final seen = <String>{};
    for (var seed = 0; seed < 100; seed++) {
      seen.addAll(
        simulateLife(deck, seed).character.history.map((r) => r.cardId),
      );
    }
    expect(
      seen,
      containsAll(['zincir_devam', 'askerlik', 'zor_donem_destek', 'icra']),
    );
  });
}
