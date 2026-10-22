import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';
import '../helpers/test_character.dart';

Character _withBackground(FamilyBackground b, {int age = 17, int money = 0}) =>
    Character.fromJson(
      testCharacter(age: age, money: money).toJson()..['background'] = b.id,
    );

void main() {
  test('doğumda aile durumu aile profillerinden gelir: %5 / %60 / %35', () {
    // Fabrikatör 5 → varlıklı; esnaf 20, memur 25, işçinin yarısı 15 → orta;
    // işçinin yarısı 15, çiftçi 10, yalnız ebeveyn 10 → dar.
    final families = FamilyBook.parse(
      familiesSource: File('assets/families.json').readAsStringSync(),
      namesSource: File('assets/names.json').readAsStringSync(),
    );
    final counts = <FamilyBackground, int>{};
    for (var seed = 0; seed < 4000; seed++) {
      final b = BirthGenerator(
        SeededRandom(seed),
        families: families,
      ).generate().background;
      counts.update(b, (n) => n + 1, ifAbsent: () => 1);
    }
    expect(counts[FamilyBackground.varlikli]!, inInclusiveRange(140, 260));
    expect(counts[FamilyBackground.orta]!, inInclusiveRange(2300, 2500));
    expect(counts[FamilyBackground.dar]!, inInclusiveRange(1300, 1500));
  });

  test('aile durumu başlangıç göstergelerini etkiler', () {
    expect(BirthGenerator.backgroundStart(FamilyBackground.varlikli), {
      StatKind.happiness: 5,
      StatKind.knowledge: 5,
    });
    expect(BirthGenerator.backgroundStart(FamilyBackground.orta), isEmpty);
    expect(BirthGenerator.backgroundStart(FamilyBackground.dar), {
      StatKind.family: 5,
      StatKind.happiness: -5,
    });
  });

  test('18 yaşına girerken aile desteği gelir, bir kez', () {
    const tick = YearTick();
    for (final b in FamilyBackground.values) {
      final at18 = tick.apply(_withBackground(b));
      expect(at18.age, 18);
      expect(at18.stats.money, b.adulthoodSupport, reason: b.id);
      expect(tick.apply(at18).stats.money, b.adulthoodSupport, reason: '19');
    }
    expect(FamilyBackground.varlikli.adulthoodSupport, 400000);
    expect(FamilyBackground.orta.adulthoodSupport, 100000);
    expect(FamilyBackground.dar.adulthoodSupport, 0);
  });

  test('aile durumu kart koşulu olarak çalışır', () {
    final card = testCard('harclik', conditions: {'background': 'dar'});
    expect(
      card.conditions.isMetBy(_withBackground(FamilyBackground.dar)),
      isTrue,
    );
    expect(
      card.conditions.isMetBy(_withBackground(FamilyBackground.orta)),
      isFalse,
    );
    expect(
      () => testCard('x', conditions: {'background': 'zengin'}),
      throwsA(isA<CardFormatException>()),
    );
  });

  test('aile durumu kayıttan geri gelir', () {
    final c = _withBackground(FamilyBackground.varlikli);
    final back = Character.fromJson(
      jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
    );
    expect(back.background, FamilyBackground.varlikli);
  });
}
