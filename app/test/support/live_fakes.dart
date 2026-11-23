import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:roehens/core/contracts/file_transfer_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
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

/// Share sheet and file picker without a phone: remembers what was shared and
/// hands back a file chosen by the test.
class FakeFileTransfer implements FileTransferContract {
  final List<({Uint8List bytes, String fileName, String mimeType})> shared =
      <({Uint8List bytes, String fileName, String mimeType})>[];
  PickedFile? toPick;
  AppError? failure;

  @override
  Future<Result<void>> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (failure != null) {
      return Err<void>(failure!);
    }
    shared.add((bytes: bytes, fileName: fileName, mimeType: mimeType));
    return const Ok<void>(null);
  }

  @override
  Future<Result<PickedFile?>> pickJsonFile() async {
    if (failure != null) {
      return Err<PickedFile?>(failure!);
    }
    return Ok<PickedFile?>(toPick);
  }
}
