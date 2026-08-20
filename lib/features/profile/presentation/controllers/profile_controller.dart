import 'package:flutter/foundation.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';
import 'package:massdrive/features/profile/domain/repositories/vehicle_repository.dart';
import 'package:massdrive/features/profile/presentation/states/profile_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  late final ProfileRepository _repository;
  late final VehicleRepository _vehicleRepository;

  @override
  ProfileState build() {
    _repository = getIt<ProfileRepository>();
    _vehicleRepository = getIt<VehicleRepository>();
    return const ProfileState();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getProfile();
      // acceptance_rate / cancellation_rate are NOT on /api/driver/profile —
      // they live on /api/driver/tier (TierStatus). Merge them in so the
      // profile screen shows the real percentages instead of 0%.
      final merged = await _mergeTierRates(profile);
      state = state.copyWith(isLoading: false, profile: merged);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Best-effort overlay of acceptance/cancellation rate from GET /api/driver/tier.
  /// Never throws — on any failure the original profile (rates 0) is returned.
  Future<DriverProfileEntity> _mergeTierRates(DriverProfileEntity profile) async {
    try {
      final data = (await getIt<QuestApiService>().getTier()).data;
      if (data == null) return profile;
      // The API may express a rate as a 0..1 fraction or a 0..100 percentage;
      // normalise both to a percentage for display.
      double? pct(dynamic v) {
        final n = (v as num?)?.toDouble();
        if (n == null) return null;
        return n <= 1 ? n * 100 : n;
      }
      return profile.copyWith(
        acceptanceRate: pct(data['acceptance_rate']) ?? profile.acceptanceRate,
        cancellationRate:
            pct(data['cancellation_rate']) ?? profile.cancellationRate,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('ProfileController: tier rates merge failed → $e');
      return profile;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
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

  Future<bool> toggleVehicleType(String typeId, bool isEnabled) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      await _vehicleRepository.toggleVehicleType(typeId, {
        "enabled": isEnabled,
      });
      await fetchProfile();
      return true;
    } catch (e) {
      state = state.copyWith(isUpdating: false, errorMessage: e.toString());
      return false;
    }
  }
}
