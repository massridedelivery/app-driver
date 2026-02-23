import 'package:massdrive/features/auth/presentation/states/login_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  LoginState build() => const .new();
}
