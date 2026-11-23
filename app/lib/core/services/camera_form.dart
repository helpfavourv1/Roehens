import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/camera_brand_profile.dart';
import 'package:roehens/core/models/discovery_result.dart';
import 'package:roehens/core/models/stream_protocol.dart';
import 'package:roehens/core/services/rtsp_url_normalizer.dart';
import 'package:roehens/core/services/url_builder.dart';

/// What the camera form shows, as text the person typed or chose.
class CameraFormValues {
  const CameraFormValues({
    this.name = '',
    this.protocol = StreamProtocol.rtsp,
    this.host = '',
    this.port = '554',
    this.username = '',
    this.password = '',
    this.mainPath = '',
    this.subPath = '',
    this.transport = StreamTransport.auto,
    this.onvifEnabled = false,
    this.onvifPort = '',
    this.brandId,
    this.modelHint = '',
  });

  /// A form filled from a saved camera and its credentials.
  factory CameraFormValues.fromCamera(
    Camera camera,
    CameraCredentials credentials,
  ) {
    return CameraFormValues(
      name: camera.name,
      protocol: camera.protocol,
      host: camera.host,
      port: '${camera.port}',
      username: credentials.username,
      password: credentials.password,
      mainPath: camera.mainPath,
      subPath: camera.subPath ?? '',
      transport: camera.transport,
      onvifEnabled: camera.onvifEnabled,
      onvifPort: camera.onvifPort == null ? '' : '${camera.onvifPort}',
      brandId: camera.brandId,
      modelHint: camera.modelHint ?? '',
    );
  }

  final String name;
  final StreamProtocol protocol;
  final String host;
  final String port;
  final String username;
  final String password;
  final String mainPath;
  final String subPath;
  final StreamTransport transport;
  final bool onvifEnabled;
  final String onvifPort;
  final String? brandId;
  final String modelHint;

  CameraFormValues copyWith({
    String? name,
    StreamProtocol? protocol,
    String? host,
    String? port,
    String? username,
    String? password,
    String? mainPath,
    String? subPath,
    StreamTransport? transport,
    bool? onvifEnabled,
    String? onvifPort,
    String? brandId,
    String? modelHint,
  }) {
    return CameraFormValues(
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      mainPath: mainPath ?? this.mainPath,
      subPath: subPath ?? this.subPath,
      transport: transport ?? this.transport,
      onvifEnabled: onvifEnabled ?? this.onvifEnabled,
      onvifPort: onvifPort ?? this.onvifPort,
      brandId: brandId ?? this.brandId,
      modelHint: modelHint ?? this.modelHint,
    );
  }

  CameraCredentials get credentials {
    return CameraCredentials(username: username.trim(), password: password);
  }
}

enum CameraFormField { name, host, port, onvifPort }

enum CameraFormIssue { nameRequired, hostInvalid, portInvalid }

/// The rules of the camera form, with no screen attached.
class CameraForm {
  CameraForm._();

  static const int defaultRtspPort = 554;
  static const int defaultHttpPort = 80;

  static int defaultPortFor(StreamProtocol protocol) {
    return protocol == StreamProtocol.rtsp ? defaultRtspPort : defaultHttpPort;
  }

  /// Problems with [values], by field. Empty when the form can be saved.
  static Map<CameraFormField, CameraFormIssue> validate(
    CameraFormValues values,
  ) {
    final Map<CameraFormField, CameraFormIssue> issues =
        <CameraFormField, CameraFormIssue>{};
    if (values.name.trim().isEmpty) {
      issues[CameraFormField.name] = CameraFormIssue.nameRequired;
    }
    if (!UrlBuilder.isValidHost(values.host.trim())) {
      issues[CameraFormField.host] = CameraFormIssue.hostInvalid;
    }
    if (_port(values.port) == null) {
      issues[CameraFormField.port] = CameraFormIssue.portInvalid;
    }
    if (values.onvifEnabled &&
        values.onvifPort.trim().isNotEmpty &&
        _port(values.onvifPort) == null) {
      issues[CameraFormField.onvifPort] = CameraFormIssue.portInvalid;
    }
    return issues;
  }

  static int? _port(String text) {
    final int? port = int.tryParse(text.trim());
    return port != null && port >= 1 && port <= 65535 ? port : null;
  }

  /// The camera described by [values], or null while the form has problems.
  /// A new camera gets its id, order and dates from the repository.
  static Camera? build(
    CameraFormValues values, {
    Camera? existing,
    required DateTime now,
  }) {
    if (validate(values).isNotEmpty) {
      return null;
    }
    final String sub = values.subPath.trim();
    final String model = values.modelHint.trim();
    return Camera(
      id: existing?.id ?? '',
      name: values.name.trim(),
      protocol: values.protocol,
      host: values.host.trim(),
      port: _port(values.port)!,
      mainPath: UrlBuilder.normalizePath(values.mainPath),
      subPath: sub.isEmpty ? null : UrlBuilder.normalizePath(sub),
      transport: values.transport,
      brandId: values.brandId,
      modelHint: model.isEmpty ? null : model,
      onvifEnabled: values.onvifEnabled,
      onvifPort: values.onvifEnabled && values.onvifPort.trim().isNotEmpty
          ? _port(values.onvifPort)
          : null,
      sortIndex: existing?.sortIndex ?? 0,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Starts a form from a camera that discovery found. An ONVIF answer gives
  /// the ONVIF port; a scan hit on 554 or 8554 gives the RTSP port; any other
  /// open port is most likely the camera's web or ONVIF service.
  static CameraFormValues fromDiscovery(DiscoveryResult found) {
    final String name = (found.name ?? found.model ?? '').trim();
    final bool rtspPort = found.port == 554 || found.port == 8554;
    final bool onvif = found.source == DiscoverySource.onvif || !rtspPort;
    return CameraFormValues(
      name: name.isEmpty ? found.host : name,
      host: found.host,
      port: rtspPort ? '${found.port}' : '$defaultRtspPort',
      onvifEnabled: onvif,
      onvifPort: onvif && !rtspPort ? '${found.port}' : '',
      modelHint: found.model ?? '',
    );
  }

  /// Fills the form from a pasted stream address.
  static CameraFormValues applyAddress(
    CameraFormValues values,
    ParsedStreamAddress address,
  ) {
    return values.copyWith(
      protocol: address.protocol,
      host: address.host,
      port: '${address.port}',
      mainPath: address.path,
      username: address.username ?? values.username,
      password: address.password ?? values.password,
    );
  }

  /// Switching type moves the port from the old default to the new one, but
  /// never overwrites a port the person chose.
  static CameraFormValues applyProtocol(
    CameraFormValues values,
    StreamProtocol protocol,
  ) {
    if (protocol == values.protocol) {
      return values;
    }
    final bool onDefault =
        values.port.trim().isEmpty ||
        values.port.trim() == '${defaultPortFor(values.protocol)}';
    return values.copyWith(
      protocol: protocol,
      port: onDefault ? '${defaultPortFor(protocol)}' : values.port,
    );
  }

  /// Chooses a brand: its usual port and first paths are filled in where the
  /// person has not typed their own.
  static CameraFormValues applyBrand(
    CameraFormValues values,
    CameraBrandProfile brand, {
    CameraBrandProfile? previous,
  }) {
    final List<String> mains = UrlBuilder.pathsFor(
      brand,
      kind: _mainKind(values.protocol),
    );
    final List<String> subs = values.protocol == StreamProtocol.rtsp
        ? UrlBuilder.pathsFor(brand, kind: PathKind.sub)
        : const <String>[];

    bool unset(String current, String? previousValue) {
      return current.trim().isEmpty ||
          (previousValue != null && current.trim() == previousValue);
    }

    final String? previousMain = previous == null
        ? null
        : _first(
            UrlBuilder.pathsFor(previous, kind: _mainKind(values.protocol)),
          );
    final String? previousSub = previous == null
        ? null
        : _first(UrlBuilder.pathsFor(previous, kind: PathKind.sub));
    final int? previousPort = previous == null || previous.defaultPorts.isEmpty
        ? null
        : previous.defaultPorts.first;
    final bool portUnset =
        values.port.trim().isEmpty ||
        values.port.trim() == '${defaultPortFor(values.protocol)}' ||
        (previousPort != null && values.port.trim() == '$previousPort');

    return values.copyWith(
      brandId: brand.id,
      port: portUnset && brand.defaultPorts.isNotEmpty
          ? '${brand.defaultPorts.first}'
          : values.port,
      mainPath: unset(values.mainPath, previousMain) && mains.isNotEmpty
          ? mains.first
          : values.mainPath,
      subPath: unset(values.subPath, previousSub) && subs.isNotEmpty
          ? subs.first
          : values.subPath,
    );
  }

  /// Brand paths worth trying for the main stream of [values], without the
  /// one already in use.
  static List<String> alternativeMainPaths(
    CameraFormValues values,
    CameraBrandProfile? brand,
  ) {
    if (brand == null) {
      return const <String>[];
    }
    final String current = values.mainPath.trim();
    return <String>[
      for (final String p in UrlBuilder.pathsFor(
        brand,
        kind: _mainKind(values.protocol),
      ))
        if (p != current) p,
    ];
  }

  static PathKind _mainKind(StreamProtocol protocol) {
    return switch (protocol) {
      StreamProtocol.rtsp => PathKind.main,
      StreamProtocol.mjpeg => PathKind.mjpeg,
      StreamProtocol.httpSnapshot => PathKind.snapshot,
    };
  }

  static String? _first(List<String> list) => list.isEmpty ? null : list.first;
}
