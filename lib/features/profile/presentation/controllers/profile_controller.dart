import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';
import 'package:massdrive/features/profile/presentation/states/profile_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  late final ProfileRepository _repository;

  @override
  ProfileState build() {
    _repository = getIt<ProfileRepository>();
    return const ProfileState();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getProfile();
      state = state.copyWith(
        isLoading: false,
        profile: profile,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateVehicleDetails(Map<String, dynamic> data) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      await _repository.updateProfile(data);
      // Fetch the updated profile
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }
}
