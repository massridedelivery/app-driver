import 'package:massdrive/features/home/domain/entities/home_entity.dart';

abstract class HomeRepository {
  Future<HomeEntity> getHome();
}
