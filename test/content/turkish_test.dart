import 'package:bir_omur/content/turkish.dart';
import 'package:bir_omur/engine/birth.dart';
import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ad → [e, i, in, de, den, le] ekli hâlleri (elle hesaplandı).
const Map<String, List<String>> _expected = {
  // Kalın, sert ünsüzle biten
  'Murat': [
    "Murat'a",
    "Murat'ı",
    "Murat'ın",
    "Murat'ta",
    "Murat'tan",
    "Murat'la",
  ],
  'Burak': [
    "Burak'a",
    "Burak'ı",
    "Burak'ın",
    "Burak'ta",
    "Burak'tan",
    "Burak'la",
  ],
  'Yusuf': [
    "Yusuf'a",
    "Yusuf'u",
    "Yusuf'un",
    "Yusuf'ta",
    "Yusuf'tan",
    "Yusuf'la",
  ],
  // İnce, sert ünsüzle biten (özel adda yumuşama yok)
  'Ahmet': [
    "Ahmet'e",
    "Ahmet'i",
    "Ahmet'in",
    "Ahmet'te",
    "Ahmet'ten",
    "Ahmet'le",
  ],
  'Mehmet': [
    "Mehmet'e",
    "Mehmet'i",
    "Mehmet'in",
    "Mehmet'te",
    "Mehmet'ten",
    "Mehmet'le",
  ],
  'Zeynep': [
    "Zeynep'e",
    "Zeynep'i",
    "Zeynep'in",
    "Zeynep'te",
    "Zeynep'ten",
    "Zeynep'le",
  ],
  'Elif': ["Elif'e", "Elif'i", "Elif'in", "Elif'te", "Elif'ten", "Elif'le"],
  // Yumuşak ünsüzle biten
  'Hasan': [
    "Hasan'a",
    "Hasan'ı",
    "Hasan'ın",
    "Hasan'da",
    "Hasan'dan",
    "Hasan'la",
  ],
  'Can': ["Can'a", "Can'ı", "Can'ın", "Can'da", "Can'dan", "Can'la"],
  'Nur': ["Nur'a", "Nur'u", "Nur'un", "Nur'da", "Nur'dan", "Nur'la"],
  'Oktay': [
    "Oktay'a",
    "Oktay'ı",
    "Oktay'ın",
    "Oktay'da",
    "Oktay'dan",
    "Oktay'la",
  ],
  'Kerem': [
    "Kerem'e",
    "Kerem'i",
    "Kerem'in",
    "Kerem'de",
    "Kerem'den",
    "Kerem'le",
  ],
  'Eymen': [
    "Eymen'e",
    "Eymen'i",
    "Eymen'in",
    "Eymen'de",
    "Eymen'den",
    "Eymen'le",
  ],
  'Ömer': ["Ömer'e", "Ömer'i", "Ömer'in", "Ömer'de", "Ömer'den", "Ömer'le"],
  'Hüseyin': [
    "Hüseyin'e",
    "Hüseyin'i",
    "Hüseyin'in",
    "Hüseyin'de",
    "Hüseyin'den",
    "Hüseyin'le",
  ],
  'İbrahim': [
    "İbrahim'e",
    "İbrahim'i",
    "İbrahim'in",
    "İbrahim'de",
    "İbrahim'den",
    "İbrahim'le",
  ],
  'Selin': [
    "Selin'e",
    "Selin'i",
    "Selin'in",
    "Selin'de",
    "Selin'den",
    "Selin'le",
  ],
  'Ömür': ["Ömür'e", "Ömür'ü", "Ömür'ün", "Ömür'de", "Ömür'den", "Ömür'le"],
  'Gönül': [
    "Gönül'e",
    "Gönül'ü",
    "Gönül'ün",
    "Gönül'de",
    "Gönül'den",
    "Gönül'le",
  ],
  // Ünlüyle biten (kaynaştırma)
  'Mustafa': [
    "Mustafa'ya",
    "Mustafa'yı",
    "Mustafa'nın",
    "Mustafa'da",
    "Mustafa'dan",
    "Mustafa'yla",
  ],
  'Fatma': [
    "Fatma'ya",
    "Fatma'yı",
    "Fatma'nın",
    "Fatma'da",
    "Fatma'dan",
    "Fatma'yla",
  ],
  'Esra': ["Esra'ya", "Esra'yı", "Esra'nın", "Esra'da", "Esra'dan", "Esra'yla"],
  'Asya': ["Asya'ya", "Asya'yı", "Asya'nın", "Asya'da", "Asya'dan", "Asya'yla"],
  'Zehra': [
    "Zehra'ya",
    "Zehra'yı",
    "Zehra'nın",
    "Zehra'da",
    "Zehra'dan",
    "Zehra'yla",
  ],
  'Büşra': [
    "Büşra'ya",
    "Büşra'yı",
    "Büşra'nın",
    "Büşra'da",
    "Büşra'dan",
    "Büşra'yla",
  ],
  'Ali': ["Ali'ye", "Ali'yi", "Ali'nin", "Ali'de", "Ali'den", "Ali'yle"],
  'Ayşe': ["Ayşe'ye", "Ayşe'yi", "Ayşe'nin", "Ayşe'de", "Ayşe'den", "Ayşe'yle"],
  'Emre': ["Emre'ye", "Emre'yi", "Emre'nin", "Emre'de", "Emre'den", "Emre'yle"],
  'Emine': [
    "Emine'ye",
    "Emine'yi",
    "Emine'nin",
    "Emine'de",
    "Emine'den",
    "Emine'yle",
  ],
  'Hatice': [
    "Hatice'ye",
    "Hatice'yi",
    "Hatice'nin",
    "Hatice'de",
    "Hatice'den",
    "Hatice'yle",
  ],
  'Merve': [
    "Merve'ye",
    "Merve'yi",
    "Merve'nin",
    "Merve'de",
    "Merve'den",
    "Merve'yle",
  ],
  'Defne': [
    "Defne'ye",
    "Defne'yi",
    "Defne'nin",
    "Defne'de",
    "Defne'den",
    "Defne'yle",
  ],
  'Ece': ["Ece'ye", "Ece'yi", "Ece'nin", "Ece'de", "Ece'den", "Ece'yle"],
  'Burcu': [
    "Burcu'ya",
    "Burcu'yu",
    "Burcu'nun",
    "Burcu'da",
    "Burcu'dan",
    "Burcu'yla",
  ],
  'Doğu': ["Doğu'ya", "Doğu'yu", "Doğu'nun", "Doğu'da", "Doğu'dan", "Doğu'yla"],
  'Hüsnü': [
    "Hüsnü'ye",
    "Hüsnü'yü",
    "Hüsnü'nün",
    "Hüsnü'de",
    "Hüsnü'den",
    "Hüsnü'yle",
  ],
  // Kalın ünlüyle bitip ince ek alan istisnalar
  'Kemal': [
    "Kemal'e",
    "Kemal'i",
    "Kemal'in",
    "Kemal'de",
    "Kemal'den",
    "Kemal'le",
  ],
  'Meral': [
    "Meral'e",
    "Meral'i",
    "Meral'in",
    "Meral'de",
    "Meral'den",
    "Meral'le",
  ],
};

const _order = [
  Suffix.e,
  Suffix.i,
  Suffix.in_,
  Suffix.de,
  Suffix.den,
  Suffix.le,
];

void main() {
  group('özel adlara ek', () {
    for (final MapEntry(key: name, value: forms) in _expected.entries) {
      test(name, () {
        for (var k = 0; k < _order.length; k++) {
          expect(withSuffix(name, _order[k]), forms[k], reason: _order[k].key);
        }
      });
    }

    test('oyunun bütün ad listeleri beklenti tablosunda', () {
      final all = [...BirthGenerator.maleNames, ...BirthGenerator.femaleNames];
      final missing = all.where((n) => !_expected.containsKey(n)).toList();
      expect(missing, isEmpty, reason: 'yeni ad eklendiyse beklentisini yaz');
    });

    test('çok kelimeli adda son kelimeye bakılır', () {
      expect(withSuffix('Hüsnü Amca', Suffix.e), "Hüsnü Amca'ya");
      expect(withSuffix('Ayşe Nur', Suffix.in_), "Ayşe Nur'un");
      expect(withSuffix('Recep Tayfun', Suffix.de), "Recep Tayfun'da");
    });

    test('büyük harfle yazılmış ad', () {
      expect(withSuffix('İREM', Suffix.e), "İREM'e");
      expect(withSuffix('IŞIL', Suffix.i), "IŞIL'ı");
    });

    test('ünlüsüz kısaltma harf adıyla okunur', () {
      expect(withSuffix('BMW', Suffix.e), "BMW'e");
    });
  });

  group('cins adlara ek (kesme işareti yok)', () {
    test('rol adları', () {
      expect(withSuffix('teyze', Suffix.e, proper: false), 'teyzeye');
      expect(withSuffix('amca', Suffix.in_, proper: false), 'amcanın');
      expect(withSuffix('bakkal', Suffix.e, proper: false), 'bakkala');
      expect(withSuffix('kardeş', Suffix.i, proper: false), 'kardeşi');
      expect(withSuffix('komşu', Suffix.de, proper: false), 'komşuda');
      expect(withSuffix('dede', Suffix.le, proper: false), 'dedeyle');
      expect(withSuffix('anne', Suffix.den, proper: false), 'anneden');
      expect(withSuffix('patron', Suffix.in_, proper: false), 'patronun');
      expect(withSuffix('müdür', Suffix.e, proper: false), 'müdüre');
      expect(withSuffix('kuzen', Suffix.le, proper: false), 'kuzenle');
    });
  });

  group('hitaplar', () {
    test('cinsiyete göre', () {
      expect(Address.abi.forGender(Gender.erkek), 'abi');
      expect(Address.abi.forGender(Gender.kadin), 'abla');
      expect(Address.evlat.forGender(Gender.erkek), 'oğlum');
      expect(Address.evlat.forGender(Gender.kadin), 'kızım');
      expect(Address.amca.forGender(Gender.kadin), 'teyze');
      expect(Address.bey.forGender(Gender.kadin), 'Hanım');
    });

    test('her hitabın şablon adı benzersiz', () {
      final keys = Address.values.map((a) => a.key).toSet();
      expect(keys, hasLength(Address.values.length));
      for (final a in Address.values) {
        expect(Address.fromKey(a.key), a);
      }
    });
  });

  group('şablon', () {
    TemplateValue? resolve(String path) => switch (path) {
      'kerem.ad' => const TemplateValue('Kerem'),
      'musteri.ad' => const TemplateValue('Ayşe'),
      'oyuncu.ad' => const TemplateValue('Murat'),
      'kerem.rol' => const TemplateValue('kuzen', proper: false),
      'anne.hitap.evlat' => const TemplateValue('kızım', proper: false),
      _ => null,
    };

    test('yer tutucular ve ekler çözülür', () {
      expect(
        renderTemplate('{kerem.ad} seni {musteri.ad|e} kötülemiş.', resolve),
        "Kerem seni Ayşe'ye kötülemiş.",
      );
      expect(
        renderTemplate(
          '{oyuncu.ad|in} kuzeni, yani {kerem.rol|in} annesi.',
          resolve,
        ),
        "Murat'ın kuzeni, yani kuzenin annesi.",
      );
      expect(
        renderTemplate('"Yemek yedin mi {anne.hitap.evlat}?"', resolve),
        '"Yemek yedin mi kızım?"',
      );
    });

    test('yer tutucusuz metin aynen döner', () {
      expect(renderTemplate('Teneffüs bitti.', resolve), 'Teneffüs bitti.');
    });

    test('çözülemeyen yer tutucu hata verir', () {
      expect(
        () => renderTemplate('{yok.ad} geldi.', resolve),
        throwsStateError,
      );
    });

    test('yer tutucular sırayla ayrıştırılır', () {
      final tokens = parseTemplate('{a.ad|e} ve {b.ad} ile {c.ad|le}');
      expect(tokens.map((t) => t.path), ['a.ad', 'b.ad', 'c.ad']);
      expect(tokens.map((t) => t.suffix), [Suffix.e, null, Suffix.le]);
    });

    group('denetim', () {
      List<String> problems(String t) =>
          templateProblems(t).map((p) => p.message).toList();

      test('temiz şablon', () {
        expect(problems('{kerem.ad} seni {musteri.ad|e} kötülemiş.'), isEmpty);
        expect(problems('"{kerem.ad}!" dedi, {kerem.ad}.'), isEmpty);
      });

      test('elle yazılmış ek yakalanır', () {
        expect(problems("{kerem.ad}'e söyle"), [contains('elle yazılmış ek')]);
        expect(problems('{kerem.ad}’in evi'), [contains('elle yazılmış ek')]);
        expect(problems('{kerem.ad}e söyle'), [contains('bitişik harf')]);
      });

      test('bilinmeyen ek yakalanır', () {
        expect(problems('{kerem.ad|a} git'), [contains('bilinmeyen ek')]);
      });

      test('bozuk yol yakalanır', () {
        expect(problems('{Kerem Ad} geldi'), [contains('bozuk yer tutucu')]);
        expect(problems('{} geldi'), [contains('bozuk yer tutucu')]);
      });

      test('parantez dengesi', () {
        expect(problems('{kerem.ad geldi'), [contains('kapanmamış')]);
        expect(problems('kerem.ad} geldi'), [contains('açılmamış')]);
      });

      test('bozuk şablon çözülmeye çalışılınca hata verir', () {
        expect(
          () => renderTemplate("{kerem.ad}'e", resolve),
          throwsFormatException,
        );
      });
    });
  });

  test('büyük ve küçük harf', () {
    expect(lowerTr('IŞIK İĞNE'), 'ışık iğne');
    expect(upperTr('bir ömür ışığı'), 'BİR ÖMÜR IŞIĞI');
  });
}
