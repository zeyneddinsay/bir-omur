/// Kartlarda ve rozetlerde incelenmesi gereken kelimeler (CLAUDE.md, kart
/// yazım kuralları). Bir eşleşme hata değil uyarıdır: kelime masum bir
/// anlamda da geçebilir. İncelenen kullanımlar `registry.json` içindeki
/// `reviewedTerms` listesine yazılır ve bir daha uyarı vermez.
library;

import 'turkish.dart';

export 'turkish.dart' show lowerTr;

class SensitiveTerm {
  const SensitiveTerm(this.term, this.category, {this.wholeWord = false});

  /// Küçük harfle (Türkçe kurallarıyla) yazılır.
  final String term;
  final String category;

  /// true: yalnızca tam kelime eşleşir ("laz" → "lazım" eşleşmez).
  /// false: kelime başı eşleşir ("ezan" → "ezanına" eşleşir).
  final bool wholeWord;
}

const _siyaset = 'siyaset';
const _din = 'din ve mezhep';
const _etnik = 'etnik köken ve bölge';
const _marka = 'gerçek marka ya da kulüp';
const _kumar = 'kumar';
const _madde = 'alkol ve madde';
const _siddet = 'şiddet ve kendine zarar';
const _asagilama = 'aşağılama';

const List<SensitiveTerm> sensitiveTerms = [
  // Siyaset
  SensitiveTerm('parti', _siyaset),
  SensitiveTerm('seçim', _siyaset),
  SensitiveTerm('milletvekil', _siyaset),
  SensitiveTerm('cumhurbaşkan', _siyaset),
  SensitiveTerm('başbakan', _siyaset),
  SensitiveTerm('meclis', _siyaset),
  SensitiveTerm('miting', _siyaset),
  SensitiveTerm('darbe', _siyaset),
  // Din ve mezhep
  SensitiveTerm('allah', _din),
  SensitiveTerm('namaz', _din),
  SensitiveTerm('cami', _din),
  SensitiveTerm('ezan', _din),
  SensitiveTerm('oruç', _din),
  SensitiveTerm('kuran', _din),
  SensitiveTerm("kur'an", _din),
  SensitiveTerm('dua', _din, wholeWord: true),
  SensitiveTerm('maşallah', _din),
  SensitiveTerm('inşallah', _din),
  SensitiveTerm('hacı', _din),
  SensitiveTerm('imam', _din),
  SensitiveTerm('kilise', _din),
  SensitiveTerm('sinagog', _din),
  SensitiveTerm('mezhep', _din),
  SensitiveTerm('alevi', _din),
  SensitiveTerm('sünni', _din),
  SensitiveTerm('sünnet', _din),
  SensitiveTerm('tarikat', _din),
  SensitiveTerm('şeriat', _din),
  // Etnik köken ve bölge
  SensitiveTerm('kürt', _etnik),
  SensitiveTerm('laz', _etnik, wholeWord: true),
  SensitiveTerm('lazlar', _etnik),
  SensitiveTerm('çingene', _etnik),
  SensitiveTerm('roman', _etnik, wholeWord: true),
  SensitiveTerm('ermeni', _etnik),
  SensitiveTerm('rum', _etnik, wholeWord: true),
  SensitiveTerm('yahudi', _etnik),
  SensitiveTerm('arap', _etnik, wholeWord: true),
  SensitiveTerm('suriyeli', _etnik),
  SensitiveTerm('zenci', _etnik),
  SensitiveTerm('doğulu', _etnik),
  SensitiveTerm('karadenizli', _etnik),
  // Gerçek marka ya da kulüp
  SensitiveTerm('whatsapp', _marka),
  SensitiveTerm('instagram', _marka),
  SensitiveTerm('tiktok', _marka),
  SensitiveTerm('facebook', _marka),
  SensitiveTerm('twitter', _marka),
  SensitiveTerm('youtube', _marka),
  SensitiveTerm('google', _marka),
  SensitiveTerm('netflix', _marka),
  SensitiveTerm('iphone', _marka),
  SensitiveTerm('samsung', _marka),
  SensitiveTerm('apple', _marka),
  SensitiveTerm('coca', _marka),
  SensitiveTerm('pepsi', _marka),
  SensitiveTerm('migros', _marka),
  SensitiveTerm('bim', _marka, wholeWord: true),
  SensitiveTerm('a101', _marka),
  SensitiveTerm('ülker', _marka),
  SensitiveTerm('fenerbahçe', _marka),
  SensitiveTerm('galatasaray', _marka),
  SensitiveTerm('beşiktaş', _marka),
  SensitiveTerm('trabzonspor', _marka),
  // Kumar
  SensitiveTerm('kumar', _kumar),
  SensitiveTerm('bahis', _kumar),
  SensitiveTerm('iddaa', _kumar),
  SensitiveTerm('piyango', _kumar),
  SensitiveTerm('kazı kazan', _kumar),
  SensitiveTerm('rulet', _kumar),
  SensitiveTerm('poker', _kumar),
  SensitiveTerm('kumarhane', _kumar),
  // Alkol ve madde
  SensitiveTerm('rakı', _madde),
  SensitiveTerm('bira', _madde, wholeWord: true),
  SensitiveTerm('biralar', _madde),
  SensitiveTerm('şarap', _madde),
  SensitiveTerm('alkol', _madde),
  SensitiveTerm('sarhoş', _madde),
  SensitiveTerm('uyuşturucu', _madde),
  SensitiveTerm('esrar', _madde),
  SensitiveTerm('sigara', _madde),
  // Şiddet ve kendine zarar
  SensitiveTerm('intihar', _siddet),
  SensitiveTerm('öldür', _siddet),
  SensitiveTerm('bıçak', _siddet),
  SensitiveTerm('silah', _siddet),
  SensitiveTerm('tecavüz', _siddet),
  SensitiveTerm('taciz', _siddet),
  SensitiveTerm('dövdü', _siddet),
  SensitiveTerm('döver', _siddet, wholeWord: true),
  SensitiveTerm('dövüyor', _siddet),
  SensitiveTerm('zehir', _siddet),
  // Aşağılama
  SensitiveTerm('özürlü', _asagilama),
  SensitiveTerm('sakat', _asagilama),
  SensitiveTerm('geri zekalı', _asagilama),
  SensitiveTerm('salak', _asagilama),
  SensitiveTerm('aptal', _asagilama),
  SensitiveTerm('ibne', _asagilama),
  SensitiveTerm('karı', _asagilama, wholeWord: true),
  SensitiveTerm('kaşar', _asagilama),
];

/// Metinde geçen incelenecek kelimeler.
List<SensitiveTerm> findSensitiveTerms(String text) {
  final lower = lowerTr(text);
  const letters = 'a-zçğıöşüâîû0-9';
  return [
    for (final t in sensitiveTerms)
      if (RegExp(
        '(?<![$letters])${RegExp.escape(t.term)}'
        '${t.wholeWord ? '(?![$letters])' : ''}',
      ).hasMatch(lower))
        t,
  ];
}
