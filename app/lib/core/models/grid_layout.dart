import 'package:flutter/foundation.dart';

const Object _unset = Object();

/// A saved arrangement of cameras on the Live screen.
class GridLayout {
  const GridLayout({
    required this.id,
    required this.columns,
    required this.rows,
    required this.cameraIds,
    this.autoCycleSeconds,
  });

  /// Layout for [pageSize] tiles per page (one of the supported sizes).
  factory GridLayout.forPageSize({
    required String id,
    required int pageSize,
    List<String> cameraIds = const <String>[],
    int? autoCycleSeconds,
  }) {
    final (int columns, int rows) = dimensionsFor(pageSize);
    return GridLayout(
      id: id,
      columns: columns,
      rows: rows,
      cameraIds: cameraIds,
      autoCycleSeconds: autoCycleSeconds,
    );
  }

  factory GridLayout.fromJson(Map<String, Object?> json) {
    return GridLayout(
      id: json['id']! as String,
      columns: json['columns']! as int,
      rows: json['rows']! as int,
      cameraIds: (json['cameraIds'] as List<Object?>? ?? const <Object?>[])
          .map((Object? item) => item! as String)
          .toList(),
      autoCycleSeconds: json['autoCycleSeconds'] as int?,
    );
  }

  final String id;
  final int columns;
  final int rows;

  /// Camera ids in display order.
  final List<String> cameraIds;

  /// Overrides the global auto-cycle interval for this layout.
  final int? autoCycleSeconds;

  int get pageSize => columns * rows;

  /// Number of pages needed for [cameraCount] cameras; at least one.
  int pageCount(int cameraCount) {
    if (cameraCount <= 0) {
      return 1;
    }
    return (cameraCount + pageSize - 1) ~/ pageSize;
  }

  /// Columns and rows for a supported page size: 1, 2, 4, 6, 9, 12 or 16.
  /// An unsupported size falls back to a single tile.
  static (int columns, int rows) dimensionsFor(int pageSize) {
    switch (pageSize) {
      case 2:
        return (1, 2);
      case 4:
        return (2, 2);
      case 6:
        return (2, 3);
      case 9:
        return (3, 3);
      case 12:
        return (3, 4);
      case 16:
        return (4, 4);
      default:
        return (1, 1);
    }
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'columns': columns,
      'rows': rows,
      'pageSize': pageSize,
      'cameraIds': cameraIds,
      'autoCycleSeconds': autoCycleSeconds,
    };
  }

  GridLayout copyWith({
    String? id,
    int? columns,
    int? rows,
    List<String>? cameraIds,
    Object? autoCycleSeconds = _unset,
  }) {
    return GridLayout(
      id: id ?? this.id,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      cameraIds: cameraIds ?? this.cameraIds,
      autoCycleSeconds: identical(autoCycleSeconds, _unset)
          ? this.autoCycleSeconds
          : autoCycleSeconds as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GridLayout &&
        other.id == id &&
        other.columns == columns &&
        other.rows == rows &&
        listEquals(other.cameraIds, cameraIds) &&
        other.autoCycleSeconds == autoCycleSeconds;
  }

  @override
  int get hashCode =>
      Object.hash(id, columns, rows, Object.hashAll(cameraIds), autoCycleSeconds);
}
