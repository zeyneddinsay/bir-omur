import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';
import '../helpers/people.dart';
import '../helpers/test_character.dart';

void main() {
  final factory = PersonFactory(SeededRandom(5), realFamilies());

  group('lise', () {
    test('LGS ve lise seçimine göre lise türü 15 yaşında', () {
      Character at15(Set<String> flags, {int knowledge = 30}) =>
          EducationRules.assignHighSchool(
            testCharacter(age: 15, flags: flags, knowledge: knowledge),
          );
      expect(at15({}).education.highSchool, HighSchool.duz);
      expect(at15({'meslek_lisesi'}).education.highSchool, HighSchool.meslek);
      expect(at15({'iyi_lise'}).education.highSchool, HighSchool.anadolu);
      expect(
        at15({'iyi_lise'}, knowledge: 60).education.highSchool,
        HighSchool.fen,
      );
      expect(
        EducationRules.assignHighSchool(testCharacter(age: 14)).education,
        Education.none,
      );
    });
  });

  group('YKS', () {
    Character student({
      HighSchool school = HighSchool.duz,
      int knowledge = 50,
      Set<String> flags = const {},
    }) => testCharacter(
      age: 18,
      knowledge: knowledge,
      flags: flags,
    ).copyWith(education: Education(highSchool: school));

    double meanScore(Character c) {
      var sum = 0;
      for (var s = 0; s < 400; s++) {
        sum += EducationRules.yksScore(c, SeededRandom(s));
      }
      return sum / 400;
    }

    test('puan bilgiyle, liseyle ve sınav sabahıyla artar', () {
      expect(
        meanScore(student(knowledge: 70)),
        greaterThan(meanScore(student())),
      );
      expect(
        meanScore(student(school: HighSchool.fen)),
        greaterThan(meanScore(student(school: HighSchool.anadolu))),
      );
      expect(
        meanScore(student()),
        greaterThan(meanScore(student(school: HighSchool.meslek))),
      );
      expect(
        meanScore(student(flags: {EducationRules.goodExamFlag})),
        closeTo(meanScore(student()) + 15, 2),
      );
    });

    test('18 yaşında puan çıkar, tercih bekler; sınav bayrağı silinir', () {
      final c = EducationRules.sitYks(
        student(flags: {EducationRules.goodExamFlag}),
        SeededRandom(1),
      );
      expect(c.education.yksScore, isNotNull);
      expect(c.education.yksAttempts, 1);
      expect(c.hasFlag(EducationRules.pendingFlag), isTrue);
      expect(c.hasFlag(EducationRules.goodExamFlag), isFalse);
      // Aynı yıl ikinci kez girilmez.
      expect(EducationRules.sitYks(c, SeededRandom(2)), same(c));
      expect(
        EducationRules.sitYks(
          testCharacter(age: 17),
          SeededRandom(1),
        ).education.yksScore,
        isNull,
      );
    });

    test(
      'yerleşme: puan büyükşehirde daha çok ister; açıköğretim memlekette',
      () {
        final c = student().copyWith(
          education: const Education(highSchool: HighSchool.duz, yksScore: 300),
          flags: {EducationRules.pendingFlag},
        );
        final placements = EducationRules.placements(c);
        bool can(String dept, String city) =>
            placements.any((p) => p.$1.id == dept && p.$2 == city);
        expect(can('isletme', 'Konya'), isTrue, reason: 'orta şehir taban 300');
        expect(can('isletme', 'İstanbul'), isFalse, reason: 'büyükşehir 325');
        expect(can('isletme', 'Rize'), isTrue);
        expect(can('bilgisayar', 'Rize'), isFalse);
        expect(can('acikogretim', c.city), isTrue);
        expect(placements.where((p) => p.$1.open).map((p) => p.$2).toSet(), {
          c.city,
        });
      },
    );
  });

  group('üniversite', () {
    final pending = testCharacter(age: 18).copyWith(
      education: const Education(highSchool: HighSchool.duz, yksScore: 340),
      flags: {EducationRules.pendingFlag},
    );
    final isletme = EducationRules.department('isletme')!;

    test('başka şehre yerleşen yurda taşınır; sınıf ve oda arkadaşı gelir', () {
      final c = EducationRules.enroll(pending, isletme, 'İzmir', factory);
      expect(c.city, 'İzmir');
      expect(c.home, HomeKind.yurt);
      expect(c.hasFlag(ActionCatalog.studentFlag), isTrue);
      expect(c.hasFlag(EducationRules.pendingFlag), isFalse);
      final uni = c.people.all.where((p) => p.origin == Origin.universite);
      expect(uni.where((p) => p.hasRole(RoleKind.sinifArkadasi)), hasLength(5));
      final mate = uni.singleWhere((p) => p.hasRole(RoleKind.odaArkadasi));
      expect(mate.gender, c.gender);
      expect(uni.every((p) => p.city == 'İzmir'), isTrue);
    });

    test('memlekette okuyan aileyle kalır', () {
      final c = EducationRules.enroll(pending, isletme, pending.city, factory);
      expect(c.home, HomeKind.aile);
      expect(c.city, pending.city);
    });

    test('burs: dar aileye KYK, yüksek puana başarı bursu', () {
      final dar = Character.fromJson(pending.toJson()..['background'] = 'dar');
      expect(
        EducationRules.enroll(
          dar,
          isletme,
          dar.city,
          factory,
        ).education.scholarship,
        EducationRules.needScholarship,
      );
      final top = pending.copyWith(education: const Education(yksScore: 450));
      expect(
        EducationRules.enroll(
          top,
          isletme,
          top.city,
          factory,
        ).education.scholarship,
        EducationRules.meritScholarship,
      );
    });

    test('dört yıl sonra mezun; yurttaki ailesinin yanına döner', () {
      var c = withPeople(pending, [
        testPerson(
          'x',
          kin: Kinship.anne,
          gender: Gender.kadin,
          age: 45,
          playerAge: 18,
        ),
      ]);
      c = EducationRules.enroll(c, isletme, 'İzmir', factory);
      final notes = <EducationNote?>[];
      final random = SeededRandom(1);
      while (c.education.isStudent) {
        c = c.copyWith(age: c.age + 1, stats: c.stats.copyWith(knowledge: 100));
        final (next, note) = EducationRules.yearOfStudy(c, random);
        c = next;
        notes.add(note);
      }
      expect(c.education.graduatedAt, 22);
      expect(notes.last, EducationNote.mezunOldu);
      expect(c.home, HomeKind.aile);
      expect(c.city, pending.city);
      expect(c.hasFlag('universite_mezunu'), isTrue);
      expect(c.hasFlag(ActionCatalog.studentFlag), isFalse);
      expect(
        c.people.all
            .where((p) => p.origin == Origin.universite)
            .any((p) => p.roles.any((r) => r.active)),
        isFalse,
        reason: 'okul bitince sınıf rolleri biter',
      );
    });

    test('bilgisi düşük öğrencinin dersi alttan kalır, en fazla iki yıl', () {
      var c = EducationRules.enroll(pending, isletme, pending.city, factory);
      final random = SeededRandom(3);
      var failed = 0;
      while (c.education.isStudent) {
        c = c.copyWith(age: c.age + 1, stats: c.stats.copyWith(knowledge: 0));
        final (next, note) = EducationRules.yearOfStudy(c, random);
        c = next;
        if (note == EducationNote.dersKaldi) failed++;
      }
      expect(failed, inInclusiveRange(1, EducationRules.maxExtraYears));
      expect(c.education.graduatedAt, 22 + failed);
    });

    test('tercih yapmadan seçenekler: mezuna kal, çalış, çırak', () {
      expect(
        EducationRules.decline(
          pending,
          TercihKind.mezunaKal,
        ).hasFlag(EducationRules.retakeFlag),
        isTrue,
      );
      expect(
        EducationRules.decline(pending, TercihKind.cirak).education.apprentice,
        isTrue,
      );
      final work = EducationRules.decline(pending, TercihKind.calis);
      expect(work.hasFlag(EducationRules.pendingFlag), isFalse);
      expect(EducationRules.takesYksNow(work.copyWith(age: 19)), isFalse);
    });
  });

  group('motor', () {
    test('tercih yapmadan yaşlanan çalışmayı seçmiş sayılır', () {
      final engine = LifeEngine(
        deck: EventDeck(const []),
        seed: 3,
        families: realFamilies(),
      )..startLife();
      while (engine.state.character.age < 18) {
        engine.advanceYear();
      }
      expect(
        engine.state.character.hasFlag(EducationRules.pendingFlag),
        isTrue,
      );
      expect(
        engine.state.notes.map((n) => n.kind),
        contains(NoteKind.yksPuani),
      );
      engine.advanceYear();
      final c = engine.state.character;
      expect(c.hasFlag(EducationRules.pendingFlag), isFalse);
      expect(c.education.department, isNull);
      expect(c.education.highSchool, isNotNull);
    });

    test('yerleşme kayda girip çıkar; burs deftere yazılır', () {
      LifeEngine? engine;
      for (var seed = 0; engine == null; seed++) {
        final e = LifeEngine(
          deck: EventDeck(const []),
          seed: seed,
          families: realFamilies(),
        )..startLife();
        while (e.state.character.age < 18) {
          e.advanceYear();
        }
        if (e.state.character.background == FamilyBackground.dar &&
            e.tercihPlacements().isNotEmpty) {
          engine = e;
        }
      }
      final (d, city) = engine.tercihPlacements().first;
      engine.enroll(d.id, city);
      final restored = LifeEngine.restore(
        deck: EventDeck(const []),
        families: realFamilies(),
        snapshot: engine.toSnapshot(),
      );
      expect(
        restored.state.character.education,
        engine.state.character.education,
      );
      engine.advanceYear();
      expect(
        engine.state.character.ledger.where(
          (e) => e.source == MoneySource.burs && e.age == 19,
        ),
        hasLength(1),
      );
    });
  });
}
