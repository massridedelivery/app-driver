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

 String get jobId; String get pickupAddress; String get dropoffAddress; String get pickupAddressDetail;// Added for new UI
 String get dropoffAddressDetail;// Added for new UI
 double get pickupDistanceKm; double get dropoffDistanceKm; double get pickupLat; double get pickupLng; double get dropoffLat; double get dropoffLng; double get netIncome;// Added for new UI
 String get paymentMethod;// Added for new UI
 int get points;// Added for new UI
 String get serviceType;// Added for new UI
 String get itemSummary;// Added for new UI
 int get timeoutSeconds;
/// Create a copy of IncomingJobModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingJobModelCopyWith<IncomingJobModel> get copyWith => _$IncomingJobModelCopyWithImpl<IncomingJobModel>(this as IncomingJobModel, _$identity);

  /// Serializes this IncomingJobModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingJobModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.pickupAddressDetail, pickupAddressDetail) || other.pickupAddressDetail == pickupAddressDetail)&&(identical(other.dropoffAddressDetail, dropoffAddressDetail) || other.dropoffAddressDetail == dropoffAddressDetail)&&(identical(other.pickupDistanceKm, pickupDistanceKm) || other.pickupDistanceKm == pickupDistanceKm)&&(identical(other.dropoffDistanceKm, dropoffDistanceKm) || other.dropoffDistanceKm == dropoffDistanceKm)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.points, points) || other.points == points)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.itemSummary, itemSummary) || other.itemSummary == itemSummary)&&(identical(other.timeoutSeconds, timeoutSeconds) || other.timeoutSeconds == timeoutSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,pickupAddress,dropoffAddress,pickupAddressDetail,dropoffAddressDetail,pickupDistanceKm,dropoffDistanceKm,pickupLat,pickupLng,dropoffLat,dropoffLng,netIncome,paymentMethod,points,serviceType,itemSummary,timeoutSeconds);

@override
String toString() {
  return 'IncomingJobModel(jobId: $jobId, pickupAddress: $pickupAddress, dropoffAddress: $dropoffAddress, pickupAddressDetail: $pickupAddressDetail, dropoffAddressDetail: $dropoffAddressDetail, pickupDistanceKm: $pickupDistanceKm, dropoffDistanceKm: $dropoffDistanceKm, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, netIncome: $netIncome, paymentMethod: $paymentMethod, points: $points, serviceType: $serviceType, itemSummary: $itemSummary, timeoutSeconds: $timeoutSeconds)';
}


}

/// @nodoc
abstract mixin class $IncomingJobModelCopyWith<$Res>  {
  factory $IncomingJobModelCopyWith(IncomingJobModel value, $Res Function(IncomingJobModel) _then) = _$IncomingJobModelCopyWithImpl;
@useResult
$Res call({
 String jobId, String pickupAddress, String dropoffAddress, String pickupAddressDetail, String dropoffAddressDetail, double pickupDistanceKm, double dropoffDistanceKm, double pickupLat, double pickupLng, double dropoffLat, double dropoffLng, double netIncome, String paymentMethod, int points, String serviceType, String itemSummary, int timeoutSeconds
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
@pragma('vm:prefer-inline') @override $Res call({Object? jobId = null,Object? pickupAddress = null,Object? dropoffAddress = null,Object? pickupAddressDetail = null,Object? dropoffAddressDetail = null,Object? pickupDistanceKm = null,Object? dropoffDistanceKm = null,Object? pickupLat = null,Object? pickupLng = null,Object? dropoffLat = null,Object? dropoffLng = null,Object? netIncome = null,Object? paymentMethod = null,Object? points = null,Object? serviceType = null,Object? itemSummary = null,Object? timeoutSeconds = null,}) {
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
as String,itemSummary: null == itemSummary ? _self.itemSummary : itemSummary // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String jobId,  String pickupAddress,  String dropoffAddress,  String pickupAddressDetail,  String dropoffAddressDetail,  double pickupDistanceKm,  double dropoffDistanceKm,  double pickupLat,  double pickupLng,  double dropoffLat,  double dropoffLng,  double netIncome,  String paymentMethod,  int points,  String serviceType,  String itemSummary,  int timeoutSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.itemSummary,_that.timeoutSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String jobId,  String pickupAddress,  String dropoffAddress,  String pickupAddressDetail,  String dropoffAddressDetail,  double pickupDistanceKm,  double dropoffDistanceKm,  double pickupLat,  double pickupLng,  double dropoffLat,  double dropoffLng,  double netIncome,  String paymentMethod,  int points,  String serviceType,  String itemSummary,  int timeoutSeconds)  $default,) {final _that = this;
switch (_that) {
case _IncomingJobModel():
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.itemSummary,_that.timeoutSeconds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String jobId,  String pickupAddress,  String dropoffAddress,  String pickupAddressDetail,  String dropoffAddressDetail,  double pickupDistanceKm,  double dropoffDistanceKm,  double pickupLat,  double pickupLng,  double dropoffLat,  double dropoffLng,  double netIncome,  String paymentMethod,  int points,  String serviceType,  String itemSummary,  int timeoutSeconds)?  $default,) {final _that = this;
switch (_that) {
case _IncomingJobModel() when $default != null:
return $default(_that.jobId,_that.pickupAddress,_that.dropoffAddress,_that.pickupAddressDetail,_that.dropoffAddressDetail,_that.pickupDistanceKm,_that.dropoffDistanceKm,_that.pickupLat,_that.pickupLng,_that.dropoffLat,_that.dropoffLng,_that.netIncome,_that.paymentMethod,_that.points,_that.serviceType,_that.itemSummary,_that.timeoutSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IncomingJobModel extends IncomingJobModel {
  const _IncomingJobModel({required this.jobId, required this.pickupAddress, required this.dropoffAddress, required this.pickupAddressDetail, required this.dropoffAddressDetail, required this.pickupDistanceKm, required this.dropoffDistanceKm, required this.pickupLat, required this.pickupLng, required this.dropoffLat, required this.dropoffLng, required this.netIncome, required this.paymentMethod, required this.points, required this.serviceType, required this.itemSummary, required this.timeoutSeconds}): super._();
  factory _IncomingJobModel.fromJson(Map<String, dynamic> json) => _$IncomingJobModelFromJson(json);

@override final  String jobId;
@override final  String pickupAddress;
@override final  String dropoffAddress;
@override final  String pickupAddressDetail;
// Added for new UI
@override final  String dropoffAddressDetail;
// Added for new UI
@override final  double pickupDistanceKm;
@override final  double dropoffDistanceKm;
@override final  double pickupLat;
@override final  double pickupLng;
@override final  double dropoffLat;
@override final  double dropoffLng;
@override final  double netIncome;
// Added for new UI
@override final  String paymentMethod;
// Added for new UI
@override final  int points;
// Added for new UI
@override final  String serviceType;
// Added for new UI
@override final  String itemSummary;
// Added for new UI
@override final  int timeoutSeconds;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingJobModel&&(identical(other.jobId, jobId) || other.jobId == jobId)&&(identical(other.pickupAddress, pickupAddress) || other.pickupAddress == pickupAddress)&&(identical(other.dropoffAddress, dropoffAddress) || other.dropoffAddress == dropoffAddress)&&(identical(other.pickupAddressDetail, pickupAddressDetail) || other.pickupAddressDetail == pickupAddressDetail)&&(identical(other.dropoffAddressDetail, dropoffAddressDetail) || other.dropoffAddressDetail == dropoffAddressDetail)&&(identical(other.pickupDistanceKm, pickupDistanceKm) || other.pickupDistanceKm == pickupDistanceKm)&&(identical(other.dropoffDistanceKm, dropoffDistanceKm) || other.dropoffDistanceKm == dropoffDistanceKm)&&(identical(other.pickupLat, pickupLat) || other.pickupLat == pickupLat)&&(identical(other.pickupLng, pickupLng) || other.pickupLng == pickupLng)&&(identical(other.dropoffLat, dropoffLat) || other.dropoffLat == dropoffLat)&&(identical(other.dropoffLng, dropoffLng) || other.dropoffLng == dropoffLng)&&(identical(other.netIncome, netIncome) || other.netIncome == netIncome)&&(identical(other.paymentMethod, paymentMethod) || other.paymentMethod == paymentMethod)&&(identical(other.points, points) || other.points == points)&&(identical(other.serviceType, serviceType) || other.serviceType == serviceType)&&(identical(other.itemSummary, itemSummary) || other.itemSummary == itemSummary)&&(identical(other.timeoutSeconds, timeoutSeconds) || other.timeoutSeconds == timeoutSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jobId,pickupAddress,dropoffAddress,pickupAddressDetail,dropoffAddressDetail,pickupDistanceKm,dropoffDistanceKm,pickupLat,pickupLng,dropoffLat,dropoffLng,netIncome,paymentMethod,points,serviceType,itemSummary,timeoutSeconds);

@override
String toString() {
  return 'IncomingJobModel(jobId: $jobId, pickupAddress: $pickupAddress, dropoffAddress: $dropoffAddress, pickupAddressDetail: $pickupAddressDetail, dropoffAddressDetail: $dropoffAddressDetail, pickupDistanceKm: $pickupDistanceKm, dropoffDistanceKm: $dropoffDistanceKm, pickupLat: $pickupLat, pickupLng: $pickupLng, dropoffLat: $dropoffLat, dropoffLng: $dropoffLng, netIncome: $netIncome, paymentMethod: $paymentMethod, points: $points, serviceType: $serviceType, itemSummary: $itemSummary, timeoutSeconds: $timeoutSeconds)';
}


}

/// @nodoc
abstract mixin class _$IncomingJobModelCopyWith<$Res> implements $IncomingJobModelCopyWith<$Res> {
  factory _$IncomingJobModelCopyWith(_IncomingJobModel value, $Res Function(_IncomingJobModel) _then) = __$IncomingJobModelCopyWithImpl;
@override @useResult
$Res call({
 String jobId, String pickupAddress, String dropoffAddress, String pickupAddressDetail, String dropoffAddressDetail, double pickupDistanceKm, double dropoffDistanceKm, double pickupLat, double pickupLng, double dropoffLat, double dropoffLng, double netIncome, String paymentMethod, int points, String serviceType, String itemSummary, int timeoutSeconds
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
@override @pragma('vm:prefer-inline') $Res call({Object? jobId = null,Object? pickupAddress = null,Object? dropoffAddress = null,Object? pickupAddressDetail = null,Object? dropoffAddressDetail = null,Object? pickupDistanceKm = null,Object? dropoffDistanceKm = null,Object? pickupLat = null,Object? pickupLng = null,Object? dropoffLat = null,Object? dropoffLng = null,Object? netIncome = null,Object? paymentMethod = null,Object? points = null,Object? serviceType = null,Object? itemSummary = null,Object? timeoutSeconds = null,}) {
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
as String,itemSummary: null == itemSummary ? _self.itemSummary : itemSummary // ignore: cast_nullable_to_non_nullable
as String,timeoutSeconds: null == timeoutSeconds ? _self.timeoutSeconds : timeoutSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
