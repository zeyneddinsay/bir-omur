import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Görseli telefonun paylaşım menüsüyle paylaşır. Paylaşıma karşılık oyun
/// içi ödül verilmez (CLAUDE.md).
abstract interface class ShareService {
  /// [origin], iPad'de paylaşım penceresinin çıkacağı yer.
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
    Rect? origin,
  });
}

class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    String? text,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
