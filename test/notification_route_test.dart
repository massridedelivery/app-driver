import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/constants/app_routes.dart';
import 'package:massdrive/core/services/push_notification_service.dart';

void main() {
  // Stand-in for AppRouter.isKnownLocation: only these routes exist.
  final known = <String>{
    AppRoutes.homeNamedPage,
    AppRoutes.documentRegistrationChecklistNamedPage,
    '/held-fares',
  };
  bool isKnown(String location) => known.contains(Uri.parse(location).path);

  test('backend /documents opens the registration checklist', () {
    expect(resolveNotificationRoute('/documents', isKnown),
        AppRoutes.documentRegistrationChecklistNamedPage);
  });

  test('known routes pass through unchanged', () {
    expect(resolveNotificationRoute('/held-fares', isKnown), '/held-fares');
  });

  test('unknown routes are ignored instead of stranding the driver', () {
    expect(resolveNotificationRoute('/no-such-screen', isKnown), isNull);
  });

  test('non-path values are ignored', () {
    expect(resolveNotificationRoute('documents', isKnown), isNull);
    expect(resolveNotificationRoute('', isKnown), isNull);
  });
}
