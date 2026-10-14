// Kart dosyası denetleyicisi.
//
// Kullanım (proje kökünden):
//   dart run tools/card_lint/bin/card_lint.dart [assets klasörü]
//
// Hata varsa 1 ile çıkar; uyarılar çıkış kodunu değiştirmez.
import 'dart:io';

import 'package:bir_omur/content/card_validator.dart';
import 'package:bir_omur/content/content_registry.dart';
import 'package:bir_omur/models/models.dart';

void main(List<String> args) {
  final assetsDir = Directory(args.isEmpty ? 'assets' : args.first);
  final registryFile = File('${assetsDir.path}/registry.json');
  final cardsDir = Directory('${assetsDir.path}/cards');
  if (!registryFile.existsSync() || !cardsDir.existsSync()) {
    stderr.writeln(
      '${assetsDir.path}/registry.json ya da ${assetsDir.path}/cards bulunamadı.',
    );
    stderr.writeln('Komutu proje kökünden çalıştır.');
    exitCode = 2;
    return;
  }

  final ContentRegistry registry;
  try {
    registry = ContentRegistry.parse(registryFile.readAsStringSync());
  } on FormatException catch (e) {
    stderr.writeln('HATA  registry.json: ${e.message}');
    exitCode = 1;
    return;
  }

  final files =
      cardsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final result = CardValidator(registry).check({
    for (final f in files) f.uri.pathSegments.last: f.readAsStringSync(),
  });

  for (final issue in result.issues) {
    (issue.isError ? stderr : stdout).writeln(issue);
  }

  final perStage = <LifeStage, int>{for (final s in LifeStage.values) s: 0};
  for (final c in result.cards) {
    perStage.update(c.card.stage, (n) => n + 1);
  }
  stdout
    ..writeln()
    ..writeln('${files.length} dosya, ${result.cards.length} kart')
    ..writeln(perStage.entries.map((e) => '${e.key.id}: ${e.value}').join(', '))
    ..writeln('${result.errors.length} hata, ${result.warnings.length} uyarı');

  if (result.hasErrors) exitCode = 1;
}
