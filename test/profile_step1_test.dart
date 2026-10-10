import 'package:flutter_test/flutter_test.dart';
import 'package:massdrive/core/managers/api/api_exception.dart';
import 'package:massdrive/features/document_registration/domain/models/driver_profile_info.dart';
import 'package:massdrive/features/document_registration/domain/models/profile_update_error.dart';
import 'package:massdrive/core/utils/thai_date.dart';

void main() {
  group('ProfileUpdateError.from', () {
    ProfileUpdateError bad(String msg) =>
        ProfileUpdateError.from(ApiException(400, message: msg));

    test('maps each backend validation message to its field', () {
      expect(bad('invalid profile: first_name is required').field,
          ProfileField.firstName);
      expect(bad('invalid profile: last_name may only contain letters').field,
          ProfileField.lastName);
      expect(bad('invalid profile: date_of_birth must be YYYY-MM-DD').field,
          ProfileField.dateOfBirth);
    });

    test('under-18 message (no field name) still lands on date of birth', () {
      final e = bad('invalid profile: drivers must be at least 18 years old');
      expect(e.field, ProfileField.dateOfBirth);
      expect(e.message, 'ต้องมีอายุ 18 ปีขึ้นไป');
    });

    test('409 is a lock with the support message', () {
      final e = ProfileUpdateError.from(const ApiException(409,
          message: "name and date of birth can't be changed after approval"));
      expect(e.locked, isTrue);
      expect(e.field, isNull);
      expect(e.message, ProfileUpdateError.lockedMessage);
    });
  });

  group('date of birth', () {
    test('API date is Gregorian YYYY-MM-DD, display is Thai BE', () {
      final d = DateTime(1990, 5, 17);
      expect(DriverProfileInfo.formatApiDate(d), '1990-05-17');
      expect(formatThaiDate(d), '17 พ.ค. 2533');
    });

    test('parses backend date and tolerates null/garbage', () {
      expect(DriverProfileInfo.parseApiDate('1990-05-17'), DateTime(1990, 5, 17));
      expect(DriverProfileInfo.parseApiDate(null), isNull);
      expect(DriverProfileInfo.parseApiDate('nope'), isNull);
    });

    test('step 1 complete only with first, last and date of birth', () {
      expect(
          DriverProfileInfo(firstName: 'สมชาย', lastName: 'ใจดี').isComplete,
          isFalse);
      expect(
          DriverProfileInfo(
                  firstName: 'สมชาย',
                  lastName: 'ใจดี',
                  dateOfBirth: DateTime(1990, 5, 17))
              .isComplete,
          isTrue);
    });
  });
}
