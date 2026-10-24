import 'package:bir_omur/content/turkish.dart';

import 'dart:convert';
import 'dart:io';

import 'package:bir_omur/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ad → [e, i, in, de, den, le] ekli hâlleri (elle hesaplandı).
const Map<String, List<String>> _expected = {
  // Yeni adlar (assets/names.json)
  'Emir': ["Emir'e", "Emir'i", "Emir'in", "Emir'de", "Emir'den", "Emir'le"],
  'Mert': ["Mert'e", "Mert'i", "Mert'in", "Mert'te", "Mert'ten", "Mert'le"],
  'Berk': ["Berk'e", "Berk'i", "Berk'in", "Berk'te", "Berk'ten", "Berk'le"],
  'Yiğit': [
    "Yiğit'e",
    "Yiğit'i",
    "Yiğit'in",
    "Yiğit'te",
    "Yiğit'ten",
    "Yiğit'le",
  ],
  'Aras': ["Aras'a", "Aras'ı", "Aras'ın", "Aras'ta", "Aras'tan", "Aras'la"],
  'Eren': ["Eren'e", "Eren'i", "Eren'in", "Eren'de", "Eren'den", "Eren'le"],
  'Baran': [
    "Baran'a",
    "Baran'ı",
    "Baran'ın",
    "Baran'da",
    "Baran'dan",
    "Baran'la",
  ],
  'Enes': ["Enes'e", "Enes'i", "Enes'in", "Enes'te", "Enes'ten", "Enes'le"],
  'Furkan': [
    "Furkan'a",
    "Furkan'ı",
    "Furkan'ın",
    "Furkan'da",
    "Furkan'dan",
    "Furkan'la",
  ],
  'Oğuz': ["Oğuz'a", "Oğuz'u", "Oğuz'un", "Oğuz'da", "Oğuz'dan", "Oğuz'la"],
  'Doruk': [
    "Doruk'a",
    "Doruk'u",
    "Doruk'un",
    "Doruk'ta",
    "Doruk'tan",
    "Doruk'la",
  ],
  'Batuhan': [
    "Batuhan'a",
    "Batuhan'ı",
    "Batuhan'ın",
    "Batuhan'da",
    "Batuhan'dan",
    "Batuhan'la",
  ],
  'Nisa': ["Nisa'ya", "Nisa'yı", "Nisa'nın", "Nisa'da", "Nisa'dan", "Nisa'yla"],
  'Azra': ["Azra'ya", "Azra'yı", "Azra'nın", "Azra'da", "Azra'dan", "Azra'yla"],
  'Ceren': [
    "Ceren'e",
    "Ceren'i",
    "Ceren'in",
    "Ceren'de",
    "Ceren'den",
    "Ceren'le",
  ],
  'Buse': ["Buse'ye", "Buse'yi", "Buse'nin", "Buse'de", "Buse'den", "Buse'yle"],
  'Sude': ["Sude'ye", "Sude'yi", "Sude'nin", "Sude'de", "Sude'den", "Sude'yle"],
  'Beren': [
    "Beren'e",
    "Beren'i",
    "Beren'in",
    "Beren'de",
    "Beren'den",
    "Beren'le",
  ],
  'Ecrin': [
    "Ecrin'e",
    "Ecrin'i",
    "Ecrin'in",
    "Ecrin'de",
    "Ecrin'den",
    "Ecrin'le",
  ],
  'İrem': ["İrem'e", "İrem'i", "İrem'in", "İrem'de", "İrem'den", "İrem'le"],
  'Damla': [
    "Damla'ya",
    "Damla'yı",
    "Damla'nın",
    "Damla'da",
    "Damla'dan",
    "Damla'yla",
  ],
  'Eylül': [
    "Eylül'e",
    "Eylül'ü",
    "Eylül'ün",
    "Eylül'de",
    "Eylül'den",
    "Eylül'le",
  ],
  'Ela': ["Ela'ya", "Ela'yı", "Ela'nın", "Ela'da", "Ela'dan", "Ela'yla"],
  'Dilara': [
    "Dilara'ya",
    "Dilara'yı",
    "Dilara'nın",
    "Dilara'da",
    "Dilara'dan",
    "Dilara'yla",
  ],
  'Serkan': [
    "Serkan'a",
    "Serkan'ı",
    "Serkan'ın",
    "Serkan'da",
    "Serkan'dan",
    "Serkan'la",
  ],
  'Tolga': [
    "Tolga'ya",
    "Tolga'yı",
    "Tolga'nın",
    "Tolga'da",
    "Tolga'dan",
    "Tolga'yla",
  ],
  'Barış': [
    "Barış'a",
    "Barış'ı",
    "Barış'ın",
    "Barış'ta",
    "Barış'tan",
    "Barış'la",
  ],
  'Onur': ["Onur'a", "Onur'u", "Onur'un", "Onur'da", "Onur'dan", "Onur'la"],
  'Cem': ["Cem'e", "Cem'i", "Cem'in", "Cem'de", "Cem'den", "Cem'le"],
  'Volkan': [
    "Volkan'a",
    "Volkan'ı",
    "Volkan'ın",
    "Volkan'da",
    "Volkan'dan",
    "Volkan'la",
  ],
  'Selim': [
    "Selim'e",
    "Selim'i",
    "Selim'in",
    "Selim'de",
    "Selim'den",
    "Selim'le",
  ],
  'Arda': ["Arda'ya", "Arda'yı", "Arda'nın", "Arda'da", "Arda'dan", "Arda'yla"],
  'Efe': ["Efe'ye", "Efe'yi", "Efe'nin", "Efe'de", "Efe'den", "Efe'yle"],
  'Kaan': ["Kaan'a", "Kaan'ı", "Kaan'ın", "Kaan'da", "Kaan'dan", "Kaan'la"],
  'Erkan': [
    "Erkan'a",
    "Erkan'ı",
    "Erkan'ın",
    "Erkan'da",
    "Erkan'dan",
    "Erkan'la",
  ],
  'Sinan': [
    "Sinan'a",
    "Sinan'ı",
    "Sinan'ın",
    "Sinan'da",
    "Sinan'dan",
    "Sinan'la",
  ],
  'Halil': [
    "Halil'e",
    "Halil'i",
    "Halil'in",
    "Halil'de",
    "Halil'den",
    "Halil'le",
  ],
  'Necla': [
    "Necla'ya",
    "Necla'yı",
    "Necla'nın",
    "Necla'da",
    "Necla'dan",
    "Necla'yla",
  ],
  'Sevgi': [
    "Sevgi'ye",
    "Sevgi'yi",
    "Sevgi'nin",
    "Sevgi'de",
    "Sevgi'den",
    "Sevgi'yle",
  ],
  'Derya': [
    "Derya'ya",
    "Derya'yı",
    "Derya'nın",
    "Derya'da",
    "Derya'dan",
    "Derya'yla",
  ],
  'Gül': ["Gül'e", "Gül'ü", "Gül'ün", "Gül'de", "Gül'den", "Gül'le"],
  'Özlem': [
    "Özlem'e",
    "Özlem'i",
    "Özlem'in",
    "Özlem'de",
    "Özlem'den",
    "Özlem'le",
  ],
  'Pınar': [
    "Pınar'a",
    "Pınar'ı",
    "Pınar'ın",
    "Pınar'da",
    "Pınar'dan",
    "Pınar'la",
  ],
  'Songül': [
    "Songül'e",
    "Songül'ü",
    "Songül'ün",
    "Songül'de",
    "Songül'den",
    "Songül'le",
  ],
  'Tuba': ["Tuba'ya", "Tuba'yı", "Tuba'nın", "Tuba'da", "Tuba'dan", "Tuba'yla"],
  'İpek': ["İpek'e", "İpek'i", "İpek'in", "İpek'te", "İpek'ten", "İpek'le"],
  'Melis': [
    "Melis'e",
    "Melis'i",
    "Melis'in",
    "Melis'te",
    "Melis'ten",
    "Melis'le",
  ],
  'Duygu': [
    "Duygu'ya",
    "Duygu'yu",
    "Duygu'nun",
    "Duygu'da",
    "Duygu'dan",
    "Duygu'yla",
  ],
  'Yasemin': [
    "Yasemin'e",
    "Yasemin'i",
    "Yasemin'in",
    "Yasemin'de",
    "Yasemin'den",
    "Yasemin'le",
  ],
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
      final json = jsonDecode(
        File('assets/names.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final all = [
        for (final key in ['male', 'female'])
          for (final entry in json[key] as List)
            (entry as Map<String, dynamic>)['name'] as String,
      ];
      expect(all, hasLength(84));
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

  test('soru eki ayrı ve uyumlu yazılır', () {
    expect(withSuffix('Ahmet', Suffix.mi), 'Ahmet mi');
    expect(withSuffix('Can', Suffix.mi), 'Can mı');
    expect(withSuffix('Umut', Suffix.mi), 'Umut mu');
    expect(withSuffix('Gül', Suffix.mi), 'Gül mü');
    expect(withSuffix('Ayşe', Suffix.mi), 'Ayşe mi');
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

      test('yer tutucudan sonra elle yazılmış de/da ve mi yakalanır', () {
        expect(problems('{kerem.ad} de geldi'), [
          contains('elle yazılmış "de"'),
        ]);
        expect(problems('{anne.akraba} da gitti.'), [contains('"da"')]);
        expect(problems('{kerem.ad} mi?'), [contains('"mi"')]);
        expect(problems('{kerem.ad} dedi ki'), isEmpty);
        expect(problems('{kerem.ad} bile geldi'), isEmpty);
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
