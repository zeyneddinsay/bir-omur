// Denge raporu: gerçek kartlarla çok sayıda hayatı rastgele bir oyuncuyla
// oynatır ve özet istatistikleri yazar.
//
// Kullanım (proje kökünden):
//   dart run tools/life_report/bin/life_report.dart [hayat sayısı] [ilk tohum]
//
// Rastgele oyuncu gerçek oyuncudan kötü oynar (her kartta yazı tura atar);
// sonuçlar dengenin yönünü gösterir, mutlak değerini değil.
import 'dart:io';
import 'dart:math';

import 'package:bir_omur/content/disk_content_source.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';

void main(List<String> args) {
  final lives = args.isNotEmpty ? int.parse(args[0]) : 500;
  final firstSeed = args.length > 1 ? int.parse(args[1]) : 0;

  final content = loadContentFromDisk();
  final deck = content.deck;

  final deathAges = <int>[];
  final netWorths = <int>[];
  final nicknames = <Nickname, int>{};
  final causes = <DeathCause, int>{};
  final seenCards = <String, int>{};
  var everInDebt = 0;
  var everDepressed = 0;
  var homeOwners = 0;
  var goldOwners = 0;
  var carOwners = 0;
  final lastCareer = <String, int>{};
  final worthByBackground = <FamilyBackground, List<int>>{};
  var counterSum = LifeCounters.zero;
  final badgeCounts = <String, int>{};
  final badges = content.achievements ?? AchievementBook.empty;
  final statSums = <StatKind, int>{for (final k in StatKind.values) k: 0};
  final statHigh = <StatKind, int>{for (final k in StatKind.values) k: 0};
  final topTier = <String, int>{};
  var retiredEarly = 0;
  final people = _PeopleStats();
  final biz = _BusinessStats();
  var hardYears = 0;
  var livesWithHardDay = 0;
  var livesWithTrueFriend = 0;
  var worldSmall = 0;
  var married = 0;
  var divorced = 0;
  var children = 0;
  final marriageAges = <int>[];

  for (var i = 0; i < lives; i++) {
    final seed = firstSeed + i;
    final engine = LifeEngine(
      deck: deck,
      seed: seed,
      careers: content.careers,
      families: content.families,
      interactions: content.interactions,
    );
    final player = _RandomPlayer(seed);
    var inDebt = false;
    var depressed = false;
    Job? lastJob;
    var retireAge = 0;
    engine.startLife();
    var age = engine.state.character.age;
    var hadHardDay = false;
    var worldSeen = 0;
    while (!engine.state.isOver) {
      player.step(engine);
      final worldNow = engine.state.notes
          .where((n) => n.kind == NoteKind.dunyaKucuk)
          .length;
      final newYear = engine.state.character.age != age;
      worldSmall += newYear ? worldNow : max(0, worldNow - worldSeen);
      worldSeen = worldNow;
      if (newYear) {
        age = engine.state.character.age;
        biz.addNotes(engine.state.notes);
        final notes = engine.state.notes;
        if (notes.any((n) => n.kind == NoteKind.zorGun)) {
          hardYears++;
          hadHardDay = true;
        }
      }
      final flags = engine.state.character.flags;
      inDebt |= flags.contains(EngineFlags.borclu);
      depressed |= flags.contains(EngineFlags.bunalim);
      final c = engine.state.character;
      if (c.job != null) lastJob = c.job;
      if (c.isRetired && retireAge == 0) retireAge = c.age;
    }
    final summary = engine.state.summary!;
    final c = summary.character;
    people.add(c, interactions: player.interactions);
    biz.addLife(c, opened: player.openedBusinesses);
    if (hadHardDay) livesWithHardDay++;
    if (HardDay.trueFriends(c).isNotEmpty) livesWithTrueFriend++;
    final spouses = c.people.all.where(
      (p) => p.kin == Kinship.es || p.bond == Bond.eskiEs,
    );
    if (spouses.isNotEmpty) married++;
    if (c.people.all.any((p) => p.bond == Bond.eskiEs)) divorced++;
    children += c.people.all.where((p) => p.kin == Kinship.cocuk).length;
    for (final s in spouses) {
      final m = s.memories.where((m) => m.kind == 'evlendik').firstOrNull;
      if (m != null) marriageAges.add(m.age);
    }
    deathAges.add(summary.deathAge);
    netWorths.add(summary.netWorth);
    for (final a in badges.earnedBy(summary)) {
      badgeCounts.update(a.id, (n) => n + 1, ifAbsent: () => 1);
    }
    final k = c.counters;
    counterSum = LifeCounters(
      moves: counterSum.moves + k.moves,
      rentPaid: counterSum.rentPaid + k.rentPaid,
      goldReceived: counterSum.goldReceived + k.goldReceived,
      promotions: counterSum.promotions + k.promotions,
      yearsWorked: counterSum.yearsWorked + k.yearsWorked,
      lifetimeIncome: counterSum.lifetimeIncome + k.lifetimeIncome,
      debtSpells: counterSum.debtSpells + k.debtSpells,
    );
    for (final k in StatKind.values) {
      statSums.update(k, (v) => v + c.stats[k]);
      if (c.stats[k] >= SummaryBuilder.statThreshold) {
        statHigh.update(k, (v) => v + 1);
      }
    }
    worthByBackground.putIfAbsent(c.background, () => []).add(summary.netWorth);
    nicknames.update(summary.nickname, (n) => n + 1, ifAbsent: () => 1);
    causes.update(summary.cause, (n) => n + 1, ifAbsent: () => 1);
    for (final r in c.history) {
      seenCards.update(r.cardId, (n) => n + 1, ifAbsent: () => 1);
    }
    if (inDebt) everInDebt++;
    if (depressed) everDepressed++;
    if (c.assets.houses > 0) homeOwners++;
    if (c.assets.goldGrams > 0) goldOwners++;
    if (c.assets.cars > 0) carOwners++;
    final careerId = lastJob?.careerId ?? '(hiç çalışmadı)';
    lastCareer.update(careerId, (n) => n + 1, ifAbsent: () => 1);
    if (lastJob != null) {
      topTier.update(
        careerId,
        (n) => n + lastJob!.tier,
        ifAbsent: () => lastJob!.tier,
      );
    }
    if (retireAge > 0 && retireAge < Careers.retireAge) retiredEarly++;
  }

  String pct(int n) => '%${(100 * n / lives).toStringAsFixed(0)}';
  String tl(int v) => '${(v / 1000).round()} bin';

  deathAges.sort();
  netWorths.sort();
  int at(List<int> sorted, double q) =>
      sorted[(q * (sorted.length - 1)).round()];

  stdout
    ..writeln('$lives hayat (tohum $firstSeed–${firstSeed + lives - 1})')
    ..writeln()
    ..writeln(
      'Ölüm yaşı   ortalama ${(deathAges.reduce((a, b) => a + b) / lives).toStringAsFixed(1)}'
      ', en düşük ${deathAges.first}, medyan ${at(deathAges, 0.5)}, en yüksek ${deathAges.last}',
    )
    ..writeln(
      'Ölüm sebebi ${causes.entries.map((e) => '${e.key.name} ${pct(e.value)}').join(', ')}',
    )
    ..writeln()
    ..writeln(
      'Net servet  %10: ${tl(at(netWorths, 0.1))}, medyan: ${tl(at(netWorths, 0.5))}, '
      '%90: ${tl(at(netWorths, 0.9))} TL',
    )
    ..writeln(
      'Ölürken     ev sahibi ${pct(homeOwners)}, altını olan ${pct(goldOwners)}, '
      'arabası olan ${pct(carOwners)}',
    )
    ..writeln(
      'Zor dönem   en az bir kez borçlu ${pct(everInDebt)}, bunalım ${pct(everDepressed)}',
    )
    ..writeln()
    ..writeln(
      'Ölürken gösterge ortalaması (80 ve üstü olanlar): '
      '${StatKind.values.map((k) => '${k.key} ${(statSums[k]! / lives).round()} (${pct(statHigh[k]!)})').join(', ')}',
    )
    ..writeln()
    ..writeln(
      'Hayatın sayıları (ortalama): taşınma ${(counterSum.moves / lives).toStringAsFixed(1)}, '
      'kira ${tl(counterSum.rentPaid ~/ lives)}, takılan altın ${counterSum.goldReceived ~/ lives} gr, '
      'terfi ${(counterSum.promotions / lives).toStringAsFixed(1)}, çalışılan yıl ${counterSum.yearsWorked ~/ lives}, '
      'borç dönemi ${(counterSum.debtSpells / lives).toStringAsFixed(1)}',
    )
    ..writeln()
    ..writeln('Aileye göre medyan net servet:');
  for (final b in FamilyBackground.values) {
    final worths = (worthByBackground[b] ?? [])..sort();
    if (worths.isEmpty) continue;
    stdout.writeln(
      '  ${b.id.padRight(24)} ${pct(worths.length)}, ${tl(at(worths, 0.5))} TL',
    );
  }
  stdout
    ..writeln()
    ..writeln('Meslek (son iş, ortalama son kademe):');
  for (final e
      in lastCareer.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))) {
    final avgTier = topTier[e.key] == null
        ? ''
        : ', kademe ${(topTier[e.key]! / e.value).toStringAsFixed(1)}';
    stdout.writeln('  ${e.key.padRight(24)} ${pct(e.value)}$avgTier');
  }
  stdout
    ..writeln('Erken emekli ${pct(retiredEarly)}')
    ..writeln()
    ..writeln('Lakaplar:');
  for (final e
      in nicknames.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value))) {
    stdout.writeln('  ${e.key.name.padRight(24)} ${pct(e.value)}');
  }

  final unseen = [
    for (final card in deck.cards)
      if (!seenCards.containsKey(card.id)) card.id,
  ];
  stdout
    ..writeln()
    ..writeln(
      'Hiç gelmeyen kartlar (${unseen.length}): ${unseen.isEmpty ? '-' : unseen.join(', ')}',
    )
    ..writeln()
    ..writeln('Rozetler (kazanan hayat oranı):');
  for (final a in badges.all) {
    stdout.writeln('  ${a.id.padRight(28)} ${pct(badgeCounts[a.id] ?? 0)}');
  }
  people.write(lives);
  biz.write(lives);
  stdout
    ..writeln()
    ..writeln(
      'Zor gün: hayat başına ${(hardYears / lives).toStringAsFixed(1)} yıl, '
      'en az bir kez ${pct(livesWithHardDay)}, gerçek dostu olan ${pct(livesWithTrueFriend)}; '
      'dünya küçük tesadüfü hayat başına ${(worldSmall / lives).toStringAsFixed(1)}',
    );
  marriageAges.sort();
  stdout.writeln(
    'Aşk: evlenen ${pct(married)}, boşanan ${pct(divorced)}, '
    'hayat başına çocuk ${(children / lives).toStringAsFixed(1)}'
    '${marriageAges.isEmpty ? '' : ', medyan evlilik yaşı ${marriageAges[marriageAges.length ~/ 2]}'}',
  );
}

/// Açık ilanlardan biri şu anki işten daha iyi mi.
bool _betterThanCurrent(LifeEngine engine, List<JobListing> open) {
  final job = engine.state.character.job!;
  final current = engine.careers.require(job.careerId).tier(job.tier).salary;
  return open.any(
    (l) => engine.careers.require(l.careerId).tier(l.tier).salary > current,
  );
}

/// En yüksek giriş maaşlı ilan.
JobListing bestListing(LifeEngine engine, List<JobListing> open) {
  int salary(JobListing l) =>
      engine.careers.require(l.careerId).tier(l.tier).salary;
  return open.reduce((a, b) => salary(b) > salary(a) ? b : a);
}

/// Her kartta rastgele bir yön seçen, yılların çoğunda rastgele aksiyon
/// yapan oyuncu.
class _RandomPlayer {
  _RandomPlayer(int seed) : _random = Random(seed);

  final Random _random;

  /// Bu hayatta yapılan etkileşim sayısı.
  int interactions = 0;

  /// Bu hayatta açılan işletme türleri.
  final List<String> openedBusinesses = [];

  /// Aşk hamlesi (test oyuncusundaki gibi): ilişkiyi ilerletir, sevgiliyle
  /// vakit geçirir, bekârsa yakınlaşır ya da biriyle tanışır.
  bool _romanceMove(LifeEngine engine) {
    if (_random.nextInt(3) == 0) return false;
    const steps = {
      InteractionKind.acil,
      InteractionKind.ciddi,
      InteractionKind.teklif,
      InteractionKind.cocukIste,
    };
    final requests = engine.possibleInteractions();
    final step = requests.where((r) => steps.contains(r.kind)).toList();
    if (step.isNotEmpty) {
      engine.interact(step[_random.nextInt(step.length)]);
      interactions++;
      return true;
    }
    final c = engine.state.character;
    if (!Romance.isSingle(c)) {
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
      if (warm.isEmpty) return false;
      engine.interact(warm.first);
      interactions++;
      return true;
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
      engine.interact(courting[_random.nextInt(courting.length)]);
      interactions++;
      return true;
    }
    final meet = engine
        .availableActions()
        .where((a) => a.$2 && a.$1.id == 'tanis')
        .firstOrNull;
    if (meet == null) return false;
    engine.doAction(meet.$1.id);
    return true;
  }

  /// Akıllıca işletme: parası kuruluşun iki katıysa ara sıra beklenen kârı
  /// en yüksek türü açar; iki yıl üst üste zarar edeni satar; kâr edeni
  /// reklamla ve şubeyle büyütür.
  bool _businessMove(LifeEngine engine) {
    final c = engine.state.character;
    for (final b in c.businesses) {
      final losing =
          b.profits.length >= 2 &&
          b.profits.reversed.take(2).every((p) => p < 0);
      if (losing) {
        engine.disposeBusiness(b.id, sell: BusinessRules.canSell(b));
        return true;
      }
      if (engine.canHireKnown(b.id) && _random.nextInt(4) == 0) {
        final candidates = engine.hireCandidates(b.id);
        final kin = candidates.where((p) => p.kin != null).toList();
        engine.hireKnown(b.id, (kin.isNotEmpty ? kin : candidates).first.id);
        return true;
      }
      final partners = engine.partnerCandidates(b.id);
      if (partners.isNotEmpty && _random.nextInt(8) == 0) {
        engine.takePartner(b.id, partners.first.id);
        return true;
      }
      if (!b.present &&
          BusinessTypes.require(b.type).laborBound &&
          !c.businesses.any((x) => x.present) &&
          engine.canSetBusinessPresent(b.id, true)) {
        engine.setBusinessPresent(b.id, true);
        return true;
      }
      if ((b.lastProfit ?? 0) > 0 &&
          engine.canExpand(b.id) &&
          _random.nextInt(3) == 0) {
        engine.expandBusiness(b.id);
        return true;
      }
      if (engine.canAdvertise(b.id) &&
          b.reputation < 60 &&
          _random.nextInt(3) == 0) {
        engine.advertiseBusiness(b.id);
        return true;
      }
    }
    if (c.businesses.length < BusinessRules.maxBusinesses &&
        _random.nextInt(c.job == null ? 6 : 25) == 0) {
      final open = [
        for (final (t, blocked) in engine.businessOptions())
          if (blocked == null && c.stats.money >= t.setupCost * 2) t,
      ];
      if (open.isNotEmpty) {
        final t = open[_random.nextInt(open.length)];
        engine.openBusiness(t.id);
        openedBusinesses.add(t.id);
        return true;
      }
    }
    return false;
  }

  void step(LifeEngine engine) {
    final state = engine.state;
    switch (state.phase) {
      case YearPhase.cards:
        final sides = [
          ChoiceSide.left,
          ChoiceSide.right,
          if (state.currentEvent!.card.up != null) ChoiceSide.up,
        ];
        engine.choose(sides[_random.nextInt(sides.length)]);
      case YearPhase.actions:
        if (state.character.hasFlag(EducationRules.pendingFlag)) {
          final placements = engine.tercihPlacements();
          if (placements.isNotEmpty && _random.nextInt(4) > 0) {
            final (d, city) = placements[_random.nextInt(placements.length)];
            engine.enroll(d.id, city);
          } else {
            const others = [
              TercihKind.mezunaKal,
              TercihKind.calis,
              TercihKind.cirak,
            ];
            engine.declineTercih(others[_random.nextInt(others.length)]);
          }
          return;
        }
        // Yaşlılıkta ara sıra memlekete döner.
        final me0 = engine.state.character;
        if (me0.age >= 60 &&
            me0.city != me0.hometown &&
            _random.nextInt(15) == 0 &&
            engine.moveOptions().any(
              (o) => o.$1 == me0.hometown && o.$2 == null,
            )) {
          engine.moveTo(me0.hometown, withFamily: true);
          return;
        }
        if (_random.nextInt(200) == 0) {
          final cities = [
            for (final (city, blocked, _) in engine.moveOptions())
              if (blocked == null) city,
          ];
          if (cities.isNotEmpty) {
            engine.moveTo(
              cities[_random.nextInt(cities.length)],
              withFamily: _random.nextBool(),
            );
            return;
          }
        }
        final open = [
          for (final (l, blocked) in engine.listingOptions())
            if (blocked == null) l,
        ];
        final me = engine.state.character;
        if (open.isNotEmpty &&
            (me.job == null
                ? _random.nextInt(3) > 0
                : _betterThanCurrent(engine, open) &&
                      _random.nextInt(3) == 0)) {
          // Çoğunlukla en yüksek maaşlı ilana başvurur.
          final listing = _random.nextInt(4) > 0
              ? bestListing(engine, open)
              : open[_random.nextInt(open.length)];
          final refs = engine.listingReferences(listing);
          engine.applyFor(
            listing,
            _random.nextBool() ? ChoiceSide.left : ChoiceSide.right,
            referenceId: refs.isNotEmpty && _random.nextBool()
                ? refs.first.id
                : null,
          );
          return;
        }
        if (me.job != null) {
          final tempo = Tempo.values[_random.nextInt(Tempo.values.length)];
          if (_random.nextInt(10) == 0 && engine.canSetTempo(tempo)) {
            engine.setTempo(tempo);
            return;
          }
          if (engine.canRequest(promotion: true) && _random.nextInt(3) == 0) {
            engine.requestPromotion();
            return;
          }
          if (engine.canRequest(promotion: false) && _random.nextInt(4) == 0) {
            engine.requestRaise();
            return;
          }
        }
        if (_businessMove(engine)) return;
        if (_romanceMove(engine)) return;
        final requests = engine.possibleInteractions();
        if (requests.isNotEmpty && _random.nextBool()) {
          engine.interact(requests[_random.nextInt(requests.length)]);
          interactions++;
          return;
        }
        // Akıllıca: mezunsa KPSS'ye girer; parası yetmeden evden çıkmaz,
        // ev ve araba almaz.
        final money = engine.state.character.stats.money;
        final enabled = [
          for (final (action, ok) in engine.availableActions())
            if (ok &&
                (action.special == null ||
                    action.special == ActionSpecial.kpss ||
                    action.special == ActionSpecial.yazilimKursu ||
                    money > 3000000))
              action,
        ];
        final kpss = enabled.where((a) => a.id == 'kpss').firstOrNull;
        if (kpss != null) {
          engine.doAction(kpss.id);
        } else if (enabled.isNotEmpty && _random.nextInt(4) > 0) {
          engine.doAction(enabled[_random.nextInt(enabled.length)].id);
        } else {
          engine.advanceYear();
        }
      case YearPhase.dead:
        break;
    }
  }
}

/// Kişiler, hafıza ve olay akışı (D1). Hayat sonundaki duruma bakar.
class _PeopleStats {
  int _known = 0;
  int _dead = 0;
  int _active = 0;
  int _archived = 0;
  int _friends = 0;
  int _hostile = 0;
  int _livesWithHostile = 0;
  int _memories = 0;
  int _interactions = 0;
  int _events = 0;
  int _years = 0;
  int _emptyYears = 0;
  int _funerals = 0;
  int _reached19 = 0;
  int _universityStarted = 0;
  int _graduated = 0;
  int _men41 = 0;
  int _bedelli = 0;
  int _served = 0;

  static const _funeralIds = {
    'cenaze_cocuk',
    'cenaze_akraba',
    'cenaze_ebeveyn',
  };

  void add(Character c, {required int interactions}) {
    final now = c.age;
    final known = c.people.bornBy(now).toList();
    _known += known.length;
    _dead += known.where((p) => !p.isAlive).length;
    final active = c.people.active(now).toList();
    _active += active.length;
    _archived += known.where((p) => p.isAlive && p.archived).length;
    _friends += active
        .where((p) => Relationships.colorOf(p, now) == RelationColor.dost)
        .length;
    final hostile = active.where((p) => Relationships.isHostile(p, now)).length;
    _hostile += hostile;
    if (hostile > 0) _livesWithHostile++;
    _memories += known.fold(0, (s, p) => s + p.memories.length);
    _interactions += interactions;

    _events += c.history.length;
    final eventAges = {for (final r in c.history) r.age};
    for (var age = 3; age < now; age++) {
      _years++;
      if (!eventAges.contains(age)) _emptyYears++;
    }
    _funerals += c.history.where((r) => _funeralIds.contains(r.cardId)).length;

    if (now > 19) {
      _reached19++;
      if (c.education.uniStartAge != null && !c.education.openEducation) {
        _universityStarted++;
      }
      if (c.hasFlag('universite_mezunu')) _graduated++;
    }
    if (c.gender == Gender.erkek && now > 41) {
      _men41++;
      if (c.hasFlag('bedelli')) _bedelli++;
      if (c.hasFlag('asker_anilari')) _served++;
    }
  }

  void write(int lives) {
    String avg(int n) => (n / lives).toStringAsFixed(1);
    String share(int n, int of) =>
        of == 0 ? '-' : '%${(100 * n / of).toStringAsFixed(0)}';
    stdout
      ..writeln()
      ..writeln('Kişiler (hayat sonunda, ortalama):')
      ..writeln(
        '  tanınan ${avg(_known)}, vefat eden ${avg(_dead)}, aktif ${avg(_active)}, '
        'eski tanıdık ${avg(_archived)}',
      )
      ..writeln(
        '  dost ${avg(_friends)}, husumetli ${avg(_hostile)} '
        '(en az bir husumetlisi olan hayat ${share(_livesWithHostile, lives)})',
      )
      ..writeln(
        '  anı ${avg(_memories)} (kişi başına '
        '${(_memories / (_known == 0 ? 1 : _known)).toStringAsFixed(2)}), '
        'etkileşim ${avg(_interactions)}',
      )
      ..writeln()
      ..writeln('Olay akışı:')
      ..writeln(
        '  hayat başına ${avg(_events)} olay, yılda '
        '${(_events / (_years == 0 ? 1 : _years)).toStringAsFixed(2)}; '
        '3 yaştan sonra olaysız yıl ${share(_emptyYears, _years)}',
      )
      ..writeln('  cenaze kartı hayat başına ${avg(_funerals)}')
      ..writeln(
        '  19 yaşını görenlerde üniversite ${share(_universityStarted, _reached19)}, '
        'mezun ${share(_graduated, _reached19)}',
      )
      ..writeln(
        '  41 yaşını gören erkeklerde askerlik yaparak ${share(_served, _men41)}, '
        'bedelli ${share(_bedelli, _men41)}',
      );
  }
}

/// İşletmeler (D3): açılan, batan, yaşayan ve türlere göre yıllık kâr.
class _BusinessStats {
  var _livesWithBusiness = 0;
  var _heldAtDeath = 0;
  final _opened = <String, int>{};
  final _bankrupt = <String, int>{};
  final _profitSum = <String, int>{};
  final _years = <String, int>{};
  final _losingYears = <String, int>{};

  void addNotes(List<LifeNote> notes) {
    for (final n in notes) {
      if (n.kind == NoteKind.isletmeYili) {
        final [type, amount] = n.detail!.split('|');
        final profit = int.parse(amount);
        _profitSum.update(type, (v) => v + profit, ifAbsent: () => profit);
        _years.update(type, (v) => v + 1, ifAbsent: () => 1);
        if (profit < 0) {
          _losingYears.update(type, (v) => v + 1, ifAbsent: () => 1);
        }
      } else if (n.kind == NoteKind.isletmeBatti) {
        _bankrupt.update(n.detail!, (v) => v + 1, ifAbsent: () => 1);
      }
    }
  }

  void addLife(Character c, {required List<String> opened}) {
    if (opened.isNotEmpty) _livesWithBusiness++;
    if (c.businesses.isNotEmpty) _heldAtDeath++;
    for (final t in opened) {
      _opened.update(t, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  void write(int lives) {
    String pct(int n, int of) =>
        of == 0 ? '-' : '%${(100 * n / of).toStringAsFixed(0)}';
    stdout
      ..writeln()
      ..writeln(
        'İşletmeler: işletme açan hayat ${pct(_livesWithBusiness, lives)}, '
        'ölürken işletmesi olan ${pct(_heldAtDeath, lives)}',
      );
    final types = {..._opened.keys, ..._years.keys}.toList()..sort();
    for (final t in types) {
      final years = _years[t] ?? 0;
      final avg = years == 0 ? 0 : (_profitSum[t] ?? 0) ~/ years;
      stdout.writeln(
        '  ${t.padRight(14)} açılış ${_opened[t] ?? 0}, batış ${_bankrupt[t] ?? 0}, '
        'yıl $years, ortalama kâr ${(avg / 1000).round()} bin, '
        'zarar yılı ${pct(_losingYears[t] ?? 0, years)}',
      );
    }
  }
}
