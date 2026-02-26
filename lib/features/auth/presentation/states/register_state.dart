import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_state.freezed.dart';

@freezed
sealed class RegisterState with _$RegisterState {
  const factory RegisterState({
    @Default(false) bool isLoading,
    @Default('') String errorMessage,
    @Default('') String fullName,
    @Default('') String email,
    @Default('') String phone,
    @Default('') String password,
  }) = _RegisterState;
}
