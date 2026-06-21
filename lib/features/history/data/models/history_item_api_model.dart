import 'package:json_annotation/json_annotation.dart';
import '../../domain/models/history_item_model.dart';

part 'history_item_api_model.g.dart';

@JsonSerializable()
class HistoryItemApiModel {
  @JsonKey(name: 'job_id')
  final String jobId;

  @JsonKey(name: 'completed_at')
  final String completedAt;

  final double? earnings;

  @JsonKey(name: 'distance_km')
  final double? distanceKm;

  @JsonKey(name: 'payment_method')
  final String? paymentMethod;

  final String type; // "RIDE" or "FOOD"

  final String title;

  final String? status; // "COMPLETED", "CANCELLED", etc.

  HistoryItemApiModel({
    required this.jobId,
    required this.completedAt,
    this.earnings,
    this.distanceKm,
    this.paymentMethod,
    required this.type,
    required this.title,
    this.status,
  });

  factory HistoryItemApiModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemApiModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemApiModelToJson(this);

  HistoryItemModel toEntity() {
    return HistoryItemModel(
      id: jobId,
      dateTime: DateTime.tryParse(completedAt) ?? DateTime.now(),
      title: title,
      amount: earnings,
      paymentType: _parsePaymentType(paymentMethod),
      status: _parseStatus(status),
      serviceType: type.toUpperCase() == 'FOOD' ? ServiceType.food : ServiceType.ride,
    );
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
    if (value?.toUpperCase() == 'CANCELLED') {
      return HistoryStatus.cancelled;
    }
    return HistoryStatus.completed;
  }
}

@JsonSerializable()
class HistoryListResponseModel {
  final List<HistoryItemApiModel> data;
  final int page;
  final int limit;
  final int total;

  HistoryListResponseModel({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory HistoryListResponseModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryListResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryListResponseModelToJson(this);
}
