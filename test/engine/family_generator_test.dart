import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/engine/birth.dart';
import 'package:bir_omur/engine/family_generator.dart';
import 'package:bir_omur/engine/seeded_random.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/families.dart';

void main() {
  final book = realFamilies();
  const seeds = 5000;

  FamilyResult family(int seed) => FamilyGenerator(
    SeededRandom(seed),
    book,
    cities: BirthGenerator.hometowns,
  ).generate(hometown: 'Samsun');

  final results = [for (var s = 0; s < seeds; s++) family(s)];

  Person? kin(FamilyResult f, Kinship k) {
    final list = f.people.withKin(k);
    return list.isEmpty ? null : list.single;
  }

  int ageOf(Person p) => -p.bornAt;

  test('aynı tohum aynı aileyi üretir', () {
    expect(
      jsonEncode(family(42).people.toJson()),
      jsonEncode(family(42).people.toJson()),
    );
    expect(
      jsonEncode(family(42).people.toJson()),
      isNot(jsonEncode(family(43).people.toJson())),
    );
  });

  test('profil dağılımı ağırlıklara uyar (±2 puan)', () {
    final counts = <String, int>{};
    for (final f in results) {
      counts.update(f.profile.id, (n) => n + 1, ifAbsent: () => 1);
    }
    final total = book.profiles.fold(0, (s, p) => s + p.weight);
    for (final p in book.profiles) {
      final share = 100 * (counts[p.id] ?? 0) / seeds;
      expect(
        share,
        closeTo(100 * p.weight / total, 2),
        reason: '${p.id}: %${share.toStringAsFixed(1)}',
      );
    }
  });

  test('anne ve baba', () {
    for (final f in results) {
      final mother = kin(f, Kinship.anne);
      final father = kin(f, Kinship.baba);
      if (f.profile.singleParent == null) {
        expect(mother, isNotNull);
        expect(father, isNotNull);
        expect(mother!.marital, MaritalStatus.evli);
        expect(mother.base, FamilyGenerator.motherBase);
        expect(father!.base, FamilyGenerator.fatherBase);
        expect(
          ageOf(father),
          inInclusiveRange(f.profile.fatherAgeMin, f.profile.fatherAgeMax),
        );
        expect(ageOf(mother), greaterThanOrEqualTo(19));
        expect(ageOf(mother), lessThanOrEqualTo(ageOf(father)));
      } else {
        expect([mother, father].whereType<Person>(), hasLength(1));
        final parent = mother ?? father!;
        expect(parent.base, FamilyGenerator.singleParentBase);
      }
      for (final parent in [mother, father].whereType<Person>()) {
        expect(parent.surname, f.surname);
        expect(parent.side, isNull);
        expect(parent.metAt, 0);
        expect(parent.origin, Origin.aile);
      }
      if (mother != null) expect(mother.gender, Gender.kadin);
      if (father != null) expect(father.gender, Gender.erkek);
    }
  });

  test('yalnız ebeveynde anne ve baba oranı (75 / 25, ±4 puan)', () {
    final singles = results.where((f) => f.profile.singleParent != null);
    final mothers = singles.where((f) => kin(f, Kinship.anne) != null).length;
    expect(100 * mothers / singles.length, closeTo(75, 4));
  });

  test('kardeşler', () {
    for (final f in results) {
      final siblings = f.people.withKin(Kinship.kardes);
      expect(siblings.length, lessThanOrEqualTo(3));
      final years = siblings.map((s) => s.bornAt).toSet();
      expect(years, hasLength(siblings.length), reason: 'aynı yıl iki kardeş');
      expect(years, isNot(contains(0)));
      final mother = kin(f, Kinship.anne);
      for (final s in siblings) {
        expect(s.surname, f.surname);
        expect(s.base, FamilyGenerator.siblingBase);
        expect(s.metAt, s.bornAt > 0 ? s.bornAt : 0);
        expect(s.lastContactAt, s.metAt);
        if (mother != null) {
          final motherAgeThen = ageOf(mother) + s.bornAt;
          expect(motherAgeThen, inInclusiveRange(19, 42));
        }
      }
    }
  });

  test('kardeş sayısı ağırlıklara uyar (±3 puan)', () {
    for (final profile in book.profiles) {
      final group = results.where((f) => f.profile.id == profile.id).toList();
      if (group.length < 400) continue;
      final total = profile.siblingWeights.fold(0, (s, w) => s + w);
      final none = group
          .where((f) => f.people.withKin(Kinship.kardes).isEmpty)
          .length;
      expect(
        100 * none / group.length,
        // Anne genç ya da yaşlıysa kardeş seçeneği azalabilir; sıfır kardeş
        // oranı ağırlıktan düşük olamaz.
        greaterThanOrEqualTo(100 * profile.siblingWeights[0] / total - 3),
        reason: profile.id,
      );
    }
  });

  test('dede ve nineler', () {
    for (final f in results) {
      final grands = [
        ...f.people.withKin(Kinship.dede),
        ...f.people.withKin(Kinship.nine),
      ];
      expect(grands.length, lessThanOrEqualTo(4));
      for (final g in grands) {
        expect(g.side, isNotNull);
        expect(ageOf(g), lessThanOrEqualTo(FamilyGenerator.grandparentMaxAge));
        final parent = kin(
          f,
          g.side == Side.baba ? Kinship.baba : Kinship.anne,
        );
        expect(parent, isNotNull, reason: 'olmayan ebeveynin anne-babası');
        expect(ageOf(g), greaterThanOrEqualTo(ageOf(parent!) + 19));
        if (g.side == Side.baba) {
          expect(g.surname, f.surname);
        } else {
          expect(g.surname, isNot(f.surname));
        }
        final sameSide = grands.where((o) => o.side == g.side).toList();
        expect(
          g.marital,
          sameSide.length == 2 ? MaritalStatus.evli : MaritalStatus.dul,
        );
        expect(sameSide.where((o) => o.kin == g.kin), hasLength(1));
      }
    }
  });

  test('akrabalar doğru taraftan', () {
    for (final f in results) {
      final relatives = f.people.all.where(
        (p) => const {
          Kinship.amca,
          Kinship.hala,
          Kinship.dayi,
          Kinship.teyze,
        }.contains(p.kin),
      );
      expect(relatives.length, inInclusiveRange(1, 2));
      for (final r in relatives) {
        final paternal = r.kin == Kinship.amca || r.kin == Kinship.hala;
        expect(r.side, paternal ? Side.baba : Side.anne);
        expect(
          kin(f, paternal ? Kinship.baba : Kinship.anne),
          isNotNull,
          reason: 'olmayan ebeveynin kardeşi',
        );
        final male = r.kin == Kinship.amca || r.kin == Kinship.dayi;
        expect(r.gender, male ? Gender.erkek : Gender.kadin);
        if (r.kin == Kinship.amca) expect(r.surname, f.surname);
      }
    }
  });

  test('mahalle: bir dedikoducu komşu teyze ve bir bakkal', () {
    for (final f in results) {
      final neighbors = f.people.all
          .where((p) => p.hasRole(RoleKind.komsu))
          .toList();
      final grocers = f.people.all
          .where((p) => p.hasRole(RoleKind.bakkal))
          .toList();
      expect(neighbors, hasLength(1));
      expect(grocers, hasLength(1));
      expect(neighbors.single.gender, Gender.kadin);
      expect(neighbors.single.hasTrait(Trait.dedikoducu), isTrue);
      expect(grocers.single.occupation, 'bakkal');
      for (final p in [...neighbors, ...grocers]) {
        expect(p.kin, isNull);
        expect(p.bond, Bond.tanidik);
        expect(p.origin, Origin.mahalle);
        expect(p.city, 'Samsun');
      }
    }
  });

  test('herkes için ortak kurallar', () {
    for (final f in results) {
      final ids = f.people.all.map((p) => p.id).toList();
      expect(ids, [for (var i = 1; i <= ids.length; i++) 'p$i']);
      expect(f.people.nextId, ids.length + 1);
      for (final p in f.people.all) {
        expect(p.traits.length, inInclusiveRange(1, 2));
        if (p.traits.length == 2) {
          expect(Trait.compatible(p.traits.first, p.traits.last), isTrue);
        }
        if (p.occupation != null) {
          expect(book.occupations, contains(p.occupation));
        }
        if (p.occupation == 'ev_hanimi') expect(p.gender, Gender.kadin);
        expect(p.memories, isEmpty);
        expect(p.isAlive, isTrue);
        expect(p.archived, isFalse);
        expect(BirthGenerator.hometowns, contains(p.city));
        final era = NameEra.forAgeGap(ageOf(p));
        expect(
          book.namesFor(p.gender, era),
          contains(p.name),
          reason: '${p.name} (${ageOf(p)} yaşında) ${era.name} kuşağında değil',
        );
      }
    }
  });

  group('doğum', () {
    test('karakter aileyi taşır', () {
      final c = BirthGenerator(SeededRandom(7), families: book).generate();
      final profile = book.profileById(c.familyProfile!)!;
      expect(profile.backgrounds, contains(c.background));
      expect(c.surname, isNotEmpty);
      expect(c.people.length, greaterThan(3));
      expect(book.namesFor(c.gender, NameEra.yeni), contains(c.name));
      expect(
        c.people.all.where(
          (p) => p.kin == Kinship.anne || p.kin == Kinship.baba,
        ),
        isNotEmpty,
      );
    });

    test('oyuncunun yazdığı ad korunur', () {
      final c = BirthGenerator(
        SeededRandom(7),
        families: book,
      ).generate(name: '  Hasan  ', gender: Gender.erkek);
      expect(c.name, 'Hasan');
    });

    test('karakter kişileriyle birlikte kayda girip çıkar', () {
      final c = BirthGenerator(SeededRandom(11), families: book).generate();
      final round = Character.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(jsonEncode(round.toJson()), jsonEncode(c.toJson()));
      expect(round.people.length, c.people.length);
      expect(round.surname, c.surname);
      expect(round.familyProfile, c.familyProfile);
    });

    test('kişisiz eski kayıt boş kitapla açılır', () {
      final c = BirthGenerator(SeededRandom(11), families: book).generate();
      final json = c.toJson()
        ..remove('people')
        ..remove('surname')
        ..remove('family');
      final old = Character.fromJson(
        jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
      );
      expect(old.people.length, 0);
      expect(old.surname, '');
      expect(old.familyProfile, isNull);
    });
  });

  group('aile dosyası denetimi', () {
    Map<String, dynamic> families() =>
        jsonDecode(File('assets/families.json').readAsStringSync())
            as Map<String, dynamic>;
    final names = File('assets/names.json').readAsStringSync();

    FamilyBook parse(Map<String, dynamic> f) =>
        FamilyBook.parse(familiesSource: jsonEncode(f), namesSource: names);

    test('gerçek dosya geçerli', () {
      expect(book.profiles, hasLength(6));
      expect(book.surnames.toSet(), hasLength(book.surnames.length));
    });

    test('bilinmeyen meslek reddedilir', () {
      final f = families();
      ((f['profiles'] as List).first as Map)['fatherJobs'] = ['astronot'];
      expect(() => parse(f), throwsA(isA<CardFormatException>()));
    });

    test('bozuk kardeş ağırlığı reddedilir', () {
      final f = families();
      ((f['profiles'] as List).first as Map)['siblings'] = [1, 2];
      expect(() => parse(f), throwsA(isA<CardFormatException>()));
    });

    test('tekrar eden profil reddedilir', () {
      final f = families();
      final list = f['profiles'] as List;
      list.add(list.first);
      expect(() => parse(f), throwsA(isA<CardFormatException>()));
    });

    test('bilinmeyen alan reddedilir', () {
      final f = families();
      ((f['profiles'] as List).first as Map)['renk'] = 'mavi';
      expect(() => parse(f), throwsA(isA<CardFormatException>()));
    });
  });
}
