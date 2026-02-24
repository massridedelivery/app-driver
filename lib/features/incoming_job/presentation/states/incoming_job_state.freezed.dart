// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'incoming_job_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$IncomingJobState {

 IncomingJobModel? get currentJob; bool get isModalVisible;
/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IncomingJobStateCopyWith<IncomingJobState> get copyWith => _$IncomingJobStateCopyWithImpl<IncomingJobState>(this as IncomingJobState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IncomingJobState&&(identical(other.currentJob, currentJob) || other.currentJob == currentJob)&&(identical(other.isModalVisible, isModalVisible) || other.isModalVisible == isModalVisible));
}


@override
int get hashCode => Object.hash(runtimeType,currentJob,isModalVisible);

@override
String toString() {
  return 'IncomingJobState(currentJob: $currentJob, isModalVisible: $isModalVisible)';
}


}

/// @nodoc
abstract mixin class $IncomingJobStateCopyWith<$Res>  {
  factory $IncomingJobStateCopyWith(IncomingJobState value, $Res Function(IncomingJobState) _then) = _$IncomingJobStateCopyWithImpl;
@useResult
$Res call({
 IncomingJobModel? currentJob, bool isModalVisible
});


$IncomingJobModelCopyWith<$Res>? get currentJob;

}
/// @nodoc
class _$IncomingJobStateCopyWithImpl<$Res>
    implements $IncomingJobStateCopyWith<$Res> {
  _$IncomingJobStateCopyWithImpl(this._self, this._then);

  final IncomingJobState _self;
  final $Res Function(IncomingJobState) _then;

/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentJob = freezed,Object? isModalVisible = null,}) {
  return _then(_self.copyWith(
currentJob: freezed == currentJob ? _self.currentJob : currentJob // ignore: cast_nullable_to_non_nullable
as IncomingJobModel?,isModalVisible: null == isModalVisible ? _self.isModalVisible : isModalVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingJobModelCopyWith<$Res>? get currentJob {
    if (_self.currentJob == null) {
    return null;
  }

  return $IncomingJobModelCopyWith<$Res>(_self.currentJob!, (value) {
    return _then(_self.copyWith(currentJob: value));
  });
}
}


/// Adds pattern-matching-related methods to [IncomingJobState].
extension IncomingJobStatePatterns on IncomingJobState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IncomingJobState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IncomingJobState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IncomingJobState value)  $default,){
final _that = this;
switch (_that) {
case _IncomingJobState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IncomingJobState value)?  $default,){
final _that = this;
switch (_that) {
case _IncomingJobState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( IncomingJobModel? currentJob,  bool isModalVisible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IncomingJobState() when $default != null:
return $default(_that.currentJob,_that.isModalVisible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( IncomingJobModel? currentJob,  bool isModalVisible)  $default,) {final _that = this;
switch (_that) {
case _IncomingJobState():
return $default(_that.currentJob,_that.isModalVisible);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( IncomingJobModel? currentJob,  bool isModalVisible)?  $default,) {final _that = this;
switch (_that) {
case _IncomingJobState() when $default != null:
return $default(_that.currentJob,_that.isModalVisible);case _:
  return null;

}
}

}

/// @nodoc


class _IncomingJobState extends IncomingJobState {
  const _IncomingJobState({this.currentJob, this.isModalVisible = false}): super._();
  

@override final  IncomingJobModel? currentJob;
@override@JsonKey() final  bool isModalVisible;

/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IncomingJobStateCopyWith<_IncomingJobState> get copyWith => __$IncomingJobStateCopyWithImpl<_IncomingJobState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IncomingJobState&&(identical(other.currentJob, currentJob) || other.currentJob == currentJob)&&(identical(other.isModalVisible, isModalVisible) || other.isModalVisible == isModalVisible));
}


@override
int get hashCode => Object.hash(runtimeType,currentJob,isModalVisible);

@override
String toString() {
  return 'IncomingJobState(currentJob: $currentJob, isModalVisible: $isModalVisible)';
}


}

/// @nodoc
abstract mixin class _$IncomingJobStateCopyWith<$Res> implements $IncomingJobStateCopyWith<$Res> {
  factory _$IncomingJobStateCopyWith(_IncomingJobState value, $Res Function(_IncomingJobState) _then) = __$IncomingJobStateCopyWithImpl;
@override @useResult
$Res call({
 IncomingJobModel? currentJob, bool isModalVisible
});


@override $IncomingJobModelCopyWith<$Res>? get currentJob;

}
/// @nodoc
class __$IncomingJobStateCopyWithImpl<$Res>
    implements _$IncomingJobStateCopyWith<$Res> {
  __$IncomingJobStateCopyWithImpl(this._self, this._then);

  final _IncomingJobState _self;
  final $Res Function(_IncomingJobState) _then;

/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentJob = freezed,Object? isModalVisible = null,}) {
  return _then(_IncomingJobState(
currentJob: freezed == currentJob ? _self.currentJob : currentJob // ignore: cast_nullable_to_non_nullable
as IncomingJobModel?,isModalVisible: null == isModalVisible ? _self.isModalVisible : isModalVisible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of IncomingJobState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$IncomingJobModelCopyWith<$Res>? get currentJob {
    if (_self.currentJob == null) {
    return null;
  }

  return $IncomingJobModelCopyWith<$Res>(_self.currentJob!, (value) {
    return _then(_self.copyWith(currentJob: value));
  });
}
}

// dart format on
