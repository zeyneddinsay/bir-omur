import 'package:bir_omur/ui/portrait/portrait_spec.dart';

/// Uygulama ikonunun SVG'si (1024×1024). [parts]: portre parçaları.
///
/// [foregroundOnly]: Android uyarlanabilir ikonunun ön katmanı; zemin yok,
/// çizim güvenli alan (ortadaki %61) içinde kalır.
String appIconSvg(
  Map<String, String> parts, {
  required PortraitSpec spec,
  bool foregroundOnly = false,
}) {
  final portrait = composePortraitSvg(spec, parts);
  final inner = portrait.substring(
    portrait.indexOf('>') + 1,
    portrait.lastIndexOf('</svg>'),
  );
  // Ön katmanda çizim küçülür: uyarlanabilir ikon kenarları kırpılır.
  final scale = foregroundOnly ? 0.62 : 1.0;
  final offset = 512 * (1 - scale);
  return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">'
      '<defs><clipPath id="c"><circle cx="100" cy="100" r="100"/></clipPath></defs>'
      '${foregroundOnly ? '' : '<rect width="1024" height="1024" fill="#C0392B"/>'}'
      '<g transform="translate($offset $offset) scale($scale)">'
      '<circle cx="512" cy="512" r="392" fill="#FFF8F0"/>'
      '<g transform="translate(152 152) scale(3.6)" clip-path="url(#c)">$inner</g>'
      '<circle cx="512" cy="512" r="392" fill="none" stroke="#FFF8F0" stroke-width="24"/>'
      '</g></svg>';
}
