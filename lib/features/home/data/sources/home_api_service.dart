import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/managers/api/api_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_api_service.g.dart';

class HomeApiService {
  final ApiManager _apiManager;

  const HomeApiService({required ApiManager apiManager})
    : _apiManager = apiManager;

  Future<ResponseData> fetchHome() async {
    final response = await _apiManager.fetchApi(
      endPoint: Endpoints.home,
      method: 'GET',
      feature: 'GET: home',
    );
    return response;
  }
}

@riverpod
HomeApiService homeApiService(Ref ref) {
  return HomeApiService(apiManager: ref.read(apiManagerProvider));
}
