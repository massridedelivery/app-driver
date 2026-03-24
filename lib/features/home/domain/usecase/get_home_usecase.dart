import 'package:massdrive/features/home/data/repositories/home_repository_impl.dart';
import 'package:massdrive/features/home/domain/entities/home_entity.dart';
import 'package:massdrive/features/home/domain/repositories/home_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_home_usecase.g.dart';

class GetHomeUseCase {
  final HomeRepository _repository;

  const GetHomeUseCase(this._repository);

  Future<HomeEntity> execute() async {
    return await _repository.getHome();
  }
}

@riverpod
GetHomeUseCase getHomeUseCase(Ref ref) {
  return GetHomeUseCase(ref.read(homeRepositoryProvider));
}
