import 'package:injectable/injectable.dart';
import '../../data/sources/notification_api_service.dart';
import '../../domain/repositories/notification_repository.dart';

@LazySingleton(as: NotificationRepository)
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepositoryImpl(this._apiService);

  @override
  Future<void> registerDevice(Map<String, dynamic> data) async {
    await _apiService.registerDevice(data);
  }
}
