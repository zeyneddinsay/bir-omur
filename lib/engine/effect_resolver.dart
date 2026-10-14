import 'dart:math';

import '../models/models.dart';
import 'careers.dart';
import 'economy.dart';

/// Bir seçimin sonucu: yeni karakter, zar sonucu ve planlanan zincir kartları.
class ChoiceOutcome {
  const ChoiceOutcome({
    required this.character,
    required this.choice,
    this.rollSucceeded,
    this.scheduled = const [],
  });

  final Character character;
  final Choice choice;

  /// Seçenekte zar yoksa null.
  final bool? rollSucceeded;
  final List<ScheduledEvent> scheduled;
}

/// Seçilen seçeneğin etkilerini karaktere uygular.
class EffectResolver {
  EffectResolver(this.random, {CareerBook? careers})
    : careers = careers ?? CareerBook.empty;

  final Random random;
  final CareerBook careers;

  ChoiceOutcome resolve(Character character, EventCard card, ChoiceSide side) {
    final choice = card.choice(side);
    final scheduled = <ScheduledEvent>[];

    var next = _countCardEffect(
      applyEffect(character, choice.effects, careers: careers),
      choice.effects,
    );
    if (choice.effects.schedule case final s?) scheduled.add(s);

    bool? succeeded;
    if (choice.roll case final roll?) {
      succeeded = rollSucceeds(next, roll);
      final branch = succeeded ? choice.success! : choice.fail!;
      next = _countCardEffect(
        applyEffect(next, branch, careers: careers),
        branch,
      );
      if (branch.schedule case final s?) scheduled.add(s);
    }

    next = next.withRecord(
      CardRecord(
        age: character.age,
        cardId: card.id,
        side: side,
        rollSucceeded: succeeded,
      ),
    );
    return ChoiceOutcome(
      character: next,
      choice: choice,
      rollSucceeded: succeeded,
      scheduled: scheduled,
    );
  }

  /// Gösterge, para, varlık, iş ve bayrak değişikliklerini uygular. Zincir
  /// kartını uygulamaz; o sıra (ScheduleQueue) motorun işidir.
  ///
  /// İş değişikliği olan bir etki [careers] ister.
  static Character applyEffect(
    Character character,
    Effect effect, {
    CareerBook? careers,
  }) {
    if (effect.isEmpty) return character;
    var stats = character.stats.withMoneyDelta(effect.money);
    effect.stats.forEach((kind, delta) => stats = stats.withDelta(kind, delta));
    final flags = {...character.flags}
      ..addAll(effect.addFlags)
      ..removeAll(effect.removeFlags);
    var next = Economy.applyAssetEffect(
      character.copyWith(stats: stats, flags: flags),
      effect,
    );
    if (effect.career case final change?) {
      next = Careers.applyChange(next, change, careers ?? CareerBook.empty);
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Kartın etkisini hayatın sayılarına yazar: taşınma ve kartla gelen
  /// altın. Aksiyonlarla alınan altın sayılmaz.
  static Character _countCardEffect(Character c, Effect effect) {
    final moved = effect.addFlags.contains(Economy.movedFlag);
    final gold = effect.gold > 0 ? effect.gold : 0;
    if (!moved && gold == 0) return c;
    final counters = c.counters;
    return c.copyWith(
      counters: counters.copyWith(
        moves: counters.moves + (moved ? 1 : 0),
        goldReceived: counters.goldReceived + gold,
      ),
    );
  }

  /// Zar: 0–100 arası bir atış ile bakılan değerin ortalaması eşiği
  /// geçerse başarılı. Şans dışındaki zarlarda şans küçük bir pay ekler
  /// (şans 100 ise +5, 0 ise −5).
  bool rollSucceeds(Character character, Roll roll) {
    final kind = roll.stat.statKind;
    final value = kind == null ? character.luck : character.stats[kind];
    final luckBonus = kind == null ? 0 : (character.luck - 50) / 10;
    final dice = random.nextInt(101);
    return (value + dice) / 2 + luckBonus >= roll.threshold;
  }
}
