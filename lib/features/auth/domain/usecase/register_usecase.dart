import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/entities/register_request.dart';
import 'package:massdrive/features/auth/domain/entities/user_entity.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@injectable
class RegisterUseCase {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  Future<UserEntity> execute(RegisterRequest request) {
    return _repository.register(request);
  }
}
