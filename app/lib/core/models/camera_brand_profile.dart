import 'package:flutter/foundation.dart';

List<String> _strings(Object? value) {
  return (value as List<Object?>? ?? const <Object?>[])
      .map((Object? item) => item! as String)
      .toList();
}

/// A camera brand from the bundled profile database: default ports and the
/// stream path patterns people most often need. Brand names are text only.
class CameraBrandProfile {
  const CameraBrandProfile({
    required this.id,
    required this.displayName,
    required this.defaultPorts,
    required this.mainPathTemplates,
    required this.subPathTemplates,
    required this.mjpegTemplates,
    required this.snapshotTemplates,
    this.notes,
    this.verified = false,
  });

  factory CameraBrandProfile.fromJson(Map<String, Object?> json) {
    return CameraBrandProfile(
      id: json['id']! as String,
      displayName: json['displayName']! as String,
      defaultPorts: (json['defaultPorts'] as List<Object?>? ?? const <Object?>[])
          .map((Object? item) => item! as int)
          .toList(),
      mainPathTemplates: _strings(json['mainPathTemplates']),
      subPathTemplates: _strings(json['subPathTemplates']),
      mjpegTemplates: _strings(json['mjpegTemplates']),
      snapshotTemplates: _strings(json['snapshotTemplates']),
      notes: json['notes'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }

  final String id;
  final String displayName;
  final List<int> defaultPorts;

  /// Path patterns with placeholders such as `{channel}`.
  final List<String> mainPathTemplates;
  final List<String> subPathTemplates;
  final List<String> mjpegTemplates;
  final List<String> snapshotTemplates;
  final String? notes;

  /// True when the paths were confirmed against a real device.
  final bool verified;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'displayName': displayName,
      'defaultPorts': defaultPorts,
      'mainPathTemplates': mainPathTemplates,
      'subPathTemplates': subPathTemplates,
      'mjpegTemplates': mjpegTemplates,
      'snapshotTemplates': snapshotTemplates,
      'notes': notes,
      'verified': verified,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is CameraBrandProfile &&
        other.id == id &&
        other.displayName == displayName &&
        listEquals(other.defaultPorts, defaultPorts) &&
        listEquals(other.mainPathTemplates, mainPathTemplates) &&
        listEquals(other.subPathTemplates, subPathTemplates) &&
        listEquals(other.mjpegTemplates, mjpegTemplates) &&
        listEquals(other.snapshotTemplates, snapshotTemplates) &&
        other.notes == notes &&
        other.verified == verified;
  }

  @override
  int get hashCode => Object.hash(
        id,
        displayName,
        Object.hashAll(defaultPorts),
        Object.hashAll(mainPathTemplates),
        Object.hashAll(subPathTemplates),
        Object.hashAll(mjpegTemplates),
        Object.hashAll(snapshotTemplates),
        notes,
        verified,
      );
}
