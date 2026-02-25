// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'socket_message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SocketMessageModel {

 String get type; Map<String, dynamic>? get data; Map<String, dynamic> get raw;
/// Create a copy of SocketMessageModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SocketMessageModelCopyWith<SocketMessageModel> get copyWith => _$SocketMessageModelCopyWithImpl<SocketMessageModel>(this as SocketMessageModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SocketMessageModel&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.data, data)&&const DeepCollectionEquality().equals(other.raw, raw));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(data),const DeepCollectionEquality().hash(raw));

@override
String toString() {
  return 'SocketMessageModel(type: $type, data: $data, raw: $raw)';
}


}

/// @nodoc
abstract mixin class $SocketMessageModelCopyWith<$Res>  {
  factory $SocketMessageModelCopyWith(SocketMessageModel value, $Res Function(SocketMessageModel) _then) = _$SocketMessageModelCopyWithImpl;
@useResult
$Res call({
 String type, Map<String, dynamic>? data, Map<String, dynamic> raw
});




}
/// @nodoc
class _$SocketMessageModelCopyWithImpl<$Res>
    implements $SocketMessageModelCopyWith<$Res> {
  _$SocketMessageModelCopyWithImpl(this._self, this._then);

  final SocketMessageModel _self;
  final $Res Function(SocketMessageModel) _then;

/// Create a copy of SocketMessageModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? data = freezed,Object? raw = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,raw: null == raw ? _self.raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}

}


/// Adds pattern-matching-related methods to [SocketMessageModel].
extension SocketMessageModelPatterns on SocketMessageModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SocketMessageModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SocketMessageModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SocketMessageModel value)  $default,){
final _that = this;
switch (_that) {
case _SocketMessageModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SocketMessageModel value)?  $default,){
final _that = this;
switch (_that) {
case _SocketMessageModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? data,  Map<String, dynamic> raw)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SocketMessageModel() when $default != null:
return $default(_that.type,_that.data,_that.raw);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  Map<String, dynamic>? data,  Map<String, dynamic> raw)  $default,) {final _that = this;
switch (_that) {
case _SocketMessageModel():
return $default(_that.type,_that.data,_that.raw);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  Map<String, dynamic>? data,  Map<String, dynamic> raw)?  $default,) {final _that = this;
switch (_that) {
case _SocketMessageModel() when $default != null:
return $default(_that.type,_that.data,_that.raw);case _:
  return null;

}
}

}

/// @nodoc


class _SocketMessageModel implements SocketMessageModel {
  const _SocketMessageModel({required this.type, final  Map<String, dynamic>? data, final  Map<String, dynamic> raw = const {}}): _data = data,_raw = raw;
  

@override final  String type;
 final  Map<String, dynamic>? _data;
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

 final  Map<String, dynamic> _raw;
@override@JsonKey() Map<String, dynamic> get raw {
  if (_raw is EqualUnmodifiableMapView) return _raw;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_raw);
}


/// Create a copy of SocketMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SocketMessageModelCopyWith<_SocketMessageModel> get copyWith => __$SocketMessageModelCopyWithImpl<_SocketMessageModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SocketMessageModel&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._data, _data)&&const DeepCollectionEquality().equals(other._raw, _raw));
}


@override
int get hashCode => Object.hash(runtimeType,type,const DeepCollectionEquality().hash(_data),const DeepCollectionEquality().hash(_raw));

@override
String toString() {
  return 'SocketMessageModel(type: $type, data: $data, raw: $raw)';
}


}

/// @nodoc
abstract mixin class _$SocketMessageModelCopyWith<$Res> implements $SocketMessageModelCopyWith<$Res> {
  factory _$SocketMessageModelCopyWith(_SocketMessageModel value, $Res Function(_SocketMessageModel) _then) = __$SocketMessageModelCopyWithImpl;
@override @useResult
$Res call({
 String type, Map<String, dynamic>? data, Map<String, dynamic> raw
});




}
/// @nodoc
class __$SocketMessageModelCopyWithImpl<$Res>
    implements _$SocketMessageModelCopyWith<$Res> {
  __$SocketMessageModelCopyWithImpl(this._self, this._then);

  final _SocketMessageModel _self;
  final $Res Function(_SocketMessageModel) _then;

/// Create a copy of SocketMessageModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? data = freezed,Object? raw = null,}) {
  return _then(_SocketMessageModel(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,raw: null == raw ? _self._raw : raw // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

// dart format on
