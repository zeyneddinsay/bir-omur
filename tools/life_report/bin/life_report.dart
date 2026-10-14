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
  final statSums = <StatKind, int>{for (final k in StatKind.values) k: 0};
  final statHigh = <StatKind, int>{for (final k in StatKind.values) k: 0};
  final topTier = <String, int>{};
  var retiredEarly = 0;

  for (var i = 0; i < lives; i++) {
    final seed = firstSeed + i;
    final engine = LifeEngine(deck: deck, seed: seed, careers: content.careers);
    final player = _RandomPlayer(seed);
    var inDebt = false;
    var depressed = false;
    Job? lastJob;
    var retireAge = 0;
    engine.startLife();
    while (!engine.state.isOver) {
      player.step(engine);
      final flags = engine.state.character.flags;
      inDebt |= flags.contains(EngineFlags.borclu);
      depressed |= flags.contains(EngineFlags.bunalim);
      final c = engine.state.character;
      if (c.job != null) lastJob = c.job;
      if (c.isRetired && retireAge == 0) retireAge = c.age;
    }
    final summary = engine.state.summary!;
    final c = summary.character;
    deathAges.add(summary.deathAge);
    netWorths.add(summary.netWorth);
    for (final k in StatKind.values) {
      statSums.update(k, (v) => v + c.stats[k]);
      if (c.stats[k] >= SummaryBuilder.statThreshold)
        statHigh.update(k, (v) => v + 1);
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
    );
}

/// Her kartta rastgele bir yön seçen, yılların çoğunda rastgele aksiyon
/// yapan oyuncu.
class _RandomPlayer {
  _RandomPlayer(int seed) : _random = Random(seed);

  final Random _random;

  void step(LifeEngine engine) {
    final state = engine.state;
    switch (state.phase) {
      case YearPhase.cards:
        final sides = [
          ChoiceSide.left,
          ChoiceSide.right,
          if (state.currentCard!.up != null) ChoiceSide.up,
        ];
        engine.choose(sides[_random.nextInt(sides.length)]);
      case YearPhase.actions:
        final enabled = [
          for (final (action, ok) in engine.availableActions())
            if (ok) action,
        ];
        if (enabled.isNotEmpty && _random.nextInt(4) > 0) {
          engine.doAction(enabled[_random.nextInt(enabled.length)].id);
        } else {
          engine.advanceYear();
        }
      case YearPhase.dead:
        break;
    }
  }
}
