import 'dart:math';

import '../models/models.dart';

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
  const EffectResolver(this.random);

  final Random random;

  ChoiceOutcome resolve(Character character, EventCard card, ChoiceSide side) {
    final choice = card.choice(side);
    final scheduled = <ScheduledEvent>[];

    var next = applyEffect(character, choice.effects);
    if (choice.effects.schedule case final s?) scheduled.add(s);

    bool? succeeded;
    if (choice.roll case final roll?) {
      succeeded = rollSucceeds(next, roll);
      final branch = succeeded ? choice.success! : choice.fail!;
      next = applyEffect(next, branch);
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

  /// Gösterge, para ve bayrak değişikliklerini uygular. Zincir kartını
  /// uygulamaz; o sıra (ScheduleQueue) motorun işidir.
  static Character applyEffect(Character character, Effect effect) {
    if (effect.isEmpty) return character;
    var stats = character.stats.withMoneyDelta(effect.money);
    effect.stats.forEach((kind, delta) => stats = stats.withDelta(kind, delta));
    final flags = {...character.flags}
      ..addAll(effect.addFlags)
      ..removeAll(effect.removeFlags);
    return character.copyWith(stats: stats, flags: flags);
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
