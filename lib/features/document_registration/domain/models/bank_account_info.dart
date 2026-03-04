class BankAccountInfo {
  final String bankName;
  final String accountName;
  final String accountNumber;

  BankAccountInfo({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
  });

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
