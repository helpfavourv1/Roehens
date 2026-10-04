import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/stream_protocol.dart';

Camera sample() {
  return Camera(
    id: 'a1',
    name: 'Front door',
    protocol: StreamProtocol.rtsp,
    host: '192.168.1.20',
    port: 554,
    mainPath: '/stream0',
    subPath: '/stream1',
    transport: StreamTransport.tcp,
    brandId: 'generic',
    modelHint: 'X1',
    onvifEnabled: true,
    onvifPort: 80,
    sortIndex: 2,
    createdAt: DateTime.utc(2026, 10, 4, 12),
    updatedAt: DateTime.utc(2026, 10, 4, 13),
  );
}

void main() {
  test('survives a JSON round trip', () {
    final Camera camera = sample();
    final String text = jsonEncode(camera.toJson());
    final Camera back =
        Camera.fromJson(jsonDecode(text) as Map<String, Object?>);
    expect(back, camera);
    expect(back.hashCode, camera.hashCode);
  });

  test('JSON never contains credentials', () {
    final String text = jsonEncode(sample().toJson()).toLowerCase();
    expect(text.contains('password'), isFalse);
    expect(text.contains('username'), isFalse);
  });

  test('optional fields default when absent', () {
    final Camera back = Camera.fromJson(<String, Object?>{
      'id': 'b',
      'name': 'Yard',
      'protocol': 'mjpeg',
      'host': 'cam.local',
      'port': 80,
      'mainPath': '/mjpg/video.mjpg',
      'sortIndex': 0,
      'createdAtMillis': 0,
      'updatedAtMillis': 0,
    });
    expect(back.transport, StreamTransport.auto);
    expect(back.onvifEnabled, isFalse);
    expect(back.subPath, isNull);
    expect(back.hasSubstream, isFalse);
  });

  test('copyWith changes only what it is given and can clear optionals', () {
    final Camera camera = sample();
    final Camera renamed = camera.copyWith(name: 'Back door');
    expect(renamed.name, 'Back door');
    expect(renamed.host, camera.host);
    expect(renamed.subPath, camera.subPath);

    final Camera cleared = camera.copyWith(subPath: null, onvifPort: null);
    expect(cleared.subPath, isNull);
    expect(cleared.onvifPort, isNull);
    expect(cleared.hasSubstream, isFalse);
    expect(camera.subPath, '/stream1');
  });

  test('credentials are redacted in text and compare by value', () {
    const CameraCredentials a =
        CameraCredentials(username: 'admin', password: 'secret1');
    expect(a.toString().contains('secret1'), isFalse);
    expect(a.toString().contains('admin'), isFalse);
    expect(
      a,
      const CameraCredentials(username: 'admin', password: 'secret1'),
    );
    expect(CameraCredentials.none.isEmpty, isTrue);
    expect(CameraCredentials.fromJson(a.toJson()), a);
  });

  test('generated ids are version 4 UUIDs and differ', () {
    final RegExp uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final Random random = Random(7);
    final Set<String> ids = <String>{};
    for (int i = 0; i < 50; i++) {
      final String id = generateCameraId(random);
      expect(uuid.hasMatch(id), isTrue, reason: id);
      ids.add(id);
    }
    expect(ids.length, 50);
    expect(uuid.hasMatch(generateCameraId()), isTrue);
  });
}
