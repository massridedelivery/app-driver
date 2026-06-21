import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/wallet/domain/entities/transaction.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_status.dart';
import 'package:massdrive/features/wallet/domain/enums/transaction_type.dart';

part 'transaction_model.g.dart';

/// Data model for a single transaction item in the API response.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class TransactionModel {
  final String id;
  final String type;
  final double amount;
  final String status;
  final String description;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    String desc = json['description'] as String? ?? '';
    if (desc.isEmpty) {
      final metadataStr = json['metadata'] as String?;
      if (metadataStr != null && metadataStr.isNotEmpty) {
        try {
          final Map<String, dynamic> meta = jsonDecode(metadataStr);
          final reason = meta['reason'] as String?;
          if (reason != null && reason.isNotEmpty) {
            if (reason == 'Manual Top-up Slip Approval') {
              desc = 'เติมเงินด้วยสลิป (อนุมัติโดยระบบ)';
            } else {
              desc = reason;
            }
          }
        } catch (_) {}
      }
    }
    if (desc.isEmpty) {
      final typeStr = json['type'] as String? ?? '';
      switch (typeStr.toUpperCase()) {
        case 'FARE_PAYMENT':
          desc = 'ค่าโดยสาร';
          break;
        case 'COMMISSION_DEDUCTION':
          desc = 'ค่าคอมมิชชัน';
          break;
        case 'TOPUP':
          desc = 'เติมเงินเครดิต';
          break;
        case 'WITHDRAWAL':
          desc = 'ถอนเงินเครดิต';
          break;
        case 'BONUS':
          desc = 'โบนัสพิเศษ';
          break;
        default:
          desc = 'รายการธุรกรรม';
          break;
      }
    }

    return TransactionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      description: desc,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  Transaction toEntity() {
    return Transaction(
      id: id,
      type: TransactionType.fromString(type),
      amount: amount,
      status: TransactionStatus.fromString(status),
      description: description,
      createdAt: createdAt,
    );
  }
}

/// Data model for the full paginated transaction list response.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class TransactionListModel {
  final List<TransactionModel> transactions;
  final int total;

  const TransactionListModel({
    required this.transactions,
    required this.total,
  });

  factory TransactionListModel.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        [];
    final transactions = list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = json['total'] as int? ?? transactions.length;
    return TransactionListModel(
      transactions: transactions,
      total: total,
    );
  }

  Map<String, dynamic> toJson() => _$TransactionListModelToJson(this);

  TransactionListResult toEntity() {
    return TransactionListResult(
      transactions: transactions.map((m) => m.toEntity()).toList(),
      total: total,
    );
  }
}
