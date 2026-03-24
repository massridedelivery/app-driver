import 'package:massdrive/features/home/data/models/home_model.dart';
import 'package:massdrive/features/home/data/sources/home_api_service.dart';
import 'package:massdrive/features/home/domain/entities/home_entity.dart';
import 'package:massdrive/features/home/domain/repositories/home_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_repository_impl.g.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeApiService _apiService;

  const HomeRepositoryImpl(this._apiService);

  @override
  Future<HomeEntity> getHome() async {
    final response = await _apiService.fetchHome();
    if (response.isSuccessful) {
      return HomeModel.fromJson(response.data['data']).toEntity();
    } else {
      return HomeEntity(id: 0, title: '');
    }
  }
}

@riverpod
HomeRepository homeRepository(Ref ref) {
  return HomeRepositoryImpl(ref.read(homeApiServiceProvider));
}
