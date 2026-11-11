import 'package:flutter/services.dart';

/// Shown under a phone field while the number is incomplete or too long.
const thaiPhoneHint = 'กรุณากรอกเบอร์มือถือ 10 หลัก';

/// What the driver typed or pasted, as local digits: spaces and dashes go,
/// and a `+66` (or bare `66` before 9 digits) country code becomes the
/// leading 0. "081-234-5678", "081 234 5678" and "+66812345678" all give
/// "0812345678".
String thaiPhoneDigits(String input) {
  final trimmed = input.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (trimmed.startsWith('+66')) return '0${digits.substring(2)}';
  if (digits.length == 11 && digits.startsWith('66')) {
    return '0${digits.substring(2)}';
  }
  return digits;
}

/// Normalises what the driver typed after the login field's fixed `+66`
/// prefix to the local `0XXXXXXXXX` form. Both `812345678` and `0812345678`
/// give `0812345678`; empty stays empty.
String normalizeThaiPhone(String input) {
  final digits = thaiPhoneDigits(input);
  if (digits.isEmpty) return '';
  return digits.startsWith('0') ? digits : '0$digits';
}

/// A Thai mobile number in local form: exactly 10 digits starting with 0.
/// Only the length is checked, like the backend (INVALID_PHONE): demo and
/// store-review numbers such as 0000000000 must still pass.
bool isValidThaiPhone(String local) => RegExp(r'^0\d{9}$').hasMatch(local);

/// The E.164 form the API takes: "0812345678" → "+66812345678". Spaces and
/// dashes are dropped; the local form never goes to the server.
String toThaiE164(String input) {
  final local = thaiPhoneDigits(input);
  if (local.startsWith('0')) return '+66${local.substring(1)}';
  return '+$local';
}

/// The local form for showing a stored number: "+66812345678" →
/// "0812345678"; anything else is returned as is.
String thaiPhoneForDisplay(String? stored) {
  final raw = stored?.trim() ?? '';
  return raw.startsWith('+66') ? thaiPhoneDigits(raw) : raw;
}

/// Keeps a phone field to at most 10 local digits: spaces and dashes are
/// dropped as they are typed, and a pasted `+66…` number becomes `0…`.
class ThaiPhoneInputFormatter extends TextInputFormatter {
  const ThaiPhoneInputFormatter();

  static const maxDigits = 10;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = thaiPhoneDigits(newValue.text);
    if (digits.length > maxDigits) {
      // Too long: keep the old text rather than silently cutting a paste.
      if (thaiPhoneDigits(oldValue.text).length <= maxDigits &&
          newValue.text.length - oldValue.text.length == 1) {
        return oldValue;
      }
      digits = digits.substring(0, maxDigits);
    }
    if (digits == newValue.text) return newValue;
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
