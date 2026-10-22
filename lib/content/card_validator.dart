import 'dart:convert';

import '../engine/achievements.dart';
import '../engine/business_types.dart';
import '../engine/education.dart';
import '../models/models.dart';
import 'content_registry.dart';
import 'sensitive_terms.dart';
import 'turkish.dart';

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
  const CardCheckResult(
    this.cards,
    this.issues, {
    this.careers = const [],
    this.achievements = const [],
  });

  final List<SourcedCard> cards;
  final List<Career> careers;
  final List<Achievement> achievements;
  final List<CardIssue> issues;

  Iterable<CardIssue> get errors => issues.where((i) => i.isError);
  Iterable<CardIssue> get warnings => issues.where((i) => !i.isError);
  bool get hasErrors => errors.isNotEmpty;
}

/// Kart dosyalarını okur ve tasarım kurallarına göre denetler. Hem uygulama
/// yüklerken hem de `tools/card_lint` aynı denetimi kullanır.
class CardValidator {
  CardValidator(this.registry, {this.familyProfiles});

  final ContentRegistry registry;

  /// Geçerli aile profili kimlikleri; verilmezse koşuldaki profil
  /// denetlenmez.
  final Set<String>? familyProfiles;

  static const int maxTextLength = 140;
  static const int maxLabelLength = 24;

  /// [files]: dosya adı → JSON içeriği. Her dosya bir kart dizisidir.
  /// [careerFiles]: her dosya tek bir meslek tanımıdır.
  CardCheckResult check(
    Map<String, String> files, {
    Map<String, String> careerFiles = const {},
    String? achievementsSource,
  }) {
    final issues = <CardIssue>[];
    final careers = _parseCareers(careerFiles, issues);
    final cards = <SourcedCard>[];
    for (final MapEntry(key: file, value: source) in files.entries) {
      cards.addAll(_parseFile(file, source, issues));
    }
    _careersById = {for (final c in careers) c.id: c};
    _checkDuplicates(cards, issues);
    final byId = {for (final c in cards) c.card.id: c.card};
    final ids = byId.keys.toSet();
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
      _checkCard(sourced, byId, scheduledIds, addedFlags, issues);
    }
    _checkRegistry(issues);
    final achievements = achievementsSource == null
        ? const <Achievement>[]
        : _parseAchievements(achievementsSource, ids, issues);
    _checkSensitiveTerms(cards, achievements, issues);
    return CardCheckResult(
      List.unmodifiable(cards),
      List.unmodifiable(issues),
      careers: List.unmodifiable(careers),
      achievements: List.unmodifiable(achievements),
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
        _checkCareerFlags(career, file, issues);
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

  /// Kart ve rozet metinlerinde incelenecek kelimeleri arar. İncelenmiş
  /// kullanımlar (`registry.json` → `reviewedTerms`) uyarı vermez; artık
  /// metinde geçmeyen onaylar da uyarı verir ki liste temiz kalsın.
  void _checkSensitiveTerms(
    List<SourcedCard> cards,
    List<Achievement> achievements,
    List<CardIssue> issues,
  ) {
    final texts = <String, (String file, String text)>{
      for (final c in cards)
        c.card.id: (
          c.file,
          [
            c.card.text,
            for (final choice in c.card.choices) choice.label,
          ].join('\n'),
        ),
      for (final a in achievements)
        a.id: (achievementsFile, '${a.name}\n${a.description}'),
    };
    for (final MapEntry(key: id, value: (file, text)) in texts.entries) {
      final reviewed = registry.reviewedTerms[id] ?? const {};
      for (final term in findSensitiveTerms(text)) {
        if (reviewed.contains(term.term)) continue;
        issues.add(
          CardIssue(
            IssueLevel.warning,
            file,
            id,
            'incelenecek kelime "${term.term}" (${term.category}); uygunsa '
            'registry.json → reviewedTerms listesine ekle',
          ),
        );
      }
    }
    for (final MapEntry(key: id, value: terms)
        in registry.reviewedTerms.entries) {
      final found = {
        for (final t in findSensitiveTerms(texts[id]?.$2 ?? '')) t.term,
      };
      for (final term in terms.difference(found)) {
        issues.add(
          CardIssue(
            IssueLevel.warning,
            'registry.json',
            'reviewedTerms.$id',
            '"$term" artık bu metinde geçmiyor; onayı kaldır',
          ),
        );
      }
    }
  }

  /// Meslek dosyasındaki şartlarda (terfi, iş arama) geçen bayraklar da
  /// kayıtta olmalı.
  void _checkCareerFlags(Career career, String file, List<CardIssue> issues) {
    final conditions = [
      career.entry.requires,
      for (final tier in career.tiers) ?tier.promotion?.requires,
    ];
    for (final flag in career.entry.flags) {
      if (!registry.knownFlags.contains(flag)) {
        issues.add(
          CardIssue(
            IssueLevel.error,
            file,
            career.id,
            'giriş bayrağı "$flag" kayıtta yok (registry.json)',
          ),
        );
      }
    }
    for (final department in career.entry.departments) {
      if (EducationRules.department(department) == null) {
        issues.add(
          CardIssue(
            IssueLevel.error,
            file,
            career.id,
            'bilinmeyen bölüm "$department"',
          ),
        );
      }
    }
    for (final c in conditions) {
      for (final flag in [...c.flags, ...c.notFlags]) {
        if (!registry.knownFlags.contains(flag)) {
          issues.add(
            CardIssue(
              IssueLevel.error,
              file,
              career.id,
              'bilinmeyen bayrak "$flag" (registry.json)',
            ),
          );
        }
      }
    }
  }

  static const String achievementsFile = 'achievements.json';
  static const int maxAchievementName = 32;
  static const int maxAchievementDescription = 100;

  List<Achievement> _parseAchievements(
    String source,
    Set<String> cardIds,
    List<CardIssue> issues,
  ) {
    void error(String path, String message) => issues.add(
      CardIssue(IssueLevel.error, achievementsFile, path, message),
    );
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      error('-', 'JSON okunamadı: ${e.message}');
      return const [];
    }
    if (json is! List) {
      error('-', 'dosya bir rozet dizisi olmalı');
      return const [];
    }
    final achievements = <Achievement>[];
    final seen = <String>{};
    for (var i = 0; i < json.length; i++) {
      final raw = json[i];
      if (raw is! Map<String, dynamic>) {
        error('[$i]', 'rozet bir nesne olmalı');
        continue;
      }
      final Achievement a;
      try {
        a = Achievement.fromJson(raw);
      } on CardFormatException catch (e) {
        error(e.path, e.message);
        continue;
      }
      if (!seen.add(a.id)) error(a.id, 'tekrar eden rozet kimliği');
      if (a.name.runes.length > maxAchievementName) {
        error('${a.id}.name', 'en fazla $maxAchievementName karakter');
      }
      if (a.description.runes.length > maxAchievementDescription) {
        error(
          '${a.id}.description',
          'en fazla $maxAchievementDescription karakter',
        );
      }
      final req = a.requirement;
      for (final flag in [
        ...req.conditions.flags,
        ...req.conditions.notFlags,
      ]) {
        if (!registry.knownFlags.contains(flag)) {
          error(
            '${a.id}.conditions',
            'bilinmeyen bayrak "$flag" (registry.json)',
          );
        }
      }
      if (req.lastCareer case final id? when !_careersById.containsKey(id)) {
        error('${a.id}.lastCareer', 'bilinmeyen meslek "$id"');
      }
      if (req.minLastTier case final tier?) {
        final max = _careersById[req.lastCareer]?.maxTier ?? 5;
        if (tier < 1 || tier > max) {
          error('${a.id}.minLastTier', 'kademe 1–$max arasında olmalı');
        }
      }
      for (final card in req.seenCards) {
        if (!cardIds.contains(card)) {
          error('${a.id}.seenCards', '"$card" diye bir kart yok');
        }
      }
      achievements.add(a);
    }
    return achievements;
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
    for (final id in card.conditions.careers) {
      if (!_careersById.containsKey(id)) {
        error('.conditions.careers', 'bilinmeyen meslek "$id"');
      }
    }
    if (card.conditions.careers.isNotEmpty && conditionCareer != null) {
      error('.conditions', 'career ile careers birlikte kullanılmaz');
    }
    final business = card.conditions.business;
    if (business != null &&
        business != Conditions.anyCareer &&
        business != Conditions.noCareer &&
        BusinessTypes.byId(business) == null) {
      error('.conditions.business', 'bilinmeyen işletme "$business"');
    }
    final hasJob =
        card.conditions.careers.isNotEmpty ||
        (conditionCareer != null && conditionCareer != Conditions.noCareer);
    final sides = {'left': card.left, 'right': card.right, 'up': ?card.up};
    for (final MapEntry(key: side, value: choice) in sides.entries) {
      for (final effect in choice.allEffects) {
        if (effect.business != 0 &&
            (business == null || business == Conditions.noCareer)) {
          error(
            '.$side',
            'işletme etkisi bir işletmeyi ister (conditions.business)',
          );
        }
        if (effect.performance != 0 && !hasJob) {
          error(
            '.$side',
            'performans etkisi bir işi olmayı ister (conditions.career)',
          );
        }
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

  /// Romantik bağlar: bunları isteyen ya da kuran olay 18 yaş kuralına
  /// uyar.
  static const Set<Bond> romanticBonds = {
    Bond.flort,
    Bond.sevgili,
    Bond.nisanli,
  };

  /// Yaş kuralı: 18 yaşından önce romantik bağ yok.
  static const int romanceMinAge = 18;

  /// Anı etiketinin en fazla uzunluğu (kişi ekranında bir satır).
  static const int maxMemoryLabelLength = 48;

  /// Metin uzunluğu denetiminde bir yer tutucunun en kötü hâli: en uzun ad
  /// ve en uzun akrabalık sözcüğü.
  static const String longestName = 'Muhammet';
  static const String longestKinWord = 'kayınbiraderin';
  static const String longestSurname = 'Yıldırım';

  /// Kişi yuvalarında geçerli alanlar; oyuncu için yalnızca ad.
  static final Set<String> slotFields = {
    'ad',
    'soyad',
    'akraba',
    for (final a in Address.values) 'hitap.${a.key}',
  };

  void _checkCard(
    SourcedCard sourced,
    Map<String, EventCard> byId,
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
    _checkText(card, '.text', card.text, maxTextLength, error);
    if (card.closing case final closing?) {
      if (!card.chainOnly) {
        error('.closing', 'kapanış cümlesi yalnızca iplikte olur');
      }
      _checkText(card, '.closing', closing, maxTextLength, error);
    }

    if (card.up != null && card.rarity == Rarity.siradan) {
      error('.up', 'yukarı seçeneği yalnızca nadir ve efsane kartlarda olur');
    }
    if (card.type == EventType.kisi && card.roles.isEmpty) {
      error('.roles', 'kişi olayı en az bir rol yuvası ister');
    }
    if (card.chainOnly &&
        !scheduledIds.contains(card.id) &&
        !ContentRegistry.engineScheduledEvents.contains(card.id)) {
      warning('.type', 'hiçbir olay bu ipliği planlamıyor, hiç gelmez');
    }
    if (card.type == EventType.donemec && card.rarity != Rarity.siradan) {
      error('.rarity', 'dönemeç her zaman gelir; nadirlik anlamsız');
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
          '"$flag" bayrağını hiçbir olay açmıyor, olay hiç gelmez',
        );
      }
    }
    if (familyProfiles case final profiles?) {
      for (final profile in card.conditions.familyProfiles) {
        if (!profiles.contains(profile)) {
          error(
            '.conditions.familyProfile',
            'bilinmeyen aile profili "$profile"',
          );
        }
      }
    }

    final romanticRoles = {
      for (final role in card.roles)
        if (role.bonds.any(romanticBonds.contains)) role.name,
    };

    final sides = {'left': card.left, 'right': card.right, 'up': ?card.up};
    for (final MapEntry(key: side, value: choice) in sides.entries) {
      _checkText(card, '.$side.label', choice.label, maxLabelLength, error);
      for (final effect in choice.allEffects) {
        if (effect.stats.containsKey(StatKind.family)) {
          error(
            '.$side',
            'Aile Bağı ailenin yakınlığından hesaplanır; olay onu '
                'değiştiremez (aile üyesine anı yaz)',
          );
        }
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
        for (final MapEntry(key: slot, value: change)
            in effect.people.entries) {
          final where = '.$side.people.$slot';
          if (card.role(slot) == null) {
            error(where, '"$slot" diye bir rol yuvası yok');
          } else if (card.role(slot)!.deceased) {
            error(where, 'vefat etmiş kişiye etki yazılmaz');
          }
          if (change.memory case final m?) {
            if (m.kind.trim().isEmpty) error('$where.memory', 'boş anı türü');
            _checkText(
              card,
              '$where.memory.label',
              m.label,
              maxMemoryLabelLength,
              error,
            );
          }
          if (change.heal case final heal? when heal.trim().isEmpty) {
            error('$where.heal', 'boş anı türü');
          }
          if (change.bond case final bond? when romanticBonds.contains(bond)) {
            romanticRoles.add(slot);
          }
        }
        if (effect.schedule case final s?) {
          final target = byId[s.cardId];
          if (target == null) {
            error(
              '.$side.schedule',
              'iplik hedefi "${s.cardId}" diye bir kart yok',
            );
          }
          for (final slot in s.withRoles) {
            if (card.role(slot) == null) {
              error(
                '.$side.schedule.with',
                '"$slot" bu olayda bir rol yuvası değil',
              );
            }
            if (target != null && target.role(slot) == null) {
              error(
                '.$side.schedule.with',
                '"$slot" hedef olay "${target.id}" içinde bir rol yuvası değil',
              );
            }
          }
        }
      }
    }

    if (romanticRoles.isNotEmpty) {
      if (card.minAge < romanceMinAge) {
        error(
          '.minAge',
          'romantik bağ içeren olay en erken $romanceMinAge yaşında gelir',
        );
      }
      for (final name in romanticRoles) {
        final role = card.role(name);
        if (role != null && (role.minAge ?? 0) < romanceMinAge) {
          error(
            '.roles.$name.minAge',
            'romantik bağdaki kişi en az $romanceMinAge yaşında olmalı',
          );
        }
      }
    }
  }

  /// Şablon denetimi: biçim, rol yuvaları, uzunluk (en kötü hâliyle).
  void _checkText(
    EventCard card,
    String path,
    String text,
    int maxLength,
    void Function(String path, String message) error,
  ) {
    if (text.trim().isEmpty) {
      error(path, 'boş metin');
      return;
    }
    final problems = templateProblems(text);
    for (final p in problems) {
      error(path, p.message);
    }
    if (problems.isNotEmpty) return;
    var valid = true;
    for (final token in parseTemplate(text)) {
      final dot = token.path.indexOf('.');
      final slot = dot < 0 ? token.path : token.path.substring(0, dot);
      final field = dot < 0 ? '' : token.path.substring(dot + 1);
      if (slot == EventCard.playerSlot) {
        final isAddress =
            field.startsWith('hitap.') && slotFields.contains(field);
        if (field != 'ad' && !isAddress) {
          error(path, 'oyuncu için yalnızca {oyuncu.ad} ve {oyuncu.hitap.…}');
          valid = false;
        }
      } else if (card.role(slot) == null) {
        error(path, '{${token.path}}: "$slot" diye bir rol yuvası yok');
        valid = false;
      } else if (!slotFields.contains(field)) {
        error(path, '{${token.path}}: bilinmeyen alan "$field"');
        valid = false;
      }
    }
    if (!valid) return;
    final worst = renderTemplate(text, (p) {
      final field = p.substring(p.indexOf('.') + 1);
      if (field == 'soyad') return const TemplateValue(longestSurname);
      if (field == 'akraba') {
        return const TemplateValue(longestKinWord, proper: false);
      }
      if (field.startsWith('hitap.')) {
        return const TemplateValue('kızım', proper: false);
      }
      return const TemplateValue(longestName);
    });
    final length = worst.runes.length;
    if (length > maxLength) {
      error(path, 'en uzun adla $length karakter, en fazla $maxLength');
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
