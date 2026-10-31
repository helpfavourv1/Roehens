import 'package:flutter/services.dart';
import 'package:roehens/core/contracts/device_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';

/// Orientation and system bars through the platform channel.
class OrientationService implements OrientationContract {
  OrientationService({required this._logger});

  static const String _tag = 'orientation';

  final LoggerContract _logger;

  @override
  Future<void> allowAll() {
    return _set(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Future<void> lockLandscape() {
    return _set(const <DeviceOrientation>[
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Future<void> lockPortrait() {
    return _set(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Future<void> setImmersive({required bool immersive}) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        immersive ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } on Object catch (error) {
      _logger.warning(_tag, 'could not change system bars', error: error);
    }
  }

  /// The platform ignores an empty list, so callers always pass a set.
  Future<void> _set(List<DeviceOrientation> orientations) async {
    try {
      await SystemChrome.setPreferredOrientations(orientations);
    } on Object catch (error) {
      _logger.warning(_tag, 'could not change orientation', error: error);
    }
  }
}
