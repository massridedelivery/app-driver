import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/constants/thai_provinces.dart';
import 'package:massdrive/core/theme/brand_colors.dart';
import 'package:massdrive/features/document_registration/domain/models/vehicle_info.dart';
import 'package:massdrive/features/document_registration/presentation/widgets/registration_ui.dart';

/// Colour chips offered for สีรถ; anything else goes through "อื่นๆ".
const List<String> kVehicleColors = [
  'ดำ',
  'ขาว',
  'เทา',
  'เงิน',
  'แดง',
  'น้ำเงิน',
  'เขียว',
  'เหลือง',
  'ส้ม',
  'น้ำตาล',
  'ชมพู',
  'ม่วง',
];

const _otherColorLabel = 'อื่นๆ';
const _requiredMessage = 'กรุณากรอกข้อมูลให้ครบถ้วน';

/// State of the five vehicle fields, shared by the sign-up vehicle step and
/// the edit-profile vehicle sheet.
class VehicleFieldsController extends ChangeNotifier {
  VehicleFieldsController({VehicleInfo? initial})
    : model = TextEditingController(text: initial?.model ?? ''),
      year = TextEditingController(
        text: (initial?.year ?? 0) > 0 ? '${initial!.year}' : '',
      ),
      plate = TextEditingController(text: initial?.licensePlate ?? ''),
      _province = initial?.province.trim() ?? '' {
    final color = initial?.color.trim() ?? '';
    _otherColor = color.isNotEmpty && !kVehicleColors.contains(color);
    _chipColor = _otherColor ? '' : color;
    otherColor = TextEditingController(text: _otherColor ? color : '');
    otherColor.addListener(notifyListeners);
  }

  final TextEditingController model;
  final TextEditingController year;
  final TextEditingController plate;
  late final TextEditingController otherColor;

  // A stored province outside the 77 names (older rows hold e.g. "Bangkok")
  // is kept and shown as-is until the driver picks a new one.
  String _province;
  String get province => _province;
  set province(String value) {
    if (value == _province) return;
    _province = value;
    notifyListeners();
  }

  String _chipColor = '';
  bool _otherColor = false;

  /// The chip picked, or "อื่นๆ"; empty while none is.
  String get selectedChip => _otherColor ? _otherColorLabel : _chipColor;
  bool get isOtherColor => _otherColor;

  void selectChip(String chip) {
    _otherColor = chip == _otherColorLabel;
    _chipColor = _otherColor ? '' : chip;
    notifyListeners();
  }

  /// The colour to send: the chip, or the "อื่นๆ" text.
  String get color => _otherColor ? otherColor.text.trim() : _chipColor;

  VehicleInfo get value => VehicleInfo(
    vehicleType: 'motorcycle',
    model: model.text.trim(),
    year: int.tryParse(year.text.trim()) ?? 0,
    licensePlate: normalizePlate(plate.text),
    province: province.trim(),
    color: color,
  );

  @override
  void dispose() {
    model.dispose();
    year.dispose();
    plate.dispose();
    otherColor.dispose();
    super.dispose();
  }
}

/// ยี่ห้อและรุ่น · ปีจดทะเบียน · เลขทะเบียนรถ · จังหวัด · สีรถ, all required.
/// Put it inside a [Form]; validating the form checks every field.
class VehicleFields extends StatelessWidget {
  const VehicleFields({super.key, required this.controller});

  final VehicleFieldsController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RegistrationField(
          label: 'ยี่ห้อและรุ่น',
          child: TextFormField(
            key: const Key('vehicle-model'),
            controller: controller.model,
            style: registrationInputStyle(context),
            decoration: registrationInputDecoration(
              context,
              hint: 'เช่น Honda Wave 110i',
            ),
            validator: _required,
          ),
        ),
        RegistrationField(
          label: 'ปีจดทะเบียน',
          child: TextFormField(
            key: const Key('vehicle-year'),
            controller: controller.year,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            style: registrationInputStyle(context),
            decoration: registrationInputDecoration(context, hint: 'เช่น 2023'),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return _requiredMessage;
              return t.length == 4 ? null : 'กรุณากรอกปี 4 หลัก เช่น 2023';
            },
          ),
        ),
        RegistrationField(
          label: 'เลขทะเบียนรถ',
          child: TextFormField(
            key: const Key('vehicle-plate'),
            controller: controller.plate,
            style: registrationInputStyle(context),
            decoration: registrationInputDecoration(
              context,
              hint: 'เช่น 1กข 1234',
            ),
            validator: _required,
          ),
        ),
        RegistrationField(
          label: 'จังหวัด (ตามป้ายทะเบียน)',
          child: _ProvinceField(controller: controller),
        ),
        RegistrationField(
          label: 'สีรถ',
          child: _ColorField(controller: controller),
        ),
      ],
    );
  }

  static String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? _requiredMessage : null;
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({required this.controller});

  final VehicleFieldsController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) =>
          controller.province.trim().isEmpty ? 'กรุณาเลือกจังหวัด' : null,
      builder: (field) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final brand = context.brand;
          final province = controller.province;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RegistrationFieldBox(
                key: const Key('vehicle-province'),
                error: field.hasError,
                onTap: () async {
                  final picked = await showProvincePicker(
                    context,
                    current: province,
                  );
                  if (picked == null) return;
                  controller.province = picked;
                  field.didChange(picked);
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        province.isEmpty ? 'เลือกจังหวัด' : province,
                        style: province.isEmpty
                            ? AppTypography.caption4.copyWith(
                                color: brand.text3,
                              )
                            : registrationInputStyle(context),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: brand.text3),
                  ],
                ),
              ),
              if (field.hasError) _ErrorText(field.errorText!),
            ],
          );
        },
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({required this.controller});

  final VehicleFieldsController controller;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) {
        if (controller.selectedChip.isEmpty) return 'กรุณาเลือกสีรถ';
        if (controller.color.isEmpty) return 'กรุณาระบุสีรถ';
        return null;
      },
      builder: (field) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final brand = context.brand;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final chip in [...kVehicleColors, _otherColorLabel])
                    ChoiceChip(
                      key: Key('vehicle-color-$chip'),
                      label: Text(chip),
                      selected: controller.selectedChip == chip,
                      showCheckmark: false,
                      onSelected: (_) {
                        controller.selectChip(chip);
                        field.didChange(chip);
                      },
                      labelStyle: AppTypography.caption4.copyWith(
                        color: controller.selectedChip == chip
                            ? Colors.white
                            : brand.text1,
                      ),
                      backgroundColor: brand.fill,
                      selectedColor: brand.red,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                ],
              ),
              if (controller.isOtherColor) ...[
                const SizedBox(height: 10),
                TextField(
                  key: const Key('vehicle-color-other'),
                  controller: controller.otherColor,
                  maxLength: 30,
                  style: registrationInputStyle(context),
                  decoration: registrationInputDecoration(
                    context,
                    hint: 'ระบุสีรถ เช่น ฟ้า',
                  ),
                  onChanged: field.didChange,
                ),
              ],
              if (field.hasError) _ErrorText(field.errorText!),
            ],
          );
        },
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, left: 4),
    child: Text(
      text,
      style: AppTypography.caption5.copyWith(color: context.brand.bad),
    ),
  );
}

/// Bottom-sheet province picker: a search box over the 77 provinces, filtered
/// as the driver types. Returns the picked name, or null when dismissed.
Future<String?> showProvincePicker(
  BuildContext context, {
  String current = '',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.brand.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      String query = '';
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          final brand = ctx.brand;
          final provinces = searchThaiProvinces(query);
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: SizedBox(
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: brand.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'เลือกจังหวัด (ตามป้ายทะเบียน)',
                      style: AppTypography.heading5.copyWith(
                        color: brand.text1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: TextField(
                      key: const Key('province-search'),
                      style: AppTypography.caption3.copyWith(
                        color: brand.text1,
                      ),
                      onChanged: (v) => setSheetState(() => query = v),
                      decoration: registrationInputDecoration(
                        ctx,
                        hint: 'ค้นหาจังหวัด',
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: brand.text3,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: provinces.isEmpty
                        ? Center(
                            child: Text(
                              'ไม่พบจังหวัด',
                              style: AppTypography.caption3.copyWith(
                                color: brand.text2,
                              ),
                            ),
                          )
                        : ListView.separated(
                            // Last row clears the Android nav bar (0 while the
                            // keyboard is up — the sheet sits above it then).
                            padding: EdgeInsets.fromLTRB(
                              12,
                              0,
                              12,
                              MediaQuery.paddingOf(ctx).bottom,
                            ),
                            itemCount: provinces.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: brand.line),
                            itemBuilder: (_, i) {
                              final p = provinces[i];
                              return ListTile(
                                title: Text(
                                  p,
                                  style: AppTypography.caption3.copyWith(
                                    color: brand.text1,
                                  ),
                                ),
                                trailing: p == current
                                    ? Icon(
                                        Icons.check_circle_rounded,
                                        color: brand.red,
                                      )
                                    : null,
                                onTap: () => Navigator.pop(ctx, p),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
