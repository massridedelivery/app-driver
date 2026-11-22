import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/edit_profile/data/emergency_contact_api.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

/// What the sheet did; null when the driver closed it.
enum EmergencyContactOutcome { saved, cleared }

/// Adds, edits or removes the driver's emergency contact (ผู้ติดต่อฉุกเฉิน).
/// Saves straight away through PUT /api/driver/profile; the caller reloads
/// the profile.
Future<EmergencyContactOutcome?> showEmergencyContactSheet(
  BuildContext context, {
  EmergencyContactEntity? current,
  EmergencyContactApi? api,
}) {
  return showModalBottomSheet<EmergencyContactOutcome>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.sheet,
    builder: (_) => EmergencyContactSheet(
      current: current,
      api: api ?? EmergencyContactApi(getIt<Dio>()),
    ),
  );
}

class EmergencyContactSheet extends StatefulWidget {
  const EmergencyContactSheet({super.key, this.current, required this.api});

  /// The contact on file; null to add one.
  final EmergencyContactEntity? current;
  final EmergencyContactApi api;

  @override
  State<EmergencyContactSheet> createState() => _EmergencyContactSheetState();
}

class _EmergencyContactSheetState extends State<EmergencyContactSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.current?.name ?? '');
  late final _phone = TextEditingController(
    text: thaiPhoneForDisplay(widget.current?.phone),
  );
  late final _relationship = TextEditingController(
    text: widget.current?.relationship ?? '',
  );

  /// The server's refusal, shown under its field until that field changes.
  final _serverErrors = <EmergencyContactField, String>{};
  String? _formError;
  bool _busy = false;

  bool get _hasContact =>
      widget.current != null && widget.current!.phone.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    void clearOn(TextEditingController c, EmergencyContactField f) {
      c.addListener(() {
        if (_serverErrors.containsKey(f)) {
          setState(() => _serverErrors.remove(f));
        }
      });
    }

    clearOn(_name, EmergencyContactField.name);
    clearOn(_phone, EmergencyContactField.phone);
    clearOn(_relationship, EmergencyContactField.relationship);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relationship.dispose();
    super.dispose();
  }

  Future<void> _run(
    Future<void> Function() call,
    EmergencyContactOutcome outcome,
  ) async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _formError = null;
      _serverErrors.clear();
    });
    try {
      await call();
      if (!mounted) return;
      Navigator.of(context).pop(outcome);
    } on EmergencyContactException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.field case final f?) {
          _serverErrors[f] = e.message;
        } else {
          _formError = e.message;
        }
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _save() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    await _run(
      () => widget.api.save(
        name: _name.text,
        phone: _phone.text,
        relationship: _relationship.text,
      ),
      EmergencyContactOutcome.saved,
    );
  }

  Future<void> _clear() async {
    if (_busy) return;
    final palette = context.palette;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Text(
          'ลบผู้ติดต่อฉุกเฉิน?',
          style: AppTypography.caption3.copyWith(color: palette.textPrimary),
        ),
        content: Text(
          'ข้อมูลผู้ติดต่อฉุกเฉินจะถูกลบออกจากบัญชีของคุณ',
          style: AppTypography.caption4.copyWith(color: palette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'ยกเลิก',
              style: AppTypography.caption3.copyWith(
                color: palette.textSecondary,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('emergency-clear-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'ลบผู้ติดต่อ',
              style: AppTypography.caption3.copyWith(
                color: AppColors.semanticErrorFgHigh,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(widget.api.clear, EmergencyContactOutcome.cleared);
  }

  /// A local check first, then the server's refusal for that field.
  FormFieldValidator<String> _validator(
    EmergencyContactField field,
    FormFieldValidator<String> local,
  ) =>
      (value) => local(value) ?? _serverErrors[field];

  InputDecoration _decoration(
    AppPalette palette, {
    required String label,
    String? hint,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: TextStyle(color: palette.textSecondary),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: palette.border),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        // Keyboard when it's up, otherwise the Android nav bar.
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ผู้ติดต่อฉุกเฉิน',
                  style: AppTypography.heading3.copyWith(
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'บุคคลที่เราจะติดต่อหากเกิดเหตุฉุกเฉินระหว่างวิ่งงาน',
                  style: AppTypography.caption4.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('emergency-name'),
                  controller: _name,
                  enabled: !_busy,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: _decoration(palette, label: 'ชื่อ'),
                  validator: _validator(
                    EmergencyContactField.name,
                    validateEmergencyName,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('emergency-phone'),
                  controller: _phone,
                  enabled: !_busy,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [ThaiPhoneInputFormatter()],
                  style: TextStyle(color: palette.textPrimary),
                  decoration: _decoration(
                    palette,
                    label: 'เบอร์โทร',
                    hint: 'เช่น 0812345678',
                  ),
                  validator: _validator(
                    EmergencyContactField.phone,
                    validateEmergencyPhone,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('emergency-relationship'),
                  controller: _relationship,
                  enabled: !_busy,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  style: TextStyle(color: palette.textPrimary),
                  decoration: _decoration(
                    palette,
                    label: 'ความสัมพันธ์ (ไม่บังคับ)',
                    hint: 'เช่น พ่อ แม่ คู่สมรส',
                  ),
                  validator: _validator(
                    EmergencyContactField.relationship,
                    validateEmergencyRelationship,
                  ),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    key: const ValueKey('emergency-form-error'),
                    style: AppTypography.caption4.copyWith(
                      color: AppColors.semanticErrorFgHigh,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  key: const ValueKey('emergency-save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.foundationGreen600,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'บันทึก',
                          style: AppTypography.heading5.copyWith(
                            color: Colors.white,
                          ),
                        ),
                ),
                if (_hasContact) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('emergency-clear'),
                    onPressed: _busy ? null : _clear,
                    child: Text(
                      'ลบผู้ติดต่อ',
                      style: AppTypography.caption3.copyWith(
                        color: AppColors.semanticErrorFgHigh,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
