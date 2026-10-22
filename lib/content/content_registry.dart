import 'dart:convert';

import '../engine/engine.dart';

/// `assets/registry.json`: kartlarda kullanılabilecek bayraklar ve incelenmiş
/// hassas kelime kullanımları. Yeni bir bayrak önce buraya eklenir; card_lint kayıtta olmayan
/// adı yazım hatası sayar.
class ContentRegistry {
  ContentRegistry({
    required Map<String, String> flags,
    Map<String, Set<String>> reviewedTerms = const {},
  }) : flags = Map.unmodifiable(flags),
       reviewedTerms = Map.unmodifiable(reviewedTerms);

  /// Bayrak adı → açıklama.
  final Map<String, String> flags;

  /// İncelenip uygun bulunan hassas kelime kullanımları: kart ya da rozet
  /// kimliği → kelimeler (bkz. `sensitive_terms.dart`).
  final Map<String, Set<String>> reviewedTerms;

  /// Kayıttakiler ve motorun kendi açıp kapattığı bayraklar.
  Set<String> get knownFlags => {...flags.keys, ...engineOwnedFlags};

  /// Motorun kendisinin açıp kapattığı bayraklar: zor dönem ve varlıklardan
  /// türetilenler. Kartlar bunlara bakabilir ama değiştiremez.
  static final Set<String> engineOwnedFlags = {
    ...EngineFlags.all,
    ...Economy.derivedFlags,
    ...EducationRules.derivedFlags,
    JobMarket.kpssFlag,
    JobMarket.codingFlag,
  };

  /// Motorun koddan baktığı, kartların açtığı bayraklar; kayıtta
  /// bulunmaları gerekir.
  static const Set<String> engineReferencedFlags = {
    ...SummaryBuilder.referencedFlags,
    EducationRules.goodSchoolFlag,
    EducationRules.vocationalFlag,
    EducationRules.goodExamFlag,
    ActionCatalog.licenseFlag,
  };

  /// Motorun kendisinin planladığı iplikler (örnek: mezuniyet); hiçbir
  /// olay planlamasa da gelirler.
  static const Set<String> engineScheduledEvents = {LifeEngine.graduationEvent};

  factory ContentRegistry.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('registry.json bir nesne olmalı');
    }
    return ContentRegistry(
      flags: _stringMap(json, 'flags'),
      reviewedTerms: _reviewedTerms(json['reviewedTerms']),
    );
  }

  static Map<String, Set<String>> _reviewedTerms(Object? value) {
    if (value == null) return const {};
    if (value is! Map<String, dynamic> ||
        value.values.any((v) => v is! List || v.any((t) => t is! String))) {
      throw const FormatException(
        'registry.json: "reviewedTerms" kimlik → kelime listesi olmalı',
      );
    }
    return {
      for (final MapEntry(:key, :value) in value.entries)
        key: {...(value as List).cast<String>()},
    };
  }

  static Map<String, String> _stringMap(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! Map<String, dynamic> ||
        value.values.any((v) => v is! String)) {
      throw FormatException(
        'registry.json: "$key" ad → açıklama nesnesi olmalı',
      );
    }
    return value.cast<String, String>();
  }
}
