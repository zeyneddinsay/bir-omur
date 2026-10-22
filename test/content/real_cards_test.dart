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
    Kinship.kardes,
  },
  'cenaze_ebeveyn': {Kinship.anne, Kinship.baba},
};

void main() {
  final content = loadRealContent();
  final deck = content.deck;

  test('içerik dosyaları hatasız ve uyarısız', () {
    expect(content.warnings, isEmpty, reason: content.warnings.join('\n'));
  });

  test('MVP meslekleri var', () {
    for (final id in ['memur', 'esnaf', 'plaza']) {
      final career = content.careers.byId(id);
      expect(career, isNotNull, reason: id);
      expect(career!.maxTier, 5, reason: id);
    }
  });

  test('D1 dönemeçleri ve iplikleri var', () {
    for (final id in [
      'ilkokul_ilk_gun',
      'lgs',
      'yks',
      'yks_iyi_lise',
      'askerlik_celbi',
      'askerlik_bedelli',
      ..._funerals.keys,
    ]) {
      expect(deck.byId(id)?.type, EventType.donemec, reason: id);
    }
    for (final id in ['mezuna_kalma', 'mezuniyet', 'kardes_borc_iade']) {
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
      final text = EventText.render(card.text, event.people, c);
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
      final missing = [
        for (final card in deck.cards)
          if (!seen.contains(card.id)) card.id,
      ];
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
      expect(empty / years, lessThan(0.15));
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

    test('YKS kazanma oranı makul; iyi lise avantaj sağlar', () {
      var good = 0, goodWon = 0, other = 0, otherWon = 0;
      for (final life in lives) {
        final c = finalOf(life);
        for (final r in c.history) {
          if (r.cardId == 'yks_iyi_lise') {
            good++;
            if (r.rollSucceeded!) goodWon++;
          } else if (r.cardId == 'yks') {
            other++;
            if (r.rollSucceeded!) otherWon++;
          }
        }
      }
      final rate = (goodWon + otherWon) / (good + other);
      printOnFailure(
        'iyi lise $goodWon/$good, diğer $otherWon/$other, toplam $rate',
      );
      expect(rate, inInclusiveRange(0.3, 0.75));
      expect(goodWon / good, greaterThan(otherWon / other));
    });

    test('öğrencilik mezuniyetle biter; mezun bayrağı gelir', () {
      for (final life in lives) {
        final c = finalOf(life);
        final graduated = c.history.any((r) => r.cardId == 'mezuniyet');
        expect(c.hasFlag('universite_mezunu'), graduated);
        if (c.hasFlag(ActionCatalog.studentFlag)) {
          expect(
            deathAge(life),
            lessThanOrEqualTo(26),
            reason: 'öğrenci kaldı',
          );
        }
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
