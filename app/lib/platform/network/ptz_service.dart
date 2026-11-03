import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/ptz_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/ptz_command.dart';
import 'package:roehens/core/services/onvif_response_parser.dart';
import 'package:roehens/platform/network/onvif_client.dart';

/// PTZ through the camera's ONVIF service. The connection (clock, services,
/// profiles) is learned once per camera and reused, so a pad drag sends one
/// small request per move instead of five.
class PtzService implements PtzContract {
  PtzService({required this._client});

  final OnvifClient _client;
  final Map<String, _Connection> _connections = <String, _Connection>{};

  @override
  Future<Result<bool>> supportsPtz({
    required Camera camera,
    required CameraCredentials credentials,
  }) async {
    if (!camera.onvifEnabled) {
      return const Ok<bool>(false);
    }
    final Result<_Connection> connected = await _connect(camera, credentials);
    final AppError? error = connected.errorOrNull;
    if (error != null) {
      return Err<bool>(error);
    }
    return Ok<bool>(connected.valueOrNull!.supportsPtz);
  }

  @override
  Future<Result<void>> execute({
    required Camera camera,
    required CameraCredentials credentials,
    required PtzCommand command,
  }) async {
    final Result<_Connection> connected = await _connect(camera, credentials);
    final AppError? error = connected.errorOrNull;
    if (error != null) {
      return Err<void>(error);
    }
    final _Connection connection = connected.valueOrNull!;
    final Uri? service = connection.device.ptzService;
    final String? token = connection.profileToken;
    if (service == null || token == null) {
      return const Err<void>(
        AppError(ErrorClass.unsupportedMedia, detail: 'camera has no PTZ'),
      );
    }
    final Result<void> result = await _client.ptz(
      service,
      token,
      command,
      credentials,
      clockOffset: connection.device.clockOffset,
    );
    if (result.isErr &&
        result.errorOrNull?.errorClass != ErrorClass.authFailed) {
      // The camera may have restarted or changed address; learn it again next time.
      _connections.remove(camera.id);
    }
    return result;
  }

  /// Forget what was learned, for example after the camera was edited.
  void forget(String cameraId) => _connections.remove(cameraId);

  Future<Result<_Connection>> _connect(
    Camera camera,
    CameraCredentials credentials,
  ) async {
    final _Connection? cached = _connections[camera.id];
    if (cached != null && cached.matches(camera)) {
      return Ok<_Connection>(cached);
    }
    final int port = camera.onvifPort ?? Limits.defaultHttpPort;
    final Uri deviceService = Uri(
      scheme: 'http',
      host: camera.host,
      port: port,
      path: '/onvif/device_service',
    );
    final Result<OnvifDevice> device = await _client.connect(
      deviceService,
      credentials,
    );
    final AppError? error = device.errorOrNull;
    if (error != null) {
      return Err<_Connection>(error);
    }
    final _Connection connection = _Connection(camera, device.valueOrNull!);
    _connections[camera.id] = connection;
    return Ok<_Connection>(connection);
  }
}

class _Connection {
  _Connection(Camera camera, this.device)
    : host = camera.host,
      port = camera.onvifPort;

  final OnvifDevice device;
  final String host;
  final int? port;

  bool matches(Camera camera) =>
      camera.host == host && camera.onvifPort == port;

  /// The profile PTZ commands go to: the first one the camera says has PTZ,
  /// else the first profile.
  String? get profileToken {
    if (device.profiles.isEmpty) {
      return null;
    }
    for (final OnvifProfile profile in device.profiles) {
      if (profile.hasPtz) {
        return profile.token;
      }
    }
    return device.profiles.first.token;
  }

  bool get supportsPtz => device.ptzService != null;
}
