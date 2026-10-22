import 'dart:convert';

import 'json_reader.dart';

/// Etkileşim sonuçlarının metinleri ve anı etiketleri
/// (assets/interactions.json). Anahtarların eksiksizliğini içerik yükleyici
/// motorun listesiyle karşılaştırarak denetler.
class InteractionBook {
  InteractionBook({
    required Map<String, List<String>> texts,
    required Map<String, String> memoryLabels,
  }) : texts = Map.unmodifiable({
         for (final e in texts.entries)
           e.key: List<String>.unmodifiable(e.value),
       }),
       memoryLabels = Map.unmodifiable(memoryLabels);

  /// Sonuç anahtarı → metin seçenekleri.
  final Map<String, List<String>> texts;

  /// Anı türü → kişinin gözünden kısa etiket.
  final Map<String, String> memoryLabels;

  /// [outcome] için metin; kişinin özelliğine özel metin varsa o seçilir.
  /// [variant] seçeneklerden hangisinin geleceğini belirler.
  String? textFor(
    String outcome,
    int variant, {
    Iterable<String> traits = const [],
  }) {
    for (final trait in traits) {
      final special = texts['$outcome.$trait'];
      if (special != null) return special[variant % special.length];
    }
    final options = texts[outcome];
    if (options == null) return null;
    return options[variant % options.length];
  }

  factory InteractionBook.parse(String source) {
    final r = JsonReader(
      jsonDecode(source) as Map<String, dynamic>,
      'interactions',
    )..rejectUnknownKeys(const {'_aciklama', 'texts', 'memories'});
    final textsReader = r.requireObject('texts');
    final memories = r.requireObject('memories');
    return InteractionBook(
      texts: {
        for (final key in textsReader.json.keys)
          key: textsReader.requireStringList(key),
      },
      memoryLabels: {
        for (final key in memories.json.keys) key: memories.requireString(key),
      },
    );
  }

  /// İçerik yüklenmeden motoru kuran testler için: etiket, anı türünün
  /// kendisidir; metin yoktur.
  static final InteractionBook minimal = InteractionBook(
    texts: const {},
    memoryLabels: const {},
  );
}
