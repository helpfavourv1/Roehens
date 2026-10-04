import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/models/grid_layout.dart';

void main() {
  test('every supported size has columns times rows equal to the size', () {
    for (final int size in Limits.gridSizes) {
      final (int columns, int rows) = GridLayout.dimensionsFor(size);
      expect(columns * rows, size, reason: 'size $size');
      expect(GridLayout.forPageSize(id: 'x', pageSize: size).pageSize, size);
    }
  });

  test('an unsupported size falls back to a single tile', () {
    expect(GridLayout.dimensionsFor(5), (1, 1));
    expect(GridLayout.dimensionsFor(0), (1, 1));
  });

  test('page count rounds up and is at least one', () {
    final GridLayout four = GridLayout.forPageSize(id: 'x', pageSize: 4);
    expect(four.pageCount(0), 1);
    expect(four.pageCount(1), 1);
    expect(four.pageCount(4), 1);
    expect(four.pageCount(5), 2);
    expect(four.pageCount(9), 3);
  });

  test('survives a JSON round trip', () {
    final GridLayout layout = GridLayout.forPageSize(
      id: 'main',
      pageSize: 6,
      cameraIds: <String>['a', 'b', 'c'],
      autoCycleSeconds: 15,
    );
    final GridLayout back = GridLayout.fromJson(
      jsonDecode(jsonEncode(layout.toJson())) as Map<String, Object?>,
    );
    expect(back, layout);
    expect(back.hashCode, layout.hashCode);
  });

  test('copyWith can clear the auto-cycle override', () {
    final GridLayout layout =
        GridLayout.forPageSize(id: 'x', pageSize: 4, autoCycleSeconds: 5);
    expect(layout.copyWith(autoCycleSeconds: null).autoCycleSeconds, isNull);
    expect(layout.copyWith(id: 'y').autoCycleSeconds, 5);
  });
}
