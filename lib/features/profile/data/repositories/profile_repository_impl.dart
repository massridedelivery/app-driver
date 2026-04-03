import 'package:injectable/injectable.dart';
import 'package:massdrive/features/profile/data/sources/profile_api_service.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService _apiService;

  ProfileRepositoryImpl(this._apiService);

  @override
  Future<DriverProfileEntity> getProfile() async {
    final response = await _apiService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      final json = response.data!;
      print('Profile API Raw Response Keys: ${json.keys}');
      if (json.containsKey('vehicle_types')) {
        print('vehicle_types raw data (first item): ${json['vehicle_types'] is List && (json['vehicle_types'] as List).isNotEmpty ? (json['vehicle_types'] as List).first : 'empty'}');
      } else {
        print('WARNING: vehicle_types key is MISSING from profile response');
      }
      return DriverProfileEntity.fromJson(json);
    } else {
      throw Exception('Failed to get profile: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateProfile(data);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}
