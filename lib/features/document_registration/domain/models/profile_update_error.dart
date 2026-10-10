import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/core/utils/friendly_error.dart';

/// Which Step-1 field a `PUT /api/driver/profile` rejection belongs to, so the
/// form can show the message under the right input.
enum ProfileField { firstName, lastName, dateOfBirth }

/// A failed Step-1 profile save, translated for the form.
///
/// [field] is null for errors that don't belong to one input (e.g. the 409
/// "already approved" lock, or a network failure) — the form shows those as a
/// general message instead.
class ProfileUpdateError {
  final ProfileField? field;
  final String message;

  /// True for 409: an approved driver can't change name / date of birth.
  final bool locked;

  const ProfileUpdateError({
    required this.message,
    this.field,
    this.locked = false,
  });

  static const lockedMessage = 'แก้ชื่อหรือวันเกิดได้ผ่านฝ่ายบริการลูกค้า';

  /// Map a thrown error from the profile save into a form-friendly error.
  ///
  /// The backend replies `400 {"error": "invalid profile: <field> <reason>"}`
  /// for validation and `409` once the driver is approved.
  factory ProfileUpdateError.from(Object error) {
    if (error is ApiException) {
      if (error.code == 409) {
        return const ProfileUpdateError(message: lockedMessage, locked: true);
      }
      final raw = (error.message ?? '').toLowerCase();
      if (error.code == 400 && raw.isNotEmpty) {
        return _fromValidation(raw);
      }
    }
    return ProfileUpdateError(message: friendlyErrorMessage(error));
  }

  static ProfileUpdateError _fromValidation(String raw) {
    ProfileField? field;
    if (raw.contains('first_name')) {
      field = ProfileField.firstName;
    } else if (raw.contains('last_name')) {
      field = ProfileField.lastName;
    } else if (raw.contains('date_of_birth') || raw.contains('years old')) {
      field = ProfileField.dateOfBirth;
    }

    final String message;
    if (field == ProfileField.dateOfBirth) {
      if (raw.contains('at least 18')) {
        message = 'ต้องมีอายุ 18 ปีขึ้นไป';
      } else if (raw.contains('looks wrong') || raw.contains('80')) {
        message = 'อายุต้องไม่เกิน 80 ปี';
      } else {
        message = 'วันเกิดไม่ถูกต้อง';
      }
    } else if (field != null) {
      if (raw.contains('required')) {
        message = 'กรุณากรอกข้อมูล';
      } else if (raw.contains('only contain letters')) {
        message = 'ใช้ได้เฉพาะตัวอักษรไทยหรืออังกฤษ';
      } else if (raw.contains('at most')) {
        message = 'ยาวได้ไม่เกิน 50 ตัวอักษร';
      } else {
        message = 'ข้อมูลไม่ถูกต้อง';
      }
    } else {
      message = 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบแล้วลองใหม่';
    }
    return ProfileUpdateError(field: field, message: message);
  }
}
