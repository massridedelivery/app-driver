import 'package:freezed_annotation/freezed_annotation.dart';

part 'incoming_job_model.freezed.dart';
part 'incoming_job_model.g.dart';

@freezed
sealed class IncomingJobModel with _$IncomingJobModel {
  const IncomingJobModel._();

  const factory IncomingJobModel({
    required String jobId,
    required String pickupAddress,
    required String dropoffAddress,
    required String pickupAddressDetail, // Added for new UI
    required String dropoffAddressDetail, // Added for new UI
    required double pickupDistanceKm,
    required double dropoffDistanceKm,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    required double netIncome, // Added for new UI
    required String paymentMethod, // Added for new UI
    required int points, // Added for new UI
    required String serviceType, // Added for new UI
    required String itemSummary, // Added for new UI
    required int timeoutSeconds,
  }) = _IncomingJobModel;

  factory IncomingJobModel.fromJson(Map<String, dynamic> json) =>
      _$IncomingJobModelFromJson(json);
}
