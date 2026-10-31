import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:roehens/core/constants/limits.dart';
import 'package:roehens/core/contracts/file_transfer_contract.dart';
import 'package:roehens/core/contracts/logger_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/errors/result.dart';

/// Opens the system file picker. Any file type is offered because some
/// providers label a .json file as plain binary; the import service checks the
/// content, not the name.
class FilePickerService {
  FilePickerService({required this._logger});

  static const String _tag = 'file_picker';

  final LoggerContract _logger;

  /// Null when the person cancels.
  Future<Result<PickedFile?>> pickJsonFile() async {
    try {
      final PlatformFile? file = await FilePicker.pickFile();
      if (file == null) {
        return const Ok<PickedFile?>(null);
      }
      if (await file.length() > Limits.maxImportBytes) {
        return const Err<PickedFile?>(
          AppError(ErrorClass.invalidFile, detail: 'file too large'),
        );
      }
      final Uint8List bytes = await file.readAsBytes();
      return Ok<PickedFile?>(PickedFile(name: file.name, bytes: bytes));
    } on Object catch (error, stackTrace) {
      _logger.error(_tag, 'pick failed', error: error, stackTrace: stackTrace);
      return const Err<PickedFile?>(
        AppError(ErrorClass.transferFailed, detail: 'file picker failed'),
      );
    }
  }
}
