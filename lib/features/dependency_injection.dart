import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:injectable/injectable.dart';
import 'package:get_it/get_it.dart';
import 'dependency_injection.config.dart';

final getIt = GetIt.instance;

@module
abstract class NetworkModule {
  @lazySingleton
  Dio get dio => Dio();
}

@InjectableInit()
void configureDependencies(String env) => getIt.init(environment: env);

final dioProvider = Provider<Dio>((ref) => GetIt.I<Dio>());
