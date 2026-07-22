import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:massdrive/core/configs/environment_config.dart';
import 'package:massdrive/core/services/route_restoration_service.dart';
import 'package:massdrive/firebase_options.dart';
import 'package:massdrive/router/app_routes.dart';

import 'package:massdrive/features/dependency_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // If a widget throws, show the actual error instead of a blank black screen
  // (release builds otherwise render nothing useful).
  ErrorWidget.builder = (details) => _StartupErrorApp(
    message: details.exceptionAsString(),
  );

  // Cap the in-memory image cache well below Flutter's 100 MB default so the OS
  // is far less likely to kill the app for memory pressure while backgrounded.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 << 20; // 40 MB

  // Each init step is isolated so a single failure can never leave main()
  // stuck before runApp() (which shows up as a permanent black screen).
  try {
    await dotenv.load(fileName: '.env');
  } catch (e, s) {
    debugPrint('main: dotenv.load failed: $e\n$s');
  }

  // Firebase options come from --dart-define (see firebase_options.dart /
  // config/mass_*.json). A build without those defines leaves every field
  // empty; on iOS, native FIRApp configuration then aborts with an
  // Objective-C exception (SIGABRT) that a Dart try/catch cannot catch, so
  // the app crashes on launch. Guard on the required fields and skip init
  // entirely when they are absent — FCM (app_startup_controller) already
  // tolerates an uninitialized app and falls back to a dummy token.
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions.appId.isNotEmpty && firebaseOptions.projectId.isNotEmpty) {
    try {
      await Firebase.initializeApp(options: firebaseOptions);
    } catch (e, s) {
      debugPrint('main: Firebase.initializeApp failed: $e\n$s');
    }
  } else {
    debugPrint(
      'main: Firebase options empty (no --dart-define?) — skipping init',
    );
  }

  try {
    await initializeDateFormatting('th_TH', null);
  } catch (e, s) {
    debugPrint('main: initializeDateFormatting failed: $e\n$s');
  }

  try {
    configureDependencies(EnvironmentConfig.env);
  } catch (e, s) {
    debugPrint('main: configureDependencies failed: $e\n$s');
  }

  // Route restoration is best-effort — never let its storage block startup.
  try {
    await RouteRestorationService.instance.init();
    RouteRestorationService.instance.attach(AppRouter.router);
  } catch (e, s) {
    debugPrint('main: route restoration init failed: $e\n$s');
  }

  runApp(const ProviderScope(child: MyApp()));
}

/// Minimal fallback shown by [ErrorWidget.builder] so a build-time crash is
/// visible on-device instead of a black screen.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFF7A0C0C),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            'Startup error:\n\n$message',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
    );
  }
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
