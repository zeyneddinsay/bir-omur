import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

/// Emülatörde oynanan hayatta bulunan hataların düzeltmeleri (23 Ekim 2026).
void main() {
  final families = realFamilies();

  test('yeni kişiye hayattaki tanıdıkların adı verilmez', () {
    final f = PersonFactory(SeededRandom(1), families, avoidName: 'Emre');
    final names = families.namesFor(Gender.erkek, NameEra.forAgeGap(0));
    final taken = names.skip(1).toSet();
    for (var i = 0; i < 20; i++) {
      expect(f.pickName(names, taken: taken), names.first);
    }
    // Hepsi alınmışsa yine de bir ad seçilir (oyuncununki hariç).
    expect(f.pickName(names, taken: names.toSet()), isNot('Emre'));
  });

  test('eşini bu yıl kaybeden dede yas yılında sayılır', () {
    final c = withPeople(testCharacter(age: 7), [
      testPerson('x', kin: Kinship.dede, side: Side.baba, age: 70),
      testPerson(
        'x',
        name: 'Emine',
        gender: Gender.kadin,
        kin: Kinship.nine,
        side: Side.baba,
        age: 67,
      ),
      testPerson('x', kin: Kinship.dede, side: Side.anne, age: 72),
    ]);
    final widowed = c.copyWith(
      people: c.people.update(c.people['p2']!.copyWith(diedAt: 7)),
    );
    expect(
      Relationships.widowedRecently(widowed, widowed.people['p1']!),
      isTrue,
    );
    // Öbür taraftaki dede yasta değil; iki yıl sonra yas biter.
    expect(
      Relationships.widowedRecently(widowed, widowed.people['p3']!),
      isFalse,
    );
    final later = widowed.copyWith(age: 9);
    expect(Relationships.widowedRecently(later, later.people['p1']!), isFalse);
  });

  test(
    'tek ebeveynli ailede öbür ebeveynin neden olmadığı doğumda yazılır',
    () {
      var found = 0;
      for (var seed = 0; seed < 400 && found < 5; seed++) {
        final engine = LifeEngine(
          deck: EventDeck([]),
          families: families,
          seed: seed,
        );
        final state = engine.startLife(name: 'Emre', gender: Gender.erkek);
        final parents = state.character.people.all
            .where((p) => p.kin == Kinship.anne || p.kin == Kinship.baba)
            .toList();
        final note = state.notes
            .where((n) => n.kind == NoteKind.tekEbeveyn)
            .firstOrNull;
        if (parents.length == 2) {
          expect(note, isNull);
          continue;
        }
        found++;
        expect(note, isNotNull, reason: 'tohum $seed');
        expect(
          parents.single.marital,
          anyOf(MaritalStatus.dul, MaritalStatus.bosanmis),
        );
        final missing = parents.single.kin == Kinship.anne ? 'baba' : 'anne';
        expect(note!.detail, startsWith('$missing|'));
      }
      expect(found, greaterThan(0), reason: 'tek ebeveynli aile bulunamadı');
    },
  );

  test('açıköğretim her puana açık; bir sonraki basamak gösterilir', () {
    final c = testCharacter(age: 18)
        .copyWith(education: const Education(yksScore: 125));
    final placements = EducationRules.placements(c);
    expect(placements.map((p) => p.$1.id), ['acikogretim']);
    final (next, need) = EducationRules.nextGoal(c)!;
    expect(next.id, 'tarih');
    expect(need, greaterThan(125));
  });

  test('performansın gidişi tempo ve bilgiden', () {
    final low = testCharacter(knowledge: 19);
    expect(Careers.expectedPerformanceChange(low, Tempo.normal), -1);
    expect(Careers.expectedPerformanceChange(low, Tempo.yukle), 7);
    final high = testCharacter(knowledge: 80);
    expect(Careers.expectedPerformanceChange(high, Tempo.normal), 5);
  });

  group('borçlanan yaşlı çocuğunun yanına taşınır', () {
    Character elder({int age = 70, int money = -600000, bool child = true}) =>
        withPeople(testCharacter(age: age, money: money, home: HomeKind.kira), [
          if (child)
            testPerson(
              'x',
              name: 'Selin',
              gender: Gender.kadin,
              kin: Kinship.cocuk,
              age: 45,
              playerAge: age,
            ),
          testPerson(
            'x',
            name: 'Mert',
            kin: Kinship.cocuk,
            age: 42,
            playerAge: age,
            city: 'İzmir',
          ),
        ]);

    final f = PersonFactory(SeededRandom(2), families);

    test('aynı şehirdeki çocuk yanına alır; kira ve gider biter', () {
      final (moved, host) = Housing.moveInWithChild(elder(), f)!;
      expect(host.name, 'Selin', reason: 'aynı şehirdeki önce');
      expect(moved.home, HomeKind.cocukYaninda);
      expect(moved.assets.rent, 0);
      expect(Economy.livingCostOf(moved), 0);
      expect(Economy.rentDue(moved), 0);
      final selin = moved.people[host.id]!;
      expect(selin.hasRole(RoleKind.evSahibi), isTrue);
      expect(PeopleTick.livesTogether(moved, selin), isTrue);
      expect(selin.memories.last.kind, 'yanima_aldim');
    });

    test('başka şehirdeki çocuğun şehrine taşınılır', () {
      final (moved, host) = Housing.moveInWithChild(elder(child: false), f)!;
      expect(host.name, 'Mert');
      expect(moved.city, 'İzmir');
    });

    test('ev sahibi çocuk vefat edince öbür çocuk yanına alır', () {
      final (moved, host) = Housing.moveInWithChild(elder(), f)!;
      final gone = moved.copyWith(
        people: moved.people.update(
          moved.people[host.id]!.copyWith(diedAt: moved.age),
        ),
      );
      final rehomed = Housing.rehomeIfHostGone(gone, f);
      expect(rehomed.home, HomeKind.cocukYaninda);
      final newHost = rehomed.people.all.firstWhere(
        (p) => p.isAlive && p.hasRole(RoleKind.evSahibi),
      );
      expect(newHost.name, 'Mert');
    });

    test('65 yaş altı, borcu az ya da çocuğu yoksa taşınılmaz', () {
      expect(Housing.moveInWithChild(elder(age: 60), f), isNull);
      expect(Housing.moveInWithChild(elder(money: -100000), f), isNull);
      final childless = withPeople(
        testCharacter(age: 75, money: -900000, home: HomeKind.kira),
        const [],
      );
      expect(Housing.moveInWithChild(childless, f), isNull);
    });
  });
}
