import 'package:flutter/foundation.dart';
import 'package:roehens/core/models/remote_flags.dart';

/// Remote kill switches. A failed fetch keeps the cache, then the defaults
/// (everything on).
abstract interface class FlagsContract {
  /// The flags in force now.
  ValueListenable<RemoteFlags> get flags;

  /// Loads the cache, then fetches. Never throws.
  Future<void> refresh();
}
