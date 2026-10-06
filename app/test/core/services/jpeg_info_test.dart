import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/jpeg_info.dart';

import '../../support/mjpeg_fixtures.dart';

void main() {
  test('reads the size from the frame header', () {
    expect(readJpegSize(fakeSizedJpeg(640, 480)), const JpegSize(640, 480));
    expect(readJpegSize(fakeSizedJpeg(1280, 720)), const JpegSize(1280, 720));
    expect(readJpegSize(fakeSizedJpeg(2592, 1944)), const JpegSize(2592, 1944));
  });

  test('segments before the frame header are skipped', () {
    // The fixture already carries an APP0 segment before the frame header.
    final Uint8List jpeg = fakeSizedJpeg(320, 240);
    expect(jpeg[2], 0xFF);
    expect(jpeg[3], 0xE0);
    expect(readJpegSize(jpeg), const JpegSize(320, 240));
  });

  test('anything that is not a JPEG gives null', () {
    expect(readJpegSize(Uint8List(0)), isNull);
    expect(readJpegSize(Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6])), isNull);
    expect(readJpegSize(fakeJpeg(1)), isNull); // no frame header at all
  });

  test('a truncated header gives null instead of throwing', () {
    final Uint8List jpeg = fakeSizedJpeg(640, 480);
    for (int cut = 0; cut < 30; cut++) {
      expect(() => readJpegSize(jpeg.sublist(0, cut)), returnsNormally);
    }
    expect(readJpegSize(jpeg.sublist(0, 26)), isNull);
  });

  test('a zero size is rejected', () {
    expect(readJpegSize(fakeSizedJpeg(0, 480)), isNull);
  });
}
