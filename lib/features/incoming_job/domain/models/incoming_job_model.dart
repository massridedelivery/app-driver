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
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'fare') required double netIncome,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'points') @Default(0) int points,
    @JsonKey(name: 'service_type') @Default('Saver Bike') String serviceType,
    @JsonKey(name: 'passenger_name') @Default('Passenger') String passengerName,
    @JsonKey(name: 'item_summary') @Default('') String itemSummary,
    @JsonKey(name: 'timeout_seconds') @Default(30) int timeoutSeconds,
    @JsonKey(name: 'surge_multiplier') @Default(1.0) double surgeMultiplier,
    @JsonKey(name: 'surge_active') @Default(false) bool surgeActive,
    @JsonKey(name: 'is_scheduled') @Default(false) bool isScheduled,
    @JsonKey(name: 'scheduled_at') String? scheduledAt,
  }) = _IncomingJobModel;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) =>
      _$IncomingJobModelFromJson(json);
}
