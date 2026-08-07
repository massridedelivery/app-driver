import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/history_entity.dart';

part 'history_model.g.dart';

@JsonSerializable()
class HistoryModel {
  final String id;

  @JsonKey(name: 'date_time')
  final String dateTime;

  @JsonKey(name: 'pickup_address')
  final String pickupAddress;

  @JsonKey(name: 'dropoff_address')
  final String dropoffAddress;

  @JsonKey(name: 'distance_km')
  final double distanceKm;

  @JsonKey(name: 'duration_minute')
  final int durationMinute;

  final double total;

  @JsonKey(name: 'payment_method')
  final String paymentMethod;

  @JsonKey(name: 'driver_net')
  final double driverNet;

  @JsonKey(name: 'pickup_lat')
  final double? pickupLat;

  @JsonKey(name: 'pickup_lng')
  final double? pickupLng;

  @JsonKey(name: 'dropoff_lat')
  final double? dropoffLat;

  @JsonKey(name: 'dropoff_lng')
  final double? dropoffLng;

  HistoryModel({
    required this.id,
    required this.dateTime,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.durationMinute,
    required this.total,
    required this.paymentMethod,
    required this.driverNet,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  /// ---------- JSON ----------

  factory HistoryModel.fromJson(Map<String, dynamic> json) =>
      _$HistoryModelFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryModelToJson(this);

  /// ---------- Entity Mapping ----------

  HistoryDetailEntity toEntity() {
    return HistoryDetailEntity(
      id: id,
      dateTime: DateTime.parse(dateTime),
      pickupAddress: pickupAddress,
      dropoffAddress: dropoffAddress,
      distanceKm: distanceKm,
      durationMinute: durationMinute,
      total: total,
      paymentMethod: paymentMethod,
      driverNet: driverNet,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
    );
  }

  /// ---------- Factory from Entity (Optional for caching) ----------

  factory HistoryModel.fromEntity(HistoryDetailEntity entity) {
    return HistoryModel(
      id: entity.id,
      dateTime: entity.dateTime.toIso8601String(),
      pickupAddress: entity.pickupAddress,
      dropoffAddress: entity.dropoffAddress,
      distanceKm: entity.distanceKm,
      durationMinute: entity.durationMinute,
      total: entity.total,
      paymentMethod: entity.paymentMethod,
      driverNet: entity.driverNet,
      pickupLat: entity.pickupLat,
      pickupLng: entity.pickupLng,
      dropoffLat: entity.dropoffLat,
      dropoffLng: entity.dropoffLng,
    );
  }
}
