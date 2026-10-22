import 'dart:convert';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:bir_omur/content/sensitive_terms.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_cards.dart';

List<String> _found(String text) =>
    findSensitiveTerms(text).map((t) => t.term).toList();

void main() {
  group('kelime eşleşmesi', () {
    test('kelime başı eşleşir, ekler sorun olmaz', () {
      expect(_found('akşam ezanına kadar'), ['ezan']);
      expect(_found('Kumarhaneye gitti'), containsAll(['kumar', 'kumarhane']));
    });

    test('tam kelime terimleri içinde geçen kelimeyle karışmaz', () {
      expect(_found('Bunun için imzan lazım.'), isEmpty);
      expect(_found('Romanı bitirdi, rumuz aldı, bira bira değil birazdan.'), [
        'bira',
      ]);
      expect(_found('Kahvaltıda bir dua okudu.'), ['dua']);
      expect(_found('Duadan sonra'), isEmpty, reason: '"dua" tam kelimedir');
    });

    test('Türkçe büyük harfler doğru küçültülür', () {
      expect(_found('İNTİHAR'), ['intihar']);
      expect(_found('ALLAH'), ['allah']);
      expect(lowerTr('IŞIK İĞNE'), 'ışık iğne');
    });

    test('kelime başında olmayan parça eşleşmez', () {
      expect(_found('Darbuka çaldı'), isEmpty);
      expect(_found('Kurtarıcı geldi'), isEmpty);
    });
  });

  group('card_lint', () {
    Map<String, dynamic> card(String id, String text) =>
        testCardJson(id, minAge: 20, maxAge: 30, text: text);

    CardCheckResult check(
      Map<String, Set<String>> reviewed,
      List<Object> cards,
    ) => CardValidator(
      ContentRegistry(
        flags: const {
          'iyi_lise': '',
          'meslek_lisesi': '',
          'yks_iyi_gecti': '',
          'ehliyet_var': '',
          'staj_yapti': '',
          'asker_anilari': '',
          'tasindi': '',
        },

        reviewedTerms: reviewed,
      ),
    ).check({'x.json': jsonEncode(cards)});

    test('incelenmemiş kelime uyarı verir', () {
      final result = check(const {}, [card('a', 'Akşam ezanı okundu.')]);
      expect(result.errors, isEmpty);
      expect(result.warnings.single.message, contains('"ezan"'));
    });

    test('onay listesindeki kullanım uyarı vermez', () {
      final result = check(
        {
          'a': {'ezan'},
        },
        [card('a', 'Akşam ezanı okundu.')],
      );
      expect(result.issues, isEmpty);
    });

    test('artık geçmeyen onay uyarı verir', () {
      final result = check(
        {
          'a': {'ezan'},
          'yok': {'rakı'},
        },
        [card('a', 'Akşam oldu.')],
      );
      expect(result.warnings.map((w) => w.path), [
        'reviewedTerms.a',
        'reviewedTerms.yok',
      ]);
    });

    test('seçenek metinleri de denetlenir', () {
      final c = card('a', 'Temiz metin.')
        ..['left'] = {'label': 'Rakı söylerim'};
      expect(check(const {}, [c]).warnings.single.message, contains('"rakı"'));
    });
  });
}
