import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'developer_options_controller.g.dart';

@riverpod
class DeveloperOptionsController extends _$DeveloperOptionsController {
  final int _requiredTaps = 10;
  final Duration _tapTimeout = const Duration(milliseconds: 500);

  @override
  DeveloperOptionsState build() => const DeveloperOptionsState();

  void onTapped() {
    final now = DateTime.now();
    int currentCount = state.count;

    if (state.lastTap != null && now.difference(state.lastTap!) > _tapTimeout) {
      currentCount = 0;
    }

    currentCount++;
    state = DeveloperOptionsState(count: currentCount, lastTap: now);
    if (currentCount >= _requiredTaps) {
      state = const DeveloperOptionsState();
    }
  }
}

class DeveloperOptionsState {
  final int count;
  final DateTime? lastTap;

  const DeveloperOptionsState({this.count = 0, this.lastTap});
}
