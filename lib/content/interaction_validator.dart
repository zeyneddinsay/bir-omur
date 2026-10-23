import '../engine/interactions.dart';
import '../models/models.dart';
import 'person_text.dart';
import 'turkish.dart';

/// `assets/interactions.json` denetimi. Dönen her satır bir hatadır.
List<String> validateInteractions(InteractionBook book) {
  final problems = <String>[];
  final traits = {
    for (final t in Trait.values) t.name,
    InteractionBook.childKey,
  };

  for (final outcome in Interactions.outcomes) {
    final options = book.texts[outcome];
    if (options == null || options.isEmpty) {
      problems.add('texts.$outcome: metin yok');
    }
  }
  for (final key in book.texts.keys) {
    final dot = key.lastIndexOf('.');
    final known =
        Interactions.outcomes.contains(key) ||
        (dot > 0 &&
            traits.contains(key.substring(dot + 1)) &&
            Interactions.outcomes.contains(key.substring(0, dot)));
    if (!known) problems.add('texts.$key: bilinmeyen sonuç');
  }
  for (final kind in Interactions.memoryKinds) {
    final label = book.memoryLabels[kind];
    if (label == null || label.trim().isEmpty) {
      problems.add('memories.$kind: etiket yok');
    }
  }
  for (final kind in book.memoryLabels.keys) {
    if (!Interactions.memoryKinds.contains(kind)) {
      problems.add('memories.$kind: bilinmeyen anı');
    }
  }

  for (final MapEntry(key: key, value: options) in book.texts.entries) {
    for (var i = 0; i < options.length; i++) {
      final text = options[i];
      final where = 'texts.$key[$i]';
      for (final p in templateProblems(text)) {
        problems.add('$where: ${p.message}');
      }
      for (final token in parseTemplate(text)) {
        if (!PersonText.allowedPaths.contains(token.path)) {
          problems.add('$where: izin verilmeyen yer tutucu {${token.path}}');
        }
      }
    }
  }
  return problems;
}
