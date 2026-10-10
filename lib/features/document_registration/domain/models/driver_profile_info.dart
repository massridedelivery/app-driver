class DriverProfileInfo {
  final String firstName;
  final String lastName;

  /// Date of birth (date only). Sent as `YYYY-MM-DD` (Gregorian) and shown to
  /// the driver in Thai Buddhist-era form.
  final DateTime? dateOfBirth;
  final String email;
  final String emergencyContact;

  DriverProfileInfo({
    required this.firstName,
    required this.lastName,
    this.dateOfBirth,
    this.email = '',
    this.emergencyContact = '',
  });

  /// Step 1 is complete once first name, last name and date of birth are set.
  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      dateOfBirth != null;

  DriverProfileInfo copyWith({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? email,
    String? emergencyContact,
  }) {
    return DriverProfileInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      email: email ?? this.email,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  /// `YYYY-MM-DD` in the Gregorian calendar, as the backend expects.
  static String formatApiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Parse the backend's `YYYY-MM-DD` (null/invalid → null).
  static DateTime? parseApiDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final d = DateTime.tryParse(s.trim());
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }
}
