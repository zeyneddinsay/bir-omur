import 'dart:io';

import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/portrait/portrait_spec.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/people.dart';
import '../helpers/test_character.dart';

Map<String, String> _partsFromDisk() => {
  for (final name in PortraitDesigner.allParts)
    name: File('assets/portraits/$name.svg').readAsStringSync(),
};

/// Farklı yaş, cinsiyet ve tohumlardan çok sayıda tarif.
Iterable<PortraitSpec> _manySpecs() sync* {
  for (var seed = 0; seed < 60; seed++) {
    for (final gender in Gender.values) {
      for (final age in AgeLook.values) {
        for (final mood in Mood.values) {
          yield PortraitDesigner.build(
            seed: seed,
            gender: gender,
            age: age,
            mood: mood,
          );
        }
      }
    }
  }
}

void main() {
  test('her parça dosyası var ve 200×200 tuvalde', () {
    for (final name in PortraitDesigner.allParts) {
      final file = File('assets/portraits/$name.svg');
      expect(file.existsSync(), isTrue, reason: name);
      expect(
        file.readAsStringSync(),
        contains('viewBox="0 0 200 200"'),
        reason: name,
      );
    }
  });

  test('tarifler yalnızca bilinen parçaları kullanır', () {
    final known = PortraitDesigner.allParts.toSet();
    for (final spec in _manySpecs()) {
      expect(known.containsAll(spec.layers), isTrue, reason: '${spec.layers}');
      expect(spec.layers.first, 'bg');
    }
  });

  test('aynı karakter aynı yüzü alır, farklısı farklı', () {
    final a = PortraitDesigner.forCharacter(testCharacter(age: 30));
    final b = PortraitDesigner.forCharacter(testCharacter(age: 30));
    expect(a.layers, b.layers);
    expect(a.colors, b.colors);
    final others = {
      for (var i = 0; i < 20; i++)
        PortraitDesigner.forPerson(
          name: 'Kişi $i',
          hometown: 'Rize',
          gender: Gender.kadin,
          age: 30,
        ).colors.toString(),
    };
    expect(others.length, greaterThan(10));
  });

  test('yaş görünümleri: bebek, yaşlı, başörtüsü', () {
    final baby = PortraitDesigner.build(
      seed: 1,
      gender: Gender.erkek,
      age: AgeLook.bebek,
    );
    expect(
      baby.layers,
      containsAll(['hair_baby_tuft', 'cheeks', 'mouth_baby', 'face_round']),
    );
    expect(baby.layers, isNot(contains('mustache')));

    final elder = PortraitDesigner.build(
      seed: 1,
      gender: Gender.kadin,
      age: AgeLook.yasli,
    );
    expect(elder.layers, contains('wrinkles'));
    expect(elder.colors[PortraitTokens.hair], anyOf('#9E9E9E', '#E3E3E3'));

    final scarf = PortraitDesigner.forSpeaker('babaanne', playerAge: 10);
    expect(scarf.layers, contains('headscarf'));
    expect(scarf.layers.where((l) => l.startsWith('hair_')), isEmpty);
    expect(
      PortraitDesigner.forSpeaker('dede', playerAge: 10).layers,
      contains('cap_flat'),
    );
  });

  test('ifade mutluluğa göre', () {
    String mouth(int happiness) => PortraitDesigner.forCharacter(
      testCharacter(age: 40, happiness: happiness),
    ).layers.firstWhere((l) => l.startsWith('mouth_'));
    expect(mouth(80), 'mouth_smile');
    expect(mouth(50), 'mouth_neutral');
    expect(mouth(10), 'mouth_sad');
  });

  test('karma sürümden sürüme sabit', () {
    expect(PortraitDesigner.stableHash(''), 0x811C9DC5);
    expect(PortraitDesigner.stableHash('a'), 0xE40C292C);
  });

  test('birleşik SVG tek kök ve yer tutucusuz', () {
    final parts = _partsFromDisk();
    final spec = PortraitDesigner.build(
      seed: 5,
      gender: Gender.kadin,
      age: AgeLook.yetiskin,
    );
    final svg = composePortraitSvg(spec, parts);
    expect('<svg'.allMatches(svg).length, 1);
    for (final MapEntry(:key, :value) in spec.colors.entries) {
      if (key != value) {
        expect(svg, isNot(contains(key)), reason: 'yer tutucu $key kalmış');
      }
    }
  });

  testWidgets('birleşik SVG\'ler hatasız çözülür', (tester) async {
    final parts = _partsFromDisk();
    final specs = _manySpecs().take(300).toList();
    await tester.runAsync(() async {
      for (final spec in specs) {
        final info = await vg.loadPicture(
          SvgStringLoader(composePortraitSvg(spec, parts)),
          null,
        );
        info.picture.dispose();
      }
    });
  });

  test('aynı kişi her yaşta aynı saç modeli ve rengiyle tanınır', () {
    String hairOf(PortraitSpec s) =>
        s.layers.where((l) => l.startsWith('hair_')).join(',');
    for (var seed = 0; seed < 80; seed++) {
      for (final gender in Gender.values) {
        PortraitSpec at(AgeLook age) =>
            PortraitDesigner.build(seed: seed, gender: gender, age: age);
        final young = at(AgeLook.genc);
        // Genç, yetişkin: saç modeli ve rengi aynı.
        expect(hairOf(at(AgeLook.yetiskin)), hairOf(young), reason: '$seed');
        expect(
          at(AgeLook.yetiskin).colors[PortraitTokens.hair],
          young.colors[PortraitTokens.hair],
        );
        // Ten, yüz ve gömlek ömür boyu aynı.
        for (final age in AgeLook.values) {
          final s = at(age);
          expect(
            s.colors[PortraitTokens.skin],
            young.colors[PortraitTokens.skin],
          );
          expect(
            s.colors[PortraitTokens.shirt],
            young.colors[PortraitTokens.shirt],
          );
        }
        // Yaşlılıkta yalnızca bilinen dönüşümler: kadında uzun saç topuz,
        // erkekte kelleşme ve kıvırcığın kısalması.
        final oldHair = hairOf(at(AgeLook.yasli));
        if (gender == Gender.kadin) {
          expect(
            oldHair == hairOf(young) ||
                oldHair == 'hair_bun' ||
                at(AgeLook.yasli).layers.contains('headscarf'),
            isTrue,
            reason: '$seed: ${hairOf(young)} → $oldHair',
          );
        } else {
          expect(
            {hairOf(young), 'hair_bald_sides', 'hair_short'},
            contains(oldHair),
            reason: '$seed: ${hairOf(young)} → $oldHair',
          );
        }
      }
    }
  });

  test('60 yaş ve üstü çoğunlukla gri saçlı; dede ve nine hep yaşlı', () {
    var grey = 0;
    for (var seed = 0; seed < 100; seed++) {
      final s = PortraitDesigner.build(
        seed: seed,
        gender: Gender.kadin,
        age: AgeLook.olgun,
      );
      if (const {
        '#9E9E9E',
        '#E3E3E3',
      }.contains(s.colors[PortraitTokens.hair])) {
        grey++;
      }
    }
    expect(grey, greaterThan(60));
    // 55 yaşındaki nine de yaşlı görünür.
    final nine = testPerson(
      'p1',
      gender: Gender.kadin,
      kin: Kinship.nine,
      side: Side.baba,
      age: 55,
      playerAge: 0,
    );
    final spec = PortraitDesigner.ofPerson(nine, playerAge: 0);
    expect(spec.layers, contains('wrinkles'));
    expect(spec.colors[PortraitTokens.hair], anyOf('#9E9E9E', '#E3E3E3'));
  });

  test('kan bağı olan akrabalar oyuncuyla aynı ya da komşu ten tonunda', () {
    final tones = [
      for (final (_, shadow) in const [
        ('#F5D5B8', '#D9AE8C'),
        ('#E8B98F', '#CC9A72'),
        ('#C9946A', '#A8744D'),
        ('#8D5A3B', '#6E4329'),
      ])
        shadow,
    ];
    int toneOf(PortraitSpec s) =>
        tones.indexOf(s.colors[PortraitTokens.skinShadow]!);
    for (var i = 0; i < 40; i++) {
      final kin = [
        (Kinship.baba, null),
        (Kinship.anne, null),
        (Kinship.kardes, null),
        (Kinship.dede, Side.baba),
        (Kinship.nine, Side.anne),
        (Kinship.amca, Side.baba),
        (Kinship.teyze, Side.anne),
      ];
      final c = withPeople(testCharacter(age: 10).copyWith(name: 'Kişi $i'), [
        for (final (j, (k, side)) in kin.indexed)
          testPerson('p${j + 1}', kin: k, side: side, age: 40, playerAge: 10),
      ]);
      final player = toneOf(PortraitDesigner.forCharacter(c));
      final byKin = <Kinship, int>{
        for (final p in c.people.all)
          p.kin!: toneOf(
            PortraitDesigner.ofPerson(p, playerAge: 10, family: c),
          ),
      };
      // Baba tarafı oyuncunun tonunda, anne tarafı en fazla bir ton uzakta.
      expect(byKin[Kinship.baba], player);
      expect(byKin[Kinship.dede], player);
      expect(byKin[Kinship.amca], player);
      expect(byKin[Kinship.kardes], player);
      expect((byKin[Kinship.anne]! - player).abs(), lessThanOrEqualTo(1));
      expect(byKin[Kinship.nine], byKin[Kinship.anne]);
      expect(byKin[Kinship.teyze], byKin[Kinship.anne]);
    }
  });
}
