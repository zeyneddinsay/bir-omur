import 'package:flutter/services.dart';

import 'content_loader.dart';

const String registryAsset = 'assets/registry.json';
const String cardsAssetDir = 'assets/cards/';

/// İçeriği uygulama paketinden okur. `assets/cards/` altındaki her JSON
/// dosyası kendiliğinden yüklenir; yeni kart dosyası için kod değişmez.
Future<GameContent> loadContentFromAssets(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final paths =
      manifest
          .listAssets()
          .where((p) => p.startsWith(cardsAssetDir) && p.endsWith('.json'))
          .toList()
        ..sort();
  return loadContent(
    registrySource: await bundle.loadString(registryAsset),
    cardFiles: {
      for (final path in paths)
        path.substring(cardsAssetDir.length): await bundle.loadString(path),
    },
  );
}
