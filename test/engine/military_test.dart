import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/test_character.dart';

void main() {
  final factory = PersonFactory(SeededRandom(4), realFamilies());

  test('askerdeki yıl vakit yok', () {
    expect(
      ActionCatalog.timeFor(
        testCharacter(age: 21, flags: {Military.serviceFlag}),
      ),
      0,
    );
  });

  test('dönüşte askerlik biter, bölük arkadaşları gelir', () {
    final c = Military.returnHome(
      testCharacter(age: 21, flags: {Military.serviceFlag}),
      factory,
    );
    expect(c.hasFlag(Military.serviceFlag), isFalse);
    expect(c.hasFlag(Military.doneFlag), isTrue);
    expect(c.hasFlag(Military.memoriesFlag), isTrue);
    final comrades = c.people.all.where((p) => p.origin == Origin.askerlik);
    expect(comrades, hasLength(Military.comrades));
    for (final p in comrades) {
      expect(p.gender, Gender.erkek);
      expect(p.ageAt(21), inInclusiveRange(19, 23));
      expect(p.hasRole(RoleKind.bolukArkadasi, activeOnly: false), isTrue);
    }
    expect(comrades.where((p) => p.bond == Bond.arkadas), hasLength(1));
  });

  test('askerde olmayana dokunmaz', () {
    final c = testCharacter(age: 21);
    expect(Military.returnHome(c, factory), same(c));
  });
}
