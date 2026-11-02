import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/features/document_registration/domain/models/vehicle_info.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/vehicle_fields.dart';

void main() {
  late VehicleFieldsController fields;
  final formKey = GlobalKey<FormState>();

  Future<void> pump(WidgetTester t, {VehicleInfo? initial}) async {
    t.view.physicalSize = const Size(1170, 3000);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    fields = VehicleFieldsController(initial: initial);
    addTearDown(fields.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: VehicleFields(controller: fields),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('province and colour are required', (t) async {
    await pump(t);
    await t.enterText(find.byKey(const Key('vehicle-model')), 'Honda Wave');
    await t.enterText(find.byKey(const Key('vehicle-year')), '2020');
    await t.enterText(find.byKey(const Key('vehicle-plate')), '1กข 1234');
    expect(formKey.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('กรุณาเลือกจังหวัด'), findsOneWidget);
    expect(find.text('กรุณาเลือกสีรถ'), findsOneWidget);
  });

  testWidgets('pick a province by searching, a colour chip, then valid', (
    t,
  ) async {
    await pump(t);
    await t.enterText(find.byKey(const Key('vehicle-model')), 'Honda Wave');
    await t.enterText(find.byKey(const Key('vehicle-year')), '2020');
    await t.enterText(find.byKey(const Key('vehicle-plate')), ' 1กข   1234 ');

    await t.tap(find.byKey(const Key('vehicle-province')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('province-search')), 'เชียง');
    await t.pump();
    expect(find.text('เชียงราย'), findsOneWidget);
    expect(find.text('เชียงใหม่'), findsOneWidget);
    expect(find.text('กรุงเทพมหานคร'), findsNothing);
    await t.tap(find.text('เชียงใหม่'));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('vehicle-color-ดำ')));
    await t.pump();

    expect(formKey.currentState!.validate(), isTrue);
    final v = fields.value;
    expect(v.licensePlate, '1กข 1234');
    expect(v.province, 'เชียงใหม่');
    expect(v.color, 'ดำ');
    expect(v.year, 2020);
  });

  testWidgets('"อื่นๆ" takes a typed colour', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('vehicle-color-อื่นๆ')));
    await t.pump();
    await t.enterText(find.byKey(const Key('vehicle-color-other')), 'ฟ้า');
    expect(fields.color, 'ฟ้า');
  });

  testWidgets('prefill keeps an old province name and a custom colour', (
    t,
  ) async {
    await pump(
      t,
      initial: VehicleInfo(
        vehicleType: 'motorcycle',
        model: 'Honda Click',
        year: 2019,
        licensePlate: '1กข 1234',
        province: 'Bangkok',
        color: 'ฟ้าอ่อน',
      ),
    );
    expect(find.text('Bangkok'), findsOneWidget);
    expect(fields.province, 'Bangkok');
    expect(fields.isOtherColor, isTrue);
    expect(fields.color, 'ฟ้าอ่อน');
    expect(find.text('Honda Click'), findsOneWidget);
  });
}
