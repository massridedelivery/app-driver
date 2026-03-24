import 'package:massdrive/core/data/secure_storage/secure_storage_key.dart';
import 'package:massdrive/core/data/secure_storage/secure_storage_manager.dart';
import 'package:massdrive/features/auth/presentation/states/auth_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:massdrive/features/dependency_injection.dart' as massdrive_di;
import 'package:massdrive/features/auth/domain/usecase/logout_usecase.dart'
    as massdrive_logout;

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  late final SecureStorageManager _secureStorage;

  Future<AuthState> get _state async {
    return AuthState(
      await _secureStorage.isContain(SecureStorageKey.accessToken),
    );
  }

  bool get isLogin {
    return state.value?.isLogin ?? false;
  }

  @override
  Future<AuthState> build() async {
    _secureStorage = SecureStorageManager();
    return await _state;
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _state);
  }

  Future<void> logout() async {
    final usecase = massdrive_di.getIt<massdrive_logout.LogoutUseCase>();
    await usecase.execute();
    await refresh();
  }
}
