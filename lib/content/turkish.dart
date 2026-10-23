/// Türkçe metin yardımcıları: büyük-küçük harf, hâl ekleri ve olay
/// metinlerindeki yer tutucular. Saf Dart'tır; motor, card_lint ve arayüz
/// aynı kodu kullanır.
library;

import '../models/character.dart' show Gender;

/// Türkçe küçük harf: "I" → "ı", "İ" → "i".
String lowerTr(String text) =>
    text.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();

/// Türkçe büyük harf: "i" → "İ", "ı" → "I".
String upperTr(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Yer tutucunun arkasına eklenebilen hâl ekleri. [key], şablondaki
/// `{ad|e}` yazımında `|` işaretinden sonra gelen addır.
enum Suffix {
  /// Yönelme: Murat'a, Ayşe'ye.
  e('e'),

  /// Belirtme: Murat'ı, Ayşe'yi.
  i('i'),

  /// İlgi: Murat'ın, Ayşe'nin.
  in_('in'),

  /// Bulunma: Murat'ta, Ayşe'de.
  de('de'),

  /// Ayrılma: Murat'tan, Ayşe'den.
  den('den'),

  /// Birliktelik ("ile"): Murat'la, Ayşe'yle.
  le('le'),

  /// Soru eki, ayrı yazılır: Ahmet mi, Can mı, Umut mu.
  mi('mi');

  const Suffix(this.key);

  final String key;

  static Suffix? fromKey(String key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

const _backVowels = 'aıou';
const _frontVowels = 'eiöü';
const _vowels = '$_backVowels$_frontVowels';

/// Sert ünsüzler (fıstıkçı şahap): bulunma ve ayrılma ekinde d → t.
const _hardConsonants = 'fstkçşhp';

/// Son hecesi kalın olduğu hâlde ince ek alan adlar ve kelimeler
/// ("Kemal'e", "Meral'in"). Küçük harfle yazılır.
const Set<String> frontHarmonyExceptions = {
  'kemal',
  'celal',
  'cemal',
  'bilal',
  'hilal',
  'nihal',
  'iclal',
  'meral',
  'jale',
  'saat',
  'hayal',
  'helal',
  'kontrol',
  'gol',
  'alkol',
  'rol',
};

/// [word]e [suffix] ekini ünlü uyumuna ve kaynaştırma harfine göre ekler.
///
/// [proper] true ise (özel ad) araya kesme işareti girer ve ünsüz
/// yumuşaması yapılmaz: "Ahmet'e", "Burak'ı". false ise kesme işareti
/// yoktur: "teyzeye", "amcanın". Cins adlarda ünsüz yumuşaması (kitap →
/// kitabı) yapılmaz; şablonlarda yalnızca yumuşamayan rol adları kullanılır
/// (teyze, amca, bakkal, komşu, kardeş).
String withSuffix(String word, Suffix suffix, {bool proper = true}) {
  final trimmed = word.trimRight();
  if (trimmed.isEmpty) return word;
  final lower = lowerTr(_lastWord(trimmed));
  final lastChar = lower[lower.length - 1];
  final endsWithVowel = _vowels.contains(lastChar);
  final harmony = _harmonyOf(lower);
  final back = harmony.back;
  final rounded = harmony.rounded;

  // İki yönlü ünlü: a/e. Dört yönlü ünlü: ı/i/u/ü.
  final two = back ? 'a' : 'e';
  final four = back ? (rounded ? 'u' : 'ı') : (rounded ? 'ü' : 'i');
  final d = _hardConsonants.contains(lastChar) ? 't' : 'd';

  final ending = switch (suffix) {
    Suffix.e => endsWithVowel ? 'y$two' : two,
    Suffix.i => endsWithVowel ? 'y$four' : four,
    Suffix.in_ => endsWithVowel ? 'n${four}n' : '${four}n',
    Suffix.de => '$d$two',
    Suffix.den => '$d${two}n',
    Suffix.le => endsWithVowel ? 'yl$two' : 'l$two',
    Suffix.mi => 'm$four',
  };
  if (suffix == Suffix.mi) return '$trimmed $ending';
  return proper ? "$trimmed'$ending" : '$trimmed$ending';
}

String _lastWord(String text) {
  final space = text.lastIndexOf(' ');
  return space < 0 ? text : text.substring(space + 1);
}

({bool back, bool rounded}) _harmonyOf(String lowerWord) {
  if (frontHarmonyExceptions.contains(lowerWord)) {
    final last = _lastVowel(lowerWord);
    return (back: false, rounded: last == 'o' || last == 'u');
  }
  final last = _lastVowel(lowerWord);
  // Ünlüsüz kelimeler (kısaltma gibi) harf adıyla okunur: "be", "ce".
  if (last == null) return (back: false, rounded: false);
  return (back: _backVowels.contains(last), rounded: 'ouöü'.contains(last));
}

String? _lastVowel(String lowerWord) {
  for (var i = lowerWord.length - 1; i >= 0; i--) {
    final c = lowerWord[i];
    if (_vowels.contains(c)) return c;
    // Şapkalı ünlüler: â kalın, î ve û ince/yuvarlak sayılır.
    if (c == 'â') return 'a';
    if (c == 'î') return 'i';
    if (c == 'û') return 'u';
  }
  return null;
}

/// Kişiye göre değişen hitaplar. Şablonda `{kişi.hitap.abi}` gibi yazılır.
enum Address {
  /// Yaşça büyük tanıdık: abi / abla.
  abi('abi'),

  /// Anne ya da babanın çocuğuna seslenişi: oğlum / kızım.
  evlat('evlat'),

  /// Yaşça çok büyük tanıdık: amca / teyze. Kişi metinlerinde yaş farkına
  /// göre abi/abla ya da Bey/Hanım'a döner (`PersonText.elderAddress`).
  amca('amca'),

  /// Resmî: Bey / Hanım (addan sonra).
  bey('bey');

  const Address(this.key);

  final String key;

  static Address? fromKey(String key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return null;
  }

  String forGender(Gender gender) => switch ((this, gender)) {
    (Address.abi, Gender.erkek) => 'abi',
    (Address.abi, Gender.kadin) => 'abla',
    (Address.evlat, Gender.erkek) => 'oğlum',
    (Address.evlat, Gender.kadin) => 'kızım',
    (Address.amca, Gender.erkek) => 'amca',
    (Address.amca, Gender.kadin) => 'teyze',
    (Address.bey, Gender.erkek) => 'Bey',
    (Address.bey, Gender.kadin) => 'Hanım',
  };
}

/// Bir yer tutucunun çözülmüş değeri. [proper] true ise özel addır ve ek
/// kesme işaretiyle eklenir.
class TemplateValue {
  const TemplateValue(this.text, {this.proper = true});

  final String text;
  final bool proper;
}

/// Şablondaki tek bir yer tutucu: `{yol}` ya da `{yol|ek}`.
class TemplateToken {
  const TemplateToken({
    required this.path,
    required this.suffix,
    required this.start,
    required this.end,
  });

  /// Noktalı yol: `kerem.ad`, `oyuncu.ad`, `anne.hitap.evlat`.
  final String path;

  /// Ek yoksa null.
  final Suffix? suffix;

  /// Şablondaki konumu ([start] dahil, [end] hariç).
  final int start;
  final int end;
}

/// Şablonu çözmeye ya da denetlemeye engel olan bir sorun.
class TemplateProblem {
  const TemplateProblem(this.message, this.offset);

  final String message;
  final int offset;

  @override
  String toString() => '$message (konum $offset)';
}

final RegExp _tokenPattern = RegExp(r'\{([^{}|]*)(?:\|([^{}]*))?\}');
final RegExp _pathPattern = RegExp(r'^[a-zçğıöşü_]+(\.[a-zçğıöşü_]+)*$');
final RegExp _letter = RegExp(r"[A-Za-zÇĞİIÖŞÜçğıiöşüâîû]");

/// Şablondaki yer tutucular, yazıldıkları sırayla. Biçimi bozuk olanlar
/// [templateProblems] ile bulunur; burada atlanır.
List<TemplateToken> parseTemplate(String template) => [
  for (final m in _tokenPattern.allMatches(template))
    if (_pathPattern.hasMatch(m[1]!) &&
        (m[2] == null || Suffix.fromKey(m[2]!) != null))
      TemplateToken(
        path: m[1]!,
        suffix: m[2] == null ? null : Suffix.fromKey(m[2]!),
        start: m.start,
        end: m.end,
      ),
];

/// card_lint için şablon denetimi: kapanmamış süslü parantez, bilinmeyen
/// ek, bozuk yol ve yer tutucunun arkasına elle yazılmış ek ("{ad}'e",
/// "{ad}e"). Ek her zaman `{ad|e}` biçiminde yazılmalı.
List<TemplateProblem> templateProblems(String template) {
  final problems = <TemplateProblem>[];
  var depth = 0;
  for (var i = 0; i < template.length; i++) {
    final c = template[i];
    if (c == '{') {
      if (depth > 0) problems.add(TemplateProblem('iç içe süslü parantez', i));
      depth++;
    } else if (c == '}') {
      if (depth == 0) {
        problems.add(TemplateProblem('açılmamış süslü parantez', i));
      } else {
        depth--;
      }
    }
  }
  if (depth > 0) {
    problems.add(TemplateProblem('kapanmamış süslü parantez', template.length));
  }
  for (final m in _tokenPattern.allMatches(template)) {
    final path = m[1]!;
    final suffix = m[2];
    if (!_pathPattern.hasMatch(path)) {
      problems.add(TemplateProblem('bozuk yer tutucu "{$path}"', m.start));
    }
    if (suffix != null && Suffix.fromKey(suffix) == null) {
      problems.add(
        TemplateProblem(
          'bilinmeyen ek "$suffix" (geçerli: '
          '${Suffix.values.map((s) => s.key).join(', ')})',
          m.start,
        ),
      );
    }
    final rest = template.substring(m.end);
    if (rest.startsWith("'") || rest.startsWith('’')) {
      problems.add(
        TemplateProblem(
          'yer tutucudan sonra elle yazılmış ek; {$path|...} kullan',
          m.end,
        ),
      );
    } else if (rest.isNotEmpty && _letter.hasMatch(rest[0])) {
      problems.add(
        TemplateProblem(
          'yer tutucuya bitişik harf; ek gerekiyorsa {$path|...} kullan',
          m.end,
        ),
      );
    } else if (_harmonyParticle.firstMatch(rest) case final p?) {
      // "{ad} de", "{akraba} da": ünlü uyumu ada göre değişir ("Kaan da",
      // "annen de"); elle yazılan hep birinde yanlış çıkar.
      problems.add(
        TemplateProblem(
          'yer tutucudan sonra elle yazılmış "${p[1]}"; ünlü uyumu tutmaz, '
          'soru için {$path|mi} kullan ya da cümleyi değiştir',
          m.end,
        ),
      );
    }
  }
  return problems;
}

/// Yer tutucudan sonra ayrı yazılan ama ünlü uyumuna giren ilgeçler.
final RegExp _harmonyParticle = RegExp(
  r'^ (de|da|mi|mı|mu|mü)(?=[\s.,;:!?…]|$)',
);

/// Şablondaki yer tutucuları [resolve] ile çözüp ekleri ekler. [resolve]
/// null dönerse [StateError] fırlatır: olay seçicisi rolleri doldurmadan
/// metin istememelidir.
/// Yazılan metin bir cümle başında mı bitiyor: boş, nokta, ünlem, soru ya da
/// iki nokta üstüne açılan alıntıdan sonra.
bool _startsSentence(String before) {
  var s = before.trimRight();
  if (s.isEmpty) return true;
  if (s.endsWith("'") || s.endsWith('"')) {
    s = s.substring(0, s.length - 1).trimRight();
    if (s.isEmpty || s.endsWith(':')) return true;
  }
  if (before.length == s.length) return false;
  return s.endsWith('.') || s.endsWith('!') || s.endsWith('?');
}

String renderTemplate(
  String template,
  TemplateValue? Function(String path) resolve,
) {
  final problems = templateProblems(template);
  if (problems.isNotEmpty) {
    throw FormatException('Şablon bozuk: ${problems.first}', template);
  }
  final out = StringBuffer();
  var cursor = 0;
  for (final token in parseTemplate(template)) {
    out.write(template.substring(cursor, token.start));
    final value = resolve(token.path);
    if (value == null) {
      throw StateError('Yer tutucu çözülemedi: {${token.path}}');
    }
    var text = token.suffix == null
        ? value.text
        : withSuffix(value.text, token.suffix!, proper: value.proper);
    // Cümle başındaki küçük harfli sözcük ("annen", "dayın") büyür.
    if (_startsSentence(out.toString()) && text.isNotEmpty) {
      text = upperTr(text[0]) + text.substring(1);
    }
    out.write(text);
    cursor = token.end;
  }
  out.write(template.substring(cursor));
  return out.toString();
}
