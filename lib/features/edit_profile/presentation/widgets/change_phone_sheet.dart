import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:massdrive/core/constants/app_colors.dart';
import 'package:massdrive/core/constants/app_typography.dart';
import 'package:massdrive/core/theme/app_palette.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/dependency_injection.dart';
import 'package:massdrive/features/edit_profile/data/phone_link_api.dart';
import 'package:pinput/pinput.dart';

/// Wait before another code can be asked for, unless the backend says longer.
const phoneChangeResendCooldown = Duration(seconds: 60);

/// Changes the driver's number with an SMS code sent to the new one. Returns
/// the number now on the account (E.164), or null when the driver closed the
/// sheet. Nothing is saved until the code is verified.
Future<String?> showChangePhoneSheet(
  BuildContext context, {
  required String currentPhone,
  PhoneLinkApi? api,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.sheet,
    builder: (_) => ChangePhoneSheet(
      currentPhone: currentPhone,
      api: api ?? PhoneLinkApi(getIt<Dio>()),
    ),
  );
}

class ChangePhoneSheet extends StatefulWidget {
  const ChangePhoneSheet({
    super.key,
    required this.currentPhone,
    required this.api,
  });

  final String currentPhone;
  final PhoneLinkApi api;

  @override
  State<ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<ChangePhoneSheet> {
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  /// Set once a code was sent: the sheet then asks for it.
  String? _refId;
  String? _phoneError;
  String? _codeError;
  bool _busy = false;
  Timer? _timer;
  Duration _left = Duration.zero;

  String get _digits => thaiPhoneDigits(_phone.text);
  String get _current => thaiPhoneForDisplay(widget.currentPhone);

  bool get _canSend =>
      !_busy && isValidThaiPhone(_digits) && _digits != _current;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() {
      if (_phoneError != null) _phoneError = null;
      setState(() {});
    });
    _pin.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _cooldown(Duration wait) {
    _timer?.cancel();
    _left = wait;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final next = _left - const Duration(seconds: 1);
      setState(() => _left = next.isNegative ? Duration.zero : next);
      if (_left == Duration.zero) t.cancel();
    });
  }

  Future<void> _send() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _phoneError = null;
      _codeError = null;
    });
    try {
      final ref = await widget.api.sendCode(_digits);
      if (!mounted) return;
      _pin.clear();
      setState(() {
        _refId = ref;
        _busy = false;
      });
      _cooldown(phoneChangeResendCooldown);
    } on PhoneChangeException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        // On the code step a refused resend shows under the code.
        if (_refId == null || e.aboutPhone) {
          _refId = e.aboutPhone ? null : _refId;
          _phoneError = e.message;
        } else {
          _codeError = e.message;
        }
      });
      if (e.retryAfter case final wait?) _cooldown(wait);
    }
  }

  Future<void> _verify() async {
    final refId = _refId;
    if (refId == null || _pin.text.length != 6 || _busy) return;
    setState(() {
      _busy = true;
      _codeError = null;
    });
    try {
      final saved = await widget.api.verify(
        phone: _digits,
        otp: _pin.text,
        refId: refId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } on PhoneChangeException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (e.aboutPhone) {
          // Taken meanwhile: back to the number.
          _refId = null;
          _phoneError = e.message;
        } else {
          _codeError = e.message;
        }
      });
      if (e.needsNewCode) {
        _pin.clear();
        _timer?.cancel();
        setState(() => _left = Duration.zero);
      }
    }
  }

  void _editNumber() {
    _timer?.cancel();
    _pin.clear();
    setState(() {
      _refId = null;
      _codeError = null;
      _left = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        // Keyboard when it's up, otherwise the Android nav bar.
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เปลี่ยนหมายเลขโทรศัพท์มือถือ',
            style: AppTypography.heading3.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _refId == null
                ? 'เราจะส่งรหัส OTP ไปที่เบอร์ใหม่เพื่อยืนยัน'
                : 'รหัส 6 หลักส่งไปที่ ${_maskedPhone(_digits)}'
                      '${_refId!.length > 4 ? ' (Ref: ${_refId!.substring(_refId!.length - 4)})' : ''}',
            style: AppTypography.caption4.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_refId == null) ..._phoneStep(palette) else ..._codeStep(palette),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<Widget> _phoneStep(AppPalette palette) => [
    TextField(
      key: const ValueKey('change-phone-field'),
      controller: _phone,
      autofocus: true,
      style: TextStyle(color: palette.textPrimary),
      keyboardType: TextInputType.phone,
      inputFormatters: const [ThaiPhoneInputFormatter()],
      decoration: InputDecoration(
        labelText: 'เบอร์ใหม่',
        hintText: 'เช่น 0812345678',
        labelStyle: TextStyle(color: palette.textSecondary),
        helperText: _current.isEmpty ? null : 'เบอร์ปัจจุบัน $_current',
        errorText:
            _phoneError ??
            (_digits.isNotEmpty && !isValidThaiPhone(_digits)
                ? thaiPhoneHint
                : null),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    ),
    const SizedBox(height: 24),
    _button(
      'ขอรหัส OTP',
      onPressed: _canSend && _left == Duration.zero ? _send : null,
      key: const ValueKey('change-phone-send'),
    ),
  ];

  List<Widget> _codeStep(AppPalette palette) {
    final theme = PinTheme(
      width: 44,
      height: 52,
      textStyle: AppTypography.heading3.copyWith(color: palette.textPrimary),
      decoration: BoxDecoration(
        border: Border.all(color: palette.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return [
      Center(
        child: Pinput(
          key: const ValueKey('change-phone-pin'),
          length: 6,
          controller: _pin,
          autofocus: true,
          defaultPinTheme: theme,
          focusedPinTheme: theme.copyBorderWith(
            border: Border.all(color: AppColors.foundationGreen600, width: 1.5),
          ),
          errorPinTheme: theme.copyBorderWith(
            border: Border.all(
              color: AppColors.semanticErrorFgHigh,
              width: 1.5,
            ),
          ),
          forceErrorState: _codeError != null,
          onCompleted: (_) => _verify(),
        ),
      ),
      if (_codeError != null) ...[
        const SizedBox(height: 12),
        Text(
          _codeError!,
          key: const ValueKey('change-phone-code-error'),
          textAlign: TextAlign.center,
          style: AppTypography.caption4.copyWith(
            color: AppColors.semanticErrorFgHigh,
          ),
        ),
      ],
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _busy ? null : _editNumber,
            child: Text(
              'แก้ไขเบอร์',
              style: AppTypography.caption4.copyWith(
                color: palette.textPrimary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          TextButton(
            onPressed: _busy || _left > Duration.zero ? null : _send,
            child: Text(
              _left > Duration.zero
                  ? 'ขอรหัสใหม่ได้ใน ${_mmss(_left)}'
                  : 'ขอรหัสใหม่',
              style: AppTypography.caption4.copyWith(
                color: _left > Duration.zero
                    ? palette.textSecondary
                    : palette.textPrimary,
                decoration: _left > Duration.zero
                    ? null
                    : TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _button(
        'ยืนยัน',
        onPressed: !_busy && _pin.text.length == 6 ? _verify : null,
        key: const ValueKey('change-phone-verify'),
      ),
    ];
  }

  Widget _button(String label, {VoidCallback? onPressed, Key? key}) {
    return ElevatedButton(
      key: key,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.foundationGreen600,
        minimumSize: const Size.fromHeight(48),
      ),
      onPressed: onPressed,
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
              label,
              style: AppTypography.heading5.copyWith(color: Colors.white),
            ),
    );
  }
}

/// "081•••5678" for the subtitle.
String _maskedPhone(String digits) => digits.length == 10
    ? '${digits.substring(0, 3)}•••${digits.substring(6)}'
    : digits;

String _mmss(Duration d) {
  final s = d.inSeconds.clamp(0, 5999);
  return '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';
}
