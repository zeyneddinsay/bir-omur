import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'portrait_spec.dart';

/// Bütün portre parçaları: ad → SVG metni. Bir kez yüklenir.
final portraitPartsProvider = FutureProvider<Map<String, String>>((ref) async {
  return {
    for (final name in PortraitDesigner.allParts)
      name: await rootBundle.loadString('assets/portraits/$name.svg'),
  };
}, retry: (_, _) => null);

/// Katmanlı SVG portre; daire içinde çizilir.
class Portrait extends ConsumerWidget {
  const Portrait({super.key, required this.spec, this.size = 64});

  final PortraitSpec spec;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parts = ref.watch(portraitPartsProvider).value;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: parts == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : SvgPicture.string(
                composePortraitSvg(spec, parts),
                width: size,
                height: size,
              ),
      ),
    );
  }
}
