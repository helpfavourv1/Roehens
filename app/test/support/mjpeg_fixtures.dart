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
