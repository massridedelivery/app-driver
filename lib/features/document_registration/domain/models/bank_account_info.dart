import 'package:massdrive/core/constants/thai_banks.dart';

class BankAccountInfo {
  /// Bank of Thailand code from the backend (e.g. "004"); older records may
  /// still hold a name or short code ("kbank").
  final String bankName;
  final String accountName;
  final String accountNumber;

  /// Thai bank name from `GET /api/driver/payouts/method`
  /// (`bank_display_name`), when the backend sends it.
  final String? bankDisplayName;

  BankAccountInfo({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    this.bankDisplayName,
  });

  /// Name to show the driver: the backend's display name, else our own
  /// lookup of the stored code/name, else the raw value.
  String get bankLabel {
    final display = bankDisplayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    return findThaiBank(bankName)?.nameLong ?? bankName;
  }

  BankAccountInfo copyWith({
    String? bankName,
    String? accountName,
    String? accountNumber,
  }) {
    return BankAccountInfo(
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountName': accountName,
      'accountNumber': accountNumber,
    };
  }

  factory BankAccountInfo.fromMap(Map<String, dynamic> map) {
    return BankAccountInfo(
      bankName: map['bankName'] ?? '',
      accountName: map['accountName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
    );
  }
}
