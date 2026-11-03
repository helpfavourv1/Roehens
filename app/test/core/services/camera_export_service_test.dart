import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_export_bundle.dart';
import 'package:roehens/core/services/camera_export_service.dart';

import '../../support/fakes.dart';

void main() {
  final FakeClock clock = FakeClock(DateTime.utc(2026, 10, 31, 9, 30));

  test('the file name carries the date', () {
    expect(
      CameraExportService.fileNameFor(DateTime.utc(2026, 1, 5)),
      'roehens-cameras-20260105.json',
    );
  });

  test('writes every camera and no credential field', () {
    final ExportFile file =
        CameraExportService(clock: clock, appVersion: '0.1.0').build(<Camera>[
          testCamera(id: 'a', name: 'Garden'),
          testCamera(id: 'b', name: 'Door', sortIndex: 1),
        ]);
    final String text = utf8.decode(file.bytes);

    expect(file.cameraCount, 2);
    expect(file.fileName, 'roehens-cameras-20261031.json');
    expect(file.mimeType, 'application/json');
    expect(text.toLowerCase(), isNot(contains('password')));
    expect(text.toLowerCase(), isNot(contains('username')));
    expect(text, contains('Garden'));
  });

  test('the output reads back as the same cameras', () {
    final List<Camera> cameras = <Camera>[
      testCamera(id: 'a', name: 'Garden'),
      testCamera(id: 'b', name: 'Door', sortIndex: 1),
    ];
    final ExportFile file = CameraExportService(clock: clock).build(cameras);
    final CameraExportBundle back = CameraExportBundle.fromJson(
      jsonDecode(utf8.decode(file.bytes)) as Map<String, Object?>,
    );

    expect(back.cameras, cameras);
  });

  test('an empty list still makes a valid file', () {
    final ExportFile file = CameraExportService(clock: clock).build(<Camera>[]);
    expect(file.cameraCount, 0);
    expect(utf8.decode(file.bytes), contains('"cameras": []'));
  });
}
