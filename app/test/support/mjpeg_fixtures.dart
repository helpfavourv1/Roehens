import 'dart:convert';
import 'dart:typed_data';

/// A fake but structurally valid JPEG: FFD8 ... FFD9, payload bytes below 0xFF.
Uint8List fakeJpeg(int id, {int size = 400}) {
  return Uint8List.fromList(<int>[
    0xFF,
    0xD8,
    ...List<int>.generate(size, (int i) => ((i + id) % 200) + 1),
    0xFF,
    0xD9,
  ]);
}

/// One multipart part carrying [body].
Uint8List multipartPart(Uint8List body, {String boundary = 'frame'}) {
  final String head = '--$boundary\r\nContent-Type: image/jpeg\r\n'
      'Content-Length: ${body.length}\r\n\r\n';
  return Uint8List.fromList(<int>[
    ...ascii.encode(head),
    ...body,
    ...ascii.encode('\r\n'),
  ]);
}

/// A fake JPEG whose start-of-frame segment declares [width] x [height].
Uint8List fakeSizedJpeg(int width, int height, {int id = 0}) {
  return Uint8List.fromList(<int>[
    0xFF, 0xD8, // start of image
    0xFF, 0xE0, 0x00, 0x10, // APP0, 16 bytes long
    ...List<int>.filled(14, 0x41),
    0xFF, 0xC0, 0x00, 0x11, 0x08, // SOF0, 17 bytes long, 8-bit samples
    height >> 8, height & 0xFF, width >> 8, width & 0xFF,
    0x03, 0x01, 0x22, 0x00, 0x02, 0x11, 0x01, 0x03, 0x11, 0x01,
    ...List<int>.generate(200, (int i) => ((i + id) % 200) + 1),
    0xFF, 0xD9, // end of image
  ]);
}
