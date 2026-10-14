import 'dart:io';

import 'package:bir_omur/content/content_registry.dart';
import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/portrait/portrait_spec.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

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

  test('kayıttaki her konuşmacının bir görünümü var', () {
    final registry = ContentRegistry.parse(
      File('assets/registry.json').readAsStringSync(),
    );
    for (final id in registry.speakers.keys) {
      expect(
        PortraitDesigner.speakers.containsKey(id) ||
            PortraitDesigner.peerSpeakers.contains(id),
        isTrue,
        reason: '$id için portre görünümü yok',
      );
    }
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
}
