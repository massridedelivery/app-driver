import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@injectable
class LoginWithEmailUseCase {
  final AuthRepository _repository;

  LoginWithEmailUseCase(this._repository);

  Future<UserEntity> execute(String email, String password) {
    return _repository.loginWithEmail(email, password);
  }
}
