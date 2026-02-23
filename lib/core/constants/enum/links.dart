import 'package:json_annotation/json_annotation.dart';

enum DestinationType {
  @JsonValue(1)
  deeplink,
  @JsonValue(2)
  scheme,
  @JsonValue(3)
  internal,
  @JsonValue(4)
  external,
}

extension DestinationTypeExtension on DestinationType {
  String get value => ['external', 'internal', 'deeplink', 'scheme'][index];
}
