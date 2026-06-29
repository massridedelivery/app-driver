import 'package:json_annotation/json_annotation.dart';
import '../../domain/models/history_item_model.dart';

part 'history_item_api_model.g.dart';

@JsonSerializable()
class HistoryItemApiModel {
  // /transactions fields
  final String? id;
  final String? type; // "payout", "topup", "earning"
  final double? amount;
  final String? status; // "completed", "pending", "failed"
  final String? description;
  @JsonKey(name: 'created_at')
  final String? createdAt;

  // Legacy /trips fields (fallback)
  @JsonKey(name: 'job_id')
  final String? jobId;
  @JsonKey(name: 'completed_at')
  final String? completedAt;
  final double? earnings;
  @JsonKey(name: 'distance_km')
  final double? distanceKm;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  final String? title;

  HistoryItemApiModel({
    this.id,
    this.type,
    this.amount,
    this.status,
    this.description,
    this.createdAt,
    this.jobId,
    this.completedAt,
    this.earnings,
    this.distanceKm,
    this.paymentMethod,
    this.title,
  });

  factory HistoryItemApiModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemApiModelToJson(this);

  HistoryItemModel toEntity() {
    final effectiveId = id ?? jobId ?? '';
    final effectiveDateStr = createdAt ?? completedAt;
    final effectiveDate = effectiveDateStr != null
        ? (DateTime.tryParse(effectiveDateStr) ?? DateTime.now())
        : DateTime.now();
    final effectiveAmount = amount ?? earnings;
    final rawDescription = description ?? title ?? _typeLabel(type);
    final effectiveTitle = _formatDescription(rawDescription, type);
    final effectiveStatus = _parseStatus(status);

    // Determine service type: payout/topup = ride icon, food type = food icon
    final effectiveServiceType = type?.toLowerCase() == 'food'
        ? ServiceType.food
        : ServiceType.ride;

    return HistoryItemModel(
      id: effectiveId,
      dateTime: effectiveDate,
      title: effectiveTitle,
      amount: effectiveAmount,
      paymentType: _parsePaymentType(paymentMethod),
      status: effectiveStatus,
      serviceType: effectiveServiceType,
      rawType: type,
    );
  }

  static String _formatDescription(String desc, String? apiType) {
    if (desc.isEmpty) {
      return _typeLabel(apiType);
    }
    
    // Find UUIDs (8-4-4-4-12 hex chars) and shorten them
    final uuidRegex = RegExp(r'[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}');
    
    String formatted = desc;
    final match = uuidRegex.firstMatch(desc);
    if (match != null) {
      final fullUuid = match.group(0)!;
      final shortUuid = fullUuid.substring(0, 6);
      formatted = desc.replaceAll(fullUuid, shortUuid);
    }
    
    // Translate common English patterns to nice Thai labels
    if (formatted.toLowerCase().startsWith('commission for #job-')) {
      formatted = formatted.replaceAll(
            RegExp(r'commission for #job-', caseSensitive: false),
            'ค่าคอมมิชชัน (งาน #',
          ) +
          ')';
    } else if (formatted.toLowerCase().startsWith('trip #job-')) {
      formatted = formatted.replaceAll(
        RegExp(r'trip #job-', caseSensitive: false),
        'รายได้จากงาน #',
      );
    } else if (formatted.toLowerCase() == 'topup') {
      formatted = 'เติมเงินเครดิต';
    } else if (formatted.toLowerCase() == 'withdrawal') {
      formatted = 'ถอนเงินเครดิต';
    }
    
    return formatted;
  }

  static String _typeLabel(String? type) {
    switch (type?.toLowerCase()) {
      case 'payout':
        return 'ถอนเงิน';
      case 'topup':
        return 'เติมเงิน';
      case 'earning':
        return 'รายได้จากงาน';
      default:
        return type ?? '-';
    }
  }

  static PaymentType? _parsePaymentType(String? value) {
    if (value == null) return null;
    switch (value.toUpperCase()) {
      case 'CASH':
        return PaymentType.cash;
      case 'GRAB_PAY':
      case 'QR_PAYMENT':
      default:
        return PaymentType.grabPay;
    }
  }

  static HistoryStatus _parseStatus(String? value) {
    if (value?.toLowerCase() == 'cancelled' ||
        value?.toLowerCase() == 'failed' ||
        value?.toLowerCase() == 'rejected') {
      return HistoryStatus.cancelled;
    }
    return HistoryStatus.completed;
  }
}

class HistoryListResponseModel {
  final List<HistoryItemApiModel> data;
  final int offset;
  final int limit;
  final int total;

  HistoryListResponseModel({
    required this.data,
    required this.offset,
    required this.limit,
    required this.total,
  });

  factory HistoryListResponseModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] ?? json['data'];
    final list = rawList is List ? rawList : <dynamic>[];
    final items = list
        .map((e) {
          if (e is Map) {
            return HistoryItemApiModel.fromJson(Map<String, dynamic>.from(e));
          }
          return null;
        })
        .whereType<HistoryItemApiModel>()
        .toList();

    return HistoryListResponseModel(
      data: items,
      offset: _parseInt(json['offset']),
      limit: _parseInt(json['limit'], defaultValue: 20),
      total: _parseInt(json['total']),
    );
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}

