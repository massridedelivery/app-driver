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

  // Additional fields from API
  final String? jobId;
  final String? orderId;
  final String? userId;
  final String? counterpartyId;
  final String? currency;
  final String? paymentMethod;
  final String? metadata;
  final double? commission;
  final double? discount;
  final double? platformFee;
  final double? subtotal;
  final DateTime? completedAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    required this.createdAt,
    this.jobId,
    this.orderId,
    this.userId,
    this.counterpartyId,
    this.currency,
    this.paymentMethod,
    this.metadata,
    this.commission,
    this.discount,
    this.platformFee,
    this.subtotal,
    this.completedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    // Resolve description: use field → metadata.reason → type fallback
    String desc = json['description'] as String? ?? '';
    if (desc.isEmpty) {
      final metadataStr = json['metadata'] as String?;
      if (metadataStr != null && metadataStr.isNotEmpty) {
        try {
          final Map<String, dynamic> meta = jsonDecode(metadataStr);
          final reason = meta['reason'] as String?;
          if (reason != null && reason.isNotEmpty) {
            desc = reason == 'Manual Top-up Slip Approval'
                ? 'เติมเงินด้วยสลิป (อนุมัติโดยระบบ)'
                : reason;
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

    DateTime? parseDate(String? s) =>
        s != null && s.isNotEmpty ? DateTime.tryParse(s) : null;

    return TransactionModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      description: desc,
      createdAt: parseDate(json['created_at'] as String?) ?? DateTime.now(),
      jobId: json['job_id'] as String?,
      orderId: json['order_id'] as String?,
      userId: json['user_id'] as String?,
      counterpartyId: json['counterparty_id'] as String?,
      currency: json['currency'] as String?,
      paymentMethod: json['payment_method'] as String?,
      metadata: json['metadata'] as String?,
      commission: (json['commission'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      platformFee: (json['platform_fee'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      completedAt: parseDate(json['completed_at'] as String?),
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
      jobId: jobId,
      orderId: orderId,
      userId: userId,
      counterpartyId: counterpartyId,
      currency: currency,
      paymentMethod: paymentMethod,
      metadata: metadata,
      commission: commission,
      discount: discount,
      platformFee: platformFee,
      subtotal: subtotal,
      completedAt: completedAt,
    );
  }
}

/// Data model for the full paginated transaction list response.
@JsonSerializable(createFactory: false, fieldRename: FieldRename.snake)
class TransactionListModel {
  final List<TransactionModel> transactions;
  final int total;
  final int limit;
  final int offset;

  const TransactionListModel({
    required this.transactions,
    required this.total,
    this.limit = 20,
    this.offset = 0,
  });

  factory TransactionListModel.fromJson(Map<String, dynamic> json) {
    final list = (json['transactions'] as List<dynamic>?) ??
        (json['data'] as List<dynamic>?) ??
        [];
    final transactions = list
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return TransactionListModel(
      transactions: transactions,
      total: json['total'] as int? ?? transactions.length,
      limit: json['limit'] as int? ?? 20,
      offset: json['offset'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$TransactionListModelToJson(this);

  TransactionListResult toEntity() {
    return TransactionListResult(
      transactions: transactions.map((m) => m.toEntity()).toList(),
      total: total,
      limit: limit,
      offset: offset,
    );
  }
}

