// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incoming_job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IncomingJobModel {

@JsonKey(name: 'id') String get jobId;@JsonKey(name: 'pickup_address') String get pickupAddress;@JsonKey(name: 'dropoff_address') String get dropoffAddress;@JsonKey(name: 'pickup_address_detail') String get pickupAddressDetail;@JsonKey(name: 'dropoff_address_detail') String get dropoffAddressDetail;@JsonKey(name: 'pickup_distance_km') double get pickupDistanceKm;@JsonKey(name: 'dropoff_distance_km') double get dropoffDistanceKm;@JsonKey(name: 'pickup_lat') double get pickupLat;@JsonKey(name: 'pickup_lng') double get pickupLng;@JsonKey(name: 'dropoff_lat') double get dropoffLat;@JsonKey(name: 'dropoff_lng') double get dropoffLng;@JsonKey(name: 'fare') double get netIncome;@JsonKey(name: 'payment_method') String get paymentMethod;@JsonKey(name: 'points') int get points;@JsonKey(name: 'service_type') String get serviceType;@JsonKey(name: 'passenger_name') String get passengerName;@JsonKey(name: 'item_summary') String get itemSummary;@JsonKey(name: 'timeout_seconds') int get timeoutSeconds;@JsonKey(name: 'surge_multiplier') double get surgeMultiplier;@JsonKey(name: 'surge_active') bool get surgeActive;@JsonKey(name: 'is_scheduled') bool get isScheduled;@JsonKey(name: 'scheduled_at') String? get scheduledAt;
/// Create a copy of IncomingJobModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingJobModelCopyWith<IncomingJobModel> get copyWith => _$IncomingJobModelCopyWithImpl<IncomingJobModel>(this as IncomingJobModel, _$identity);

  /// Serializes this IncomingJobModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingJobModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.pickupAddressDetail, pickupAddressDetail) || other.pickupAddressDetail == pickupAddressDetail)&&(identical(other.dropoffAddressDetail, dropoffAddressDetail) || other.dropoffAddressDetail == dropoffAddressDetail)&&(identical(other.pickupDistanceKm, pickupDistanceKm) || other.pickupDistanceKm == pickupDistanceKm)&&(identical(other.dropoffDistanceKm, dropoffDistanceKm) || other.dropoffDistanceKm == dropoffDistanceKm)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.points, points) || other.points == points)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.itemSummary, itemSummary) || other.itemSummary == itemSummary)&&(identical(other.timeoutSeconds, timeoutSeconds) || other.timeoutSeconds == timeoutSeconds)&&(identical(other.surgeMultiplier, surgeMultiplier) || other.surgeMultiplier == surgeMultiplier)&&(identical(other.surgeActive, surgeActive) || other.surgeActive == surgeActive)&&(identical(other.isScheduled, isScheduled) || other.isScheduled == isScheduled)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,jobId,pickupAddress,dropoffAddress,pickupAddressDetail,dropoffAddressDetail,pickupDistanceKm,dropoffDistanceKm,pickupLat,pickupLng,dropoffLat,dropoffLng,netIncome,paymentMethod,points,serviceType,passengerName,itemSummary,timeoutSeconds,surgeMultiplier,surgeActive,isScheduled,scheduledAt]);

@override
String toString() {
  return 'IncomingJobModel(jobId: $jobId, pickupAddress: $pickupAddress, dropoffAddress: $dropoffAddress, pickupAddressDetail: $pickupAddressDetail, dropoffAddressDetail: $dropoffAddressDetail, pickupDistanceKm: $pickupDistanceKm, dropoffDistanceKm: $dropoffDistanceKm, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, netIncome: $netIncome, paymentMethod: $paymentMethod, points: $points, serviceType: $serviceType, passengerName: $passengerName, itemSummary: $itemSummary, timeoutSeconds: $timeoutSeconds, surgeMultiplier: $surgeMultiplier, surgeActive: $surgeActive, isScheduled: $isScheduled, scheduledAt: $scheduledAt)';
}


}

/// @nodoc
abstract mixin class $IncomingJobModelCopyWith<$Res>  {
  factory $IncomingJobModelCopyWith(IncomingJobModel value, $Res Function(IncomingJobModel) _then) = _$IncomingJobModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String jobId,@JsonKey(name: 'pickup_address') String pickupAddress,@JsonKey(name: 'dropoff_address') String dropoffAddress,@JsonKey(name: 'pickup_address_detail') String pickupAddressDetail,@JsonKey(name: 'dropoff_address_detail') String dropoffAddressDetail,@JsonKey(name: 'pickup_distance_km') double pickupDistanceKm,@JsonKey(name: 'dropoff_distance_km') double dropoffDistanceKm,@JsonKey(name: 'pickup_lat') double pickupLat,@JsonKey(name: 'pickup_lng') double pickupLng,@JsonKey(name: 'dropoff_lat') double dropoffLat,@JsonKey(name: 'dropoff_lng') double dropoffLng,@JsonKey(name: 'fare') double netIncome,@JsonKey(name: 'payment_method') String paymentMethod,@JsonKey(name: 'points') int points,@JsonKey(name: 'service_type') String serviceType,@JsonKey(name: 'passenger_name') String passengerName,@JsonKey(name: 'item_summary') String itemSummary,@JsonKey(name: 'timeout_seconds') int timeoutSeconds,@JsonKey(name: 'surge_multiplier') double surgeMultiplier,@JsonKey(name: 'surge_active') bool surgeActive,@JsonKey(name: 'is_scheduled') bool isScheduled,@JsonKey(name: 'scheduled_at') String? scheduledAt
});




}
/// @nodoc
class _$IncomingJobModelCopyWithImpl<$Res>
    implements $IncomingJobModelCopyWith<$Res> {
  _$IncomingJobModelCopyWithImpl(this._self, this._then);

  final IncomingJobModel _self;
  final $Res Function(IncomingJobModel) _then;

/// Create a copy of IncomingJobModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? pickupAddress = null,Object? dropoffAddress = null,Object? pickupAddressDetail = null,Object? dropoffAddressDetail = null,Object? pickupDistanceKm = null,Object? dropoffDistanceKm = null,Object? pickupLat = null,Object? pickupLng = null,Object? dropoffLat = null,Object? dropoffLng = null,Object? netIncome = null,Object? paymentMethod = null,Object? points = null,Object? serviceType = null,Object? passengerName = null,Object? itemSummary = null,Object? timeoutSeconds = null,Object? surgeMultiplier = null,Object? surgeActive = null,Object? isScheduled = null,Object? scheduledAt = freezed,}) {
  return _then(_self.copyWith(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,pickupAddress: null == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String,dropoffAddress: null == dropoffAddress ? _self.dropoffAddress : dropoffAddress // ignore: cast_nullable_to_non_nullable
as String,pickupAddressDetail: null == pickupAddressDetail ? _self.pickupAddressDetail : pickupAddressDetail // ignore: cast_nullable_to_non_nullable
as String,dropoffAddressDetail: null == dropoffAddressDetail ? _self.dropoffAddressDetail : dropoffAddressDetail // ignore: cast_nullable_to_non_nullable
as String,pickupDistanceKm: null == pickupDistanceKm ? _self.pickupDistanceKm : pickupDistanceKm // ignore: cast_nullable_to_non_nullable
as double,dropoffDistanceKm: null == dropoffDistanceKm ? _self.dropoffDistanceKm : dropoffDistanceKm // ignore: cast_nullable_to_non_nullable
as double,pickupLat: null == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double,pickupLng: null == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double,dropoffLat: null == dropoffLat ? _self.dropoffLat : dropoffLat // ignore: cast_nullable_to_non_nullable
as double,dropoffLng: null == dropoffLng ? _self.dropoffLng : dropoffLng // ignore: cast_nullable_to_non_nullable
as double,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,serviceType: null == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,itemSummary: null == itemSummary ? _self.itemSummary : itemSummary // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,surgeMultiplier: null == surgeMultiplier ? _self.surgeMultiplier : surgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,surgeActive: null == surgeActive ? _self.surgeActive : surgeActive // ignore: cast_nullable_to_non_nullable
as bool,isScheduled: null == isScheduled ? _self.isScheduled : isScheduled // ignore: cast_nullable_to_non_nullable
as bool,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [IncomingJobModel].
extension IncomingJobModelPatterns on IncomingJobModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomingJobModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomingJobModel value)  $default,){
final _that = this;
switch (_that) {
case _IncomingJobModel():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomingJobModel value)?  $default,){
final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String jobId, @JsonKey(name: 'pickup_address')  String pickupAddress, @JsonKey(name: 'dropoff_address')  String dropoffAddress, @JsonKey(name: 'pickup_address_detail')  String pickupAddressDetail, @JsonKey(name: 'dropoff_address_detail')  String dropoffAddressDetail, @JsonKey(name: 'pickup_distance_km')  double pickupDistanceKm, @JsonKey(name: 'dropoff_distance_km')  double dropoffDistanceKm, @JsonKey(name: 'pickup_lat')  double pickupLat, @JsonKey(name: 'pickup_lng')  double pickupLng, @JsonKey(name: 'dropoff_lat')  double dropoffLat, @JsonKey(name: 'dropoff_lng')  double dropoffLng, @JsonKey(name: 'fare')  double netIncome, @JsonKey(name: 'payment_method')  String paymentMethod, @JsonKey(name: 'points')  int points, @JsonKey(name: 'service_type')  String serviceType, @JsonKey(name: 'passenger_name')  String passengerName, @JsonKey(name: 'item_summary')  String itemSummary, @JsonKey(name: 'timeout_seconds')  int timeoutSeconds, @JsonKey(name: 'surge_multiplier')  double surgeMultiplier, @JsonKey(name: 'surge_active')  bool surgeActive, @JsonKey(name: 'is_scheduled')  bool isScheduled, @JsonKey(name: 'scheduled_at')  String? scheduledAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.passengerName,_that.itemSummary,_that.timeoutSeconds,_that.surgeMultiplier,_that.surgeActive,_that.isScheduled,_that.scheduledAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String jobId, @JsonKey(name: 'pickup_address')  String pickupAddress, @JsonKey(name: 'dropoff_address')  String dropoffAddress, @JsonKey(name: 'pickup_address_detail')  String pickupAddressDetail, @JsonKey(name: 'dropoff_address_detail')  String dropoffAddressDetail, @JsonKey(name: 'pickup_distance_km')  double pickupDistanceKm, @JsonKey(name: 'dropoff_distance_km')  double dropoffDistanceKm, @JsonKey(name: 'pickup_lat')  double pickupLat, @JsonKey(name: 'pickup_lng')  double pickupLng, @JsonKey(name: 'dropoff_lat')  double dropoffLat, @JsonKey(name: 'dropoff_lng')  double dropoffLng, @JsonKey(name: 'fare')  double netIncome, @JsonKey(name: 'payment_method')  String paymentMethod, @JsonKey(name: 'points')  int points, @JsonKey(name: 'service_type')  String serviceType, @JsonKey(name: 'passenger_name')  String passengerName, @JsonKey(name: 'item_summary')  String itemSummary, @JsonKey(name: 'timeout_seconds')  int timeoutSeconds, @JsonKey(name: 'surge_multiplier')  double surgeMultiplier, @JsonKey(name: 'surge_active')  bool surgeActive, @JsonKey(name: 'is_scheduled')  bool isScheduled, @JsonKey(name: 'scheduled_at')  String? scheduledAt)  $default,) {final _that = this;
switch (_that) {
case _IncomingJobModel():
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.passengerName,_that.itemSummary,_that.timeoutSeconds,_that.surgeMultiplier,_that.surgeActive,_that.isScheduled,_that.scheduledAt);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String jobId, @JsonKey(name: 'pickup_address')  String pickupAddress, @JsonKey(name: 'dropoff_address')  String dropoffAddress, @JsonKey(name: 'pickup_address_detail')  String pickupAddressDetail, @JsonKey(name: 'dropoff_address_detail')  String dropoffAddressDetail, @JsonKey(name: 'pickup_distance_km')  double pickupDistanceKm, @JsonKey(name: 'dropoff_distance_km')  double dropoffDistanceKm, @JsonKey(name: 'pickup_lat')  double pickupLat, @JsonKey(name: 'pickup_lng')  double pickupLng, @JsonKey(name: 'dropoff_lat')  double dropoffLat, @JsonKey(name: 'dropoff_lng')  double dropoffLng, @JsonKey(name: 'fare')  double netIncome, @JsonKey(name: 'payment_method')  String paymentMethod, @JsonKey(name: 'points')  int points, @JsonKey(name: 'service_type')  String serviceType, @JsonKey(name: 'passenger_name')  String passengerName, @JsonKey(name: 'item_summary')  String itemSummary, @JsonKey(name: 'timeout_seconds')  int timeoutSeconds, @JsonKey(name: 'surge_multiplier')  double surgeMultiplier, @JsonKey(name: 'surge_active')  bool surgeActive, @JsonKey(name: 'is_scheduled')  bool isScheduled, @JsonKey(name: 'scheduled_at')  String? scheduledAt)?  $default,) {final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.passengerName,_that.itemSummary,_that.timeoutSeconds,_that.surgeMultiplier,_that.surgeActive,_that.isScheduled,_that.scheduledAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncomingJobModel extends IncomingJobModel {
  const _IncomingJobModel({@JsonKey(name: 'id') required this.jobId, @JsonKey(name: 'pickup_address') required this.pickupAddress, @JsonKey(name: 'dropoff_address') required this.dropoffAddress, @JsonKey(name: 'pickup_address_detail') this.pickupAddressDetail = '', @JsonKey(name: 'dropoff_address_detail') this.dropoffAddressDetail = '', @JsonKey(name: 'pickup_distance_km') this.pickupDistanceKm = 0.0, @JsonKey(name: 'dropoff_distance_km') this.dropoffDistanceKm = 0.0, @JsonKey(name: 'pickup_lat') required this.pickupLat, @JsonKey(name: 'pickup_lng') required this.pickupLng, @JsonKey(name: 'dropoff_lat') required this.dropoffLat, @JsonKey(name: 'dropoff_lng') required this.dropoffLng, @JsonKey(name: 'fare') required this.netIncome, @JsonKey(name: 'payment_method') required this.paymentMethod, @JsonKey(name: 'points') this.points = 0, @JsonKey(name: 'service_type') this.serviceType = 'Saver Bike', @JsonKey(name: 'passenger_name') this.passengerName = 'Passenger', @JsonKey(name: 'item_summary') this.itemSummary = '', @JsonKey(name: 'timeout_seconds') this.timeoutSeconds = 30, @JsonKey(name: 'surge_multiplier') this.surgeMultiplier = 1.0, @JsonKey(name: 'surge_active') this.surgeActive = false, @JsonKey(name: 'is_scheduled') this.isScheduled = false, @JsonKey(name: 'scheduled_at') this.scheduledAt}): super._();
  factory _IncomingJobModel.fromJson(Map<String, dynamic> json) => _$IncomingJobModelFromJson(json);

@override@JsonKey(name: 'id') final  String jobId;
@override@JsonKey(name: 'pickup_address') final  String pickupAddress;
@override@JsonKey(name: 'dropoff_address') final  String dropoffAddress;
@override@JsonKey(name: 'pickup_address_detail') final  String pickupAddressDetail;
@override@JsonKey(name: 'dropoff_address_detail') final  String dropoffAddressDetail;
@override@JsonKey(name: 'pickup_distance_km') final  double pickupDistanceKm;
@override@JsonKey(name: 'dropoff_distance_km') final  double dropoffDistanceKm;
@override@JsonKey(name: 'pickup_lat') final  double pickupLat;
@override@JsonKey(name: 'pickup_lng') final  double pickupLng;
@override@JsonKey(name: 'dropoff_lat') final  double dropoffLat;
@override@JsonKey(name: 'dropoff_lng') final  double dropoffLng;
@override@JsonKey(name: 'fare') final  double netIncome;
@override@JsonKey(name: 'payment_method') final  String paymentMethod;
@override@JsonKey(name: 'points') final  int points;
@override@JsonKey(name: 'service_type') final  String serviceType;
@override@JsonKey(name: 'passenger_name') final  String passengerName;
@override@JsonKey(name: 'item_summary') final  String itemSummary;
@override@JsonKey(name: 'timeout_seconds') final  int timeoutSeconds;
@override@JsonKey(name: 'surge_multiplier') final  double surgeMultiplier;
@override@JsonKey(name: 'surge_active') final  bool surgeActive;
@override@JsonKey(name: 'is_scheduled') final  bool isScheduled;
@override@JsonKey(name: 'scheduled_at') final  String? scheduledAt;

/// Create a copy of IncomingJobModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomingJobModelCopyWith<_IncomingJobModel> get copyWith => __$IncomingJobModelCopyWithImpl<_IncomingJobModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IncomingJobModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingJobModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.pickupAddressDetail, pickupAddressDetail) || other.pickupAddressDetail == pickupAddressDetail)&&(identical(other.dropoffAddressDetail, dropoffAddressDetail) || other.dropoffAddressDetail == dropoffAddressDetail)&&(identical(other.pickupDistanceKm, pickupDistanceKm) || other.pickupDistanceKm == pickupDistanceKm)&&(identical(other.dropoffDistanceKm, dropoffDistanceKm) || other.dropoffDistanceKm == dropoffDistanceKm)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.points, points) || other.points == points)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.passengerName, passengerName) || other.passengerName == passengerName)&&(identical(other.itemSummary, itemSummary) || other.itemSummary == itemSummary)&&(identical(other.timeoutSeconds, timeoutSeconds) || other.timeoutSeconds == timeoutSeconds)&&(identical(other.surgeMultiplier, surgeMultiplier) || other.surgeMultiplier == surgeMultiplier)&&(identical(other.surgeActive, surgeActive) || other.surgeActive == surgeActive)&&(identical(other.isScheduled, isScheduled) || other.isScheduled == isScheduled)&&(identical(other.scheduledAt, scheduledAt) || other.scheduledAt == scheduledAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,jobId,pickupAddress,dropoffAddress,pickupAddressDetail,dropoffAddressDetail,pickupDistanceKm,dropoffDistanceKm,pickupLat,pickupLng,dropoffLat,dropoffLng,netIncome,paymentMethod,points,serviceType,passengerName,itemSummary,timeoutSeconds,surgeMultiplier,surgeActive,isScheduled,scheduledAt]);

@override
String toString() {
  return 'IncomingJobModel(jobId: $jobId, pickupAddress: $pickupAddress, dropoffAddress: $dropoffAddress, pickupAddressDetail: $pickupAddressDetail, dropoffAddressDetail: $dropoffAddressDetail, pickupDistanceKm: $pickupDistanceKm, dropoffDistanceKm: $dropoffDistanceKm, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, netIncome: $netIncome, paymentMethod: $paymentMethod, points: $points, serviceType: $serviceType, passengerName: $passengerName, itemSummary: $itemSummary, timeoutSeconds: $timeoutSeconds, surgeMultiplier: $surgeMultiplier, surgeActive: $surgeActive, isScheduled: $isScheduled, scheduledAt: $scheduledAt)';
}


}

/// @nodoc
abstract mixin class _$IncomingJobModelCopyWith<$Res> implements $IncomingJobModelCopyWith<$Res> {
  factory _$IncomingJobModelCopyWith(_IncomingJobModel value, $Res Function(_IncomingJobModel) _then) = __$IncomingJobModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String jobId,@JsonKey(name: 'pickup_address') String pickupAddress,@JsonKey(name: 'dropoff_address') String dropoffAddress,@JsonKey(name: 'pickup_address_detail') String pickupAddressDetail,@JsonKey(name: 'dropoff_address_detail') String dropoffAddressDetail,@JsonKey(name: 'pickup_distance_km') double pickupDistanceKm,@JsonKey(name: 'dropoff_distance_km') double dropoffDistanceKm,@JsonKey(name: 'pickup_lat') double pickupLat,@JsonKey(name: 'pickup_lng') double pickupLng,@JsonKey(name: 'dropoff_lat') double dropoffLat,@JsonKey(name: 'dropoff_lng') double dropoffLng,@JsonKey(name: 'fare') double netIncome,@JsonKey(name: 'payment_method') String paymentMethod,@JsonKey(name: 'points') int points,@JsonKey(name: 'service_type') String serviceType,@JsonKey(name: 'passenger_name') String passengerName,@JsonKey(name: 'item_summary') String itemSummary,@JsonKey(name: 'timeout_seconds') int timeoutSeconds,@JsonKey(name: 'surge_multiplier') double surgeMultiplier,@JsonKey(name: 'surge_active') bool surgeActive,@JsonKey(name: 'is_scheduled') bool isScheduled,@JsonKey(name: 'scheduled_at') String? scheduledAt
});




}
/// @nodoc
class __$IncomingJobModelCopyWithImpl<$Res>
    implements _$IncomingJobModelCopyWith<$Res> {
  __$IncomingJobModelCopyWithImpl(this._self, this._then);

  final _IncomingJobModel _self;
  final $Res Function(_IncomingJobModel) _then;

/// Create a copy of IncomingJobModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? pickupAddress = null,Object? dropoffAddress = null,Object? pickupAddressDetail = null,Object? dropoffAddressDetail = null,Object? pickupDistanceKm = null,Object? dropoffDistanceKm = null,Object? pickupLat = null,Object? pickupLng = null,Object? dropoffLat = null,Object? dropoffLng = null,Object? netIncome = null,Object? paymentMethod = null,Object? points = null,Object? serviceType = null,Object? passengerName = null,Object? itemSummary = null,Object? timeoutSeconds = null,Object? surgeMultiplier = null,Object? surgeActive = null,Object? isScheduled = null,Object? scheduledAt = freezed,}) {
  return _then(_IncomingJobModel(
jobId: null == jobId ? _self.jobId : jobId // ignore: cast_nullable_to_non_nullable
as String,pickupAddress: null == pickupAddress ? _self.pickupAddress : pickupAddress // ignore: cast_nullable_to_non_nullable
as String,dropoffAddress: null == dropoffAddress ? _self.dropoffAddress : dropoffAddress // ignore: cast_nullable_to_non_nullable
as String,pickupAddressDetail: null == pickupAddressDetail ? _self.pickupAddressDetail : pickupAddressDetail // ignore: cast_nullable_to_non_nullable
as String,dropoffAddressDetail: null == dropoffAddressDetail ? _self.dropoffAddressDetail : dropoffAddressDetail // ignore: cast_nullable_to_non_nullable
as String,pickupDistanceKm: null == pickupDistanceKm ? _self.pickupDistanceKm : pickupDistanceKm // ignore: cast_nullable_to_non_nullable
as double,dropoffDistanceKm: null == dropoffDistanceKm ? _self.dropoffDistanceKm : dropoffDistanceKm // ignore: cast_nullable_to_non_nullable
as double,pickupLat: null == pickupLat ? _self.pickupLat : pickupLat // ignore: cast_nullable_to_non_nullable
as double,pickupLng: null == pickupLng ? _self.pickupLng : pickupLng // ignore: cast_nullable_to_non_nullable
as double,dropoffLat: null == dropoffLat ? _self.dropoffLat : dropoffLat // ignore: cast_nullable_to_non_nullable
as double,dropoffLng: null == dropoffLng ? _self.dropoffLng : dropoffLng // ignore: cast_nullable_to_non_nullable
as double,netIncome: null == netIncome ? _self.netIncome : netIncome // ignore: cast_nullable_to_non_nullable
as double,paymentMethod: null == paymentMethod ? _self.paymentMethod : paymentMethod // ignore: cast_nullable_to_non_nullable
as String,points: null == points ? _self.points : points // ignore: cast_nullable_to_non_nullable
as int,serviceType: null == serviceType ? _self.serviceType : serviceType // ignore: cast_nullable_to_non_nullable
as String,passengerName: null == passengerName ? _self.passengerName : passengerName // ignore: cast_nullable_to_non_nullable
as String,itemSummary: null == itemSummary ? _self.itemSummary : itemSummary // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,surgeMultiplier: null == surgeMultiplier ? _self.surgeMultiplier : surgeMultiplier // ignore: cast_nullable_to_non_nullable
as double,surgeActive: null == surgeActive ? _self.surgeActive : surgeActive // ignore: cast_nullable_to_non_nullable
as bool,isScheduled: null == isScheduled ? _self.isScheduled : isScheduled // ignore: cast_nullable_to_non_nullable
as bool,scheduledAt: freezed == scheduledAt ? _self.scheduledAt : scheduledAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
