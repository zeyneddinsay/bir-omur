import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  const good = Memory(
    kind: 'iyi',
    label: 'İyi gün',
    age: 20,
    tone: MemoryTone.olumlu,
    severity: 3,
  );

  group('zor gün', () {
    final c = testCharacter(age: 40);

    (HardDayCause, String?)? cause({
      int before = 100,
      int after = 100,
      bool fired = false,
      bool bankrupt = false,
      List<String> deaths = const [],
      Character? character,
    }) => HardDay.causeOf(
      before: c,
      after: character ?? c,
      worthBefore: before,
      worthAfter: after,
      fired: fired,
      bankrupt: bankrupt,
      deaths: deaths,
    );

    test('sebepler: borç, kovulma, iflas, yakının vefatı', () {
      expect(cause(), isNull);
      expect(cause(after: -1)?.$1, HardDayCause.borc);
      expect(cause(before: -5, after: -10), isNull, reason: 'zaten borçluydu');
      expect(cause(fired: true)?.$1, HardDayCause.kovuldun);
      expect(cause(bankrupt: true)?.$1, HardDayCause.iflas);
      final mother = testPerson(
        'p1',
        kin: Kinship.anne,
        age: 70,
        playerAge: 40,
      ).copyWith(diedAt: 40);
      final withMother = withPeople(c, [mother]);
      expect(cause(deaths: ['p1'], character: withMother), (
        HardDayCause.vefat,
        'p1',
      ));
    });

    test('yakın arayabilir; aramayan arkadaşa anı yazılır', () {
      final friend = testPerson(
        'p1',
        bond: Bond.arkadas,
        base: 90,
        memories: [good],
        playerAge: 40,
      );
      final cold = testPerson(
        'p2',
        bond: Bond.arkadas,
        base: 10,
        playerAge: 40,
      );
      final life = withPeople(c, [friend, cold]);
      final callers = HardDay.callers(life, SeededRandom(1), HardDayCause.borc);
      expect(callers.map((p) => p.id), isNot(contains('p2')));
      final marked = HardDay.markMissed(life, {for (final p in callers) p.id});
      expect(
        marked.people['p2']!.memories.any(
          (m) => m.kind == HardDay.missedMemory,
        ),
        isTrue,
      );
    });
  });

  test('hayat hikâyesi: yanındaki, gerçek dost, kurduğu işler', () {
    final child = testPerson(
      'p1',
      name: 'Zeynep',
      kin: Kinship.cocuk,
      age: 40,
      playerAge: 70,
      base: 80,
    );
    final friend = testPerson(
      'p2',
      name: 'Ayşe',
      age: 70,
      playerAge: 70,
      base: 70,
      memories: const [
        Memory(
          kind: HardDay.talkedMemory,
          label: 'Zor gününde aradım',
          age: 50,
          tone: MemoryTone.olumlu,
          severity: 3,
        ),
      ],
    );
    final c = withPeople(testCharacter(age: 70), [
      child,
      friend,
    ]).copyWith(bankruptcies: {'simit': 40}, businessExits: {'berber': 55});
    final story = LifeStory(c);
    expect(story.bedside?.id, 'p1');
    expect(story.trueFriends.map((p) => p.name), ['Ayşe']);
    expect(story.mourners, hasLength(2));
    expect(story.businesses, {
      'simit': BusinessEnd.batti,
      'berber': BusinessEnd.birakildi,
    });
  });
}
