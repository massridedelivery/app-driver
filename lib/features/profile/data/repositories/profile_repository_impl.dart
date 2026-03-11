import 'package:injectable/injectable.dart';
import 'package:massdrive/features/profile/data/sources/profile_api_service.dart';
import 'package:massdrive/features/profile/data/sources/mock_profile_api_service.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileApiService _apiService;
  final MockProfileApiService _mockApiService;

  // Toggle this to switch between Real and Mock
  final bool _isMock = true;

  ProfileRepositoryImpl(this._apiService, this._mockApiService);

  ProfileApiService get _activeService => _isMock ? _mockApiService : _apiService;

  @override
  Future<DriverProfileEntity> getProfile() async {
    final response = await _activeService.getProfile();
    if (response.statusCode == 200 && response.data != null) {
      return DriverProfileEntity.fromJson(response.data!);
    } else {
      throw Exception('Failed to get profile: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final response = await _activeService.updateProfile(data);
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }
}
