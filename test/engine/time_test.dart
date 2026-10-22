import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../content/real_cards_test.dart' show loadRealContent;
import '../helpers/test_character.dart';

void main() {
  final content = loadRealContent();

  /// İşi olan, aksiyon aşamasında 19 yaşında bir hayat.
  LifeEngine working() {
    for (var seed = 0; seed < 200; seed++) {
      final e = LifeEngine(
        deck: EventDeck(const []),
        seed: seed,
        careers: content.careers,
        families: content.families,
      )..startLife();
      while (e.state.character.age < 19) {
        e.advanceYear();
      }
      final open = [
        for (final (l, blocked) in e.listingOptions())
          if (blocked == null) l,
      ];
      for (final l in open) {
        e.applyFor(l, ChoiceSide.left);
        if (e.state.character.job != null) return e;
        if (e.state.timeLeft == 0) break;
      }
    }
    throw StateError('İşe giren hayat bulunamadı');
  }

  test('vakit harcanandan hesaplanır: tempo düğmesiyle vakit kazanılmaz', () {
    final e = working();
    // Vakti bitir.
    while (e.state.timeLeft > 0) {
      final action = e.availableActions().where((a) => a.$2).first.$1;
      e.doAction(action.id);
    }
    expect(e.canSetTempo(Tempo.yukle), isFalse, reason: 'yüklenmek 1 vakit');
    expect(() => e.setTempo(Tempo.yukle), throwsStateError);
    e.setTempo(Tempo.rahat);
    expect(e.state.timeLeft, 0, reason: 'rahat tempo vakit vermez');
    e.setTempo(Tempo.normal);
    expect(e.state.timeLeft, 0);
  });

  test('iş okuldan önce gelir: çalışan açıköğretimli 3 vakit alır', () {
    final c = testCharacter(
      age: 22,
      flags: {ActionCatalog.studentFlag},
      job: const Job(careerId: 'garson', tier: 1),
    );
    expect(ActionCatalog.timeFor(c), 3);
    expect(
      ActionCatalog.byId('yarim_zamanli')!.isAvailableFor(c),
      isFalse,
      reason: 'işi olana yarı zamanlı iş yok',
    );
  });

  test('lisede (YKS yılı dahil) tam zamanlı ilan yok', () {
    expect(
      JobMarket.listingsFor(
        testCharacter(age: EducationRules.yksAge),
        content.careers,
        SeededRandom(1),
      ),
      isEmpty,
    );
  });

  test('askerdeki yıl maaş, kıdem ve yaşam gideri işlemez', () {
    const job = Job(careerId: 'garson', tier: 1, yearsInTier: 2);
    final soldier = testCharacter(
      age: 21,
      money: 0,
      job: job,
      home: HomeKind.kira,
      flags: {'askerde'},
    );
    final (c, report) = CareerTick(
      SeededRandom(1),
      content.careers,
    ).apply(soldier);
    expect(report.income, 0);
    expect(c.job, job);
    expect(DeathCheck.probability(soldier), 0);
  });
}
