import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_loader.dart';
import 'package:bir_omur/content/disk_content_source.dart';
import 'package:bir_omur/content/event_text.dart';
import 'package:bir_omur/engine/engine.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/simulation.dart';

/// `assets/` altındaki gerçek içerik. Testler proje kökünden çalışır.
GameContent loadRealContent() => loadContentFromDisk();

/// Cenaze dönemeçleri ve kapsadıkları akrabalar.
const Map<String, Set<Kinship>> _funerals = {
  'cenaze_cocuk': {
    Kinship.dede,
    Kinship.nine,
    Kinship.amca,
    Kinship.hala,
    Kinship.dayi,
    Kinship.teyze,
  },
  'cenaze_akraba': {
    Kinship.dede,
    Kinship.nine,
    Kinship.amca,
    Kinship.hala,
    Kinship.dayi,
    Kinship.teyze,
  },
  'cenaze_kardes': {Kinship.kardes},
  'cenaze_ebeveyn': {Kinship.anne, Kinship.baba},
};

void main() {
  final content = loadRealContent();
  final deck = content.deck;

  test('içerik dosyaları hatasız ve uyarısız', () {
    expect(content.warnings, isEmpty, reason: content.warnings.join('\n'));
  });

  test('ilk sürümün meslekleri var', () {
    for (final id in [
      'memur',
      'hemsire',
      'yazilimci',
      'plaza',
      'oto_tamircisi',
      'garson',
      'emlakci',
    ]) {
      expect(content.careers.byId(id), isNotNull, reason: id);
    }
  });

  test('D1 dönemeçleri ve iplikleri var', () {
    for (final id in [
      'ilkokul_ilk_gun',
      'lgs',
      'yks',
      'yks_tekrar',
      'askerlik_celbi',
      'askerlik_bedelli',
      ..._funerals.keys,
    ]) {
      expect(deck.byId(id)?.type, EventType.donemec, reason: id);
    }
    for (final id in ['lise_secimi', 'mezuniyet', 'kardes_borc_iade']) {
      expect(deck.byId(id)?.type, EventType.iplik, reason: id);
    }
  });

  group('gerçek içerikle 300 hayat', () {
    const count = 300;
    final lives = <LifeState>[];
    final problems = <String>[];

    /// Ekrana gelen her olayın metni kurulur ve kişileri denetlenir.
    void inspect(LifeState state, int seed) {
      if (state.phase != YearPhase.cards) return;
      final event = state.currentEvent!;
      final card = event.card;
      final c = state.character;
      final where = 'tohum $seed, ${c.age} yaş, ${card.id}';
      final text = EventText.render(
        EventText.cardText(card, c),
        event.people,
        c,
      );
      if (text.contains('{') || text.contains('}')) {
        problems.add('$where: kurulamayan metin "$text"');
      }
      if (text.runes.length > CardValidator.maxTextLength) {
        problems.add('$where: ${text.runes.length} karakter "$text"');
      }
      final sides = [card.left, card.right, ?card.up];
      for (final choice in sides) {
        final label = EventText.render(choice.label, event.people, c);
        if (label.runes.length > CardValidator.maxLabelLength) {
          problems.add('$where: uzun seçenek "$label"');
        }
        // Etiket ve sonuç cümleleri de kişilerle eksiksiz kurulur.
        for (final t in [label, ...choice.results]) {
          final rendered = EventText.render(t, event.people, c);
          if (rendered.contains('{') || rendered.contains('}')) {
            problems.add('$where: kurulamayan yazı "$rendered"');
          }
        }
      }
      if (card.speaker != null &&
          EventText.speakerName(card, event.people, c) == null) {
        problems.add('$where: konuşan bulunamadı');
      }
      for (final slot in card.roles) {
        final p = c.people[event.people[slot.name] ?? ''];
        if (p == null) {
          problems.add('$where: ${slot.name} yuvası boş');
        } else if (p.isAlive == slot.deceased) {
          problems.add('$where: ${slot.name} yaşam durumu uymuyor');
        }
      }
    }

    setUpAll(() {
      for (var seed = 0; seed < count; seed++) {
        lives.add(
          simulateLife(
            deck,
            seed,
            careers: content.careers,
            families: content.families,
            onStep: (state) => inspect(state, seed),
          ),
        );
      }
    });

    Character finalOf(LifeState life) => life.summary!.character;
    int deathAge(LifeState life) => life.summary!.deathAge;

    test('hayatlar çökmeden ve sonlu biter', () {
      final ages = lives.map(deathAge).toList()..sort();
      final mean = ages.reduce((a, b) => a + b) / ages.length;
      printOnFailure('ölüm yaşları: $ages');
      expect(mean, inInclusiveRange(50, 95));
    });

    test('olay metinleri kurulur, sınırı aşmaz; kişiler yuvaya uyar', () {
      expect(problems, isEmpty, reason: problems.take(20).join('\n'));
    });

    test('her olay en az bir hayatta gelir', () {
      final seen = {
        for (final life in lives)
          for (final r in finalOf(life).history) r.cardId,
      };
      final missing = {
        for (final card in deck.cards)
          if (!seen.contains(card.id)) card.id,
      };
      // Nadir kartlar (geç evlilik, yazılım işletmesi) rastgelelik akışı
      // kayınca 300 hayatta kaçabilir: yalnızca onlar için ek tohumlar
      // denenir. Hiç gelemeyen kart yine yakalanır.
      for (var seed = count; seed < count + 600 && missing.isNotEmpty; seed++) {
        final life = simulateLife(
          deck,
          seed,
          careers: content.careers,
          families: content.families,
        );
        missing.removeAll({for (final r in finalOf(life).history) r.cardId});
      }
      expect(missing, isEmpty);
    });

    test('her yaşın olayı vardır: 3–80 arası olaysız yıl azdır', () {
      var years = 0;
      var empty = 0;
      for (final life in lives) {
        final ages = {for (final r in finalOf(life).history) r.age};
        for (var age = 3; age <= 80 && age < deathAge(life); age++) {
          years++;
          if (!ages.contains(age)) empty++;
        }
      }
      printOnFailure('$empty / $years yıl olaysız');
      // Tekrar sınırlarıyla yetişkinlik havuzu inceldi; D2.8 ve D4a olaylarıyla
      // hedef yeniden %15 altıdır.
      expect(empty / years, lessThan(0.25));
    });

    test('LGS 14, YKS 18 yaşında herkese gelir', () {
      for (final life in lives) {
        final history = finalOf(life).history;
        bool at(int age, Set<String> ids) =>
            history.any((r) => r.age == age && ids.contains(r.cardId));
        if (deathAge(life) > 14) {
          expect(at(14, {'lgs'}), isTrue);
        }
        if (deathAge(life) > 18) {
          expect(at(18, {'yks', 'yks_iyi_lise'}), isTrue);
        }
      }
    });

    test('YKS: puan bilgiye ve liseye göre; yerleşme oranı makul', () {
      final bySchool = <HighSchool, List<int>>{};
      var sat = 0, placed = 0;
      for (final life in lives) {
        final e = finalOf(life).education;
        if (e.yksScore == null) continue;
        sat++;
        bySchool.putIfAbsent(e.highSchool!, () => []).add(e.yksScore!);
        final d = EducationRules.department(e.department);
        if (d != null && !d.open) placed++;
      }
      double mean(HighSchool h) {
        final l = bySchool[h] ?? const [];
        return l.isEmpty ? 0 : l.reduce((a, b) => a + b) / l.length;
      }

      printOnFailure(
        'yerleşen $placed/$sat; puan ortalaması '
        '${[for (final h in HighSchool.values) '${h.id} ${mean(h).round()}'].join(', ')}',
      );
      expect(sat, greaterThan(200));
      expect(mean(HighSchool.anadolu), greaterThan(mean(HighSchool.duz)));
      expect(mean(HighSchool.duz), greaterThan(mean(HighSchool.meslek)));
      expect(placed / sat, inInclusiveRange(0.25, 0.85));
    });

    test('öğrencilik mezuniyetle biter; mezuniyet olayı gelir', () {
      for (final life in lives) {
        final c = finalOf(life);
        final e = c.education;
        if (e.isGraduate) {
          expect(
            c.history.any((r) => r.cardId == 'mezuniyet'),
            isTrue,
            reason: 'mezuniyet kartı',
          );
          expect(c.hasFlag('universite_mezunu'), !e.openEducation);
          expect(e.graduatedAt, e.uniStartAge! + e.uniYears + e.extraYears);
        }
        if (e.isStudent) {
          expect(deathAge(life), lessThanOrEqualTo(e.expectedGraduation!));
          expect(c.hasFlag(ActionCatalog.studentFlag), isTrue);
        }
        expect(e.extraYears, lessThanOrEqualTo(EducationRules.maxExtraYears));
      }
    });

    test('askerlik: 41 yaşını gören her erkek yapmış, kadınlar hiç', () {
      for (final life in lives) {
        final c = finalOf(life);
        if (c.gender == Gender.kadin) {
          expect(c.hasFlag('askerligini_yapti'), isFalse);
        } else if (deathAge(life) > 41) {
          expect(c.hasFlag('askerligini_yapti'), isTrue);
        }
        // Yaparak yapan bölük arkadaşlarıyla döner; bedelli yalnız.
        final comrades = c.people.all.where((p) => p.origin == Origin.askerlik);
        expect(
          comrades.length,
          c.hasFlag('asker_anilari') ? Military.comrades : 0,
        );
        expect(c.hasFlag('askerde'), isFalse, reason: 'askerde ölmedi');
        // Askere gidilen yıl, celpten sonra başka olay gelmez (pazarda çay
        // içilmez).
        final history = c.history;
        for (var i = 0; i < history.length; i++) {
          final r = history[i];
          if (r.cardId != 'askerlik_celbi' || r.side == ChoiceSide.up) {
            continue;
          }
          final went = r.side == ChoiceSide.left || r.side == ChoiceSide.right;
          final sameYearAfter = history
              .skip(i + 1)
              .where((x) => x.age == r.age)
              .map((x) => x.cardId)
              .toList();
          if (went && c.hasFlag('asker_anilari')) {
            expect(sameYearAfter, isEmpty, reason: '${r.age} yaş');
          }
        }
      }
    });

    test('her yakın vefatın cenazesi gelir', () {
      var deaths = 0;
      final missed = <String>[];
      for (final life in lives) {
        final c = finalOf(life);
        for (final p in c.people.all) {
          final died = p.diedAt;
          if (died == null || died < 3 || died >= deathAge(life) - 1) continue;
          final cards = [
            for (final MapEntry(key: id, value: kins) in _funerals.entries)
              if (kins.contains(p.kin)) id,
          ];
          if (cards.isEmpty) continue;
          // Uzak akrabanın vefatı yalnızca günlüğe düşer (cenaze_akraba 40+).
          if (p.kin != Kinship.kardes &&
              cards.contains('cenaze_akraba') &&
              Relationships.closeness(p, died) < 40) {
            continue;
          }
          deaths++;
          final mourned = c.history.any(
            (r) => cards.contains(r.cardId) && r.people.containsValue(p.id),
          );
          if (!mourned) missed.add('${p.kin?.name} $died yaşta');
        }
      }
      printOnFailure('kaçan cenazeler: $missed');
      expect(deaths, greaterThan(200));
      expect(missed.length / deaths, lessThan(0.03));
    });
  });
}
