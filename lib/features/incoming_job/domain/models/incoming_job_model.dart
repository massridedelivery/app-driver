// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'incoming_job_model.freezed.dart';
part 'incoming_job_model.g.dart';

@freezed
sealed class IncomingJobModel with _$IncomingJobModel {
  const IncomingJobModel._();

  const factory IncomingJobModel({
    @JsonKey(name: 'job_id') required String jobId,
    @JsonKey(name: 'pickup_address') required String pickupAddress,
    @JsonKey(name: 'dropoff_address') required String dropoffAddress,
    @JsonKey(name: 'pickup_address_detail') required String pickupAddressDetail,
    @JsonKey(name: 'dropoff_address_detail') required String dropoffAddressDetail,
    @JsonKey(name: 'pickup_distance_km') required double pickupDistanceKm,
    @JsonKey(name: 'dropoff_distance_km') required double dropoffDistanceKm,
    @JsonKey(name: 'pickup_lat') required double pickupLat,
    @JsonKey(name: 'pickup_lng') required double pickupLng,
    @JsonKey(name: 'dropoff_lat') required double dropoffLat,
    @JsonKey(name: 'dropoff_lng') required double dropoffLng,
    @JsonKey(name: 'net_income') required double netIncome,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    @JsonKey(name: 'points') required int points,
    @JsonKey(name: 'service_type') required String serviceType,
    @JsonKey(name: 'item_summary') required String itemSummary,
    @JsonKey(name: 'timeout_seconds') required int timeoutSeconds,
  }) = _IncomingJobModel;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) =>
      _$IncomingJobModelFromJson(json);
}
