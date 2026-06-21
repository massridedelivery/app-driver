// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
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
import 'package:massdrive/features/chat/data/repositories/chat_repository_impl.dart'
    as _i514;
import 'package:massdrive/features/chat/data/sources/chat_api_service.dart'
    as _i178;
import 'package:massdrive/features/chat/domain/repositories/chat_repository.dart'
    as _i716;
import 'package:massdrive/features/dependency_injection.dart' as _i330;
import 'package:massdrive/features/document_registration/data/repositories/document_registration_repository_impl.dart'
    as _i749;
import 'package:massdrive/features/document_registration/data/sources/document_api_service.dart'
    as _i872;
import 'package:massdrive/features/document_registration/data/sources/document_registration_api.dart'
    as _i639;
import 'package:massdrive/features/document_registration/data/sources/media_api_service.dart'
    as _i1068;
import 'package:massdrive/features/document_registration/domain/repositories/document_registration_repository.dart'
    as _i84;
import 'package:massdrive/features/history/data/repositories/history_list_repository_impl.dart'
    as _i403;
import 'package:massdrive/features/history/data/sources/history_list_api_service.dart'
    as _i176;
import 'package:massdrive/features/history/data/sources/history_list_api_service_impl.dart'
    as _i392;
import 'package:massdrive/features/history/domain/repositories/history_list_repository.dart'
    as _i458;
import 'package:massdrive/features/history/domain/usecases/get_history_list_usecase.dart'
    as _i1031;
import 'package:massdrive/features/home/data/repositories/discovery_repository_impl.dart'
    as _i613;
import 'package:massdrive/features/home/data/repositories/quest_repository_impl.dart'
    as _i82;
import 'package:massdrive/features/home/data/repositories/sos_repository_impl.dart'
    as _i354;
import 'package:massdrive/features/home/data/sources/discovery_api_service.dart'
    as _i58;
import 'package:massdrive/features/home/data/sources/quest_api_service.dart'
    as _i425;
import 'package:massdrive/features/home/data/sources/sos_api_service.dart'
    as _i503;
import 'package:massdrive/features/home/domain/repositories/discovery_repository.dart'
    as _i998;
import 'package:massdrive/features/home/domain/repositories/quest_repository.dart'
    as _i412;
import 'package:massdrive/features/home/domain/repositories/sos_repository.dart'
    as _i8;
import 'package:massdrive/features/income/data/repositories/wallet_repository_impl.dart'
    as _i524;
import 'package:massdrive/features/income/data/sources/wallet_api_service.dart'
    as _i1030;
import 'package:massdrive/features/income/data/sources/wallet_api_service_impl.dart'
    as _i119;
import 'package:massdrive/features/income/domain/repositories/wallet_repository.dart'
    as _i424;
import 'package:massdrive/features/incoming_job/data/repositories/food_delivery_repository_impl.dart'
    as _i511;
import 'package:massdrive/features/incoming_job/data/sources/food_delivery_api_service.dart'
    as _i307;
import 'package:massdrive/features/incoming_job/domain/repositories/food_delivery_repository.dart'
    as _i71;
import 'package:massdrive/features/job_live/data/repositories/job_live_repository_impl.dart'
    as _i48;
import 'package:massdrive/features/job_live/data/sources/job_live_api_service.dart'
    as _i168;
import 'package:massdrive/features/job_live/domain/repositories/job_live_repository.dart'
    as _i106;
import 'package:massdrive/features/profile/data/repositories/profile_repository_impl.dart'
    as _i448;
import 'package:massdrive/features/profile/data/repositories/vehicle_repository_impl.dart'
    as _i287;
import 'package:massdrive/features/profile/data/sources/profile_api_service.dart'
    as _i190;
import 'package:massdrive/features/profile/data/sources/vehicle_api_service.dart'
    as _i893;
import 'package:massdrive/features/profile/domain/repositories/profile_repository.dart'
    as _i610;
import 'package:massdrive/features/profile/domain/repositories/vehicle_repository.dart'
    as _i733;
import 'package:massdrive/features/setting/data/repositories/notification_repository_impl.dart'
    as _i708;
import 'package:massdrive/features/setting/data/sources/notification_api_service.dart'
    as _i717;
import 'package:massdrive/features/setting/domain/repositories/notification_repository.dart'
    as _i858;
import 'package:massdrive/features/wallet/data/repositories/transaction_repository_impl.dart'
    as _i507;
import 'package:massdrive/features/wallet/data/repositories/wallet_overview_repository_impl.dart'
    as _i639;
import 'package:massdrive/features/wallet/data/sources/transaction_api_service.dart'
    as _i469;
import 'package:massdrive/features/wallet/data/sources/transaction_api_service_impl.dart'
    as _i130;
import 'package:massdrive/features/wallet/data/sources/wallet_overview_api_service.dart'
    as _i381;
import 'package:massdrive/features/wallet/data/sources/wallet_overview_api_service_impl.dart'
    as _i477;
import 'package:massdrive/features/wallet/domain/repositories/transaction_repository.dart'
    as _i551;
import 'package:massdrive/features/wallet/domain/repositories/wallet_overview_repository.dart'
    as _i1028;
import 'package:massdrive/features/wallet/domain/usecases/get_transaction_list_usecase.dart'
    as _i478;
import 'package:massdrive/features/wallet/domain/usecases/get_wallet_overview_usecase.dart'
    as _i756;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.singleton<_i822.DeeplinkManager>(() => _i822.DeeplinkManager());
    gh.lazySingleton<_i361.Dio>(() => networkModule.dio);
    gh.lazySingleton<_i307.FoodDeliveryApiService>(
      () => _i307.FoodDeliveryApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i893.VehicleApiService>(
      () => _i893.VehicleApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i168.JobLiveApiService>(
      () => _i168.JobLiveApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1068.MediaApiService>(
      () => _i1068.MediaApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1030.WalletApiService>(
      () => _i119.WalletApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i178.ChatApiService>(
      () => _i178.ChatApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i469.TransactionApiService>(
      () => _i130.TransactionApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i58.DiscoveryApiService>(
      () => _i58.DiscoveryApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i106.JobLiveRepository>(
      () => _i48.JobLiveRepositoryImpl(gh<_i168.JobLiveApiService>()),
    );
    gh.lazySingleton<_i540.AuthApiService>(
      () => _i425.AuthApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i190.ProfileApiService>(
      () => _i190.ProfileApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i639.DocumentRegistrationApi>(
      () => _i639.DocumentRegistrationApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i717.NotificationApiService>(
      () => _i717.NotificationApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i381.WalletOverviewApiService>(
      () => _i477.WalletOverviewApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i176.HistoryListApiService>(
      () => _i392.HistoryListApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i425.QuestApiService>(
      () => _i425.QuestApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i503.SosApiService>(
      () => _i503.SosApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i872.DocumentApiService>(
      () => _i872.DocumentApiServiceImpl(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i412.QuestRepository>(
      () => _i82.QuestRepositoryImpl(gh<_i425.QuestApiService>()),
    );
    gh.lazySingleton<_i733.VehicleRepository>(
      () => _i287.VehicleRepositoryImpl(gh<_i893.VehicleApiService>()),
    );
    gh.lazySingleton<_i610.ProfileRepository>(
      () => _i448.ProfileRepositoryImpl(gh<_i190.ProfileApiService>()),
    );
    gh.lazySingleton<_i424.WalletRepository>(
      () => _i524.WalletRepositoryImpl(gh<_i1030.WalletApiService>()),
    );
    gh.lazySingleton<_i998.DiscoveryRepository>(
      () => _i613.DiscoveryRepositoryImpl(gh<_i58.DiscoveryApiService>()),
    );
    gh.lazySingleton<_i600.AuthRepository>(
      () => _i48.AuthRepositoryImpl(gh<_i540.AuthApiService>()),
    );
    gh.lazySingleton<_i716.ChatRepository>(
      () => _i514.ChatRepositoryImpl(gh<_i178.ChatApiService>()),
    );
    gh.lazySingleton<_i551.TransactionRepository>(
      () => _i507.TransactionRepositoryImpl(gh<_i469.TransactionApiService>()),
    );
    gh.lazySingleton<_i71.FoodDeliveryRepository>(
      () =>
          _i511.FoodDeliveryRepositoryImpl(gh<_i307.FoodDeliveryApiService>()),
    );
    gh.lazySingleton<_i84.DocumentRegistrationRepository>(
      () => _i749.DocumentRegistrationRepositoryImpl(
        gh<_i639.DocumentRegistrationApi>(),
        gh<_i190.ProfileApiService>(),
      ),
    );
    gh.lazySingleton<_i1028.WalletOverviewRepository>(
      () => _i639.WalletOverviewRepositoryImpl(
        gh<_i381.WalletOverviewApiService>(),
      ),
    );
    gh.lazySingleton<_i8.SosRepository>(
      () => _i354.SosRepositoryImpl(gh<_i503.SosApiService>()),
    );
    gh.factory<_i756.GetWalletOverviewUseCase>(
      () =>
          _i756.GetWalletOverviewUseCase(gh<_i1028.WalletOverviewRepository>()),
    );
    gh.factory<_i478.GetTransactionListUseCase>(
      () => _i478.GetTransactionListUseCase(gh<_i551.TransactionRepository>()),
    );
    gh.lazySingleton<_i858.NotificationRepository>(
      () =>
          _i708.NotificationRepositoryImpl(gh<_i717.NotificationApiService>()),
    );
    gh.lazySingleton<_i458.HistoryListRepository>(
      () => _i403.HistoryListRepositoryImpl(gh<_i176.HistoryListApiService>()),
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
    gh.factory<_i1031.GetHistoryListUseCase>(
      () => _i1031.GetHistoryListUseCase(gh<_i458.HistoryListRepository>()),
    );
    return this;
  }
}

class _$NetworkModule extends _i330.NetworkModule {}
