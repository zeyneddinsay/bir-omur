import 'dart:convert';

import '../engine/engine.dart';

/// `assets/registry.json`: kartlarda kullanılabilecek bayrak ve konuşmacı
/// adları. Yeni bir bayrak önce buraya eklenir; card_lint kayıtta olmayan
/// adı yazım hatası sayar.
class ContentRegistry {
  ContentRegistry({
    required Map<String, String> flags,
    required Map<String, String> speakers,
  }) : flags = Map.unmodifiable(flags),
       speakers = Map.unmodifiable(speakers);

  /// Bayrak adı → açıklama.
  final Map<String, String> flags;

  /// Konuşmacı kimliği → açıklama.
  final Map<String, String> speakers;

  /// Kayıttakiler ve motorun kendi açıp kapattığı bayraklar.
  Set<String> get knownFlags => {...flags.keys, ...engineOwnedFlags};

  /// Motorun kendisinin açıp kapattığı bayraklar: zor dönem ve varlıklardan
  /// türetilenler. Kartlar bunlara bakabilir ama değiştiremez.
  static final Set<String> engineOwnedFlags = {
    ...EngineFlags.all,
    ...Economy.derivedFlags,
  };

  /// Motorun koddan baktığı bayraklar; kayıtta bulunmaları gerekir.
  static const Set<String> engineReferencedFlags = {
    ActionCatalog.studentFlag,
    ...SummaryBuilder.referencedFlags,
    Economy.movedFlag,
  };

  factory ContentRegistry.parse(String source) {
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('registry.json bir nesne olmalı');
    }
    return ContentRegistry(
      flags: _stringMap(json, 'flags'),
      speakers: _stringMap(json, 'speakers'),
    );
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
