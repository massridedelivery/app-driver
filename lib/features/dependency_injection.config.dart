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
import 'package:massdrive/features/auth/data/sources/auth_api_service_impl.dart'
    as _i425;
import 'package:massdrive/features/auth/domain/repositories/auth_repository.dart'
    as _i600;
import 'package:massdrive/features/auth/domain/usecase/login_with_email_usecase.dart'
    as _i568;
import 'package:massdrive/features/auth/domain/usecase/login_with_phone_usecase.dart'
    as _i621;
import 'package:massdrive/features/auth/domain/usecase/logout_usecase.dart'
    as _i693;
import 'package:massdrive/features/auth/domain/usecase/register_usecase.dart'
    as _i444;
import 'package:massdrive/features/auth/domain/usecase/verify_otp_usecase.dart'
    as _i244;
import 'package:massdrive/features/document_registration/data/repositories/document_registration_repository_impl.dart'
    as _i749;
import 'package:massdrive/features/document_registration/data/sources/mock_document_registration_api.dart'
    as _i583;
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart'
    as _i84;
import 'package:massdrive/features/income/data/repositories/wallet_repository_impl.dart'
    as _i524;
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart'
    as _i1030;
import 'package:massdrive/features/income/data/sources/wallet_api_service_impl.dart'
    as _i119;
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart'
    as _i424;
import 'package:massdrive/features/income/domain/usecase/get_wallet_type_usecase.dart'
    as _i189;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i822.DeeplinkManager>(() => _i822.DeeplinkManager());
    gh.lazySingleton<_i583.MockDocumentRegistrationApi>(
      () => _i583.MockDocumentRegistrationApi(),
    );
    gh.lazySingleton<_i540.AuthApiService>(() => _i425.AuthApiServiceImpl());
    gh.lazySingleton<_i84.DocumentRegistrationRepository>(
      () => _i749.DocumentRegistrationRepositoryImpl(
        gh<_i583.MockDocumentRegistrationApi>(),
      ),
    );
    gh.lazySingleton<_i1030.WalletApiService>(
      () => _i119.WalletApiServiceImpl(),
    );
    gh.lazySingleton<_i424.WalletRepository>(
      () => _i524.WalletRepositoryImpl(gh<_i1030.WalletApiService>()),
    );
    gh.lazySingleton<_i600.AuthRepository>(
      () => _i48.AuthRepositoryImpl(gh<_i540.AuthApiService>()),
    );
    gh.lazySingleton<_i621.LoginWithPhoneUseCase>(
      () => _i621.LoginWithPhoneUseCase(gh<_i600.AuthRepository>()),
    );
    gh.lazySingleton<_i693.LogoutUseCase>(
      () => _i693.LogoutUseCase(gh<_i600.AuthRepository>()),
    );
    gh.lazySingleton<_i244.VerifyOtpUseCase>(
      () => _i244.VerifyOtpUseCase(gh<_i600.AuthRepository>()),
    );
    gh.factory<_i568.LoginWithEmailUseCase>(
      () => _i568.LoginWithEmailUseCase(gh<_i600.AuthRepository>()),
    );
    gh.factory<_i444.RegisterUseCase>(
      () => _i444.RegisterUseCase(gh<_i600.AuthRepository>()),
    );
    gh.factory<_i189.GetWalletTypeUseCase>(
      () => _i189.GetWalletTypeUseCase(gh<_i424.WalletRepository>()),
    );
    return this;
  }
}
