import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'onboarding_provider.g.dart';

class OnboardingState {
  final bool hasCompleted;

  const OnboardingState({required this.hasCompleted});
}

@riverpod
class OnboardingController extends _$OnboardingController {
  static const _key = 'has_completed_onboarding';

  @override
  Future<OnboardingState> build() async {
    final prefs = await SharedPreferences.getInstance();
    return OnboardingState(hasCompleted: prefs.getBool(_key) ?? false);
  }

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(OnboardingState(hasCompleted: true));
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
    state = const AsyncValue.data(OnboardingState(hasCompleted: true));
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncValue.data(OnboardingState(hasCompleted: false));
  }
}
