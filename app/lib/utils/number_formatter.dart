/// Formatting of technical values: bitrate, resolution, frame rate and sizes.
/// Digits are always Western and units are the international abbreviations, so
/// the output is identical in every language.
class NumberFormatter {
  NumberFormatter._();

  /// `850 kbps`, `2.5 Mbps`, `12 Mbps`.
  static String bitrate(int bitsPerSecond) {
    final int bps = bitsPerSecond < 0 ? 0 : bitsPerSecond;
    if (bps >= 1000000) {
      final double mbps = bps / 1000000;
      return '${_trim(mbps, mbps >= 10 ? 0 : 1)} Mbps';
    }
    return '${(bps / 1000).round()} kbps';
  }

  /// `1920\u00D71080`.
  static String resolution(int width, int height) => '$width\u00D7$height';

  /// `25 fps`.
  static String frameRate(double framesPerSecond) {
    final double fps = framesPerSecond < 0 ? 0 : framesPerSecond;
    return '${fps.round()} fps';
  }

  /// Decimal units, matching the storage tables in the specification:
  /// `512 B`, `1.5 KB`, `38 MB`, `3.6 GB`.
  static String bytes(int byteCount) {
    final int count = byteCount < 0 ? 0 : byteCount;
    if (count < 1000) {
      return '$count B';
    }
    if (count < 1000000) {
      return '${_trim(count / 1000, count < 10000 ? 1 : 0)} KB';
    }
    if (count < 1000000000) {
      return '${_trim(count / 1000000, count < 10000000 ? 1 : 0)} MB';
    }
    return '${_trim(count / 1000000000, count < 10000000000 ? 1 : 0)} GB';
  }

  static String _trim(double value, int fractionDigits) {
    final String text = value.toStringAsFixed(fractionDigits);
    if (fractionDigits > 0 && text.endsWith('.0')) {
      return text.substring(0, text.length - 2);
    }
    return text;
  }
}
