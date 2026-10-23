import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/l10n/generated/app_localizations_tr.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/people/people_text.dart';
import 'package:bir_omur/ui/people/people_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  final l10n = AppLocalizationsTr();
  const classmate = [PersonRole(RoleKind.sinifArkadasi)];

  test('kişiler bölümlerine ayrılır; doğmamış görünmez', () {
    final c = withPeople(testCharacter(age: 30), [
      testPerson('x', kin: Kinship.anne, gender: Gender.kadin, age: 55),
      testPerson('x', kin: Kinship.dede, age: 80).copyWith(diedAt: 28),
      testPerson('x', roles: classmate),
      testPerson('x', roles: const [PersonRole(RoleKind.komsu)]),
      testPerson('x', bond: Bond.arkadas, roles: classmate),
      testPerson('x', roles: [classmate.single.ended()]),
      testPerson('x', roles: classmate, archived: true),
      testPerson('x', kin: Kinship.kardes, age: -2),
    ]);
    final groups = PeopleView.grouped(c);
    List<String> ids(PeopleGroup g) => [for (final p in groups[g]!) p.id];
    expect(groups.keys, [
      PeopleGroup.aile,
      PeopleGroup.okul,
      PeopleGroup.arkadaslar,
      PeopleGroup.mahalle,
      PeopleGroup.eski,
      PeopleGroup.vefat,
    ]);
    expect(ids(PeopleGroup.aile), ['p1']);
    expect(ids(PeopleGroup.vefat), ['p2']);
    expect(ids(PeopleGroup.okul), ['p3']);
    expect(ids(PeopleGroup.mahalle), ['p4']);
    expect(ids(PeopleGroup.arkadaslar), ['p5']);
    expect(ids(PeopleGroup.eski), containsAll(['p6', 'p7']));
  });

  test('bağ metni: akrabalık, rol, eski rol, arkadaşlık', () {
    expect(
      l10n.relationOf(
        testPerson('p1', kin: Kinship.kardes, gender: Gender.kadin, age: 33),
      ),
      'Ablan',
    );
    expect(
      l10n.relationOf(
        testPerson('p1', kin: Kinship.dede, side: Side.anne, age: 70),
      ),
      'Deden (anne tarafı)',
    );
    expect(
      l10n.relationOf(testPerson('p1', roles: classmate)),
      'Sınıf arkadaşın',
    );
    expect(
      l10n.relationOf(
        testPerson(
          'p1',
          roles: const [PersonRole(RoleKind.ogretmen, active: false)],
        ),
      ),
      'Eskiden: Öğretmenin',
    );
    expect(
      l10n.relationOf(testPerson('p1', bond: Bond.arkadas, roles: classmate)),
      'Arkadaşın',
    );
  });

  test('günlük haberi: akraba akrabalıkla, diğerleri adıyla anılır', () {
    final c = withPeople(testCharacter(age: 30), [
      testPerson('x', kin: Kinship.dede, age: 80),
      testPerson('x', name: 'Kerem'),
    ]);
    String line(PersonNews n) =>
        l10n.newsLine(n, c, occupations: const {'memur': 'Memur'});
    expect(line(const PersonNews(NewsKind.vefat, 'p1')), 'Deden vefat etti.');
    expect(line(const PersonNews(NewsKind.evlendi, 'p2')), 'Kerem evlendi.');
    expect(
      line(const PersonNews(NewsKind.isBuldu, 'p2', detail: 'memur')),
      'Kerem iş buldu: memur.',
    );
  });
}
