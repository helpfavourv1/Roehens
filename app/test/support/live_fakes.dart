import 'package:flutter/widgets.dart';
import 'package:roehens/core/contracts/ptz_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/models/stream_protocol.dart';

/// A camera with both streams, for tests that care about main versus sub.
Camera cameraWithSub({
  required String id,
  String name = 'Camera',
  int sortIndex = 0,
  StreamProtocol protocol = StreamProtocol.rtsp,
  bool onvif = false,
  String host = '192.168.1.10',
}) {
  return Camera(
    id: id,
    name: name,
    protocol: protocol,
    host: host,
    port: protocol == StreamProtocol.rtsp ? 554 : 80,
    mainPath: '/main',
    subPath: '/sub',
    sortIndex: sortIndex,
    createdAt: DateTime.utc(2026, 10, 4),
    updatedAt: DateTime.utc(2026, 10, 4),
    onvifEnabled: onvif,
  );
}

/// Records pan and tilt commands instead of sending them.
class FakePtz implements PtzContract {
  FakePtz({this.supported = true});

  bool supported;
  final List<PtzCommand> commands = <PtzCommand>[];

  @override
  Future<Result<bool>> supportsPtz({
    required Camera camera,
    required CameraCredentials credentials,
  }) async => Ok<bool>(supported);

  @override
  Future<Result<void>> execute({
    required Camera camera,
    required CameraCredentials credentials,
    required PtzCommand command,
  }) async {
    commands.add(command);
    return const Ok<void>(null);
  }
}

/// Stands in for the video view: an empty box.
Widget fakeVideoView(
  Object? handle, {
  BoxFit fit = BoxFit.cover,
  Color? backdrop,
}) {
  return const SizedBox.expand(key: ValueKey<String>('video'));
}
