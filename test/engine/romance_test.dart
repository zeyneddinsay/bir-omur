import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  final factory = PersonFactory(SeededRandom(4), realFamilies());

  test('yaş kuralı: ikisi de 18+, küçük olan en az büyüğün yarısı artı 7', () {
    expect(Romance.agesFit(17, 18), isFalse);
    expect(Romance.agesFit(20, 26), isTrue);
    expect(Romance.agesFit(20, 30), isFalse);
    expect(Romance.agesFit(40, 27), isTrue);
  });

  test('romantik ilişki yalnızca karşı cinsle', () {
    expect(Romance.partnerGender(testCharacter()), Gender.kadin);
    expect(
      Romance.partnerGender(testCharacter(gender: Gender.kadin)),
      Gender.erkek,
    );
  });

  test('duygularını açmak: bekâr, ilgi duyulan cinsiyetten, yaşı uyan', () {
    final c = testCharacter(age: 25);
    final elif = testPerson(
      'p1',
      name: 'Elif',
      gender: Gender.kadin,
      age: 24,
      playerAge: 25,
      bond: Bond.arkadas,
    );
    final kerem = testPerson('p2', age: 24, playerAge: 25);
    final teen = testPerson('p3', gender: Gender.kadin, age: 17, playerAge: 25);
    expect(Romance.canCourt(c, elif), isTrue);
    expect(Romance.canCourt(c, kerem), isFalse, reason: 'ilgi duyulmayan');
    expect(Romance.canCourt(c, teen), isFalse, reason: '18 yaş altı');
    final taken = withPeople(c, [elif.copyWith(bond: Bond.sevgili), kerem]);
    expect(Romance.isSingle(taken), isFalse);
    expect(
      Interactions.optionsFor(
        taken,
        taken.people['p1']!,
        timeLeft: 5,
        used: const {},
      ).map((o) => o.kind),
      containsAll([InteractionKind.teklif, InteractionKind.ayril]),
    );
  });

  test('evlilik: eş, kayın aile ve evli bayrağı; boşanmada para bölünür', () {
    final c = withPeople(
      Character.fromJson({
        ...testCharacter(age: 30, money: 1000000).toJson(),
        'surname': 'Acar',
      }),
      [
        testPerson(
          'p1',
          name: 'Elif',
          gender: Gender.kadin,
          age: 28,
          playerAge: 30,
          bond: Bond.nisanli,
        ),
      ],
    );
    final married = Romance.syncFlags(Romance.marry(c, 'p1', factory));
    expect(married.people['p1']!.kin, Kinship.es);
    expect(married.people['p1']!.bond, isNull);
    expect(married.hasFlag(Romance.marriedFlag), isTrue);
    expect(
      married.people.all.where(
        (p) => p.kin == Kinship.kayinvalide || p.kin == Kinship.kayinpeder,
      ),
      isNotEmpty,
    );
    // Kadın eş kocasının soyadını alır; kayın aile kendi soyadıyla gelir.
    expect(married.people['p1']!.surname, 'Acar');
    expect(
      married.people.all
          .where(
            (p) => p.kin == Kinship.kayinvalide || p.kin == Kinship.kayinpeder,
          )
          .map((p) => p.surname),
      everyElement('Yılmaz'),
    );
    final (divorced, split) = Romance.breakUp(married, 'p1');
    expect(split, 500000);
    expect(divorced.stats.money, 500000);
    expect(divorced.people['p1']!.kin, isNull);
    expect(divorced.people['p1']!.bond, Bond.eskiEs);
    expect(divorced.people['p1']!.surname, 'Yılmaz');
    expect(Romance.syncFlags(divorced).hasFlag(Romance.marriedFlag), isFalse);
  });

  test('çocuk: seçilen adla gelir; aynı evde sayılır; gideri işler', () {
    final c = withPeople(testCharacter(age: 30, home: HomeKind.kira), [
      testPerson(
        'p1',
        gender: Gender.kadin,
        age: 28,
        playerAge: 30,
        kin: Kinship.es,
      ),
    ]);
    final (withChild, child) = Romance.addChild(
      c,
      factory,
      gender: Gender.kadin,
      name: 'Zeynep',
    );
    expect(child.name, 'Zeynep');
    expect(child.kin, Kinship.cocuk);
    expect(PeopleTick.livesTogether(withChild, child), isTrue);
    expect(Economy.childCostOf(withChild), Economy.childYearlyCost);
    expect(Romance.childTooSoon(withChild), isTrue, reason: 'bebek daha küçük');
  });
}
