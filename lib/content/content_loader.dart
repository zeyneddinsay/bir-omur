import '../engine/engine.dart';
import 'card_validator.dart';
import 'content_registry.dart';

/// Oyunun yüklenmiş içeriği.
class GameContent {
  const GameContent({
    required this.deck,
    required this.careers,
    required this.registry,
    required this.warnings,
  });

  final EventDeck deck;
  final CareerBook careers;
  final ContentRegistry registry;
  final List<CardIssue> warnings;
}

/// Kart dosyalarında hata varsa yükleme durur.
class ContentException implements Exception {
  const ContentException(this.errors);

  final List<CardIssue> errors;

  @override
  String toString() =>
      'Kart dosyalarında ${errors.length} hata var:\n${errors.join('\n')}';
}

/// Kayıt, meslek ve kart dosyalarını okur, denetler ve desteyi kurar. Saf Dart'tır;
/// dosyaların nereden geldiğini (asset, disk) çağıran bilir.
GameContent loadContent({
  required String registrySource,
  required Map<String, String> cardFiles,
  Map<String, String> careerFiles = const {},
}) {
  final registry = ContentRegistry.parse(registrySource);
  final result = CardValidator(registry)
      .check(cardFiles, careerFiles: careerFiles);
  if (result.hasErrors) throw ContentException(result.errors.toList());
  return GameContent(
    deck: EventDeck(result.cards.map((c) => c.card)),
    careers: CareerBook(result.careers),
    registry: registry,
    warnings: result.warnings.toList(),
  );
}
