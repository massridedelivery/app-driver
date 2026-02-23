import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> execute() async {
    return _repository.logout();
  }
}
