import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/services/camera_repository.dart';

/// The saved cameras in display order.
class CamerasState {
  const CamerasState({
    this.cameras = const <Camera>[],
    this.isLoaded = false,
    this.error,
  });

  final List<Camera> cameras;

  /// False until the first load has finished. Screens show their chrome and
  /// nothing else until then (no skeletons).
  final bool isLoaded;

  /// Set when the last load failed.
  final AppError? error;

  bool get isEmpty => cameras.isEmpty;

  Camera? byId(String id) {
    for (final Camera camera in cameras) {
      if (camera.id == id) {
        return camera;
      }
    }
    return null;
  }
}

class CamerasProvider extends SafeValueNotifier<CamerasState> {
  CamerasProvider({required this._repository}) : super(const CamerasState());

  final CameraRepository _repository;

  /// The text in the Cameras screen's search field.
  final SafeValueNotifier<String> query = SafeValueNotifier<String>('');

  Future<void> load() async {
    final Result<List<Camera>> result = await _repository.loadCameras();
    setIfAlive(
      result.fold(
        (List<Camera> cameras) =>
            CamerasState(cameras: cameras, isLoaded: true),
        (AppError error) =>
            CamerasState(cameras: value.cameras, isLoaded: true, error: error),
      ),
    );
  }

  Future<Result<Camera>> add(
    Camera draft,
    CameraCredentials credentials,
  ) async {
    final Result<Camera> result = await _repository.addCamera(
      draft,
      credentials,
    );
    if (result.isOk) {
      await load();
    }
    return result;
  }

  Future<Result<Camera>> update(
    Camera camera, {
    CameraCredentials? credentials,
  }) async {
    final Result<Camera> result = await _repository.updateCamera(
      camera,
      credentials: credentials,
    );
    if (result.isOk) {
      await load();
    }
    return result;
  }

  /// Removes a camera and returns what is needed to put it back.
  Future<Result<DeletedCamera>> delete(String id) async {
    final Result<DeletedCamera> result = await _repository.deleteCamera(id);
    if (result.isOk) {
      await load();
    }
    return result;
  }

  Future<Result<Camera>> restore(DeletedCamera deleted) async {
    final Result<Camera> result = await _repository.restoreCamera(deleted);
    if (result.isOk) {
      await load();
    }
    return result;
  }

  /// Shows the new order at once, then saves it. A failed save reloads the
  /// saved order.
  Future<Result<void>> reorder(List<String> orderedIds) async {
    final Map<String, Camera> byId = <String, Camera>{
      for (final Camera c in value.cameras) c.id: c,
    };
    final List<Camera> reordered = <Camera>[];
    for (final String id in orderedIds) {
      final Camera? camera = byId.remove(id);
      if (camera != null) {
        reordered.add(camera.copyWith(sortIndex: reordered.length));
      }
    }
    for (final Camera rest in byId.values) {
      reordered.add(rest.copyWith(sortIndex: reordered.length));
    }
    setIfAlive(CamerasState(cameras: reordered, isLoaded: true));
    final Result<void> saved = await _repository.reorder(<String>[
      for (final Camera c in reordered) c.id,
    ]);
    if (saved.isErr) {
      await load();
    }
    return saved;
  }

  /// Cameras whose name, address or model match [text] (case-insensitive).
  /// Empty text matches everything.
  static List<Camera> filter(List<Camera> cameras, String text) {
    final String needle = text.trim().toLowerCase();
    if (needle.isEmpty) {
      return cameras;
    }
    return <Camera>[
      for (final Camera c in cameras)
        if (c.name.toLowerCase().contains(needle) ||
            c.host.toLowerCase().contains(needle) ||
            (c.modelHint?.toLowerCase().contains(needle) ?? false))
          c,
    ];
  }

  /// "Delete all local data".
  Future<Result<void>> deleteAll() async {
    final Result<void> result = await _repository.deleteAll();
    await load();
    return result;
  }

  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }
}
