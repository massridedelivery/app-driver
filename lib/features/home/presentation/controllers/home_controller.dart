import 'package:massdrive/features/home/presentation/states/home_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_controller.g.dart';

@riverpod
class HomeController extends _$HomeController {
  @override
  Future<HomeScreenState> build() async {
    return const HomeScreenState();
  }

  Future<void> fetchHameData() async {
    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      await Future.delayed(const Duration(seconds: 1));

      state = AsyncData(state.value!.copyWith(isLoading: false));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
