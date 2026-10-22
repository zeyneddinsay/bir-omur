import '../models/models.dart';
import 'turkish.dart';

/// Bir kişi hakkındaki metinlerde kullanılabilen yer tutucular:
///
/// - `{kisi.ad}`, `{kisi.soyad}`
/// - `{kisi.hitap.abi}` (abi/abla), `.evlat`, `.amca`, `.bey`
/// - `{kisi.akraba}`: oyuncunun ağzından akrabalık ("deden", "babaannen",
///   "dayın"); akraba değilse adı
/// - `{oyuncu.ad}`
///
/// Ekler `{kisi.ad|e}` gibi eklenir (bkz. [renderTemplate]).
abstract final class PersonText {
  /// Kişi metinlerinde izin verilen yollar (card_lint ve yükleyici denetler).
  static final Set<String> allowedPaths = {
    'kisi.ad',
    'kisi.soyad',
    'kisi.akraba',
    'oyuncu.ad',
    for (final a in Address.values) 'kisi.hitap.${a.key}',
  };

  /// Oyuncunun ağzından akrabalık sözcüğü (iyelik ekiyle). Akraba değilse
  /// null.
  static String? kinWord(Person p) => switch (p.kin) {
    null => null,
    Kinship.anne => 'annen',
    Kinship.baba => 'baban',
    Kinship.kardes => 'kardeşin',
    Kinship.dede => 'deden',
    Kinship.nine => p.side == Side.anne ? 'anneannen' : 'babaannen',
    Kinship.amca => 'amcan',
    Kinship.hala => 'halan',
    Kinship.dayi => 'dayın',
    Kinship.teyze => 'teyzen',
    Kinship.kuzen => 'kuzenin',
    Kinship.yegen => 'yeğenin',
    Kinship.es => 'eşin',
    Kinship.cocuk => 'çocuğun',
    Kinship.gelin => 'gelinin',
    Kinship.damat => 'damadın',
    Kinship.torun => 'torunun',
    Kinship.kayinvalide => 'kayınvaliden',
    Kinship.kayinpeder => 'kayınpederin',
    Kinship.gorumce => 'görümcen',
    Kinship.baldiz => 'baldızın',
    Kinship.kayinbirader => 'kayınbiraderin',
    Kinship.bacanak => 'bacanağın',
    Kinship.elti => 'eltin',
  };

  static TemplateValue? resolve(String path, Person p, Character c) {
    if (path == 'kisi.ad') return TemplateValue(p.name);
    if (path == 'kisi.soyad') return TemplateValue(p.surname);
    if (path == 'oyuncu.ad') return TemplateValue(c.name);
    if (path == 'kisi.akraba') {
      final word = kinWord(p);
      return word == null
          ? TemplateValue(p.name)
          : TemplateValue(word, proper: false);
    }
    const prefix = 'kisi.hitap.';
    if (path.startsWith(prefix)) {
      final address = Address.fromKey(path.substring(prefix.length));
      if (address == null) return null;
      return TemplateValue(address.forGender(p.gender), proper: false);
    }
    return null;
  }

  /// Şablonu kişiye ve oyuncuya göre kurar; ilk harf büyük yazılır.
  static String render(String template, Person p, Character c) =>
      capitalizeFirst(renderTemplate(template, (path) => resolve(path, p, c)));

  /// İlk harfi Türkçe kurala göre büyütür ("dedenin" → "Dedenin").
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return upperTr(text[0]) + text.substring(1);
  }
}
