import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/camera_form.dart';
import 'package:roehens/core/services/rtsp_url_normalizer.dart';

CameraBrandProfile brand(String id, List<int> ports, List<String> main) {
  return CameraBrandProfile(
    id: id,
    displayName: id,
    defaultPorts: ports,
    mainPathTemplates: main,
    subPathTemplates: const <String>['/sub'],
    mjpegTemplates: const <String>['/video.mjpg'],
    snapshotTemplates: const <String>['/snap.jpg'],
    verified: true,
  );
}

void main() {
  final DateTime now = DateTime.utc(2026, 10, 5);
  const CameraFormValues good = CameraFormValues(
    name: ' Porch ',
    host: ' 192.168.1.10 ',
    port: '554',
    mainPath: 'stream0',
  );

  test('a complete form builds a clean camera', () {
    final Camera camera = CameraForm.build(good, now: now)!;
    expect(camera.name, 'Porch');
    expect(camera.host, '192.168.1.10');
    expect(camera.mainPath, '/stream0');
    expect(camera.subPath, isNull);
    expect(camera.port, 554);
    expect(camera.onvifPort, isNull);
  });

  test('every problem is named by field', () {
    final Map<CameraFormField, CameraFormIssue> issues = CameraForm.validate(
      const CameraFormValues(name: '  ', host: 'a b/c', port: '70000'),
    );
    expect(issues[CameraFormField.name], CameraFormIssue.nameRequired);
    expect(issues[CameraFormField.host], CameraFormIssue.hostInvalid);
    expect(issues[CameraFormField.port], CameraFormIssue.portInvalid);
    expect(CameraForm.build(const CameraFormValues(), now: now), isNull);
  });

  test('the ONVIF port is checked only while ONVIF is on', () {
    final CameraFormValues bad = good.copyWith(onvifPort: 'x');
    expect(CameraForm.validate(bad), isEmpty);
    expect(
      CameraForm.validate(bad.copyWith(onvifEnabled: true))[CameraFormField
          .onvifPort],
      CameraFormIssue.portInvalid,
    );
    final Camera camera = CameraForm.build(
      good.copyWith(onvifEnabled: true, onvifPort: '8000'),
      now: now,
    )!;
    expect(camera.onvifPort, 8000);
  });

  test('editing keeps the id, order and creation date', () {
    final Camera first = CameraForm.build(good, now: now)!;
    final Camera saved = Camera(
      id: 'abc',
      name: first.name,
      protocol: first.protocol,
      host: first.host,
      port: first.port,
      mainPath: first.mainPath,
      sortIndex: 3,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    final Camera edited = CameraForm.build(
      good.copyWith(name: 'Gate'),
      existing: saved,
      now: now,
    )!;
    expect(edited.id, 'abc');
    expect(edited.sortIndex, 3);
    expect(edited.createdAt, DateTime.utc(2026, 1, 1));
    expect(edited.updatedAt, now);
  });

  test('a pasted address fills the form, keeping typed credentials', () {
    final CameraFormValues filled = CameraForm.applyAddress(
      const CameraFormValues(username: 'typed', password: 'secret'),
      const ParsedStreamAddress(
        protocol: StreamProtocol.rtsp,
        host: '10.0.0.7',
        port: 8554,
        path: '/live',
      ),
    );
    expect(filled.host, '10.0.0.7');
    expect(filled.port, '8554');
    expect(filled.mainPath, '/live');
    expect(filled.username, 'typed');
  });

  test('changing the type moves the default port only', () {
    final CameraFormValues http = CameraForm.applyProtocol(
      const CameraFormValues(),
      StreamProtocol.mjpeg,
    );
    expect(http.port, '80');
    final CameraFormValues custom = CameraForm.applyProtocol(
      const CameraFormValues(port: '8554'),
      StreamProtocol.mjpeg,
    );
    expect(custom.port, '8554');
  });

  test('a brand fills the empty fields and then follows a change of brand', () {
    final CameraBrandProfile a = brand('a', <int>[554], <String>['/a/main']);
    final CameraBrandProfile b = brand('b', <int>[8554], <String>['/b/main']);

    final CameraFormValues withA = CameraForm.applyBrand(
      const CameraFormValues(),
      a,
    );
    expect(withA.brandId, 'a');
    expect(withA.mainPath, '/a/main');
    expect(withA.subPath, '/sub');

    final CameraFormValues withB = CameraForm.applyBrand(withA, b, previous: a);
    expect(withB.port, '8554');
    expect(withB.mainPath, '/b/main');

    // A path the person typed is never replaced.
    final CameraFormValues typed = CameraForm.applyBrand(
      withA.copyWith(mainPath: '/mine'),
      b,
      previous: a,
    );
    expect(typed.mainPath, '/mine');
  });

  test('other paths of the brand are offered, without the one in use', () {
    final CameraBrandProfile a = brand('a', <int>[554], <String>['/1', '/2']);
    expect(
      CameraForm.alternativeMainPaths(good.copyWith(mainPath: '/1'), a),
      <String>['/2'],
    );
    expect(CameraForm.alternativeMainPaths(good, null), isEmpty);
  });

  test('discovery results become a starting form', () {
    final CameraFormValues onvif = CameraForm.fromDiscovery(
      const DiscoveryResult(
        host: '10.0.0.9',
        port: 8000,
        source: DiscoverySource.onvif,
        name: 'Garage',
        model: 'X1',
      ),
    );
    expect(onvif.name, 'Garage');
    expect(onvif.port, '554');
    expect(onvif.onvifEnabled, isTrue);
    expect(onvif.onvifPort, '8000');
    expect(onvif.modelHint, 'X1');

    final CameraFormValues rtsp = CameraForm.fromDiscovery(
      const DiscoveryResult(
        host: '10.0.0.9',
        port: 8554,
        source: DiscoverySource.sweep,
      ),
    );
    expect(rtsp.name, '10.0.0.9');
    expect(rtsp.port, '8554');
    expect(rtsp.onvifEnabled, isFalse);
  });
}
