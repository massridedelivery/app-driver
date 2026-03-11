import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

abstract class ProfileRepository {
  Future<DriverProfileEntity> getProfile();
  Future<void> updateProfile(Map<String, dynamic> data);
}
