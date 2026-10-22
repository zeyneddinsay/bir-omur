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
        return engine.openBusiness(open[_random.nextInt(open.length)].id);
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
          return engine.disposeBusiness(b.id, sell: _random.nextBool());
      }
    }
    return null;
  }

  /// YKS tercihi: çoğunlukla bir bölüme (rastgele), bazen başka yol.
  LifeState pickTercih(LifeEngine engine) {
    final placements = engine.tercihPlacements();
    if (placements.isNotEmpty && _random.nextInt(4) > 0) {
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
    return enabled[_random.nextInt(enabled.length)].id;
  }
}
