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
      final renter = testCharacter(age: 40, home: HomeKind.kira);
      expect(cause(after: -1, character: renter), isNull, reason: 'küçük eksi');
      expect(cause(after: -200000, character: renter)?.$1, HardDayCause.borc);
      expect(
        cause(after: -200000),
        isNull,
        reason: 'aileyle yaşayan borç zor günü yaşamaz',
      );
      expect(
        cause(before: -5, after: -200000, character: renter),
        isNull,
        reason: 'zaten borçluydu',
      );
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
      // Kimse aramadıysa: yakın arkadaşa anı yazılır, uzak tanıdığa yazılmaz;
      // aynı kişiye 5 yılda bir.
      final marked = HardDay.markMissed(life, const {});
      int missed(Character x, String id) => x.people[id]!.memories
          .where((m) => m.kind == HardDay.missedMemory)
          .length;
      expect(missed(marked, 'p1'), 1);
      expect(missed(marked, 'p2'), 0);
      expect(missed(HardDay.markMissed(marked, const {}), 'p1'), 1);
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

  group('ileri yaşta evlilik ve miras', () {
    // Ölüm 85 yaşında; eş 30 yaş küçük, iki yetişkin çocuk.
    Character life({
      Set<String> flags = const {LifeStory.lateMarriageFlag},
      int grudge = 0,
    }) => withPeople(testCharacter(age: 85, flags: flags), [
      testPerson(
        'p1',
        name: 'Leyla',
        gender: Gender.kadin,
        kin: Kinship.es,
        age: 55,
        playerAge: 85,
        base: 70,
      ),
      testPerson(
        'p2',
        name: 'Mert',
        kin: Kinship.cocuk,
        age: 55,
        playerAge: 85,
        base: 20,
        memories: [
          if (grudge > 0)
            testMemory('yeni_esi_secti', severity: grudge, age: 84),
        ],
      ),
      testPerson(
        'p3',
        name: 'Selin',
        gender: Gender.kadin,
        kin: Kinship.cocuk,
        age: 52,
        playerAge: 85,
        base: 20,
      ),
    ]);

    test('yakınlığı düşük çocuk da cenazeye gelir; küs olan gelmez', () {
      final calm = LifeStory(life());
      expect(calm.absentChildren, isEmpty);
      expect(calm.mourners.map((p) => p.name), containsAll(['Mert', 'Selin']));
      expect(calm.inheritance, isNull, reason: 'kırgınlık yok');

      final rift = LifeStory(life(grudge: 3));
      expect(rift.absentChildren.map((p) => p.name), ['Mert']);
      expect(rift.inheritance, Inheritance.kavga);
    });

    test('vasiyet varsa miras sessizce bölüşülür; birikimi eşle paylaşmak kavgadır', () {
      expect(
        LifeStory(
          life(
            grudge: 3,
            flags: {LifeStory.lateMarriageFlag, LifeStory.willFlag},
          ),
        ).inheritance,
        Inheritance.vasiyet,
      );
      expect(
        LifeStory(
          life(
            flags: {LifeStory.lateMarriageFlag, LifeStory.savingsToSpouseFlag},
          ),
        ).inheritance,
        Inheritance.kavga,
      );
      // İleri yaşta evlenmemişse miras konusu açılmaz.
      expect(LifeStory(life(flags: const {}, grudge: 3)).inheritance, isNull);
    });
  });
}
