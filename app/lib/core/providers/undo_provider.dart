import 'dart:async';

import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/core/models/camera.dart';
import 'package:roehens/core/providers/auto_cycle_provider.dart';
import 'package:roehens/core/providers/safe_notifier.dart';
import 'package:roehens/core/services/camera_repository.dart';

/// Puts a deleted camera back.
typedef RestoreCamera = Future<Result<Camera>> Function(DeletedCamera deleted);

/// The one delete that can still be undone, for [Limits.undoWindow]. The toast
/// with the Undo pill shows while [value] is not null.
class UndoProvider extends SafeValueNotifier<DeletedCamera?> {
  UndoProvider({
    required this._restore,
    this.window = Limits.undoWindow,
    TimerFactory? timerFactory,
  })  : _timerFactory = timerFactory ?? ((Duration d, void Function() f) => Timer(d, f)),
        super(null);

  final RestoreCamera _restore;
  final Duration window;
  final TimerFactory _timerFactory;
  Timer? _timer;

  /// Starts the window for [deleted]. A delete still pending is final now.
  void offer(DeletedCamera deleted) {
    _timer?.cancel();
    setIfAlive(deleted);
    _timer = _timerFactory(window, dismiss);
  }

  /// Restores the camera. Null when there was nothing to undo.
  Future<Result<Camera>?> undo() async {
    final DeletedCamera? pending = value;
    if (pending == null) {
      return null;
    }
    _timer?.cancel();
    _timer = null;
    setIfAlive(null);
    return _restore(pending);
  }

  /// Ends the window; the delete becomes final.
  void dismiss() {
    _timer?.cancel();
    _timer = null;
    setIfAlive(null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
