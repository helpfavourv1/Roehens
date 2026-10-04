/// Which of a camera's streams: full quality or the lighter substream.
enum StreamKind { main, sub }

const Object _unset = Object();

/// One stream of a camera as reported by ONVIF or the brand database.
class StreamProfile {
  const StreamProfile({
    required this.kind,
    required this.path,
    this.codecHint,
    this.resolutionHint,
  });

  factory StreamProfile.fromJson(Map<String, Object?> json) {
    return StreamProfile(
      kind: StreamKind.values.byName(json['kind']! as String),
      path: json['path']! as String,
      codecHint: json['codecHint'] as String?,
      resolutionHint: json['resolutionHint'] as String?,
    );
  }

  final StreamKind kind;
  final String path;
  final String? codecHint;
  final String? resolutionHint;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'kind': kind.name,
      'path': path,
      'codecHint': codecHint,
      'resolutionHint': resolutionHint,
    };
  }

  StreamProfile copyWith({
    StreamKind? kind,
    String? path,
    Object? codecHint = _unset,
    Object? resolutionHint = _unset,
  }) {
    return StreamProfile(
      kind: kind ?? this.kind,
      path: path ?? this.path,
      codecHint: identical(codecHint, _unset)
          ? this.codecHint
          : codecHint as String?,
      resolutionHint: identical(resolutionHint, _unset)
          ? this.resolutionHint
          : resolutionHint as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StreamProfile &&
        other.kind == kind &&
        other.path == path &&
        other.codecHint == codecHint &&
        other.resolutionHint == resolutionHint;
  }

  @override
  int get hashCode => Object.hash(kind, path, codecHint, resolutionHint);
}
