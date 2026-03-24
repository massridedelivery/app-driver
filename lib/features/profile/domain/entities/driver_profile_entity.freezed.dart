// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'driver_profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DriverProfileEntity {

@JsonKey(name: 'user_id') String get userId;@JsonKey(name: 'full_name') String get fullName; String? get phone; double get rating;@JsonKey(name: 'total_trips') int get totalTrips;@JsonKey(name: 'is_verified') bool get isVerified; List<DocumentEntity> get documents;@JsonKey(name: 'vehicle_type_ids') List<String> get vehicleTypeIds;@JsonKey(name: 'vehicle_types') List<VehicleTypeEntity> get vehicleTypes;@JsonKey(name: 'vehicle_plate') String? get vehiclePlate;@JsonKey(name: 'vehicle_color') String? get vehicleColor;@JsonKey(name: 'vehicle_model') String? get vehicleModel;@JsonKey(name: 'vehicle_year') int? get vehicleYear;@JsonKey(name: 'vehicle_province') String? get vehicleProvince; double get balance;@JsonKey(name: 'commission_rate') double get commissionRate;@JsonKey(name: 'incentive_tier') String? get incentiveTier;@JsonKey(name: 'loyalty_points') int get loyaltyPoints;@JsonKey(name: 'acceptance_rate') double get acceptanceRate;@JsonKey(name: 'cancellation_rate') double get cancellationRate;@JsonKey(name: 'weekly_completed_jobs') int get weeklyCompletedJobs; String get status;
/// Create a copy of DriverProfileEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DriverProfileEntityCopyWith<DriverProfileEntity> get copyWith => _$DriverProfileEntityCopyWithImpl<DriverProfileEntity>(this as DriverProfileEntity, _$identity);

  /// Serializes this DriverProfileEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DriverProfileEntity&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&const DeepCollectionEquality().equals(other.documents, documents)&&const DeepCollectionEquality().equals(other.vehicleTypeIds, vehicleTypeIds)&&const DeepCollectionEquality().equals(other.vehicleTypes, vehicleTypes)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleYear, vehicleYear) || other.vehicleYear == vehicleYear)&&(identical(other.vehicleProvince, vehicleProvince) || other.vehicleProvince == vehicleProvince)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&(identical(other.incentiveTier, incentiveTier) || other.incentiveTier == incentiveTier)&&(identical(other.loyaltyPoints, loyaltyPoints) || other.loyaltyPoints == loyaltyPoints)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.weeklyCompletedJobs, weeklyCompletedJobs) || other.weeklyCompletedJobs == weeklyCompletedJobs)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,fullName,phone,rating,totalTrips,isVerified,const DeepCollectionEquality().hash(documents),const DeepCollectionEquality().hash(vehicleTypeIds),const DeepCollectionEquality().hash(vehicleTypes),vehiclePlate,vehicleColor,vehicleModel,vehicleYear,vehicleProvince,balance,commissionRate,incentiveTier,loyaltyPoints,acceptanceRate,cancellationRate,weeklyCompletedJobs,status]);

@override
String toString() {
  return 'DriverProfileEntity(userId: $userId, fullName: $fullName, phone: $phone, rating: $rating, totalTrips: $totalTrips, isVerified: $isVerified, documents: $documents, vehicleTypeIds: $vehicleTypeIds, vehicleTypes: $vehicleTypes, vehiclePlate: $vehiclePlate, vehicleColor: $vehicleColor, vehicleModel: $vehicleModel, vehicleYear: $vehicleYear, vehicleProvince: $vehicleProvince, balance: $balance, commissionRate: $commissionRate, incentiveTier: $incentiveTier, loyaltyPoints: $loyaltyPoints, acceptanceRate: $acceptanceRate, cancellationRate: $cancellationRate, weeklyCompletedJobs: $weeklyCompletedJobs, status: $status)';
}


}

/// @nodoc
abstract mixin class $DriverProfileEntityCopyWith<$Res>  {
  factory $DriverProfileEntityCopyWith(DriverProfileEntity value, $Res Function(DriverProfileEntity) _then) = _$DriverProfileEntityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'full_name') String fullName, String? phone, double rating,@JsonKey(name: 'total_trips') int totalTrips,@JsonKey(name: 'is_verified') bool isVerified, List<DocumentEntity> documents,@JsonKey(name: 'vehicle_type_ids') List<String> vehicleTypeIds,@JsonKey(name: 'vehicle_types') List<VehicleTypeEntity> vehicleTypes,@JsonKey(name: 'vehicle_plate') String? vehiclePlate,@JsonKey(name: 'vehicle_color') String? vehicleColor,@JsonKey(name: 'vehicle_model') String? vehicleModel,@JsonKey(name: 'vehicle_year') int? vehicleYear,@JsonKey(name: 'vehicle_province') String? vehicleProvince, double balance,@JsonKey(name: 'commission_rate') double commissionRate,@JsonKey(name: 'incentive_tier') String? incentiveTier,@JsonKey(name: 'loyalty_points') int loyaltyPoints,@JsonKey(name: 'acceptance_rate') double acceptanceRate,@JsonKey(name: 'cancellation_rate') double cancellationRate,@JsonKey(name: 'weekly_completed_jobs') int weeklyCompletedJobs, String status
});




}
/// @nodoc
class _$DriverProfileEntityCopyWithImpl<$Res>
    implements $DriverProfileEntityCopyWith<$Res> {
  _$DriverProfileEntityCopyWithImpl(this._self, this._then);

  final DriverProfileEntity _self;
  final $Res Function(DriverProfileEntity) _then;

/// Create a copy of DriverProfileEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? fullName = null,Object? phone = freezed,Object? rating = null,Object? totalTrips = null,Object? isVerified = null,Object? documents = null,Object? vehicleTypeIds = null,Object? vehicleTypes = null,Object? vehiclePlate = freezed,Object? vehicleColor = freezed,Object? vehicleModel = freezed,Object? vehicleYear = freezed,Object? vehicleProvince = freezed,Object? balance = null,Object? commissionRate = null,Object? incentiveTier = freezed,Object? loyaltyPoints = null,Object? acceptanceRate = null,Object? cancellationRate = null,Object? weeklyCompletedJobs = null,Object? status = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<DocumentEntity>,vehicleTypeIds: null == vehicleTypeIds ? _self.vehicleTypeIds : vehicleTypeIds // ignore: cast_nullable_to_non_nullable
as List<String>,vehicleTypes: null == vehicleTypes ? _self.vehicleTypes : vehicleTypes // ignore: cast_nullable_to_non_nullable
as List<VehicleTypeEntity>,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleYear: freezed == vehicleYear ? _self.vehicleYear : vehicleYear // ignore: cast_nullable_to_non_nullable
as int?,vehicleProvince: freezed == vehicleProvince ? _self.vehicleProvince : vehicleProvince // ignore: cast_nullable_to_non_nullable
as String?,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,commissionRate: null == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double,incentiveTier: freezed == incentiveTier ? _self.incentiveTier : incentiveTier // ignore: cast_nullable_to_non_nullable
as String?,loyaltyPoints: null == loyaltyPoints ? _self.loyaltyPoints : loyaltyPoints // ignore: cast_nullable_to_non_nullable
as int,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,weeklyCompletedJobs: null == weeklyCompletedJobs ? _self.weeklyCompletedJobs : weeklyCompletedJobs // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DriverProfileEntity].
extension DriverProfileEntityPatterns on DriverProfileEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DriverProfileEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DriverProfileEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DriverProfileEntity value)  $default,){
final _that = this;
switch (_that) {
case _DriverProfileEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DriverProfileEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DriverProfileEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'full_name')  String fullName,  String? phone,  double rating, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'is_verified')  bool isVerified,  List<DocumentEntity> documents, @JsonKey(name: 'vehicle_type_ids')  List<String> vehicleTypeIds, @JsonKey(name: 'vehicle_types')  List<VehicleTypeEntity> vehicleTypes, @JsonKey(name: 'vehicle_plate')  String? vehiclePlate, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'vehicle_model')  String? vehicleModel, @JsonKey(name: 'vehicle_year')  int? vehicleYear, @JsonKey(name: 'vehicle_province')  String? vehicleProvince,  double balance, @JsonKey(name: 'commission_rate')  double commissionRate, @JsonKey(name: 'incentive_tier')  String? incentiveTier, @JsonKey(name: 'loyalty_points')  int loyaltyPoints, @JsonKey(name: 'acceptance_rate')  double acceptanceRate, @JsonKey(name: 'cancellation_rate')  double cancellationRate, @JsonKey(name: 'weekly_completed_jobs')  int weeklyCompletedJobs,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DriverProfileEntity() when $default != null:
return $default(_that.userId,_that.fullName,_that.phone,_that.rating,_that.totalTrips,_that.isVerified,_that.documents,_that.vehicleTypeIds,_that.vehicleTypes,_that.vehiclePlate,_that.vehicleColor,_that.vehicleModel,_that.vehicleYear,_that.vehicleProvince,_that.balance,_that.commissionRate,_that.incentiveTier,_that.loyaltyPoints,_that.acceptanceRate,_that.cancellationRate,_that.weeklyCompletedJobs,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'full_name')  String fullName,  String? phone,  double rating, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'is_verified')  bool isVerified,  List<DocumentEntity> documents, @JsonKey(name: 'vehicle_type_ids')  List<String> vehicleTypeIds, @JsonKey(name: 'vehicle_types')  List<VehicleTypeEntity> vehicleTypes, @JsonKey(name: 'vehicle_plate')  String? vehiclePlate, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'vehicle_model')  String? vehicleModel, @JsonKey(name: 'vehicle_year')  int? vehicleYear, @JsonKey(name: 'vehicle_province')  String? vehicleProvince,  double balance, @JsonKey(name: 'commission_rate')  double commissionRate, @JsonKey(name: 'incentive_tier')  String? incentiveTier, @JsonKey(name: 'loyalty_points')  int loyaltyPoints, @JsonKey(name: 'acceptance_rate')  double acceptanceRate, @JsonKey(name: 'cancellation_rate')  double cancellationRate, @JsonKey(name: 'weekly_completed_jobs')  int weeklyCompletedJobs,  String status)  $default,) {final _that = this;
switch (_that) {
case _DriverProfileEntity():
return $default(_that.userId,_that.fullName,_that.phone,_that.rating,_that.totalTrips,_that.isVerified,_that.documents,_that.vehicleTypeIds,_that.vehicleTypes,_that.vehiclePlate,_that.vehicleColor,_that.vehicleModel,_that.vehicleYear,_that.vehicleProvince,_that.balance,_that.commissionRate,_that.incentiveTier,_that.loyaltyPoints,_that.acceptanceRate,_that.cancellationRate,_that.weeklyCompletedJobs,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'user_id')  String userId, @JsonKey(name: 'full_name')  String fullName,  String? phone,  double rating, @JsonKey(name: 'total_trips')  int totalTrips, @JsonKey(name: 'is_verified')  bool isVerified,  List<DocumentEntity> documents, @JsonKey(name: 'vehicle_type_ids')  List<String> vehicleTypeIds, @JsonKey(name: 'vehicle_types')  List<VehicleTypeEntity> vehicleTypes, @JsonKey(name: 'vehicle_plate')  String? vehiclePlate, @JsonKey(name: 'vehicle_color')  String? vehicleColor, @JsonKey(name: 'vehicle_model')  String? vehicleModel, @JsonKey(name: 'vehicle_year')  int? vehicleYear, @JsonKey(name: 'vehicle_province')  String? vehicleProvince,  double balance, @JsonKey(name: 'commission_rate')  double commissionRate, @JsonKey(name: 'incentive_tier')  String? incentiveTier, @JsonKey(name: 'loyalty_points')  int loyaltyPoints, @JsonKey(name: 'acceptance_rate')  double acceptanceRate, @JsonKey(name: 'cancellation_rate')  double cancellationRate, @JsonKey(name: 'weekly_completed_jobs')  int weeklyCompletedJobs,  String status)?  $default,) {final _that = this;
switch (_that) {
case _DriverProfileEntity() when $default != null:
return $default(_that.userId,_that.fullName,_that.phone,_that.rating,_that.totalTrips,_that.isVerified,_that.documents,_that.vehicleTypeIds,_that.vehicleTypes,_that.vehiclePlate,_that.vehicleColor,_that.vehicleModel,_that.vehicleYear,_that.vehicleProvince,_that.balance,_that.commissionRate,_that.incentiveTier,_that.loyaltyPoints,_that.acceptanceRate,_that.cancellationRate,_that.weeklyCompletedJobs,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DriverProfileEntity implements DriverProfileEntity {
  const _DriverProfileEntity({@JsonKey(name: 'user_id') required this.userId, @JsonKey(name: 'full_name') required this.fullName, this.phone, this.rating = 0.0, @JsonKey(name: 'total_trips') this.totalTrips = 0, @JsonKey(name: 'is_verified') this.isVerified = false, final  List<DocumentEntity> documents = const [], @JsonKey(name: 'vehicle_type_ids') final  List<String> vehicleTypeIds = const [], @JsonKey(name: 'vehicle_types') final  List<VehicleTypeEntity> vehicleTypes = const [], @JsonKey(name: 'vehicle_plate') this.vehiclePlate, @JsonKey(name: 'vehicle_color') this.vehicleColor, @JsonKey(name: 'vehicle_model') this.vehicleModel, @JsonKey(name: 'vehicle_year') this.vehicleYear, @JsonKey(name: 'vehicle_province') this.vehicleProvince, this.balance = 0.0, @JsonKey(name: 'commission_rate') this.commissionRate = 0.0, @JsonKey(name: 'incentive_tier') this.incentiveTier, @JsonKey(name: 'loyalty_points') this.loyaltyPoints = 0, @JsonKey(name: 'acceptance_rate') this.acceptanceRate = 0.0, @JsonKey(name: 'cancellation_rate') this.cancellationRate = 0.0, @JsonKey(name: 'weekly_completed_jobs') this.weeklyCompletedJobs = 0, this.status = 'offline'}): _documents = documents,_vehicleTypeIds = vehicleTypeIds,_vehicleTypes = vehicleTypes;
  factory _DriverProfileEntity.fromJson(Map<String, dynamic> json) => _$DriverProfileEntityFromJson(json);

@override@JsonKey(name: 'user_id') final  String userId;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  String? phone;
@override@JsonKey() final  double rating;
@override@JsonKey(name: 'total_trips') final  int totalTrips;
@override@JsonKey(name: 'is_verified') final  bool isVerified;
 final  List<DocumentEntity> _documents;
@override@JsonKey() List<DocumentEntity> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

 final  List<String> _vehicleTypeIds;
@override@JsonKey(name: 'vehicle_type_ids') List<String> get vehicleTypeIds {
  if (_vehicleTypeIds is EqualUnmodifiableListView) return _vehicleTypeIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vehicleTypeIds);
}

 final  List<VehicleTypeEntity> _vehicleTypes;
@override@JsonKey(name: 'vehicle_types') List<VehicleTypeEntity> get vehicleTypes {
  if (_vehicleTypes is EqualUnmodifiableListView) return _vehicleTypes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_vehicleTypes);
}

@override@JsonKey(name: 'vehicle_plate') final  String? vehiclePlate;
@override@JsonKey(name: 'vehicle_color') final  String? vehicleColor;
@override@JsonKey(name: 'vehicle_model') final  String? vehicleModel;
@override@JsonKey(name: 'vehicle_year') final  int? vehicleYear;
@override@JsonKey(name: 'vehicle_province') final  String? vehicleProvince;
@override@JsonKey() final  double balance;
@override@JsonKey(name: 'commission_rate') final  double commissionRate;
@override@JsonKey(name: 'incentive_tier') final  String? incentiveTier;
@override@JsonKey(name: 'loyalty_points') final  int loyaltyPoints;
@override@JsonKey(name: 'acceptance_rate') final  double acceptanceRate;
@override@JsonKey(name: 'cancellation_rate') final  double cancellationRate;
@override@JsonKey(name: 'weekly_completed_jobs') final  int weeklyCompletedJobs;
@override@JsonKey() final  String status;

/// Create a copy of DriverProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DriverProfileEntityCopyWith<_DriverProfileEntity> get copyWith => __$DriverProfileEntityCopyWithImpl<_DriverProfileEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DriverProfileEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DriverProfileEntity&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.totalTrips, totalTrips) || other.totalTrips == totalTrips)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&const DeepCollectionEquality().equals(other._documents, _documents)&&const DeepCollectionEquality().equals(other._vehicleTypeIds, _vehicleTypeIds)&&const DeepCollectionEquality().equals(other._vehicleTypes, _vehicleTypes)&&(identical(other.vehiclePlate, vehiclePlate) || other.vehiclePlate == vehiclePlate)&&(identical(other.vehicleColor, vehicleColor) || other.vehicleColor == vehicleColor)&&(identical(other.vehicleModel, vehicleModel) || other.vehicleModel == vehicleModel)&&(identical(other.vehicleYear, vehicleYear) || other.vehicleYear == vehicleYear)&&(identical(other.vehicleProvince, vehicleProvince) || other.vehicleProvince == vehicleProvince)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.commissionRate, commissionRate) || other.commissionRate == commissionRate)&&(identical(other.incentiveTier, incentiveTier) || other.incentiveTier == incentiveTier)&&(identical(other.loyaltyPoints, loyaltyPoints) || other.loyaltyPoints == loyaltyPoints)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.weeklyCompletedJobs, weeklyCompletedJobs) || other.weeklyCompletedJobs == weeklyCompletedJobs)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,userId,fullName,phone,rating,totalTrips,isVerified,const DeepCollectionEquality().hash(_documents),const DeepCollectionEquality().hash(_vehicleTypeIds),const DeepCollectionEquality().hash(_vehicleTypes),vehiclePlate,vehicleColor,vehicleModel,vehicleYear,vehicleProvince,balance,commissionRate,incentiveTier,loyaltyPoints,acceptanceRate,cancellationRate,weeklyCompletedJobs,status]);

@override
String toString() {
  return 'DriverProfileEntity(userId: $userId, fullName: $fullName, phone: $phone, rating: $rating, totalTrips: $totalTrips, isVerified: $isVerified, documents: $documents, vehicleTypeIds: $vehicleTypeIds, vehicleTypes: $vehicleTypes, vehiclePlate: $vehiclePlate, vehicleColor: $vehicleColor, vehicleModel: $vehicleModel, vehicleYear: $vehicleYear, vehicleProvince: $vehicleProvince, balance: $balance, commissionRate: $commissionRate, incentiveTier: $incentiveTier, loyaltyPoints: $loyaltyPoints, acceptanceRate: $acceptanceRate, cancellationRate: $cancellationRate, weeklyCompletedJobs: $weeklyCompletedJobs, status: $status)';
}


}

/// @nodoc
abstract mixin class _$DriverProfileEntityCopyWith<$Res> implements $DriverProfileEntityCopyWith<$Res> {
  factory _$DriverProfileEntityCopyWith(_DriverProfileEntity value, $Res Function(_DriverProfileEntity) _then) = __$DriverProfileEntityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'user_id') String userId,@JsonKey(name: 'full_name') String fullName, String? phone, double rating,@JsonKey(name: 'total_trips') int totalTrips,@JsonKey(name: 'is_verified') bool isVerified, List<DocumentEntity> documents,@JsonKey(name: 'vehicle_type_ids') List<String> vehicleTypeIds,@JsonKey(name: 'vehicle_types') List<VehicleTypeEntity> vehicleTypes,@JsonKey(name: 'vehicle_plate') String? vehiclePlate,@JsonKey(name: 'vehicle_color') String? vehicleColor,@JsonKey(name: 'vehicle_model') String? vehicleModel,@JsonKey(name: 'vehicle_year') int? vehicleYear,@JsonKey(name: 'vehicle_province') String? vehicleProvince, double balance,@JsonKey(name: 'commission_rate') double commissionRate,@JsonKey(name: 'incentive_tier') String? incentiveTier,@JsonKey(name: 'loyalty_points') int loyaltyPoints,@JsonKey(name: 'acceptance_rate') double acceptanceRate,@JsonKey(name: 'cancellation_rate') double cancellationRate,@JsonKey(name: 'weekly_completed_jobs') int weeklyCompletedJobs, String status
});




}
/// @nodoc
class __$DriverProfileEntityCopyWithImpl<$Res>
    implements _$DriverProfileEntityCopyWith<$Res> {
  __$DriverProfileEntityCopyWithImpl(this._self, this._then);

  final _DriverProfileEntity _self;
  final $Res Function(_DriverProfileEntity) _then;

/// Create a copy of DriverProfileEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? fullName = null,Object? phone = freezed,Object? rating = null,Object? totalTrips = null,Object? isVerified = null,Object? documents = null,Object? vehicleTypeIds = null,Object? vehicleTypes = null,Object? vehiclePlate = freezed,Object? vehicleColor = freezed,Object? vehicleModel = freezed,Object? vehicleYear = freezed,Object? vehicleProvince = freezed,Object? balance = null,Object? commissionRate = null,Object? incentiveTier = freezed,Object? loyaltyPoints = null,Object? acceptanceRate = null,Object? cancellationRate = null,Object? weeklyCompletedJobs = null,Object? status = null,}) {
  return _then(_DriverProfileEntity(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,totalTrips: null == totalTrips ? _self.totalTrips : totalTrips // ignore: cast_nullable_to_non_nullable
as int,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<DocumentEntity>,vehicleTypeIds: null == vehicleTypeIds ? _self._vehicleTypeIds : vehicleTypeIds // ignore: cast_nullable_to_non_nullable
as List<String>,vehicleTypes: null == vehicleTypes ? _self._vehicleTypes : vehicleTypes // ignore: cast_nullable_to_non_nullable
as List<VehicleTypeEntity>,vehiclePlate: freezed == vehiclePlate ? _self.vehiclePlate : vehiclePlate // ignore: cast_nullable_to_non_nullable
as String?,vehicleColor: freezed == vehicleColor ? _self.vehicleColor : vehicleColor // ignore: cast_nullable_to_non_nullable
as String?,vehicleModel: freezed == vehicleModel ? _self.vehicleModel : vehicleModel // ignore: cast_nullable_to_non_nullable
as String?,vehicleYear: freezed == vehicleYear ? _self.vehicleYear : vehicleYear // ignore: cast_nullable_to_non_nullable
as int?,vehicleProvince: freezed == vehicleProvince ? _self.vehicleProvince : vehicleProvince // ignore: cast_nullable_to_non_nullable
as String?,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,commissionRate: null == commissionRate ? _self.commissionRate : commissionRate // ignore: cast_nullable_to_non_nullable
as double,incentiveTier: freezed == incentiveTier ? _self.incentiveTier : incentiveTier // ignore: cast_nullable_to_non_nullable
as String?,loyaltyPoints: null == loyaltyPoints ? _self.loyaltyPoints : loyaltyPoints // ignore: cast_nullable_to_non_nullable
as int,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,weeklyCompletedJobs: null == weeklyCompletedJobs ? _self.weeklyCompletedJobs : weeklyCompletedJobs // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DocumentEntity {

 String get type; String get status;@JsonKey(name: 'media_url') String? get mediaUrl;@JsonKey(name: 'reviewed_at') String? get reviewedAt;@JsonKey(name: 'rejection_reason') String? get rejectionReason;
/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DocumentEntityCopyWith<DocumentEntity> get copyWith => _$DocumentEntityCopyWithImpl<DocumentEntity>(this as DocumentEntity, _$identity);

  /// Serializes this DocumentEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DocumentEntity&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,status,mediaUrl,reviewedAt,rejectionReason);

@override
String toString() {
  return 'DocumentEntity(type: $type, status: $status, mediaUrl: $mediaUrl, reviewedAt: $reviewedAt, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class $DocumentEntityCopyWith<$Res>  {
  factory $DocumentEntityCopyWith(DocumentEntity value, $Res Function(DocumentEntity) _then) = _$DocumentEntityCopyWithImpl;
@useResult
$Res call({
 String type, String status,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'rejection_reason') String? rejectionReason
});




}
/// @nodoc
class _$DocumentEntityCopyWithImpl<$Res>
    implements $DocumentEntityCopyWith<$Res> {
  _$DocumentEntityCopyWithImpl(this._self, this._then);

  final DocumentEntity _self;
  final $Res Function(DocumentEntity) _then;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? status = null,Object? mediaUrl = freezed,Object? reviewedAt = freezed,Object? rejectionReason = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DocumentEntity].
extension DocumentEntityPatterns on DocumentEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DocumentEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DocumentEntity value)  $default,){
final _that = this;
switch (_that) {
case _DocumentEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DocumentEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String status, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'rejection_reason')  String? rejectionReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
return $default(_that.type,_that.status,_that.mediaUrl,_that.reviewedAt,_that.rejectionReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String status, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'rejection_reason')  String? rejectionReason)  $default,) {final _that = this;
switch (_that) {
case _DocumentEntity():
return $default(_that.type,_that.status,_that.mediaUrl,_that.reviewedAt,_that.rejectionReason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String status, @JsonKey(name: 'media_url')  String? mediaUrl, @JsonKey(name: 'reviewed_at')  String? reviewedAt, @JsonKey(name: 'rejection_reason')  String? rejectionReason)?  $default,) {final _that = this;
switch (_that) {
case _DocumentEntity() when $default != null:
return $default(_that.type,_that.status,_that.mediaUrl,_that.reviewedAt,_that.rejectionReason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DocumentEntity implements DocumentEntity {
  const _DocumentEntity({required this.type, required this.status, @JsonKey(name: 'media_url') this.mediaUrl, @JsonKey(name: 'reviewed_at') this.reviewedAt, @JsonKey(name: 'rejection_reason') this.rejectionReason});
  factory _DocumentEntity.fromJson(Map<String, dynamic> json) => _$DocumentEntityFromJson(json);

@override final  String type;
@override final  String status;
@override@JsonKey(name: 'media_url') final  String? mediaUrl;
@override@JsonKey(name: 'reviewed_at') final  String? reviewedAt;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DocumentEntityCopyWith<_DocumentEntity> get copyWith => __$DocumentEntityCopyWithImpl<_DocumentEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DocumentEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DocumentEntity&&(identical(other.type, type) || other.type == type)&&(identical(other.status, status) || other.status == status)&&(identical(other.mediaUrl, mediaUrl) || other.mediaUrl == mediaUrl)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,status,mediaUrl,reviewedAt,rejectionReason);

@override
String toString() {
  return 'DocumentEntity(type: $type, status: $status, mediaUrl: $mediaUrl, reviewedAt: $reviewedAt, rejectionReason: $rejectionReason)';
}


}

/// @nodoc
abstract mixin class _$DocumentEntityCopyWith<$Res> implements $DocumentEntityCopyWith<$Res> {
  factory _$DocumentEntityCopyWith(_DocumentEntity value, $Res Function(_DocumentEntity) _then) = __$DocumentEntityCopyWithImpl;
@override @useResult
$Res call({
 String type, String status,@JsonKey(name: 'media_url') String? mediaUrl,@JsonKey(name: 'reviewed_at') String? reviewedAt,@JsonKey(name: 'rejection_reason') String? rejectionReason
});




}
/// @nodoc
class __$DocumentEntityCopyWithImpl<$Res>
    implements _$DocumentEntityCopyWith<$Res> {
  __$DocumentEntityCopyWithImpl(this._self, this._then);

  final _DocumentEntity _self;
  final $Res Function(_DocumentEntity) _then;

/// Create a copy of DocumentEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? status = null,Object? mediaUrl = freezed,Object? reviewedAt = freezed,Object? rejectionReason = freezed,}) {
  return _then(_DocumentEntity(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,mediaUrl: freezed == mediaUrl ? _self.mediaUrl : mediaUrl // ignore: cast_nullable_to_non_nullable
as String?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VehicleTypeEntity {

 String get id; String get name;@JsonKey(name: 'display_name') String get displayName;@JsonKey(name: 'is_enabled') bool get isEnabled;
/// Create a copy of VehicleTypeEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VehicleTypeEntityCopyWith<VehicleTypeEntity> get copyWith => _$VehicleTypeEntityCopyWithImpl<VehicleTypeEntity>(this as VehicleTypeEntity, _$identity);

  /// Serializes this VehicleTypeEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VehicleTypeEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayName,isEnabled);

@override
String toString() {
  return 'VehicleTypeEntity(id: $id, name: $name, displayName: $displayName, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class $VehicleTypeEntityCopyWith<$Res>  {
  factory $VehicleTypeEntityCopyWith(VehicleTypeEntity value, $Res Function(VehicleTypeEntity) _then) = _$VehicleTypeEntityCopyWithImpl;
@useResult
$Res call({
 String id, String name,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'is_enabled') bool isEnabled
});




}
/// @nodoc
class _$VehicleTypeEntityCopyWithImpl<$Res>
    implements $VehicleTypeEntityCopyWith<$Res> {
  _$VehicleTypeEntityCopyWithImpl(this._self, this._then);

  final VehicleTypeEntity _self;
  final $Res Function(VehicleTypeEntity) _then;

/// Create a copy of VehicleTypeEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? isEnabled = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VehicleTypeEntity].
extension VehicleTypeEntityPatterns on VehicleTypeEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VehicleTypeEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VehicleTypeEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VehicleTypeEntity value)  $default,){
final _that = this;
switch (_that) {
case _VehicleTypeEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VehicleTypeEntity value)?  $default,){
final _that = this;
switch (_that) {
case _VehicleTypeEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'is_enabled')  bool isEnabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VehicleTypeEntity() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.isEnabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'is_enabled')  bool isEnabled)  $default,) {final _that = this;
switch (_that) {
case _VehicleTypeEntity():
return $default(_that.id,_that.name,_that.displayName,_that.isEnabled);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'is_enabled')  bool isEnabled)?  $default,) {final _that = this;
switch (_that) {
case _VehicleTypeEntity() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.isEnabled);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VehicleTypeEntity implements VehicleTypeEntity {
  const _VehicleTypeEntity({required this.id, required this.name, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'is_enabled') this.isEnabled = false});
  factory _VehicleTypeEntity.fromJson(Map<String, dynamic> json) => _$VehicleTypeEntityFromJson(json);

@override final  String id;
@override final  String name;
@override@JsonKey(name: 'display_name') final  String displayName;
@override@JsonKey(name: 'is_enabled') final  bool isEnabled;

/// Create a copy of VehicleTypeEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VehicleTypeEntityCopyWith<_VehicleTypeEntity> get copyWith => __$VehicleTypeEntityCopyWithImpl<_VehicleTypeEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VehicleTypeEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VehicleTypeEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.isEnabled, isEnabled) || other.isEnabled == isEnabled));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayName,isEnabled);

@override
String toString() {
  return 'VehicleTypeEntity(id: $id, name: $name, displayName: $displayName, isEnabled: $isEnabled)';
}


}

/// @nodoc
abstract mixin class _$VehicleTypeEntityCopyWith<$Res> implements $VehicleTypeEntityCopyWith<$Res> {
  factory _$VehicleTypeEntityCopyWith(_VehicleTypeEntity value, $Res Function(_VehicleTypeEntity) _then) = __$VehicleTypeEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String name,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'is_enabled') bool isEnabled
});




}
/// @nodoc
class __$VehicleTypeEntityCopyWithImpl<$Res>
    implements _$VehicleTypeEntityCopyWith<$Res> {
  __$VehicleTypeEntityCopyWithImpl(this._self, this._then);

  final _VehicleTypeEntity _self;
  final $Res Function(_VehicleTypeEntity) _then;

/// Create a copy of VehicleTypeEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? isEnabled = null,}) {
  return _then(_VehicleTypeEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,isEnabled: null == isEnabled ? _self.isEnabled : isEnabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
