import 'package:injectable/injectable.dart';
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart';

@lazySingleton
class LoginWithPhoneUseCase {
  final AuthRepository _repository;

  LoginWithPhoneUseCase(this._repository);

  Future<void> execute(String phone) async {
    return _repository.loginWithPhone(phone);
  }
}
