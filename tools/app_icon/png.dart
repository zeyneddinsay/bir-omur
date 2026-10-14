import 'dart:io';
import 'dart:typed_data';

/// Ham RGBA pikselleri PNG'ye çevirir. [opaque] true ise alfa kanalı
/// atılır (RGB): App Store, mağaza ikonunda alfa kanalı kabul etmez.
Uint8List encodePng(
  Uint8List rgba,
  int width,
  int height, {
  required bool opaque,
}) {
  final channels = opaque ? 3 : 4;
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // satır filtresi: yok
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw.add(rgba.sublist(i, i + channels));
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit derinliği
    ..setUint8(9, opaque ? 2 : 6) // renk tipi: RGB ya da RGBA
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final out = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  _chunk(out, 'IHDR', header.buffer.asUint8List());
  _chunk(out, 'IDAT', Uint8List.fromList(ZLibCodec().encode(raw.takeBytes())));
  _chunk(out, 'IEND', Uint8List(0));
  return out.takeBytes();
}

void _chunk(BytesBuilder out, String type, Uint8List data) {
  final typeBytes = type.codeUnits;
  out.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crc = _crc32([...typeBytes, ...data]);
  out.add((ByteData(4)..setUint32(0, crc)).buffer.asUint8List());
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >>> 8);
  }
  return c ^ 0xFFFFFFFF;
}
