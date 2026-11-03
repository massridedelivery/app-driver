import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/home/data/sources/quest_api_service.dart';
import 'package:massdrive/features/profile/data/sources/profile_photo_uploader.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/profile_updates.dart';
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
    // The photo changes server-side (an admin approves a selfie → a new
    // avatar_url), so re-read on that push and whenever the app comes back to
    // the foreground. Quietly: Home shows its skeleton while isLoading.
    void refreshLoaded() {
      if (state.profile != null) fetchProfile(silent: true);
    }

    ProfileUpdates.instance.addListener(refreshLoaded);
    final lifecycle = AppLifecycleListener(onResume: refreshLoaded);
    ref.onDispose(() {
      ProfileUpdates.instance.removeListener(refreshLoaded);
      lifecycle.dispose();
    });
    return const ProfileState();
  }

  /// [silent] refreshes in place (no isLoading) when a profile is already on
  /// screen.
  Future<void> fetchProfile({bool silent = false}) async {
    state = state.copyWith(isLoading: !silent, errorMessage: null);
    try {
      final profile = await _repository.getProfile();
      // acceptance_rate / cancellation_rate are NOT on /api/driver/profile —
      // they live on /api/driver/tier (TierStatus). Merge them in so the
      // profile screen shows the real percentages instead of 0%.
      final merged = await _mergeTierRates(profile);
      state = state.copyWith(isLoading: false, profile: merged);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyErrorMessage(e),
      );
    }
  }

  /// Best-effort overlay of the weekly stats from GET /api/driver/tier.
  /// Never throws — on any failure the original profile is returned.
  Future<DriverProfileEntity> _mergeTierRates(
    DriverProfileEntity profile,
  ) async {
    try {
      final data = (await getIt<QuestApiService>().getTier()).data;
      if (data == null) return profile;
      return mergeTierStats(profile, data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ProfileController: tier stats merge failed → $e');
      }
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
      state = state.copyWith(
        isUpdating: false,
        errorMessage: friendlyErrorMessage(e),
      );
      return false;
    }
  }

  /// Make [jpeg] (prepared: JPEG, ≤ 2 MB, no EXIF) the profile photo: upload
  /// it as an avatar, point avatar_url at it, re-read the profile. Returns
  /// null on success, or the message to show. Never the selfie document —
  /// that is the sign-up verification photo, kept on record.
  Future<String?> changePhoto(Uint8List jpeg) async {
    state = state.copyWith(isUpdating: true, errorMessage: null);
    try {
      final fileKey = await getIt<ProfilePhotoUploader>().upload(jpeg);
      await _repository.updateProfile({'avatar_url': fileKey});
      await fetchProfile(silent: true);
      state = state.copyWith(isUpdating: false);
      return null;
    } catch (e) {
      final message = friendlyErrorMessage(e);
      state = state.copyWith(isUpdating: false, errorMessage: message);
      return message;
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
      state = state.copyWith(
        isUpdating: false,
        errorMessage: friendlyErrorMessage(e),
      );
      return false;
    }
  }
}

/// The weekly figures live on GET /api/driver/tier, not /api/driver/profile:
/// `weekly_jobs` (jobs finished since Monday 00:00 Bangkok — the same week as
/// this_week_income), `acceptance_rate` and `cancellation_rate`. A rate may be
/// a 0..1 fraction or a 0..100 percentage; both read as a percentage.
DriverProfileEntity mergeTierStats(
  DriverProfileEntity profile,
  Map<String, dynamic> tier,
) {
  double? pct(dynamic v) {
    final n = (v as num?)?.toDouble();
    if (n == null) return null;
    return n <= 1 ? n * 100 : n;
  }

  final jobs = tier['weekly_jobs'];
  return profile.copyWith(
    acceptanceRate: pct(tier['acceptance_rate']) ?? profile.acceptanceRate,
    cancellationRate:
        pct(tier['cancellation_rate']) ?? profile.cancellationRate,
    weeklyCompletedJobs: jobs is num
        ? jobs.toInt()
        : profile.weeklyCompletedJobs,
  );
}
