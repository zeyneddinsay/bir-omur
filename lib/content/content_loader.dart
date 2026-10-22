import '../models/models.dart';
import '../engine/engine.dart';
import 'card_validator.dart';
import 'content_registry.dart';
import 'interaction_validator.dart';

/// Oyunun yüklenmiş içeriği.
class GameContent {
  const GameContent({
    required this.deck,
    required this.careers,
    this.achievements,
    required this.families,
    required this.interactions,
    required this.registry,
    required this.warnings,
  });

  final EventDeck deck;
  final CareerBook careers;

  /// Rozetler; içerikte yoksa boş.
  final AchievementBook? achievements;

  /// Aile profilleri, meslek adları, ad ve soyad listeleri.
  final FamilyBook families;

  /// Etkileşim sonuçlarının metinleri ve anı etiketleri.
  final InteractionBook interactions;
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
  String? achievementsSource,
  required String familiesSource,
  required String namesSource,
  required String interactionsSource,
}) {
  final registry = ContentRegistry.parse(registrySource);
  final families = _parseFamilies(familiesSource, namesSource);
  final result =
      CardValidator(
        registry,
        familyProfiles: {for (final p in families.profiles) p.id},
      ).check(
        cardFiles,
        careerFiles: careerFiles,
        achievementsSource: achievementsSource,
      );
  if (result.hasErrors) throw ContentException(result.errors.toList());
  return GameContent(
    deck: EventDeck(result.cards.map((c) => c.card)),
    careers: CareerBook(result.careers),
    achievements: AchievementBook(result.achievements),
    families: families,
    interactions: _parseInteractions(interactionsSource),
    registry: registry,
    warnings: result.warnings.toList(),
  );
}

FamilyBook _parseFamilies(String familiesSource, String namesSource) {
  try {
    return FamilyBook.parse(
      familiesSource: familiesSource,
      namesSource: namesSource,
    );
  } on CardFormatException catch (e) {
    throw ContentException([
      CardIssue(IssueLevel.error, 'families.json', e.path, e.message),
    ]);
  }
}

InteractionBook _parseInteractions(String source) {
  final InteractionBook book;
  try {
    book = InteractionBook.parse(source);
  } on CardFormatException catch (e) {
    throw ContentException([
      CardIssue(IssueLevel.error, 'interactions.json', e.path, e.message),
    ]);
  }
  final problems = validateInteractions(book);
  if (problems.isNotEmpty) {
    throw ContentException([
      for (final p in problems)
        CardIssue(IssueLevel.error, 'interactions.json', 'interactions', p),
    ]);
  }
  return book;
}
