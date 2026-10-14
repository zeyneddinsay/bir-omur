import 'package:flutter/services.dart';

import 'content_loader.dart';

const String registryAsset = 'assets/registry.json';
const String cardsAssetDir = 'assets/cards/';
const String careersAssetDir = 'assets/careers/';
const String achievementsAsset = 'assets/achievements.json';

/// İçeriği uygulama paketinden okur. `assets/cards/` ve `assets/careers/`
/// altındaki her JSON dosyası kendiliğinden yüklenir; yeni dosya için kod
/// değişmez.
Future<GameContent> loadContentFromAssets(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final assets = manifest.listAssets().toList()..sort();

  Future<Map<String, String>> jsonFilesIn(String dir) async => {
    for (final path in assets)
      if (path.startsWith(dir) && path.endsWith('.json'))
        path.substring(dir.length): await bundle.loadString(path),
  };

  return loadContent(
    registrySource: await bundle.loadString(registryAsset),
    cardFiles: await jsonFilesIn(cardsAssetDir),
    careerFiles: await jsonFilesIn(careersAssetDir),
    achievementsSource: assets.contains(achievementsAsset)
        ? await bundle.loadString(achievementsAsset)
        : null,
  );
}
