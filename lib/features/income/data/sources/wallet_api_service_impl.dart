import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart';

@LazySingleton(as: WalletApiService)
class WalletApiServiceImpl implements WalletApiService {
  late final Dio _dio;
  late final SecureStorageManager _secureStorage;

  WalletApiServiceImpl() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    // Add interceptor if needed
    _secureStorage = SecureStorageManager();
  }

  @override
  Future<Map<String, dynamic>> getWalletType() async {
    try {
      final token = await _secureStorage.read(SecureStorageKey.accessToken);
      final response = await _dio.get(
        Endpoints.walletType,
        options: Options(headers: {'Authorization': 'Bearer \$token'}),
      );

      return response.data;
    } on DioException catch (e) {
       if (e.response?.data != null && e.response?.data['error'] != null) {
        throw Exception(e.response?.data['error']);
      }
      throw Exception('Failed to fetch wallet type');
    }
  }
}
