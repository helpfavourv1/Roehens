import 'package:flutter/foundation.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/models/grid_layout.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// The active Live layout and the page being shown. The layout holds the
/// camera order; the page is session state and is not saved.
class LayoutProvider extends SafeValueNotifier<GridLayout> {
  LayoutProvider({required this._storage, required this._store, required this._logger})
      : super(_defaultLayout);

  static const String defaultLayoutId = 'default';
  static const int defaultPageSize = 4;

  static final GridLayout _defaultLayout = GridLayout.forPageSize(
    id: defaultLayoutId,
    pageSize: defaultPageSize,
  );

  static const String _tag = 'layout';

  final StorageContract _storage;
  final KeyValueStore _store;
  final LoggerContract _logger;

  /// Zero-based page of the grid.
  final SafeValueNotifier<int> page = SafeValueNotifier<int>(0);

  /// Reads the saved layouts and picks the active one.
  Future<void> load() async {
    final List<GridLayout> layouts =
        (await _storage.loadLayouts()).valueOrNull ?? const <GridLayout>[];
    if (layouts.isEmpty) {
      return;
    }
    final String? activeId =
        (await _store.getString(StorageKeys.activeLayoutId)).valueOrNull;
    GridLayout chosen = layouts.first;
    for (final GridLayout layout in layouts) {
      if (layout.id == activeId) {
        chosen = layout;
      }
    }
    setIfAlive(chosen);
  }

  /// One of [Limits.gridSizes]; anything else is ignored.
  Future<void> setPageSize(int pageSize, {required int cameraCount}) async {
    if (!Limits.gridSizes.contains(pageSize) || pageSize == value.pageSize) {
      return;
    }
    final (int columns, int rows) = GridLayout.dimensionsFor(pageSize);
    await _change(value.copyWith(columns: columns, rows: rows));
    clampPage(cameraCount);
  }

  /// Null removes the layout's own interval, so the global one applies.
  Future<void> setAutoCycleSeconds(int? seconds) {
    if (seconds != null && !Limits.autoCycleSeconds.contains(seconds)) {
      return Future<void>.value();
    }
    return _change(value.copyWith(autoCycleSeconds: seconds));
  }

  /// Saves a new camera order for the layout.
  Future<void> setCameraOrder(List<String> cameraIds) {
    return _change(value.copyWith(cameraIds: List<String>.unmodifiable(cameraIds)));
  }

  /// Brings the saved order in line with the cameras that exist: new cameras
  /// go to the end, removed ones drop out. Saves only when something changed.
  Future<void> syncCameras(List<Camera> cameras) {
    final List<String> synced = orderedIds(cameras);
    if (listEquals(synced, value.cameraIds)) {
      return Future<void>.value();
    }
    return setCameraOrder(synced);
  }

  /// The camera ids in layout order. Cameras the layout does not know come
  /// last, in their own order.
  List<String> orderedIds(List<Camera> cameras) {
    final Set<String> existing = <String>{for (final Camera c in cameras) c.id};
    final List<String> ordered = <String>[
      for (final String id in value.cameraIds)
        if (existing.contains(id)) id,
    ];
    final Set<String> placed = ordered.toSet();
    for (final Camera camera in cameras) {
      if (!placed.contains(camera.id)) {
        ordered.add(camera.id);
      }
    }
    return ordered;
  }

  /// The cameras on [pageIndex], in layout order.
  List<Camera> camerasOnPage(List<Camera> cameras, {int? pageIndex}) {
    final Map<String, Camera> byId = <String, Camera>{
      for (final Camera c in cameras) c.id: c,
    };
    final List<String> ids = orderedIds(cameras);
    final int size = value.pageSize;
    final int start = (pageIndex ?? page.value) * size;
    if (start >= ids.length) {
      return const <Camera>[];
    }
    final int end = start + size > ids.length ? ids.length : start + size;
    return <Camera>[for (final String id in ids.sublist(start, end)) byId[id]!];
  }

  int pageCount(int cameraCount) => value.pageCount(cameraCount);

  /// Keeps the page inside the available pages.
  void clampPage(int cameraCount) {
    final int last = pageCount(cameraCount) - 1;
    final int current = page.value;
    if (current > last) {
      page.setIfAlive(last);
    } else if (current < 0) {
      page.setIfAlive(0);
    }
  }

  void setPage(int index, {required int cameraCount}) {
    page.setIfAlive(index);
    clampPage(cameraCount);
  }

  /// Next page, wrapping to the first. Used by auto-cycle and swipes.
  void nextPage({required int cameraCount}) {
    final int count = pageCount(cameraCount);
    page.setIfAlive((page.value + 1) % count);
  }

  void previousPage({required int cameraCount}) {
    final int count = pageCount(cameraCount);
    page.setIfAlive((page.value - 1 + count) % count);
  }

  Future<void> _change(GridLayout next) async {
    setIfAlive(next);
    final Result<void> saved = await _storage.saveLayout(next);
    if (saved.isErr) {
      _logger.warning(_tag, 'layout not saved, kept in memory');
      return;
    }
    await _store.setString(StorageKeys.activeLayoutId, next.id);
  }

  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }
}
