class DriverProfileInfo {
  final String firstName;
  final String lastName;
  final String email;
  final String emergencyContact;

  DriverProfileInfo({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emergencyContact,
  });

  DriverProfileInfo copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? emergencyContact,
  }) {
    return DriverProfileInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'emergencyContact': emergencyContact,
    };
  }

  factory DriverProfileInfo.fromMap(Map<String, dynamic> map) {
    return DriverProfileInfo(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      email: map['email'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
    );
  }
}
