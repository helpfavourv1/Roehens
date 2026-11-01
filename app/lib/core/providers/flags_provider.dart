import 'package:roehens/core/contracts/flags_contract.dart';
import 'package:roehens/core/errors/app_error.dart';
import 'package:roehens/core/errors/error_class.dart';
import 'package:roehens/core/models/remote_flags.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// The remote kill switches as the screens read them. Mirrors the flag
/// service, so a switch changed while the app is open reaches the screens.
class FlagsProvider extends SafeValueNotifier<RemoteFlags> {
  FlagsProvider({required this._flags}) : super(_flags.flags.value) {
    _flags.flags.addListener(_sync);
  }

  final FlagsContract _flags;

  /// True when the feature may be used.
  bool isEnabled(String key) => !value.isOff(key);

  /// The treatment for a switched-off feature: the inline notice, with the
  /// server's message as detail.
  AppError disabledError(String key) {
    return AppError(ErrorClass.flagDisabled, detail: value.message ?? key);
  }

  /// True when [currentVersion] is older than the server's minimum.
  bool isUpdateRequired(String currentVersion) {
    final String? minimum = value.minSupportedVersion;
    return minimum != null && compareVersions(currentVersion, minimum) < 0;
  }

  Future<void> refresh() => _flags.refresh();

  /// Compares dotted numeric versions such as `1.2.10` and `1.3`. Missing
  /// parts count as zero; a build suffix after `+` or `-` is ignored.
  static int compareVersions(String a, String b) {
    List<int> parts(String v) {
      final String core = v.split('+').first.split('-').first;
      return <int>[
        for (final String p in core.split('.')) int.tryParse(p) ?? 0,
      ];
    }

    final List<int> left = parts(a);
    final List<int> right = parts(b);
    final int length = left.length > right.length ? left.length : right.length;
    for (int i = 0; i < length; i++) {
      final int l = i < left.length ? left[i] : 0;
      final int r = i < right.length ? right[i] : 0;
      if (l != r) {
        return l < r ? -1 : 1;
      }
    }
    return 0;
  }

  void _sync() => setIfAlive(_flags.flags.value);

  @override
  void dispose() {
    _flags.flags.removeListener(_sync);
    super.dispose();
  }
}
