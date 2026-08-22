// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'incoming_job_model.freezed.dart';
part 'incoming_job_model.g.dart';

@freezed
sealed class IncomingJobModel with _$IncomingJobModel {
  const IncomingJobModel._();

  const factory IncomingJobModel({
    @JsonKey(name: 'id') required String jobId,
    @JsonKey(name: 'pickup_address') required String pickupAddress,
    @JsonKey(name: 'dropoff_address') required String dropoffAddress,
    @JsonKey(name: 'pickup_address_detail')
    @Default('')
    String pickupAddressDetail,
    @JsonKey(name: 'dropoff_address_detail')
    @Default('')
    String dropoffAddressDetail,
    @JsonKey(name: 'pickup_distance_km') @Default(0.0) double pickupDistanceKm,
    @JsonKey(name: 'dropoff_distance_km')
    @Default(0.0)
    double dropoffDistanceKm,
    @JsonKey(name: 'distance_km') double? distanceKm,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'encoded_polyline', readValue: readPolyline)
    String? encodedPolyline,
    @JsonKey(name: 'fare') required double netIncome,
    // Amount the driver must actually COLLECT at the end (fare + tolls + waiting
    // that accrued en route) — distinct from the display `fare`. Collecting
    // `fare` under-charges (SCRUM-86 §6). Null until BE ships it.
    @JsonKey(name: 'amount_due') double? amountDue,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'points') @Default(0) int points,
    @JsonKey(name: 'service_type') @Default('Saver Bike') String serviceType,
    @JsonKey(name: 'passenger_name', readValue: readCustomerName)
    @Default('Passenger')
    String passengerName,
    // Customer phone for the in-trip "call" button. Backend sends it either flat
    // (passenger_phone) or nested under customer.phone (JobCustomerInfo).
    @JsonKey(name: 'passenger_phone', readValue: readCustomerPhone)
    @Default('')
    String passengerPhone,
    @JsonKey(name: 'item_summary') @Default('') String itemSummary,
    @JsonKey(name: 'timeout_seconds') @Default(16) int timeoutSeconds,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'surge_active') @Default(false) bool surgeActive,
    @JsonKey(name: 'is_scheduled') @Default(false) bool isScheduled,
    @JsonKey(name: 'scheduled_at') String? scheduledAt,

    // Food Delivery fields
    @JsonKey(name: 'restaurant_name') String? restaurantName,
    @JsonKey(name: 'delivery_fee') @Default(0.0) double deliveryFee,
    @JsonKey(name: 'subtotal') @Default(0.0) double subtotal,
    @JsonKey(name: 'order_items')
    @Default([])
    List<Map<String, dynamic>> orderItems,
  }) = _IncomingJobModel;

  /// Whether this job is a food delivery order
  bool get isFood =>
      serviceType.toLowerCase().contains('food') || orderItems.isNotEmpty;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) =>
      _$IncomingJobModelFromJson(json);
}

/// The route's encoded polyline (pickup→drop-off). BE ships it under a few
/// keys across offer/active-job endpoints (SCRUM-66) — accept any so the offer
/// map draws the real road route instead of the Google-Directions fallback.
Object? readPolyline(Map json, String key) =>
    json['encoded_polyline'] ?? json['polyline'] ?? json['overview_polyline'];

/// Reads the customer name from either a flat `passenger_name` field or the
/// nested `customer.full_name` (JobCustomerInfo) the backend actually sends.
Object? readCustomerName(Map json, String key) {
  final flat = json['passenger_name'];
  if (flat != null && flat.toString().isNotEmpty) return flat;
  final customer = json['customer'];
  if (customer is Map) return customer['full_name'];
  return null;
}

/// Reads the customer phone from either a flat `passenger_phone` field or the
/// nested `customer.phone` / `customer_phone` the backend actually sends.
Object? readCustomerPhone(Map json, String key) {
  final flat = json['passenger_phone'] ?? json['customer_phone'];
  if (flat != null && flat.toString().isNotEmpty) return flat;
  final customer = json['customer'];
  if (customer is Map) return customer['phone'];
  return null;
}
