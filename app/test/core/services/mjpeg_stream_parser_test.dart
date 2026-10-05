import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/services/mjpeg_stream_parser.dart';

/// A fake but structurally valid JPEG: FFD8 ... FFD9, payload bytes below 0xFF.
Uint8List jpeg(int id, {int size = 300}) {
  return Uint8List.fromList(<int>[
    0xFF,
    0xD8,
    ...List<int>.generate(size, (int i) => ((i + id) % 200) + 1),
    0xFF,
    0xD9,
  ]);
}

Uint8List part(
  Uint8List body, {
  String boundary = 'frame',
  bool withLength = true,
  String eol = '\r\n',
}) {
  final StringBuffer head = StringBuffer('--$boundary$eol')
    ..write('Content-Type: image/jpeg$eol');
  if (withLength) {
    head.write('Content-Length: ${body.length}$eol');
  }
  head.write(eol);
  return Uint8List.fromList(<int>[
    ...ascii.encode(head.toString()),
    ...body,
    ...ascii.encode(eol),
  ]);
}

Uint8List concat(List<Uint8List> pieces) {
  return Uint8List.fromList(<int>[for (final Uint8List p in pieces) ...p]);
}

/// Feeds [data] in chunks of [chunkSize] and gathers every returned frame.
List<Uint8List> feed(MjpegStreamParser parser, Uint8List data, int chunkSize) {
  final List<Uint8List> frames = <Uint8List>[];
  for (int i = 0; i < data.length; i += chunkSize) {
    final int end = i + chunkSize < data.length ? i + chunkSize : data.length;
    frames.addAll(parser.add(data.sublist(i, end)));
  }
  return frames;
}

void expectFrames(List<Uint8List> actual, List<Uint8List> expected) {
  expect(actual.length, expected.length);
  for (int i = 0; i < expected.length; i++) {
    expect(actual[i], expected[i], reason: 'frame $i differs');
  }
}

void main() {
  final List<Uint8List> frames = <Uint8List>[
    for (int i = 0; i < 12; i++) jpeg(i, size: 200 + i * 37),
  ];

  const List<int> chunkSizes = <int>[1, 3, 17, 512, 100000];

  group('parts with Content-Length', () {
    final Uint8List stream = concat(<Uint8List>[
      for (final Uint8List f in frames) part(f),
    ]);
    for (final int size in chunkSizes) {
      test('chunks of $size bytes', () {
        final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
        expectFrames(feed(parser, stream, size), frames);
        expect(parser.droppedParts, 0);
        expect(parser.framesParsed, frames.length);
      });
    }
  });

  group('parts without Content-Length', () {
    final Uint8List stream = concat(<Uint8List>[
      for (final Uint8List f in frames) part(f, withLength: false),
      ascii.encode('--frame--\r\n') as Uint8List,
    ]);
    for (final int size in chunkSizes) {
      test('chunks of $size bytes', () {
        final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
        expectFrames(feed(parser, stream, size), frames);
      });
    }
  });

  test('bare line feeds instead of CRLF are accepted', () {
    final Uint8List stream = concat(<Uint8List>[
      for (final Uint8List f in frames) part(f, eol: '\n'),
    ]);
    final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
    expectFrames(feed(parser, stream, 7), frames);
  });

  test('a boundary declared with leading dashes still matches', () {
    final MjpegStreamParser parser =
        MjpegStreamParser(boundary: '--myboundary');
    final Uint8List stream = concat(<Uint8List>[
      for (final Uint8List f in frames) part(f, boundary: 'myboundary'),
    ]);
    expectFrames(feed(parser, stream, 11), frames);
  });

  test('a quoted boundary value is unquoted', () {
    expect(
      MjpegStreamParser.boundaryFromContentType(
        'multipart/x-mixed-replace; boundary="--abc"',
      ),
      'abc',
    );
  });

  test('the boundary is found in the stream when none is declared', () {
    final MjpegStreamParser parser = MjpegStreamParser();
    final Uint8List stream = concat(<Uint8List>[
      for (final Uint8List f in frames) part(f, boundary: 'videoboundary'),
    ]);
    expectFrames(feed(parser, stream, 13), frames);
  });

  test('junk before the first part is skipped', () {
    final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
    final Uint8List stream = concat(<Uint8List>[
      ascii.encode('HTTP noise \x00\x01 more noise\r\n') as Uint8List,
      for (final Uint8List f in frames.take(3)) part(f),
    ]);
    expectFrames(feed(parser, stream, 5), frames.take(3).toList());
  });

  test('a part that is not a JPEG is dropped and the next one still parses', () {
    final Uint8List notAnImage =
        Uint8List.fromList(ascii.encode('<html>503 busy</html>'));
    final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
    final Uint8List stream = concat(<Uint8List>[
      part(frames[0]),
      part(notAnImage),
      part(frames[1]),
    ]);
    expectFrames(feed(parser, stream, 9), <Uint8List>[frames[0], frames[1]]);
    expect(parser.droppedParts, 1);
  });

  test('a truncated JPEG is dropped', () {
    final Uint8List cut = frames[0].sublist(0, 120);
    final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
    final Uint8List stream = concat(<Uint8List>[part(cut), part(frames[1])]);
    expectFrames(feed(parser, stream, 50), <Uint8List>[frames[1]]);
    expect(parser.droppedParts, 1);
  });

  test('an oversize part is skipped and the stream recovers', () {
    final MjpegStreamParser parser =
        MjpegStreamParser(boundary: 'frame', maxFrameBytes: 1000);
    final Uint8List stream = concat(<Uint8List>[
      part(jpeg(1, size: 5000)),
      part(frames[0]),
      part(frames[1]),
    ]);
    final List<Uint8List> got = feed(parser, stream, 64);
    expectFrames(got, <Uint8List>[frames[0], frames[1]]);
    expect(parser.droppedParts, 1);
    expect(parser.resyncs, greaterThan(0));
  });

  test('reset forgets a half-received part', () {
    final MjpegStreamParser parser = MjpegStreamParser(boundary: 'frame');
    final Uint8List first = part(frames[0]);
    parser.add(first.sublist(0, first.length ~/ 2));
    parser.reset();
    expectFrames(parser.add(part(frames[1])), <Uint8List>[frames[1]]);
  });

  test('boundaryFromContentType handles the usual headers', () {
    expect(
      MjpegStreamParser.boundaryFromContentType(
        'multipart/x-mixed-replace;boundary=myboundary',
      ),
      'myboundary',
    );
    expect(
      MjpegStreamParser.boundaryFromContentType(
        'multipart/x-mixed-replace; boundary=--myboundary; charset=x',
      ),
      'myboundary',
    );
    expect(MjpegStreamParser.boundaryFromContentType('image/jpeg'), isNull);
    expect(MjpegStreamParser.boundaryFromContentType(null), isNull);
  });
}
