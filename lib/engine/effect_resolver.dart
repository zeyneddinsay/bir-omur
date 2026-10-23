import 'dart:math';

import '../models/models.dart';
import 'careers.dart';
import 'economy.dart';
import 'event_deck.dart';
import 'relationships.dart';

/// Planlanmış bir iplik: hangi olay, kaç yıl sonra, hangi kişilerle.
class PlannedThread {
  const PlannedThread(this.event, this.people);

  final ScheduledEvent event;

  /// Yuva adı → kişi kimliği (yalnızca `with` ile taşınan yuvalar).
  final Map<String, String> people;
}

/// Bir seçimin sonucu: yeni karakter, zar sonucu ve planlanan iplikler.
class ChoiceOutcome {
  const ChoiceOutcome({
    required this.character,
    required this.choice,
    this.before,
    this.event,
    this.rollSucceeded,
    this.scheduled = const [],
  });

  final Character character;
  final Choice choice;

  /// Seçimden önceki karakter; arayüz seçimin göstergelere etkisini
  /// gösterir.
  final Character? before;

  /// Seçilen olay (kişileriyle); sonuç cümlesi bununla kurulur.
  final PendingEvent? event;

  /// Seçenekte zar yoksa null.
  final bool? rollSucceeded;
  final List<PlannedThread> scheduled;
}

/// Seçilen seçeneğin etkilerini karaktere uygular.
class EffectResolver {
  EffectResolver(this.random, {CareerBook? careers})
    : careers = careers ?? CareerBook.empty;

  final Random random;
  final CareerBook careers;

  ChoiceOutcome resolve(
    Character character,
    PendingEvent event,
    ChoiceSide side,
  ) {
    final card = event.card;
    final choice = card.choice(side);
    final scheduled = <PlannedThread>[];

    void plan(Effect effect) {
      final s = effect.schedule;
      if (s == null) return;
      scheduled.add(
        PlannedThread(s, {
          for (final slot in s.withRoles) slot: ?event.people[slot],
        }),
      );
    }

    var next = _countCardEffect(
      applyEffect(
        character,
        choice.effects,
        careers: careers,
        conditions: card.conditions,
      ),
      choice.effects,
    );
    next = applyPeopleEffect(next, choice.effects, event.people);
    plan(choice.effects);

    bool? succeeded;
    if (choice.roll case final roll?) {
      succeeded = rollSucceeds(next, roll);
      final branch = succeeded ? choice.success! : choice.fail!;
      next = _countCardEffect(
        applyEffect(
          next,
          branch,
          careers: careers,
          conditions: card.conditions,
        ),
        branch,
      );
      next = applyPeopleEffect(next, branch, event.people);
      plan(branch);
    }

    next = _meet(next, event);
    next = next.withRecord(
      CardRecord(
        age: character.age,
        cardId: card.id,
        side: side,
        rollSucceeded: succeeded,
        people: event.people,
      ),
    );
    return ChoiceOutcome(
      character: next,
      choice: choice,
      before: character,
      event: event,
      rollSucceeded: succeeded,
      scheduled: scheduled,
    );
  }

  /// Olaydaki kişiler: sahnede olanlarla görüşülmüş sayılır; hepsi bu
  /// yıl olaya çıkmış sayılır (dinlenme kuralı).
  static Character _meet(Character c, PendingEvent event) {
    var people = c.people;
    for (final slot in event.card.roles) {
      final id = event.people[slot.name];
      final p = id == null ? null : people[id];
      if (p == null) continue;
      var updated = p.copyWith(lastEventAt: c.age);
      if (!slot.offstage) {
        updated = Relationships.touch(updated, c.age).copyWith(archived: false);
      }
      people = people.update(updated);
    }
    return c.copyWith(people: people);
  }

  /// Rol yuvalarındaki kişilere etkiler: anı, yumuşama, bağ, arşiv.
  static Character applyPeopleEffect(
    Character c,
    Effect effect,
    Map<String, String> bindings,
  ) {
    if (effect.people.isEmpty) return c;
    var people = c.people;
    for (final MapEntry(key: slot, value: change) in effect.people.entries) {
      final id = bindings[slot];
      var p = id == null ? null : people[id];
      if (p == null) continue;
      if (change.heal case final heal?) {
        p = Relationships.heal(
          p,
          kind: heal == PersonEffect.healHeaviest ? null : heal,
          now: c.age,
        );
      }
      if (change.memory case final memory?) {
        p = Relationships.addMemory(p, memory.at(c.age), now: c.age);
      }
      if (change.bond case final bond?) p = p.copyWith(bond: bond);
      if (change.archive) p = p.copyWith(archived: true);
      people = people.update(p);
    }
    return c.copyWith(people: people);
  }

  /// Gösterge, para, varlık, iş ve bayrak değişikliklerini uygular. Zincir
  /// kartını uygulamaz; o sıra (ScheduleQueue) motorun işidir.
  ///
  /// İş değişikliği olan bir etki [careers] ister. İşletme etkisi kartın
  /// [conditions] koşuluna uyan işletmelere uygulanır.
  static Character applyEffect(
    Character character,
    Effect effect, {
    CareerBook? careers,
    Conditions? conditions,
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
    if (effect.business != 0) {
      final targets = {
        for (final b in conditions?.matchingBusinesses(next) ?? next.businesses)
          b.id,
      };
      next = next.copyWith(
        businesses: [
          for (final b in next.businesses)
            targets.contains(b.id)
                ? b.copyWith(
                    reputation: (b.reputation + effect.business).clamp(0, 100),
                  )
                : b,
        ],
      );
    }
    if (effect.performance != 0 && next.job != null) {
      final job = next.job!;
      next = next.copyWith(
        job: job.copyWith(
          performance: (job.performance + effect.performance).clamp(0, 100),
        ),
      );
    }
    return Economy.syncDerivedFlags(next);
  }

  /// Kartın etkisini hayatın sayılarına yazar: kartla gelen altın.
  /// Aksiyonlarla alınan altın sayılmaz; taşınmayı motor sayar.
  static Character _countCardEffect(Character c, Effect effect) {
    final gold = effect.gold > 0 ? effect.gold : 0;
    if (gold == 0) return c;
    final counters = c.counters;
    return c.copyWith(
      counters: counters.copyWith(goldReceived: counters.goldReceived + gold),
    );
  }

  /// Zar: 0–100 arası bir atış ile bakılan değerin ortalaması eşiği
  /// geçerse başarılı. Şans dışındaki zarlarda şans küçük bir pay ekler
  /// (şans 100 ise +5, 0 ise −5).
  bool rollSucceeds(Character character, Roll roll) =>
      _rollScore(character, roll, random.nextInt(101)) >= roll.threshold;

  static double _rollScore(Character character, Roll roll, int dice) {
    final kind = roll.stat.statKind;
    final value = kind == null ? character.luck : character.stats[kind];
    final luckBonus = kind == null ? 0 : (character.luck - 50) / 10;
    return (value + dice) / 2 + luckBonus;
  }

  /// Zarın tutma ihtimali (0–1): 0–100 arası atışlardan kaçı eşiği geçer.
  /// Arayüz bunu "yüksek / orta / düşük" diye gösterir.
  static double rollChance(Character character, Roll roll) {
    var hits = 0;
    for (var dice = 0; dice <= 100; dice++) {
      if (_rollScore(character, roll, dice) >= roll.threshold) hits++;
    }
    return hits / 101;
  }
}

/// Zar ihtimalinin oyuncuya gösterilen kabası.
enum RollOdds {
  dusuk,
  orta,
  yuksek;

  static RollOdds of(double chance) => chance >= 0.65
      ? yuksek
      : chance >= 0.35
      ? orta
      : dusuk;
}
