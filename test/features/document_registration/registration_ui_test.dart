import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/theme/brand_colors.dart';
import 'package:massdrive/features/document_registration/domain/models/registration_status.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/registration_ui.dart';

void main() {
  Future<void> pump(
    WidgetTester t,
    Widget child, {
    Brightness brightness = Brightness.light,
  }) {
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: child,
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final brand = brightness == Brightness.dark
        ? BrandColors.dark
        : BrandColors.light;

    group('RegistrationScaffold header (${brightness.name})', () {
      testWidgets('renders title, subtitle and "4/9" ring', (t) async {
        await pump(
          t,
          const RegistrationScaffold(
            icon: Icons.badge_rounded,
            title: 'ข้อมูลส่วนตัว',
            subtitle: 'ตรงกับบัตรประชาชน',
            step: 4,
            total: 9,
            child: SizedBox(),
          ),
          brightness: brightness,
        );

        expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget);
        expect(find.text('ตรงกับบัตรประชาชน'), findsOneWidget);
        expect(find.text('MASS DRIVE'), findsOneWidget);
        expect(find.byType(RegistrationProgressRing), findsOneWidget);
        expect(find.text('4/9', findRichText: true), findsOneWidget);

        final scaffold = t.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, brand.bg);
        final icon = t.widget<Icon>(find.byIcon(Icons.badge_rounded));
        expect(icon.color, brand.red);
      });

      testWidgets('hides the ring when no total is given', (t) async {
        await pump(
          t,
          const RegistrationScaffold(
            icon: Icons.person_add_rounded,
            title: 'สร้างบัญชีคนขับ',
            child: SizedBox(),
          ),
          brightness: brightness,
        );

        expect(find.text('สร้างบัญชีคนขับ'), findsOneWidget);
        expect(find.byType(RegistrationProgressRing), findsNothing);
      });
    });

    group('RegistrationPrimaryButton (${brightness.name})', () {
      Color? bg(WidgetTester t) {
        final button = t.widget<ElevatedButton>(find.byType(ElevatedButton));
        final states = <WidgetState>{
          if (button.onPressed == null) WidgetState.disabled,
        };
        return button.style!.backgroundColor!.resolve(states);
      }

      testWidgets('disabled: line face, text3 label, not tappable', (t) async {
        await pump(
          t,
          const Scaffold(
            body: RegistrationPrimaryButton(label: 'บันทึก', onPressed: null),
          ),
          brightness: brightness,
        );

        final button = t.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
        expect(bg(t), brand.line);
        final label = t.widget<Text>(find.text('บันทึก'));
        expect(label.style?.color, brand.text3);
      });

      testWidgets('enabled: red face, white label, fires onPressed', (t) async {
        var taps = 0;
        await pump(
          t,
          Scaffold(
            body: RegistrationPrimaryButton(
              label: 'บันทึก',
              onPressed: () => taps++,
            ),
          ),
          brightness: brightness,
        );

        expect(bg(t), brand.red);
        final label = t.widget<Text>(find.text('บันทึก'));
        expect(label.style?.color, Colors.white);
        await t.tap(find.byType(ElevatedButton));
        expect(taps, 1);
      });
    });
  }

  group('step numbering', () {
    test('food has 5 items, ride / both 9', () {
      expect(registrationTotalSteps(KycTier.food), 5);
      expect(registrationTotalSteps(KycTier.ride), 9);
      expect(registrationTotalSteps(KycTier.both), 9);
    });

    test('positions match the checklist order', () {
      expect(registrationStepNumber(KycTier.ride, RegistrationItem.profile), 1);
      expect(
        registrationStepNumber(KycTier.ride, RegistrationItem.drivingLicense),
        4,
      );
      expect(registrationStepNumber(KycTier.ride, RegistrationItem.bank), 9);
      expect(registrationStepNumber(KycTier.food, RegistrationItem.bank), 5);
      expect(
        registrationStepNumber(KycTier.food, RegistrationItem.vehicle),
        isNull,
      );
      expect(registrationStepNumber(KycTier.food, RegistrationItem.consent), 5);
      expect(registrationStepNumber(null, RegistrationItem.profile), isNull);
    });
  });
}
