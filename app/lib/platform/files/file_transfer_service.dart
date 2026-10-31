import 'dart:typed_data';

import 'package:roehens/core/contracts/file_transfer_contract.dart';
import 'package:roehens/core/errors/result.dart';
import 'package:roehens/platform/files/file_picker_service.dart';
import 'package:roehens/platform/files/share_service.dart';

/// The share sheet and the file picker behind one contract.
class FileTransferService implements FileTransferContract {
  FileTransferService({
    required ShareService share,
    required FilePickerService picker,
  })  : _share = share,
        _picker = picker;

  final ShareService _share;
  final FilePickerService _picker;

  @override
  Future<Result<void>> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return _share.shareBytes(bytes: bytes, fileName: fileName, mimeType: mimeType);
  }

  @override
  Future<Result<PickedFile?>> pickJsonFile() => _picker.pickJsonFile();
}
