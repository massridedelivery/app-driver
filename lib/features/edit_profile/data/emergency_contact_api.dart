import 'package:dio/dio.dart';
import 'package:massdrive/core/constants/endpoints.dart';
import 'package:massdrive/core/utils/friendly_error.dart';
import 'package:massdrive/core/utils/thai_phone.dart';
import 'package:massdrive/features/profile/domain/entities/driver_profile_entity.dart';

/// The backend's limits (internal/driver/profile/emergency.go), counted in
/// runes like the server (utf8.RuneCountInString), not grapheme clusters: a
/// Thai vowel or tone mark counts as one.
const emergencyNameMaxLength = 100;
const emergencyRelationshipMaxLength = 50;

const emergencyNameRequired = 'กรุณากรอกชื่อผู้ติดต่อฉุกเฉิน';
const emergencyNameTooLong =
    'ชื่อยาวได้ไม่เกิน $emergencyNameMaxLength ตัวอักษร';
const emergencyPhoneRequired = 'กรุณากรอกเบอร์โทรผู้ติดต่อฉุกเฉิน';
const emergencyRelationshipTooLong =
    'ความสัมพันธ์ยาวได้ไม่เกิน $emergencyRelationshipMaxLength ตัวอักษร';

int _runes(String s) => s.trim().runes.length;

/// ชื่อ: required, at most 100 characters.
String? validateEmergencyName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return emergencyNameRequired;
  if (_runes(v) > emergencyNameMaxLength) return emergencyNameTooLong;
  return null;
}

/// เบอร์โทร: required in the form (clearing the contact is its own action),
/// a 10-digit Thai mobile number.
String? validateEmergencyPhone(String? value) {
  final digits = thaiPhoneDigits(value ?? '');
  if (digits.isEmpty) return emergencyPhoneRequired;
  if (!isValidThaiPhone(digits)) return thaiPhoneHint;
  return null;
}

/// ความสัมพันธ์: optional, at most 50 characters.
String? validateEmergencyRelationship(String? value) {
  if (_runes(value ?? '') > emergencyRelationshipMaxLength) {
    return emergencyRelationshipTooLong;
  }
  return null;
}

/// The PUT /api/driver/profile body that replaces the emergency contact. Only
/// `emergency_contact` goes: every other field is left as it is (omitted keeps
/// it). The phone is sent in E.164, like every number the app sends.
Map<String, dynamic> emergencyContactBody({
  required String name,
  required String phone,
  String relationship = '',
}) => {
  'emergency_contact': {
    'name': name.trim(),
    'phone': toThaiE164(phone),
    'relationship': relationship.trim(),
  },
};

/// The body that removes the contact: a blank phone clears it server-side.
const Map<String, dynamic> clearEmergencyContactBody = {
  'emergency_contact': {'name': '', 'phone': '', 'relationship': ''},
};

/// Which form field a refusal belongs under.
enum EmergencyContactField { name, phone, relationship }

/// A refused save, with the Thai text to show and the field it is about
/// (null: show it as a toast / under the whole form).
class EmergencyContactException implements Exception {
  const EmergencyContactException(this.message, {this.field});

  static const fallback = 'บันทึกผู้ติดต่อฉุกเฉินไม่สำเร็จ กรุณาลองใหม่';

  final String message;
  final EmergencyContactField? field;

  @override
  String toString() => 'EmergencyContactException($field): $message';
}

/// Saves or clears the driver's emergency contact through PUT
/// /api/driver/profile (BE: UpdateProfileRequest.emergency_contact).
class EmergencyContactApi {
  EmergencyContactApi(this._dio);

  final Dio _dio;

  Future<void> save({
    required String name,
    required String phone,
    String relationship = '',
  }) => _put(
    emergencyContactBody(name: name, phone: phone, relationship: relationship),
    name: name,
  );

  Future<void> clear() => _put(clearEmergencyContactBody, name: '');

  Future<void> _put(Map<String, dynamic> body, {required String name}) async {
    try {
      await _dio.put<dynamic>(Endpoints.driverProfile, data: body);
    } on DioException catch (e) {
      throw emergencyContactErrorOf(e, name: name);
    }
  }
}

/// Maps a refused PUT to a Thai message under the right field.
///
/// The backend answers a bad contact with 400
/// `{"error": "invalid profile: emergency_contact.phone is not a mobile number"}`
/// (or `.name` / `.relationship`) and no `code` (v1.6.x). A `code`, when one
/// is sent, wins; otherwise the field is read from the `emergency_contact.*`
/// key in the error — the field name, never the English wording, which is not
/// shown. [name] is what was sent, to tell "missing" from "too long".
EmergencyContactException emergencyContactErrorOf(
  DioException e, {
  String name = '',
}) {
  final res = e.response;
  if (res == null || res.statusCode != 400) {
    // Network, 401, 5xx…: the app-wide wording.
    return EmergencyContactException(friendlyErrorMessage(e));
  }
  final data = res.data;
  final body = data is Map ? data : const {};
  final code = body['code']?.toString() ?? '';
  final text = '${body['error'] ?? body['message'] ?? ''}';

  final field = switch (code) {
    'INVALID_PHONE' => EmergencyContactField.phone,
    _ when text.contains('emergency_contact.phone') =>
      EmergencyContactField.phone,
    _ when text.contains('emergency_contact.name') =>
      EmergencyContactField.name,
    _ when text.contains('emergency_contact.relationship') =>
      EmergencyContactField.relationship,
    _ => null,
  };
  return switch (field) {
    EmergencyContactField.phone => const EmergencyContactException(
      thaiPhoneHint,
      field: EmergencyContactField.phone,
    ),
    EmergencyContactField.name => EmergencyContactException(
      name.trim().isEmpty ? emergencyNameRequired : emergencyNameTooLong,
      field: EmergencyContactField.name,
    ),
    EmergencyContactField.relationship => const EmergencyContactException(
      emergencyRelationshipTooLong,
      field: EmergencyContactField.relationship,
    ),
    null => const EmergencyContactException(EmergencyContactException.fallback),
  };
}

/// One line for the edit-profile row: "สมหญิง ใจดี (แม่) · 0812345678", or
/// null when there's no contact.
String? emergencyContactSummary(EmergencyContactEntity? contact) {
  if (contact == null || contact.phone.trim().isEmpty) return null;
  final name = contact.name.trim();
  final rel = contact.relationship.trim();
  final who = [
    if (name.isNotEmpty) name,
    if (rel.isNotEmpty) '($rel)',
  ].join(' ');
  final phone = thaiPhoneForDisplay(contact.phone);
  return who.isEmpty ? phone : '$who · $phone';
}
