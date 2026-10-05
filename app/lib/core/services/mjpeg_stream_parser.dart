import 'dart:convert';
import 'dart:typed_data';

enum _State { boundary, headers, body }

/// Splits an HTTP `multipart/x-mixed-replace` MJPEG byte stream into JPEG
/// frames. Feed it the chunks as they arrive, in any size; it returns the frames
/// completed by each chunk.
///
/// Handles a boundary declared in the Content-Type header (with or without the
/// leading dashes), a boundary found in the stream itself, parts with and
/// without Content-Length, and junk before the first part. Parts that are not
/// complete JPEG images are dropped and counted, never returned.
class MjpegStreamParser {
  MjpegStreamParser({String? boundary, this.maxFrameBytes = 8 * 1024 * 1024}) {
    _setBoundary(_normalize(boundary));
  }

  /// A part larger than this is skipped.
  final int maxFrameBytes;

  static final Uint8List _crlfcrlf = Uint8List.fromList(<int>[13, 10, 13, 10]);
  static final Uint8List _lflf = Uint8List.fromList(<int>[10, 10]);
  static final RegExp _contentLength = RegExp(
    r'content-length:\s*(\d+)',
    caseSensitive: false,
  );

  Uint8List _buf = Uint8List(64 * 1024);
  int _start = 0;
  int _end = 0;
  _State _state = _State.boundary;
  Uint8List? _marker;
  int? _length;

  int _framesParsed = 0;
  int _droppedParts = 0;
  int _resyncs = 0;

  /// Complete frames returned so far.
  int get framesParsed => _framesParsed;

  /// Parts that were skipped because they were not complete JPEG images.
  int get droppedParts => _droppedParts;

  /// Times the parser lost its place and searched for the next boundary.
  int get resyncs => _resyncs;

  /// Extracts the boundary from a Content-Type header value, or null.
  static String? boundaryFromContentType(String? contentType) {
    if (contentType == null) {
      return null;
    }
    final Match? match = RegExp(
      r'boundary\s*=\s*("[^"]+"|[^;\s]+)',
      caseSensitive: false,
    ).firstMatch(contentType);
    return match == null ? null : _normalize(match.group(1));
  }

  static String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    String text = value.trim();
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      text = text.substring(1, text.length - 1);
    }
    while (text.startsWith('-')) {
      text = text.substring(1);
    }
    return text.isEmpty ? null : text;
  }

  void _setBoundary(String? name) {
    _marker = name == null
        ? null
        : Uint8List.fromList(ascii.encode('--$name'));
  }

  /// Forgets buffered data, for example after a reconnect.
  void reset() {
    _start = 0;
    _end = 0;
    _state = _State.boundary;
    _length = null;
  }

  /// Adds received bytes and returns the frames they completed.
  List<Uint8List> add(Uint8List chunk) {
    _append(chunk);
    final List<Uint8List> frames = <Uint8List>[];
    while (_step(frames)) {}
    if (_end - _start > maxFrameBytes * 2) {
      _resyncs++;
      reset();
    }
    return frames;
  }

  int get _available => _end - _start;

  void _append(Uint8List chunk) {
    if (_end + chunk.length > _buf.length) {
      if (_start > 0) {
        _buf.setRange(0, _available, _buf, _start);
        _end = _available;
        _start = 0;
      }
      if (_end + chunk.length > _buf.length) {
        int size = _buf.length * 2;
        while (size < _end + chunk.length) {
          size *= 2;
        }
        final Uint8List bigger = Uint8List(size);
        bigger.setRange(0, _end, _buf);
        _buf = bigger;
      }
    }
    _buf.setRange(_end, _end + chunk.length, chunk);
    _end += chunk.length;
  }

  void _consume(int count) {
    _start += count;
    if (_start >= _end) {
      _start = 0;
      _end = 0;
    }
  }

  int _indexOf(Uint8List pattern, int from) {
    final int last = _end - pattern.length;
    for (int i = from; i <= last; i++) {
      if (_buf[i] != pattern[0]) {
        continue;
      }
      int j = 1;
      while (j < pattern.length && _buf[i + j] == pattern[j]) {
        j++;
      }
      if (j == pattern.length) {
        return i;
      }
    }
    return -1;
  }

  int _lineEnd(int from) {
    for (int i = from; i < _end; i++) {
      if (_buf[i] == 0x0A) {
        return i;
      }
    }
    return -1;
  }

  /// Advances the state machine by one step. Returns true when it consumed
  /// something and another step may be possible.
  bool _step(List<Uint8List> out) {
    if (_available == 0) {
      return false;
    }
    switch (_state) {
      case _State.boundary:
        return _marker == null ? _detectBoundary() : _stepBoundary();
      case _State.headers:
        return _stepHeaders();
      case _State.body:
        return _stepBody(out);
    }
  }

  bool _detectBoundary() {
    int i = _start;
    while (i + 1 < _end && !(_buf[i] == 0x2D && _buf[i + 1] == 0x2D)) {
      i++;
    }
    if (i + 1 >= _end) {
      if (_available > 1) {
        _start = _end - 1;
      }
      return false;
    }
    final int lineEnd = _lineEnd(i);
    if (lineEnd < 0) {
      _start = i;
      return false;
    }
    final String? name = _normalize(
      latin1.decode(_buf.sublist(i, lineEnd)).trim(),
    );
    _start = lineEnd + 1;
    if (name != null) {
      _setBoundary(name);
      _state = _State.headers;
    }
    return true;
  }

  bool _stepBoundary() {
    final Uint8List marker = _marker!;
    final int index = _indexOf(marker, _start);
    if (index < 0) {
      final int keep = marker.length - 1;
      if (_available > keep) {
        _start = _end - keep;
      }
      return false;
    }
    _start = index;
    final int lineEnd = _lineEnd(index + marker.length);
    if (lineEnd < 0) {
      return false;
    }
    final bool closing = index + marker.length + 1 < _end &&
        _buf[index + marker.length] == 0x2D &&
        _buf[index + marker.length + 1] == 0x2D;
    _start = lineEnd + 1;
    _state = closing ? _State.boundary : _State.headers;
    return true;
  }

  bool _stepHeaders() {
    final int crlf = _indexOf(_crlfcrlf, _start);
    final int lf = _indexOf(_lflf, _start);
    int headerEnd = -1;
    int separator = 0;
    if (crlf >= 0 && (lf < 0 || crlf <= lf)) {
      headerEnd = crlf;
      separator = _crlfcrlf.length;
    } else if (lf >= 0) {
      headerEnd = lf;
      separator = _lflf.length;
    }
    if (headerEnd < 0) {
      if (_available > 16 * 1024) {
        _resync();
      }
      return false;
    }
    final String headers = latin1.decode(_buf.sublist(_start, headerEnd));
    final Match? match = _contentLength.firstMatch(headers);
    _length = match == null ? null : int.tryParse(match.group(1)!);
    _start = headerEnd + separator;
    _state = _State.body;
    return true;
  }

  bool _stepBody(List<Uint8List> out) {
    final int? length = _length;
    if (length != null) {
      if (length > maxFrameBytes) {
        _droppedParts++;
        _resync();
        return false;
      }
      if (_available < length) {
        return false;
      }
      final Uint8List raw = _buf.sublist(_start, _start + length);
      _consume(length);
      _state = _State.boundary;
      _emit(raw, out);
      return true;
    }
    final Uint8List marker = _marker!;
    final int index = _indexOf(marker, _start);
    if (index < 0) {
      if (_available > maxFrameBytes) {
        _droppedParts++;
        _resync();
      }
      return false;
    }
    final Uint8List raw = _buf.sublist(_start, index);
    _start = index;
    _state = _State.boundary;
    _emit(raw, out);
    return true;
  }

  void _resync() {
    _resyncs++;
    _state = _State.boundary;
    _length = null;
    _start = _end;
    _consume(0);
  }

  void _emit(Uint8List raw, List<Uint8List> out) {
    final Uint8List? frame = _clean(raw);
    if (frame == null) {
      _droppedParts++;
      return;
    }
    _framesParsed++;
    out.add(frame);
  }

  /// A complete JPEG starts with FFD8 and ends with FFD9. Anything after the end
  /// marker (line breaks, part of a boundary) is cut off.
  static Uint8List? _clean(Uint8List raw) {
    if (raw.length < 4 || raw[0] != 0xFF || raw[1] != 0xD8) {
      return null;
    }
    final int floor = raw.length > 64 ? raw.length - 64 : 2;
    for (int i = raw.length - 2; i >= floor; i--) {
      if (raw[i] == 0xFF && raw[i + 1] == 0xD9) {
        return raw.sublist(0, i + 2);
      }
    }
    return null;
  }
}
