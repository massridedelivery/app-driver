import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/setting/presentation/screens/setting_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester, String? url) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SettingsProfilePhoto(url: url)),
    ),
  );

  testWidgets('no photo shows the person badge', (tester) async {
    await pump(tester, null);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);

    await pump(tester, '');
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });

  testWidgets('a photo url loads the image in a circle', (tester) async {
    await pump(tester, 'https://cdn.example.com/avatar.jpg');
    expect(find.byKey(const Key('settings-profile-photo')), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a photo that fails to load falls back to the badge', (
    tester,
  ) async {
    await pump(tester, 'https://cdn.example.com/avatar.jpg');
    // The test HTTP client answers 400, so the image errors out.
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
  });
}
