import 'package:json_annotation/json_annotation.dart';
import 'package:massdrive/features/messenger/domain/models/messenger_status.dart';

part 'messenger_order.g.dart';

/// Canonical messenger Order (SCRUM-41 §5). Full detail for the active/live
/// screen. Optional (`?`) fields are omitempty — nullable/defaulted so parsing
/// never throws.
@JsonSerializable(createFactory: true, createToJson: false, fieldRename: FieldRename.snake)
class MessengerOrder {
  @JsonKey(defaultValue: '')
  final String id;
  @JsonKey(defaultValue: '')
  final String customerId;
  final String? driverId;
  @JsonKey(defaultValue: '')
  final String vehicleTypeId;
  @JsonKey(defaultValue: 'PENDING')
  final String status;

  @JsonKey(defaultValue: 0.0)
  final double pickupLat;
  @JsonKey(defaultValue: 0.0)
  final double pickupLng;
  final String? pickupAddress;
  @JsonKey(defaultValue: 0.0)
  final double dropoffLat;
  @JsonKey(defaultValue: 0.0)
  final double dropoffLng;
  final String? dropoffAddress;

  final String? recipientName;
  final String? recipientPhone;

  @JsonKey(defaultValue: '')
  final String packageSizeTier;
  @JsonKey(defaultValue: 0.0)
  final double packageWeightKg;
  final double? packageLengthCm;
  final double? packageWidthCm;
  final double? packageHeightCm;
  final String? notes;

  @JsonKey(defaultValue: 0.0)
  final double codAmount;
  @JsonKey(defaultValue: 'CASH')
  final String paymentMethod;

  @JsonKey(defaultValue: 0.0)
  final double distanceKm;
  @JsonKey(defaultValue: 0.0)
  final double fare;
  @JsonKey(defaultValue: 0.0)
  final double discount;
  @JsonKey(defaultValue: 0.0)
  final double platformCommission;
  final String? promoId;

  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAtPickupAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;

  const MessengerOrder({
    this.id = '',
    this.customerId = '',
    this.driverId,
    this.vehicleTypeId = '',
    this.status = 'PENDING',
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.pickupAddress,
    this.dropoffLat = 0.0,
    this.dropoffLng = 0.0,
    this.dropoffAddress,
    this.recipientName,
    this.recipientPhone,
    this.packageSizeTier = '',
    this.packageWeightKg = 0.0,
    this.packageLengthCm,
    this.packageWidthCm,
    this.packageHeightCm,
    this.notes,
    this.codAmount = 0.0,
    this.paymentMethod = 'CASH',
    this.distanceKm = 0.0,
    this.fare = 0.0,
    this.discount = 0.0,
    this.platformCommission = 0.0,
    this.promoId,
    this.createdAt,
    this.acceptedAt,
    this.arrivedAtPickupAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
  });

  factory MessengerOrder.fromJson(Map<String, dynamic> json) =>
      _$MessengerOrderFromJson(json);

  MessengerStatus get statusEnum => MessengerStatus.fromApi(status);
  bool get isCod => paymentMethod.toUpperCase() == 'COD';

  /// Net the customer pays (gross fare minus platform-funded promo).
  double get customerPayable => fare - discount;
}
