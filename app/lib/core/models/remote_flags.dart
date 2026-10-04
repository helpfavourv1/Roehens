import 'package:flutter/foundation.dart';

/// Names of the kill switches the app understands. Unknown names in the file
/// are ignored.
class RemoteFlagKeys {
  RemoteFlagKeys._();

  static const String discovery = 'discovery';
  static const String ptz = 'ptz';
  static const String ads = 'ads';
  static const String snapshots = 'snapshots';
  static const String helpContent = 'helpContent';
  static const String pip = 'pip';

  static const List<String> all = <String>[
    discovery,
    ptz,
    ads,
    snapshots,
    helpContent,
    pip,
  ];
}

/// The remote flags file. A missing switch means the feature is on; a failed
/// fetch falls back to the cache, then to [RemoteFlags.defaults].
class RemoteFlags {
  const RemoteFlags({
    this.schemaVersion = 1,
    this.killSwitches = const <String, bool>{},
    this.minSupportedVersion,
    this.message,
  });

  /// Everything enabled.
  static const RemoteFlags defaults = RemoteFlags();

  factory RemoteFlags.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> raw =
        (json['killSwitches'] as Map<String, Object?>?) ??
            const <String, Object?>{};
    final Map<String, bool> known = <String, bool>{};
    for (final String key in RemoteFlagKeys.all) {
      final Object? value = raw[key];
      if (value is bool) {
        known[key] = value;
      }
    }
    return RemoteFlags(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      killSwitches: known,
      minSupportedVersion: json['minSupportedVersion'] as String?,
      message: json['message'] as String?,
    );
  }

  final int schemaVersion;
  final Map<String, bool> killSwitches;
  final String? minSupportedVersion;

  /// Server message shown with a disabled feature.
  final String? message;

  /// True when the kill switch [key] is on, so the feature must be disabled.
  bool isOff(String key) => killSwitches[key] ?? false;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'killSwitches': killSwitches,
      'minSupportedVersion': minSupportedVersion,
      'message': message,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is RemoteFlags &&
        other.schemaVersion == schemaVersion &&
        mapEquals(other.killSwitches, killSwitches) &&
        other.minSupportedVersion == minSupportedVersion &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        Object.hashAllUnordered(
          killSwitches.entries.map((MapEntry<String, bool> e) => (e.key, e.value)),
        ),
        minSupportedVersion,
        message,
      );
}
