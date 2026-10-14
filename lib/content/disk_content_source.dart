import 'dart:io';

import 'content_loader.dart';

/// İçeriği proje klasöründen okur; testler ve `tools/` araçları içindir.
/// Uygulama `loadContentFromAssets` kullanır.
GameContent loadContentFromDisk([String assetsDir = 'assets']) {
  return loadContent(
    registrySource: File('$assetsDir/registry.json').readAsStringSync(),
    cardFiles: readJsonFiles('$assetsDir/cards'),
    careerFiles: readJsonFiles('$assetsDir/careers'),
  );
}

/// Klasördeki JSON dosyaları: dosya adı → içerik, ada göre sıralı.
/// Klasör yoksa boş döner.
Map<String, String> readJsonFiles(String dir) {
  final directory = Directory(dir);
  if (!directory.existsSync()) return const {};
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  return {for (final f in files) f.uri.pathSegments.last: f.readAsStringSync()};
}
