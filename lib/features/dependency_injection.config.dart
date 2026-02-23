// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:massdrive/core/managers/deeplink_manager.dart' as _i822;
import 'package:massdrive/features/auth/data/repositories/auth_repository_impl.dart'
    as _i48;
import 'package:massdrive/features/auth/data/sources/auth_api_service.dart'
    as _i540;
import 'package:massdrive/features/auth/data/sources/mock_auth_api_service.dart'
    as _i633;
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart'
    as _i600;
import 'package:massdrive/features/auth/domain/usecase/login_with_phone_usecase.dart'
    as _i621;
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart'
    as _i244;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i822.DeeplinkManager>(() => _i822.DeeplinkManager());
    gh.lazySingleton<_i540.AuthApiService>(() => _i633.MockAuthApiService());
    gh.lazySingleton<_i600.AuthRepository>(
      () => _i48.AuthRepositoryImpl(gh<_i540.AuthApiService>()),
    );
    gh.lazySingleton<_i621.LoginWithPhoneUseCase>(
      () => _i621.LoginWithPhoneUseCase(gh<_i600.AuthRepository>()),
    );
    gh.lazySingleton<_i244.VerifyOtpUseCase>(
      () => _i244.VerifyOtpUseCase(gh<_i600.AuthRepository>()),
    );
    return this;
  }
}
