/// JSON'dan tip güvenli okuma yardımcısı.
///
/// Her hata, sorunun yerini gösteren bir yol içerir
/// (örnek: `kira_zammi_01.right.roll.threshold`). Böylece hem yükleyici
/// hem de card_lint aynı anlaşılır mesajı üretir.
class JsonReader {
  JsonReader(this.json, this.path);

  final Map<String, dynamic> json;
  final String path;

  /// Bir alanın tamamını okumadan önce bilinmeyen anahtarları reddeder.
  void rejectUnknownKeys(Set<String> allowed) {
    for (final key in json.keys) {
      if (!allowed.contains(key)) {
        throw CardFormatException('$path.$key', 'bilinmeyen alan');
      }
    }
  }

  bool has(String key) => json.containsKey(key);

  String requireString(String key) {
    final value = json[key];
    if (value is! String) throw _typeError(key, 'metin', value);
    return value;
  }

  String? optionalString(String key) {
    if (!has(key)) return null;
    return requireString(key);
  }

  int requireInt(String key) {
    final value = json[key];
    if (value is! int) throw _typeError(key, 'tam sayı', value);
    return value;
  }

  int? optionalInt(String key) {
    if (!has(key)) return null;
    return requireInt(key);
  }

  bool optionalBool(String key, {bool fallback = false}) {
    if (!has(key)) return fallback;
    final value = json[key];
    if (value is! bool) throw _typeError(key, 'true/false', value);
    return value;
  }

  List<String> optionalStringList(String key) {
    if (!has(key)) return const [];
    final value = json[key];
    if (value is! List || value.any((e) => e is! String)) {
      throw _typeError(key, 'metin listesi', value);
    }
    return List.unmodifiable(value.cast<String>());
  }

  JsonReader requireObject(String key) {
    final value = json[key];
    if (value is! Map<String, dynamic>) throw _typeError(key, 'nesne', value);
    return JsonReader(value, '$path.$key');
  }

  JsonReader? optionalObject(String key) {
    if (!has(key)) return null;
    return requireObject(key);
  }

  CardFormatException _typeError(String key, String expected, Object? actual) {
    final found = actual == null ? 'eksik' : '${actual.runtimeType} bulundu';
    return CardFormatException('$path.$key', '$expected bekleniyordu, $found');
  }
}

/// Kart verisi şemaya uymadığında fırlatılır.
class CardFormatException implements Exception {
  CardFormatException(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}
