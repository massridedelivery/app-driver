import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

part 'profile_state.freezed.dart';

@freezed
sealed class ProfileState with _$ProfileState {
  const factory ProfileState({
    @Default(false) bool isLoading,
    @Default(false) bool isUpdating,
    DriverProfileEntity? profile,
    String? errorMessage,
  }) = _ProfileState;
}
