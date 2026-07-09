// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'messenger_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MessengerState {

/// Pending offer awaiting accept/reject (pre-accept).
 MessengerOffer? get currentOffer;/// The accepted order currently being delivered.
 MessengerOrder? get activeOrder; bool get isModalVisible; bool get isSubmitting; String get errorMessage;
/// Create a copy of MessengerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MessengerStateCopyWith<MessengerState> get copyWith => _$MessengerStateCopyWithImpl<MessengerState>(this as MessengerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MessengerState&&(identical(other.currentOffer, currentOffer) || other.currentOffer == currentOffer)&&(identical(other.activeOrder, activeOrder) || other.activeOrder == activeOrder)&&(identical(other.isModalVisible, isModalVisible) || other.isModalVisible == isModalVisible)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentOffer,activeOrder,isModalVisible,isSubmitting,errorMessage);

@override
String toString() {
  return 'MessengerState(currentOffer: $currentOffer, activeOrder: $activeOrder, isModalVisible: $isModalVisible, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $MessengerStateCopyWith<$Res>  {
  factory $MessengerStateCopyWith(MessengerState value, $Res Function(MessengerState) _then) = _$MessengerStateCopyWithImpl;
@useResult
$Res call({
 MessengerOffer? currentOffer, MessengerOrder? activeOrder, bool isModalVisible, bool isSubmitting, String errorMessage
});




}
/// @nodoc
class _$MessengerStateCopyWithImpl<$Res>
    implements $MessengerStateCopyWith<$Res> {
  _$MessengerStateCopyWithImpl(this._self, this._then);

  final MessengerState _self;
  final $Res Function(MessengerState) _then;

/// Create a copy of MessengerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentOffer = freezed,Object? activeOrder = freezed,Object? isModalVisible = null,Object? isSubmitting = null,Object? errorMessage = null,}) {
  return _then(_self.copyWith(
currentOffer: freezed == currentOffer ? _self.currentOffer : currentOffer // ignore: cast_nullable_to_non_nullable
as MessengerOffer?,activeOrder: freezed == activeOrder ? _self.activeOrder : activeOrder // ignore: cast_nullable_to_non_nullable
as MessengerOrder?,isModalVisible: null == isModalVisible ? _self.isModalVisible : isModalVisible // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MessengerState].
extension MessengerStatePatterns on MessengerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MessengerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MessengerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MessengerState value)  $default,){
final _that = this;
switch (_that) {
case _MessengerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MessengerState value)?  $default,){
final _that = this;
switch (_that) {
case _MessengerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MessengerOffer? currentOffer,  MessengerOrder? activeOrder,  bool isModalVisible,  bool isSubmitting,  String errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MessengerState() when $default != null:
return $default(_that.currentOffer,_that.activeOrder,_that.isModalVisible,_that.isSubmitting,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MessengerOffer? currentOffer,  MessengerOrder? activeOrder,  bool isModalVisible,  bool isSubmitting,  String errorMessage)  $default,) {final _that = this;
switch (_that) {
case _MessengerState():
return $default(_that.currentOffer,_that.activeOrder,_that.isModalVisible,_that.isSubmitting,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MessengerOffer? currentOffer,  MessengerOrder? activeOrder,  bool isModalVisible,  bool isSubmitting,  String errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _MessengerState() when $default != null:
return $default(_that.currentOffer,_that.activeOrder,_that.isModalVisible,_that.isSubmitting,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _MessengerState implements MessengerState {
  const _MessengerState({this.currentOffer, this.activeOrder, this.isModalVisible = false, this.isSubmitting = false, this.errorMessage = ''});
  

/// Pending offer awaiting accept/reject (pre-accept).
@override final  MessengerOffer? currentOffer;
/// The accepted order currently being delivered.
@override final  MessengerOrder? activeOrder;
@override@JsonKey() final  bool isModalVisible;
@override@JsonKey() final  bool isSubmitting;
@override@JsonKey() final  String errorMessage;

/// Create a copy of MessengerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MessengerStateCopyWith<_MessengerState> get copyWith => __$MessengerStateCopyWithImpl<_MessengerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MessengerState&&(identical(other.currentOffer, currentOffer) || other.currentOffer == currentOffer)&&(identical(other.activeOrder, activeOrder) || other.activeOrder == activeOrder)&&(identical(other.isModalVisible, isModalVisible) || other.isModalVisible == isModalVisible)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,currentOffer,activeOrder,isModalVisible,isSubmitting,errorMessage);

@override
String toString() {
  return 'MessengerState(currentOffer: $currentOffer, activeOrder: $activeOrder, isModalVisible: $isModalVisible, isSubmitting: $isSubmitting, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$MessengerStateCopyWith<$Res> implements $MessengerStateCopyWith<$Res> {
  factory _$MessengerStateCopyWith(_MessengerState value, $Res Function(_MessengerState) _then) = __$MessengerStateCopyWithImpl;
@override @useResult
$Res call({
 MessengerOffer? currentOffer, MessengerOrder? activeOrder, bool isModalVisible, bool isSubmitting, String errorMessage
});




}
/// @nodoc
class __$MessengerStateCopyWithImpl<$Res>
    implements _$MessengerStateCopyWith<$Res> {
  __$MessengerStateCopyWithImpl(this._self, this._then);

  final _MessengerState _self;
  final $Res Function(_MessengerState) _then;

/// Create a copy of MessengerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentOffer = freezed,Object? activeOrder = freezed,Object? isModalVisible = null,Object? isSubmitting = null,Object? errorMessage = null,}) {
  return _then(_MessengerState(
currentOffer: freezed == currentOffer ? _self.currentOffer : currentOffer // ignore: cast_nullable_to_non_nullable
as MessengerOffer?,activeOrder: freezed == activeOrder ? _self.activeOrder : activeOrder // ignore: cast_nullable_to_non_nullable
as MessengerOrder?,isModalVisible: null == isModalVisible ? _self.isModalVisible : isModalVisible // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
