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
        if (state.character.hasFlag(EducationRules.pendingFlag)) {
          return pickTercih(engine);
        }
        // Ara sıra başka şehre taşınır.
        if (_random.nextInt(25) == 0) {
          final cities = [
            for (final (city, blocked, _) in engine.moveOptions())
              if (blocked == null) city,
          ];
          if (cities.isNotEmpty) {
            return engine.moveTo(
              cities[_random.nextInt(cities.length)],
              withFamily: _random.nextBool(),
            );
          }
        }
        // İşi yoksa ya da bazen işi varken ilanlara başvurur.
        final open = [
          for (final (l, blocked) in engine.listingOptions())
            if (blocked == null) l,
        ];
        final c = state.character;
        if (open.isNotEmpty &&
            (c.job == null
                ? _random.nextInt(3) > 0
                : _random.nextInt(12) == 0)) {
          // Çoğunlukla en yüksek maaşlı ilana başvurur.
          final listing = _random.nextInt(4) > 0
              ? bestListing(engine, open)
              : open[_random.nextInt(open.length)];
          final refs = engine.listingReferences(listing);
          return engine.applyFor(
            listing,
            _random.nextBool() ? ChoiceSide.left : ChoiceSide.right,
            referenceId: refs.isNotEmpty && _random.nextBool()
                ? refs.first.id
                : null,
          );
        }
        if (c.job != null) {
          final tempo = Tempo.values[_random.nextInt(Tempo.values.length)];
          if (_random.nextInt(10) == 0 && engine.canSetTempo(tempo)) {
            return engine.setTempo(tempo);
          }
          if (engine.canRequest(promotion: true) && _random.nextInt(3) == 0) {
            return engine.requestPromotion();
          }
          if (engine.canRequest(promotion: false) && _random.nextInt(4) == 0) {
            return engine.requestRaise();
          }
        }
        if (businessMove(engine) case final next?) return next;
        if (romanceMove(engine) case final next?) return next;
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

  /// Aşk hamlesi: çoğu yıl ilişkiyi bir adım ilerletir (açıl, ciddileş,
  /// teklif, çocuk); bekârsa ara sıra biriyle tanışır ya da uygun biriyle
  /// buluşup yakınlaşır. Hamle yoksa null.
  LifeState? romanceMove(LifeEngine engine) {
    if (_random.nextInt(3) == 0) return null;
    const steps = {
      InteractionKind.acil,
      InteractionKind.ciddi,
      InteractionKind.teklif,
      InteractionKind.cocukIste,
    };
    final requests = engine.possibleInteractions();
    final step = requests.where((r) => steps.contains(r.kind)).toList();
    if (step.isNotEmpty) {
      return engine.interact(step[_random.nextInt(step.length)]);
    }
    final c = engine.state.character;
    if (!Romance.isSingle(c)) {
      // Sevgiliyle ya da eşle vakit geçir.
      final partner = Romance.partner(c) ?? Romance.spouse(c);
      final warm = requests
          .where(
            (r) =>
                r.personId == partner?.id &&
                (r.kind == InteractionKind.hediye ||
                    r.kind == InteractionKind.bulus ||
                    r.kind == InteractionKind.dertles),
          )
          .toList();
      return warm.isEmpty ? null : engine.interact(warm.first);
    }
    final courting = requests
        .where(
          (r) =>
              (r.kind == InteractionKind.bulus ||
                  r.kind == InteractionKind.hediye) &&
              Romance.canCourt(c, c.people[r.personId]!),
        )
        .toList();
    if (courting.isNotEmpty) {
      return engine.interact(courting[_random.nextInt(courting.length)]);
    }
    final meet = engine
        .availableActions()
        .where((a) => a.$2 && a.$1.id == 'tanis')
        .firstOrNull;
    return meet == null ? null : engine.doAction(meet.$1.id);
  }

  /// İşletme hamlesi: ara sıra işletme açar; açtıklarında fiyatı, başında
  /// durmayı, reklamı, büyütmeyi, ortaklığı ve satışı dener. Hamle yoksa
  /// null.
  LifeState? businessMove(LifeEngine engine) {
    final c = engine.state.character;
    if (c.businesses.length < BusinessRules.maxBusinesses &&
        _random.nextInt(c.job == null ? 8 : 30) == 0) {
      final open = [
        for (final (t, blocked) in engine.businessOptions())
          if (blocked == null) t,
      ];
      if (open.isNotEmpty) {
        // Yazılım açabilen çoğu zaman onu seçer (nadir yolun olayları da
        // denensin).
        final software = open.where((t) => t.id == 'yazilim').firstOrNull;
        final pick = software != null && _random.nextBool()
            ? software
            : open[_random.nextInt(open.length)];
        return engine.openBusiness(pick.id);
      }
    }
    for (final b in c.businesses) {
      switch (_random.nextInt(30)) {
        case 0 when engine.canSetBusinessPresent(b.id, !b.present):
          return engine.setBusinessPresent(b.id, !b.present);
        case 1:
          return engine.setBusinessPrice(
            b.id,
            PriceLevel.values[_random.nextInt(PriceLevel.values.length)],
          );
        case 2 || 3 when engine.canAdvertise(b.id):
          return engine.advertiseBusiness(b.id);
        case 4 || 5 when engine.canExpand(b.id):
          return engine.expandBusiness(b.id);
        case 6:
          final partners = engine.partnerCandidates(b.id);
          if (partners.isNotEmpty) {
            return engine.takePartner(b.id, partners.first.id);
          }
        case 7 when (b.lastProfit ?? 0) < 0:
          return engine.disposeBusiness(
            b.id,
            sell: BusinessRules.canSell(b) && _random.nextBool(),
          );
        case 8 || 9 || 10 when engine.canHireKnown(b.id):
          // Çoğunlukla akrabayı alır.
          final candidates = engine.hireCandidates(b.id);
          final kin = candidates.where((p) => p.kin != null).toList();
          final pick = kin.isNotEmpty ? kin.first : candidates.first;
          return engine.hireKnown(b.id, pick.id);
      }
    }
    return null;
  }

  /// YKS tercihi: çoğunlukla bir bölüme (rastgele), bazen başka yol.
  LifeState pickTercih(LifeEngine engine) {
    final placements = engine.tercihPlacements();
    if (placements.isNotEmpty && _random.nextInt(4) > 0) {
      // Bilgisayara yetiyorsa çoğu zaman onu seçer: nadir yazılım yolunun
      // olayları da test hayatlarında denensin.
      final computer = placements.where((p) => p.$1.id == 'bilgisayar');
      if (computer.isNotEmpty && _random.nextBool()) {
        final (d, city) = computer.first;
        return engine.enroll(d.id, city);
      }
      final (d, city) = placements[_random.nextInt(placements.length)];
      return engine.enroll(d.id, city);
    }
    const others = [TercihKind.mezunaKal, TercihKind.calis, TercihKind.cirak];
    return engine.declineTercih(others[_random.nextInt(others.length)]);
  }

  /// En yüksek giriş maaşlı ilan.
  static JobListing bestListing(LifeEngine engine, List<JobListing> open) {
    int salary(JobListing l) =>
        engine.careers.require(l.careerId).tier(l.tier).salary;
    return open.reduce((a, b) => salary(b) > salary(a) ? b : a);
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
    // Öğrenci yarı yarıya ders çalışır: eğlence aksiyonları çoğalınca
    // bölümler (ve yazılım yolu) test hayatlarında kaybolmasın.
    final study = enabled.where((a) => a.id == 'ders_calis').firstOrNull;
    if (study != null && _random.nextBool()) return study.id;
    // Yazılım kursu nadir yazılımcı ve yazılım işletmesi yolunu açar.
    final course = enabled.where((a) => a.id == 'yazilim_kursu').firstOrNull;
    if (course != null && _random.nextBool()) return course.id;
    return enabled[_random.nextInt(enabled.length)].id;
  }
}
