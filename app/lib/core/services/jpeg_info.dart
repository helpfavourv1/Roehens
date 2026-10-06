import 'dart:typed_data';

/// Pixel size of a JPEG image.
class JpegSize {
  const JpegSize(this.width, this.height);

  final int width;
  final int height;

  @override
  bool operator ==(Object other) {
    return other is JpegSize && other.width == width && other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'JpegSize($width x $height)';
}

/// Reads the size from the start-of-frame segment without decoding the image.
/// Returns null when [bytes] is not a JPEG or the segment cannot be found.
JpegSize? readJpegSize(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return null;
  }
  int i = 2;
  while (i + 3 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    final int marker = bytes[i + 1];
    if (marker == 0xFF) {
      i++;
      continue;
    }
    // Markers without a length: SOI, TEM and the restart markers.
    if (marker == 0xD8 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) {
      i += 2;
      continue;
    }
    // End of image or start of scan: the frame header would have come first.
    if (marker == 0xD9 || marker == 0xDA) {
      return null;
    }
    final int length = (bytes[i + 2] << 8) | bytes[i + 3];
    final bool isFrameHeader = marker >= 0xC0 &&
        marker <= 0xCF &&
        marker != 0xC4 &&
        marker != 0xC8 &&
        marker != 0xCC;
    if (isFrameHeader) {
      if (i + 8 >= bytes.length) {
        return null;
      }
      final int height = (bytes[i + 5] << 8) | bytes[i + 6];
      final int width = (bytes[i + 7] << 8) | bytes[i + 8];
      return width > 0 && height > 0 ? JpegSize(width, height) : null;
    }
    i += 2 + length;
  }
  return null;
}
