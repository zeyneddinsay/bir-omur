import 'dart:convert';

import '../models/models.dart';
import 'content_registry.dart';

enum IssueLevel { error, warning }

/// Kart dosyalarında bulunan bir sorun.
class CardIssue {
  const CardIssue(this.level, this.file, this.path, this.message);

  final IssueLevel level;
  final String file;

  /// Kart kimliği ve alan yolu, örnek: `kira_zammi_01.left.label`.
  final String path;
  final String message;

  bool get isError => level == IssueLevel.error;

  @override
  String toString() {
    final tag = isError ? 'HATA ' : 'UYARI';
    return '$tag  $file  $path: $message';
  }
}

/// Bir kart ve geldiği dosya.
class SourcedCard {
  const SourcedCard(this.card, this.file);

  final EventCard card;
  final String file;
}

/// Kart dosyalarını okuma ve denetlemenin sonucu.
class CardCheckResult {
  const CardCheckResult(this.cards, this.issues, {this.careers = const []});

  final List<SourcedCard> cards;
  final List<Career> careers;
  final List<CardIssue> issues;

  Iterable<CardIssue> get errors => issues.where((i) => i.isError);
  Iterable<CardIssue> get warnings => issues.where((i) => !i.isError);
  bool get hasErrors => errors.isNotEmpty;
}

/// Kart dosyalarını okur ve tasarım kurallarına göre denetler. Hem uygulama
/// yüklerken hem de `tools/card_lint` aynı denetimi kullanır.
class CardValidator {
  CardValidator(this.registry);

  final ContentRegistry registry;

  static const int maxTextLength = 140;
  static const int maxLabelLength = 24;

  /// [files]: dosya adı → JSON içeriği. Her dosya bir kart dizisidir.
  /// [careerFiles]: her dosya tek bir meslek tanımıdır.
  CardCheckResult check(
    Map<String, String> files, {
    Map<String, String> careerFiles = const {},
  }) {
    final issues = <CardIssue>[];
    final careers = _parseCareers(careerFiles, issues);
    final cards = <SourcedCard>[];
    for (final MapEntry(key: file, value: source) in files.entries) {
      cards.addAll(_parseFile(file, source, issues));
    }
    _careersById = {for (final c in careers) c.id: c};
    _checkDuplicates(cards, issues);
    final ids = {for (final c in cards) c.card.id};
    final scheduledIds = {
      for (final c in cards)
        for (final choice in c.card.choices)
          for (final effect in choice.allEffects)
            if (effect.schedule != null) effect.schedule!.cardId,
    };
    final addedFlags = {
      for (final c in cards)
        for (final choice in c.card.choices)
          for (final effect in choice.allEffects) ...effect.addFlags,
    };
    for (final sourced in cards) {
      _checkCard(sourced, ids, scheduledIds, addedFlags, issues);
    }
    _checkRegistry(issues);
    return CardCheckResult(
      List.unmodifiable(cards),
      List.unmodifiable(issues),
      careers: List.unmodifiable(careers),
    );
  }

  Map<String, Career> _careersById = const {};

  List<Career> _parseCareers(
    Map<String, String> files,
    List<CardIssue> issues,
  ) {
    final careers = <Career>[];
    final seen = <String, String>{};
    for (final MapEntry(key: file, value: source) in files.entries) {
      try {
        final json = jsonDecode(source);
        if (json is! Map<String, dynamic>) {
          issues.add(
            CardIssue(
              IssueLevel.error,
              file,
              '-',
              'meslek dosyası bir nesne olmalı',
            ),
          );
          continue;
        }
        final career = Career.fromJson(json, file: file);
        final previous = seen[career.id];
        if (previous != null) {
          issues.add(
            CardIssue(
              IssueLevel.error,
              file,
              career.id,
              'tekrar eden meslek (ilki: $previous)',
            ),
          );
          continue;
        }
        seen[career.id] = file;
        careers.add(career);
      } on FormatException catch (e) {
        issues.add(
          CardIssue(
            IssueLevel.error,
            file,
            '-',
            'JSON okunamadı: ${e.message}',
          ),
        );
      } on CardFormatException catch (e) {
        issues.add(CardIssue(IssueLevel.error, file, e.path, e.message));
      }
    }
    return careers;
  }

  /// Koşullardaki ve etkilerdeki meslek kullanımlarını denetler.
  void _checkCareerUse(
    EventCard card,
    void Function(String path, String message) error,
  ) {
    final conditionCareer = card.conditions.career;
    var maxTier = 5;
    if (conditionCareer != null &&
        conditionCareer != Conditions.noCareer &&
        conditionCareer != Conditions.anyCareer) {
      final career = _careersById[conditionCareer];
      if (career == null) {
        error('.conditions.career', 'bilinmeyen meslek "$conditionCareer"');
      } else {
        maxTier = career.maxTier;
      }
    }
    if (card.conditions.minTier case final tier?) {
      if (conditionCareer == Conditions.noCareer) {
        error('.conditions.minTier', 'işsiz koşuluyla kademe istenemez');
      } else if (tier < 1 || tier > maxTier) {
        error('.conditions.minTier', 'kademe 1–$maxTier arasında olmalı');
      }
    }
    final sides = {'left': card.left, 'right': card.right, 'up': ?card.up};
    for (final MapEntry(key: side, value: choice) in sides.entries) {
      for (final effect in choice.allEffects) {
        if (effect.career case JoinCareer(:final careerId, :final tier)) {
          final career = _careersById[careerId];
          if (career == null) {
            error('.$side.career', 'bilinmeyen meslek "$careerId"');
          } else if (tier > career.maxTier) {
            error('.$side.career', '"$careerId" mesleğinde $tier. kademe yok');
          }
        }
      }
    }
  }

  List<SourcedCard> _parseFile(
    String file,
    String source,
    List<CardIssue> issues,
  ) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      issues.add(
        CardIssue(IssueLevel.error, file, '-', 'JSON okunamadı: ${e.message}'),
      );
      return const [];
    }
    if (json is! List) {
      issues.add(
        CardIssue(IssueLevel.error, file, '-', 'dosya bir kart dizisi olmalı'),
      );
      return const [];
    }
    final parsed = <SourcedCard>[];
    for (var i = 0; i < json.length; i++) {
      final raw = json[i];
      if (raw is! Map<String, dynamic>) {
        issues.add(
          CardIssue(IssueLevel.error, file, '[$i]', 'kart bir nesne olmalı'),
        );
        continue;
      }
      try {
        parsed.add(SourcedCard(EventCard.fromJson(raw), file));
      } on CardFormatException catch (e) {
        issues.add(CardIssue(IssueLevel.error, file, e.path, e.message));
      }
    }
    return parsed;
  }

  void _checkDuplicates(List<SourcedCard> cards, List<CardIssue> issues) {
    final firstFile = <String, String>{};
    for (final c in cards) {
      final previous = firstFile[c.card.id];
      if (previous != null) {
        issues.add(
          CardIssue(
            IssueLevel.error,
            c.file,
            c.card.id,
            'tekrar eden kimlik (ilki: $previous)',
          ),
        );
      } else {
        firstFile[c.card.id] = c.file;
      }
    }
  }

  void _checkCard(
    SourcedCard sourced,
    Set<String> ids,
    Set<String> scheduledIds,
    Set<String> addedFlags,
    List<CardIssue> issues,
  ) {
    final card = sourced.card;
    void error(String path, String message) => issues.add(
      CardIssue(IssueLevel.error, sourced.file, '${card.id}$path', message),
    );
    void warning(String path, String message) => issues.add(
      CardIssue(IssueLevel.warning, sourced.file, '${card.id}$path', message),
    );

    _checkCareerUse(card, error);

    final textLength = card.text.runes.length;
    if (card.text.trim().isEmpty) error('.text', 'boş metin');
    if (textLength > maxTextLength) {
      error('.text', 'metin $textLength karakter, en fazla $maxTextLength');
    }

    final expectedStage = LifeStage.forAge(card.minAge);
    if (card.stage != expectedStage) {
      error(
        '.stage',
        '"${card.stage.id}" ama minAge ${card.minAge} "${expectedStage.id}" evresinde',
      );
    }

    if (card.speaker case final speaker?
        when !registry.speakers.containsKey(speaker)) {
      error('.speaker', 'bilinmeyen konuşmacı "$speaker" (registry.json)');
    }

    if (card.up != null && card.rarity == Rarity.siradan) {
      error('.up', 'yukarı seçeneği yalnızca nadir ve efsane kartlarda olur');
    }

    if (card.mandatory && !card.once && card.cooldown == 0) {
      error(
        '.mandatory',
        'zorunlu kart once ya da cooldown istiyor, yoksa her yıl gelir',
      );
    }
    if (card.chainOnly && card.mandatory) {
      error('.chainOnly', 'zincir kartı zorunlu olamaz');
    }
    if (card.chainOnly && !scheduledIds.contains(card.id)) {
      warning(
        '.chainOnly',
        'hiçbir kart bu zincir kartını planlamıyor, hiç gelmez',
      );
    }

    final known = registry.knownFlags;
    for (final flag in [
      ...card.conditions.flags,
      ...card.conditions.notFlags,
    ]) {
      if (!known.contains(flag)) {
        error('.conditions', 'bilinmeyen bayrak "$flag" (registry.json)');
      }
    }
    for (final flag in card.conditions.flags) {
      if (known.contains(flag) &&
          !addedFlags.contains(flag) &&
          !ContentRegistry.engineOwnedFlags.contains(flag)) {
        warning(
          '.conditions',
          '"$flag" bayrağını hiçbir kart açmıyor, kart hiç gelmez',
        );
      }
    }

    final sides = {'left': card.left, 'right': card.right, 'up': ?card.up};
    for (final MapEntry(key: side, value: choice) in sides.entries) {
      final labelLength = choice.label.runes.length;
      if (choice.label.trim().isEmpty) error('.$side.label', 'boş seçenek');
      if (labelLength > maxLabelLength) {
        error(
          '.$side.label',
          '"${choice.label}" $labelLength karakter, en fazla $maxLabelLength',
        );
      }
      for (final effect in choice.allEffects) {
        for (final flag in [...effect.addFlags, ...effect.removeFlags]) {
          if (ContentRegistry.engineOwnedFlags.contains(flag)) {
            error(
              '.$side',
              '"$flag" motorun bayrağı; kartlar ekleyip kaldıramaz',
            );
          } else if (!known.contains(flag)) {
            error('.$side', 'bilinmeyen bayrak "$flag" (registry.json)');
          }
        }
        if (effect.schedule case final s? when !ids.contains(s.cardId)) {
          error(
            '.$side.schedule',
            'zincir hedefi "${s.cardId}" diye bir kart yok',
          );
        }
      }
    }
  }

  void _checkRegistry(List<CardIssue> issues) {
    for (final flag in ContentRegistry.engineReferencedFlags) {
      if (!registry.flags.containsKey(flag)) {
        issues.add(
          CardIssue(
            IssueLevel.error,
            'registry.json',
            flag,
            'motor bu bayrağa bakıyor ama kayıtta yok',
          ),
        );
      }
    }
  }
}
