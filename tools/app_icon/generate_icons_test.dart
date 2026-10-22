// Uygulama ikonlarını ve açılış görsellerini üretir. Normal test
// paketinde çalışmaz; ikon değişince elle çalıştırılır (proje kökünden):
//
//   flutter test tools/app_icon/generate_icons_test.dart
//
// Yüzü değiştirmek için aşağıdaki [iconFace] tarifini değiştir.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bir_omur/models/models.dart';
import 'package:bir_omur/ui/portrait/portrait_spec.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'icon_svg.dart';
import 'png.dart';

final PortraitSpec iconFace = PortraitDesigner.build(
  seed: 100,
  gender: Gender.kadin,
  age: AgeLook.yetiskin,
);

const _androidDensities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

void main() {
  testWidgets('ikonları üret', (tester) async {
    final parts = {
      for (final n in PortraitDesigner.allParts)
        n: File('assets/portraits/$n.svg').readAsStringSync(),
    };
    final full = appIconSvg(parts, spec: iconFace);
    final foreground = appIconSvg(parts, spec: iconFace, foregroundOnly: true);

    await tester.runAsync(() async {
      Future<void> write(
        String svg,
        int size,
        String path, {
        required bool opaque,
      }) async {
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder)..scale(size / 1024);
        canvas.drawPicture(info.picture);
        final image = await recorder.endRecording().toImage(size, size);
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(
            encodePng(rgba!.buffer.asUint8List(), size, size, opaque: opaque),
          );
      }

      const res = 'android/app/src/main/res';
      for (final MapEntry(key: name, value: scale)
          in _androidDensities.entries) {
        await write(
          full,
          (48 * scale).round(),
          '$res/mipmap-$name/ic_launcher.png',
          opaque: true,
        );
        await write(
          foreground,
          (108 * scale).round(),
          '$res/mipmap-$name/ic_launcher_foreground.png',
          opaque: false,
        );
      }

      const ios = 'ios/Runner/Assets.xcassets';
      final iconFiles = Directory('$ios/AppIcon.appiconset')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'));
      for (final file in iconFiles) {
        // Icon-App-83.5x83.5@2x.png → 83.5 × 2
        final m = RegExp(r'Icon-App-([\d.]+)x[\d.]+@(\d)x\.png')
            .firstMatch(file.path)!;
        final size = (double.parse(m[1]!) * int.parse(m[2]!)).round();
        await write(full, size, file.path, opaque: true);
      }
      for (final (suffix, scale) in [('', 1), ('@2x', 2), ('@3x', 3)]) {
        await write(
          foreground,
          168 * scale,
          '$ios/LaunchImage.imageset/LaunchImage$suffix.png',
          opaque: false,
        );
      }
    });
  });
}
