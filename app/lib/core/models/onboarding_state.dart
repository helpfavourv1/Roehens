/// Which onboarding steps the person has completed.
class OnboardingState {
  const OnboardingState({
    this.completedVersion = 0,
    this.localNetworkRationaleSeen = false,
    this.attPromptShown = false,
  });

  factory OnboardingState.fromJson(Map<String, Object?> json) {
    return OnboardingState(
      completedVersion: json['completedVersion'] as int? ?? 0,
      localNetworkRationaleSeen:
          json['localNetworkRationaleSeen'] as bool? ?? false,
      attPromptShown: json['attPromptShown'] as bool? ?? false,
    );
  }

  /// Onboarding version the person last finished; 0 when never.
  final int completedVersion;
  final bool localNetworkRationaleSeen;
  final bool attPromptShown;

  /// Onboarding is shown when the completed version is below [currentVersion].
  bool needsOnboarding(int currentVersion) => completedVersion < currentVersion;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'completedVersion': completedVersion,
      'localNetworkRationaleSeen': localNetworkRationaleSeen,
      'attPromptShown': attPromptShown,
    };
  }

  OnboardingState copyWith({
    int? completedVersion,
    bool? localNetworkRationaleSeen,
    bool? attPromptShown,
  }) {
    return OnboardingState(
      completedVersion: completedVersion ?? this.completedVersion,
      localNetworkRationaleSeen:
          localNetworkRationaleSeen ?? this.localNetworkRationaleSeen,
      attPromptShown: attPromptShown ?? this.attPromptShown,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OnboardingState &&
        other.completedVersion == completedVersion &&
        other.localNetworkRationaleSeen == localNetworkRationaleSeen &&
        other.attPromptShown == attPromptShown;
  }

  @override
  int get hashCode =>
      Object.hash(completedVersion, localNetworkRationaleSeen, attPromptShown);
}
