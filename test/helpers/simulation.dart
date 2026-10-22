import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auto_player.dart';
import 'families.dart';

final FamilyBook _families = realFamilies();

/// Bir hayatı oynatır ve her adımda değişmezleri denetler. Aile kitabı
/// verilmezse oyunun gerçek aile dosyaları kullanılır.
LifeState simulateLife(
  EventDeck deck,
  int seed, {
  CareerBook? careers,
  FamilyBook? families,
  void Function(LifeState state)? onStep,
}) {
  final engine = LifeEngine(
    deck: deck,
    seed: seed,
    careers: careers,
    families: families ?? _families,
  );
  var lastAge = 0;
  Character? previous;
  return AutoPlayer(seed).play(
    engine,
    onStep: (state) {
      final c = state.character;
      if (previous case final prev? when state.phase != YearPhase.dead) {
        expectMoneyBooked(prev, c, reason: 'tohum $seed, ${c.age} yaş');
      }
      previous = c;
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
      expect(state.timeLeft, greaterThanOrEqualTo(0));
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
      onStep?.call(state);
    },
  );
}

/// Her para değişikliği deftere kaynağıyla yazılmış olmalı: [next] defteri
/// [prev] defterinin (iki yıllık pencerede kalan) devamıdır ve yeni
/// kayıtların toplamı para farkına eşittir.
void expectMoneyBooked(Character prev, Character next, {String? reason}) {
  final kept = [
    for (final e in prev.ledger)
      if (e.age >= next.age - 1) e,
  ];
  expect(
    next.ledger.take(kept.length).toList(),
    kept,
    reason: 'defter yalnızca eklenir ($reason)',
  );
  final added = next.ledger.skip(kept.length);
  expect(
    added.fold(0, (sum, e) => sum + e.amount),
    next.stats.money - prev.stats.money,
    reason: 'kaydı olmayan para hareketi ($reason): $added',
  );
}
