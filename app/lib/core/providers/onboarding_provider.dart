import 'dart:convert';

import 'package:roehens/core/constants/app_constants.dart';
import 'package:roehens/core/constants/storage_keys.dart';
import 'package:roehens/core/contracts/storage_contract.dart';
import 'package:roehens/core/models/onboarding_state.dart';
import 'package:roehens/core/providers/safe_notifier.dart';

/// Which onboarding steps are done. Cold start shows onboarding when the
/// completed version is below the current one.
class OnboardingProvider extends SafeValueNotifier<OnboardingState> {
  OnboardingProvider({required this._store}) : super(const OnboardingState());

  final KeyValueStore _store;

  bool _loaded = false;

  /// False until [load] has finished, so the shell does not flash onboarding.
  bool get isLoaded => _loaded;

  bool get needsOnboarding =>
      value.needsOnboarding(AppConstants.onboardingVersion);

  Future<void> load() async {
    final String? raw =
        (await _store.getString(StorageKeys.onboarding)).valueOrNull;
    if (raw != null) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is Map<String, Object?>) {
          setIfAlive(OnboardingState.fromJson(decoded));
        }
      } on Object {
        // An unreadable file means onboarding runs again.
      }
    }
    _loaded = true;
    // Tell listeners that loading finished even when nothing was saved.
    if (!isDisposed) {
      notifyListeners();
    }
  }

  Future<void> complete() {
    return _save(
      value.copyWith(completedVersion: AppConstants.onboardingVersion),
    );
  }

  Future<void> markLocalNetworkRationaleSeen() {
    return _save(value.copyWith(localNetworkRationaleSeen: true));
  }

  Future<void> markAttPromptShown() {
    return _save(value.copyWith(attPromptShown: true));
  }

  Future<void> reset() async {
    setIfAlive(const OnboardingState());
    await _store.remove(StorageKeys.onboarding);
  }

  Future<void> _save(OnboardingState next) async {
    setIfAlive(next);
    await _store.setString(StorageKeys.onboarding, jsonEncode(next.toJson()));
  }
}
