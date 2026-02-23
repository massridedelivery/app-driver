class OnboardingState {
  final bool hasCompleted;
  const OnboardingState({this.hasCompleted = false});

  OnboardingState copyWith({bool? hasCompleted}) {
    return OnboardingState(hasCompleted: hasCompleted ?? this.hasCompleted);
  }
}
