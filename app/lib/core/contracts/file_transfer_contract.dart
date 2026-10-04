import 'dart:typed_data';

import 'package:roehens/core/errors/result.dart';

/// A file chosen by the person.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Share sheet and file picker. Nothing here needs a storage permission.
abstract interface class FileTransferContract {
  /// Opens the system share sheet with a file made from [bytes].
  Future<Result<void>> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });

  /// Opens the system file picker for a JSON file. Null when cancelled.
  Future<Result<PickedFile?>> pickJsonFile();
}
