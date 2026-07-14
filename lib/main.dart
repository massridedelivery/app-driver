import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/services/route_restoration_service.dart';
import 'package:massdrive/router/app_routes.dart';

import 'package:massdrive/features/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap the in-memory image cache well below Flutter's 100 MB default so the OS
  // is far less likely to kill the app for memory pressure while backgrounded.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20; // 40 MB
  await dotenv.load(fileName: '.env');
  await GetStorage.init();
  await initializeDateFormatting('th_TH', null);
  configureDependencies(EnvironmentConfig.env);
  RouteRestorationService.instance.attach(AppRouter.router);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationProvider: AppRouter.router.routeInformationProvider,
      routeInformationParser: AppRouter.router.routeInformationParser,
      routerDelegate: AppRouter.router.routerDelegate,
      title: 'Mass Drive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
      ),
    );
  }
}
