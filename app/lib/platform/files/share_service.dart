import 'dart:typed_data';
import 'dart:ui';

import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a file made from bytes. Needs no storage
/// permission: the plugin hands the file to the share sheet itself.
class ShareService {
  ShareService({required this._logger});

  static const String _tag = 'share';

  final LoggerContract _logger;

  Future<Result<void>> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
          fileNameOverrides: <String>[fileName],
          sharePositionOrigin: _centerOrigin(),
        ),
      );
      return const Ok<void>(null);
    } on Object catch (error, stackTrace) {
      _logger.error(_tag, 'share failed', error: error, stackTrace: stackTrace);
      return const Err<void>(
        AppError(ErrorClass.transferFailed, detail: 'share sheet failed'),
      );
    }
  }

  /// iPad shows the share sheet as a popover and needs an anchor. A point in
  /// the middle of the screen is always valid.
  Rect? _centerOrigin() {
    final Iterable<FlutterView> views = PlatformDispatcher.instance.views;
    if (views.isEmpty) {
      return null;
    }
    final FlutterView view = views.first;
    final Size size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromCenter(center: size.center(Offset.zero), width: 1, height: 1);
  }
}
