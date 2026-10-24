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
}
