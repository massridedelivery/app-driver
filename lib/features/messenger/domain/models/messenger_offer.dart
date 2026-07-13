import 'package:json_annotation/json_annotation.dart';

part 'messenger_offer.g.dart';

/// Messenger offer payload (SCRUM-41 §5 OfferWSResponse) — the `order` body of
/// a `messenger_offer` WS event and the `active-offer` recovery response.
/// Intentionally carries NO recipient PII.
@JsonSerializable(createFactory: true, createToJson: false, fieldRename: FieldRename.snake)
class MessengerOffer {
  @JsonKey(defaultValue: '')
  final String id;
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
  @JsonKey(defaultValue: 0.0)
  final double distanceKm;
  @JsonKey(defaultValue: 0.0)
  final double fare;
  @JsonKey(defaultValue: '')
  final String packageSizeTier;
  @JsonKey(defaultValue: 0.0)
  final double codAmount;
  @JsonKey(defaultValue: 'CASH')
  final String paymentMethod;

  const MessengerOffer({
    this.id = '',
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.pickupAddress,
    this.dropoffLat = 0.0,
    this.dropoffLng = 0.0,
    this.dropoffAddress,
    this.distanceKm = 0.0,
    this.fare = 0.0,
    this.packageSizeTier = '',
    this.codAmount = 0.0,
    this.paymentMethod = 'CASH',
  });

  factory MessengerOffer.fromJson(Map<String, dynamic> json) =>
      _$MessengerOfferFromJson(json);

  bool get isCod => paymentMethod.toUpperCase() == 'COD';
}
