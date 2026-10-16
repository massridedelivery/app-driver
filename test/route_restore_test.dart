import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:massdrive/core/services/route_restoration_service.dart';
import 'package:massdrive/features/main/screens/splash_screen.dart';

/// Cold start restores the last screen on top of home, so back goes home.
void main() {
  GoRouter router() => GoRouter(
    initialLocation: '/splash',
    routes: [
      for (final p in ['/splash', '/home', '/cash-wallet'])
        GoRoute(
          path: p,
          builder: (_, _) => Scaffold(body: Text(p)),
        ),
    ],
  );

  testWidgets('restored screen lands on top of home', (t) async {
    final r = router();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    expect(find.text('/splash'), findsOneWidget);

    pushWhenOn(r, '/home', '/cash-wallet');
    r.go('/home');
    await t.pumpAndSettle();

    expect(find.text('/cash-wallet'), findsOneWidget);
    expect(r.canPop(), isTrue); // back has somewhere to go

    r.pop();
    await t.pumpAndSettle();
    expect(find.text('/home'), findsOneWidget);
  });

  testWidgets('a plain go(restored) is the stuck case this replaces', (
    t,
  ) async {
    final r = router();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    r.go('/cash-wallet');
    await t.pumpAndSettle();
    expect(r.canPop(), isFalse);
  });

  testWidgets('pushes once only', (t) async {
    final r = router();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    pushWhenOn(r, '/home', '/cash-wallet');
    r.go('/home');
    await t.pumpAndSettle();
    r.pop();
    await t.pumpAndSettle();
    r.go('/home');
    await t.pumpAndSettle();
    expect(find.text('/home'), findsOneWidget);
    expect(r.canPop(), isFalse);
  });

  testWidgets('a pushed screen is what gets saved, not the base /home', (
    t,
  ) async {
    final r = router();
    await t.pumpWidget(MaterialApp.router(routerConfig: r));
    r.go('/home');
    await t.pumpAndSettle();
    expect(
      RouteRestorationService.topLocation(
        r.routerDelegate.currentConfiguration,
      ),
      '/home',
    );

    r.push('/cash-wallet');
    await t.pumpAndSettle();
    final config = r.routerDelegate.currentConfiguration;
    expect(config.uri.toString(), '/home'); // why pushes were never restored
    expect(RouteRestorationService.topLocation(config), '/cash-wallet');

    r.pop();
    await t.pumpAndSettle();
    expect(
      RouteRestorationService.topLocation(
        r.routerDelegate.currentConfiguration,
      ),
      '/home',
    );
  });
}
