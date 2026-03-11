import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import 'profile_api_service.dart';

@lazySingleton
class MockProfileApiService implements ProfileApiService {
  @override
  Future<Response<Map<String, dynamic>>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: {
        "user_id": "drv_mock_123",
        "full_name": "สมชาย ใจดี (Mock)",
        "phone": "0812345678",
        "rating": 4.8,
        "total_trips": 125,
        "verified": true, // Set to false to test the interceptor
        "documents": [
          {
            "type": "id_card",
            "status": "approved",
            "media_url": "https://publie.com/mock-id.jpg",
            "reviewed_at": "2024-03-01T10:00:00Z",
          },
        ],
        "vehicle_type_ids": ["van", "truck"],
        "vehicle_types": [
          {
            "id": "van",
            "name": "รถตู้",
            "display_name": "รถตู้ (Van)",
            "is_enabled": true,
          },
        ],
        "vehicle_plate": "กข 1234",
        "vehicle_model": "Toyota Hiace",
        "balance": 1500.50,
        "acceptance_rate": 98.0,
        "status": "online",
      },
    );
  }

  @override
  Future<Response<Map<String, dynamic>>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return Response(
      requestOptions: RequestOptions(path: ''),
      statusCode: 200,
      data: {"message": "Profile updated successfully (Mock)"},
    );
  }
}
