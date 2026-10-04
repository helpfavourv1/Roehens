import 'dart:math';

import 'package:roehens/core/models/stream_protocol.dart';

const Object _unset = Object();

/// A camera as stored in the database. Credentials are not part of this record:
/// they live in the secure vault as [CameraCredentials], keyed by [id].
class Camera {
  const Camera({
    required this.id,
    required this.name,
    required this.protocol,
    required this.host,
    required this.port,
    required this.mainPath,
    required this.sortIndex,
    required this.createdAt,
    required this.updatedAt,
    this.subPath,
    this.transport = StreamTransport.auto,
    this.brandId,
    this.modelHint,
    this.onvifEnabled = false,
    this.onvifPort,
  });

  factory Camera.fromJson(Map<String, Object?> json) {
    final String? transportName = json['transport'] as String?;
    return Camera(
      id: json['id']! as String,
      name: json['name']! as String,
      protocol: StreamProtocol.values.byName(json['protocol']! as String),
      host: json['host']! as String,
      port: json['port']! as int,
      mainPath: json['mainPath']! as String,
      subPath: json['subPath'] as String?,
      transport: transportName == null
          ? StreamTransport.auto
          : StreamTransport.values.byName(transportName),
      brandId: json['brandId'] as String?,
      modelHint: json['modelHint'] as String?,
      onvifEnabled: json['onvifEnabled'] as bool? ?? false,
      onvifPort: json['onvifPort'] as int?,
      sortIndex: json['sortIndex']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        json['createdAtMillis']! as int,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        json['updatedAtMillis']! as int,
        isUtc: true,
      ),
    );
  }

  /// UUID v4, generated with [generateCameraId].
  final String id;
  final String name;
  final StreamProtocol protocol;

  /// IP address or host name.
  final String host;
  final int port;
  final String mainPath;
  final String? subPath;
  final StreamTransport transport;
  final String? brandId;
  final String? modelHint;
  final bool onvifEnabled;
  final int? onvifPort;
  final int sortIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasSubstream => subPath != null && subPath!.isNotEmpty;

  /// Never contains credentials.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'protocol': protocol.name,
      'host': host,
      'port': port,
      'mainPath': mainPath,
      'subPath': subPath,
      'transport': transport.name,
      'brandId': brandId,
      'modelHint': modelHint,
      'onvifEnabled': onvifEnabled,
      'onvifPort': onvifPort,
      'sortIndex': sortIndex,
      'createdAtMillis': createdAt.millisecondsSinceEpoch,
      'updatedAtMillis': updatedAt.millisecondsSinceEpoch,
    };
  }

  Camera copyWith({
    String? id,
    String? name,
    StreamProtocol? protocol,
    String? host,
    int? port,
    String? mainPath,
    Object? subPath = _unset,
    StreamTransport? transport,
    Object? brandId = _unset,
    Object? modelHint = _unset,
    bool? onvifEnabled,
    Object? onvifPort = _unset,
    int? sortIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Camera(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: port ?? this.port,
      mainPath: mainPath ?? this.mainPath,
      subPath: identical(subPath, _unset) ? this.subPath : subPath as String?,
      transport: transport ?? this.transport,
      brandId: identical(brandId, _unset) ? this.brandId : brandId as String?,
      modelHint:
          identical(modelHint, _unset) ? this.modelHint : modelHint as String?,
      onvifEnabled: onvifEnabled ?? this.onvifEnabled,
      onvifPort: identical(onvifPort, _unset) ? this.onvifPort : onvifPort as int?,
      sortIndex: sortIndex ?? this.sortIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Camera &&
        other.id == id &&
        other.name == name &&
        other.protocol == protocol &&
        other.host == host &&
        other.port == port &&
        other.mainPath == mainPath &&
        other.subPath == subPath &&
        other.transport == transport &&
        other.brandId == brandId &&
        other.modelHint == modelHint &&
        other.onvifEnabled == onvifEnabled &&
        other.onvifPort == onvifPort &&
        other.sortIndex == sortIndex &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        name,
        protocol,
        host,
        port,
        mainPath,
        subPath,
        transport,
        brandId,
        modelHint,
        onvifEnabled,
        onvifPort,
        sortIndex,
        createdAt,
        updatedAt,
      ]);

  @override
  String toString() => 'Camera($id, $name, $host:$port)';
}

/// Username and password of one camera. Stored only in the secure vault; never
/// in the database, in exports, in logs or in diagnostics.
class CameraCredentials {
  const CameraCredentials({required this.username, required this.password});

  factory CameraCredentials.fromJson(Map<String, Object?> json) {
    return CameraCredentials(
      username: json['username']! as String,
      password: json['password']! as String,
    );
  }

  static const CameraCredentials none =
      CameraCredentials(username: '', password: '');

  final String username;
  final String password;

  bool get isEmpty => username.isEmpty && password.isEmpty;

  Map<String, Object?> toJson() {
    return <String, Object?>{'username': username, 'password': password};
  }

  @override
  bool operator ==(Object other) {
    return other is CameraCredentials &&
        other.username == username &&
        other.password == password;
  }

  @override
  int get hashCode => Object.hash(username, password);

  @override
  String toString() => 'CameraCredentials(<redacted>)';
}

/// Generates a random (version 4) UUID.
String generateCameraId([Random? random]) {
  final Random rng = random ?? Random.secure();
  final List<int> bytes = List<int>.generate(16, (int _) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int from, int to) {
    return bytes
        .sublist(from, to)
        .map((int value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
