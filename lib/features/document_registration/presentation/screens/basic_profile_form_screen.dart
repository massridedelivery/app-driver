import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/thai_date.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../profile/presentation/controllers/profile_controller.dart';
import '../../domain/models/driver_profile_info.dart';
import '../../domain/models/profile_update_error.dart';
import '../controllers/registration_controller.dart';

/// Letters only (Thai / English), plus space . - ' — same rule as the backend.
final _nameAllowed = RegExp(r"^[A-Za-z฀-๿ .'\-]+$");

/// Step 1 "ข้อมูลส่วนตัว": verified phone (read-only), first name, last name and
/// date of birth. Saved with PUT /api/driver/profile
/// `{first_name, last_name, date_of_birth}` — the backend composes full_name.
class BasicProfileFormScreen extends ConsumerStatefulWidget {
  const BasicProfileFormScreen({super.key});

  @override
  ConsumerState<BasicProfileFormScreen> createState() =>
      _BasicProfileFormScreenState();
}

class _BasicProfileFormScreenState
    extends ConsumerState<BasicProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _emergencyController = TextEditingController();

  DateTime? _dateOfBirth;
  bool _dobTouched = false;

  /// Errors returned by the backend, keyed by field; cleared when edited.
  final Map<ProfileField, String> _serverErrors = {};
  String? _generalError;
  bool _locked = false;

  late final DateTime _maxDob; // youngest allowed: today − 18 years
  late final DateTime _minDob; // oldest allowed: today − 80 years

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _maxDob = DateTime(now.year - 18, now.month, now.day);
    _minDob = DateTime(now.year - 80, now.month, now.day);

    _firstNameController.addListener(_onFieldChanged);
    _lastNameController.addListener(_onFieldChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileInfo = ref.read(registrationControllerProvider).profileInfo;
      if (profileInfo != null) {
        _firstNameController.text = profileInfo.firstName;
        _lastNameController.text = profileInfo.lastName;
        _emailController.text = profileInfo.email;
        _emergencyController.text = profileInfo.emergencyContact;
        setState(() => _dateOfBirth = profileInfo.dateOfBirth);
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _emergencyController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    // Rebuild so the "ถัดไป" button tracks completeness.
    if (mounted) setState(() {});
  }

  bool get _canSubmit =>
      !_locked &&
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _dateOfBirth != null;

  String? _validateName(String? value, ProfileField field) {
    final server = _serverErrors[field];
    if (server != null) return server;
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'กรุณากรอกข้อมูล';
    if (v.length > 50) return 'ยาวได้ไม่เกิน 50 ตัวอักษร';
    if (!_nameAllowed.hasMatch(v)) return 'ใช้ได้เฉพาะตัวอักษรไทยหรืออังกฤษ';
    return null;
  }

  String? get _dobError {
    final server = _serverErrors[ProfileField.dateOfBirth];
    if (server != null) return server;
    if (_dobTouched && _dateOfBirth == null) return 'กรุณาเลือกวันเกิด';
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors.clear();
      _generalError = null;
      _dobTouched = true;
    });
    final fieldsValid = _formKey.currentState?.validate() ?? false;
    if (!fieldsValid || _dateOfBirth == null) return;

    final info = DriverProfileInfo(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      dateOfBirth: _dateOfBirth,
      email: _emailController.text.trim(),
      emergencyContact: _emergencyController.text.trim(),
    );

    final error = await ref
        .read(registrationControllerProvider.notifier)
        .updateProfile(info);
    if (!mounted) return;

    if (error == null) {
      context.pop();
      return;
    }
    setState(() {
      if (error.locked) {
        _locked = true;
        _generalError = error.message;
      } else if (error.field != null) {
        _serverErrors[error.field!] = error.message;
      } else {
        _generalError = error.message;
      }
    });
    // Re-run validators so a server error shows under its field.
    _formKey.currentState?.validate();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registrationControllerProvider);
    final phone = ref.watch(profileControllerProvider).profile?.phone;

    return Scaffold(
      backgroundColor: context.palette.bg,
      appBar: AppBar(
        title: Text(
          'ข้อมูลส่วนตัว',
          style: AppTypography.heading4.copyWith(
            color: context.palette.textPrimary,
          ),
        ),
        backgroundColor: context.palette.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.palette.textPrimary),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          // Clear the Android edge-to-edge system nav so the submit button
          // isn't hidden behind it.
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (_generalError != null) ...[
              _buildBanner(_generalError!, locked: _locked),
              const SizedBox(height: 16),
            ],
            _buildPhoneRow(phone),
            const SizedBox(height: 16),
            _buildNameField(
              'ชื่อ *',
              _firstNameController,
              ProfileField.firstName,
              hint: 'เช่น สมชาย',
            ),
            const SizedBox(height: 16),
            _buildNameField(
              'นามสกุล *',
              _lastNameController,
              ProfileField.lastName,
              hint: 'ตรงกับบัตรประชาชน',
            ),
            const SizedBox(height: 16),
            _buildDobField(),
            const SizedBox(height: 28),
            Text(
              'ข้อมูลเพิ่มเติม (ไม่บังคับ)',
              style: AppTypography.caption2.copyWith(
                color: context.palette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildOptionalField(
              'อีเมล (Email)',
              _emailController,
              keyboardType: TextInputType.emailAddress,
              hint: 'เช่น somchai@email.com',
            ),
            const SizedBox(height: 16),
            _buildOptionalField(
              'เบอร์ติดต่อฉุกเฉิน (Emergency Contact)',
              _emergencyController,
              keyboardType: TextInputType.number,
              hint: 'เช่น 0812345678',
              maxLength: 10,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading || !_canSubmit ? null : _submit,
                style: ElevatedButton.styleFrom(
                  // Fixed light face in both themes so the black label always
                  // reads (textPrimary would be black in light mode).
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.semanticDisabledBgLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: context.palette.border),
                  ),
                ),
                child: state.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        'บันทึก',
                        // Black label: the button face is light (white when
                        // enabled in dark mode, light grey while disabled), so
                        // the old grey disabled label was near-invisible.
                        style: AppTypography.label1.copyWith(
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner(String message, {required bool locked}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.foundationRed100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.foundationRed400),
      ),
      child: Row(
        children: [
          Icon(
            locked ? Icons.lock_outline : Icons.error_outline,
            color: AppColors.foundationRed800,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption3.copyWith(
                color: AppColors.foundationRed800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Phone from OTP — shown locked with a "verified" mark.
  Widget _buildPhoneRow(String? phone) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('เบอร์โทรศัพท์'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.palette.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 18, color: context.palette.textSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatPhone(phone),
                  style: AppTypography.label2.copyWith(
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.verified,
                  size: 18, color: AppColors.foundationGreen500),
              const SizedBox(width: 4),
              Text(
                'ยืนยันแล้ว',
                style: AppTypography.caption4.copyWith(
                  color: AppColors.foundationGreen600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(
    String label,
    TextEditingController controller,
    ProfileField field, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: _locked,
          maxLength: 50,
          textInputAction: TextInputAction.next,
          style: AppTypography.label2.copyWith(
            color: context.palette.textPrimary,
          ),
          decoration: _decoration(hint),
          onChanged: (_) {
            if (_serverErrors.remove(field) != null) {
              _formKey.currentState?.validate();
            }
          },
          validator: (v) => _validateName(v, field),
        ),
      ],
    );
  }

  Widget _buildDobField() {
    final error = _dobError;
    final dob = _dateOfBirth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('วันเดือนปีเกิด *'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _locked ? null : _pickDateOfBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.palette.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: error != null
                  ? Border.all(color: AppColors.foundationRed800)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dob != null ? formatThaiDate(dob) : 'เลือกวันเกิด',
                    style: AppTypography.label2.copyWith(
                      color: dob != null
                          ? context.palette.textPrimary
                          : context.palette.textSecondary,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: context.palette.textSecondary),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, left: 4),
          child: Text(
            error ?? 'อายุ 18 ปีขึ้นไป',
            style: AppTypography.caption4.copyWith(
              color: error != null
                  ? AppColors.foundationRed800
                  : context.palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: maxLength != null
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          maxLength: maxLength,
          style: AppTypography.label2.copyWith(
            color: context.palette.textPrimary,
          ),
          decoration: _decoration(hint),
          validator: (value) {
            final v = value?.trim() ?? '';
            if (maxLength != null && v.isNotEmpty && v.length != maxLength) {
              return 'กรุณากรอกให้ครบ $maxLength หลัก';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTypography.caption2.copyWith(
          color: context.palette.textPrimary,
        ),
      );

  InputDecoration _decoration(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.label2.copyWith(
          color: context.palette.textSecondary,
        ),
        filled: true,
        fillColor: context.palette.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        counterText: '',
        errorStyle: AppTypography.caption4.copyWith(
          color: AppColors.foundationRed800,
        ),
      );

  /// "+66653333333" → "065-333-3333".
  String _formatPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    var p = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (p.startsWith('+66')) p = '0${p.substring(3)}';
    if (p.length == 10) {
      return '${p.substring(0, 3)}-${p.substring(3, 6)}-${p.substring(6)}';
    }
    return p;
  }

  /// Day / Thai month / Buddhist-era year wheels, limited to ages 18–80.
  Future<void> _pickDateOfBirth() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final initial = _dateOfBirth ??
        DateTime(DateTime.now().year - 30, 1, 1);
    var year = initial.year;
    var month = initial.month;
    var day = initial.day;

    final years = [
      for (var y = _maxDob.year; y >= _minDob.year; y--) y,
    ];
    final yearCtrl =
        FixedExtentScrollController(initialItem: years.indexOf(year).clamp(0, years.length - 1));
    final monthCtrl = FixedExtentScrollController(initialItem: month - 1);
    final dayCtrl = FixedExtentScrollController(initialItem: day - 1);

    int daysIn(int y, int m) => DateTime(y, m + 1, 0).day;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: context.palette.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final maxDay = daysIn(year, month);
            if (day > maxDay) {
              day = maxDay;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (dayCtrl.hasClients) dayCtrl.jumpToItem(day - 1);
              });
            }
            final candidate = DateTime(year, month, day);
            final tooYoung = candidate.isAfter(_maxDob);
            final tooOld = candidate.isBefore(_minDob);
            final valid = !tooYoung && !tooOld;

            Widget wheel({
              required FixedExtentScrollController controller,
              required int count,
              required String Function(int) label,
              required ValueChanged<int> onChanged,
              int flex = 1,
            }) {
              return Expanded(
                flex: flex,
                child: CupertinoPicker(
                  scrollController: controller,
                  itemExtent: 40,
                  onSelectedItemChanged: (i) => setSheet(() => onChanged(i)),
                  children: [
                    for (var i = 0; i < count; i++)
                      Center(
                        child: Text(
                          label(i),
                          style: AppTypography.label2.copyWith(
                            color: context.palette.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'วันเดือนปีเกิด',
                      style: AppTypography.heading5.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: Row(
                        children: [
                          wheel(
                            controller: dayCtrl,
                            count: maxDay,
                            label: (i) => '${i + 1}',
                            onChanged: (i) => day = i + 1,
                          ),
                          wheel(
                            controller: monthCtrl,
                            count: 12,
                            label: (i) => thaiMonthsFull[i],
                            onChanged: (i) => month = i + 1,
                            flex: 2,
                          ),
                          wheel(
                            controller: yearCtrl,
                            count: years.length,
                            label: (i) => '${years[i] + 543}',
                            onChanged: (i) => year = years[i],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tooYoung
                          ? 'ต้องมีอายุ 18 ปีขึ้นไป'
                          : tooOld
                              ? 'อายุต้องไม่เกิน 80 ปี'
                              : formatThaiDate(candidate),
                      style: AppTypography.caption3.copyWith(
                        color: valid
                            ? context.palette.textSecondary
                            : AppColors.foundationRed800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: valid
                            ? () => Navigator.pop(ctx, candidate)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.foundationOrange600,
                          disabledBackgroundColor:
                              AppColors.semanticDisabledBgLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'ตกลง',
                          style: AppTypography.label1.copyWith(
                            color: Colors.white,
                          ),
                        ),
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

    yearCtrl.dispose();
    monthCtrl.dispose();
    dayCtrl.dispose();

    setState(() {
      _dobTouched = true;
      if (picked != null) {
        _dateOfBirth = picked;
        _serverErrors.remove(ProfileField.dateOfBirth);
      }
    });
  }
}
