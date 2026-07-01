// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalletState {

 bool get isLoading; String get errorMessage; double get balance; String get currency; bool get isVerified; DateTime? get lastUpdated;// Earnings & trips
 double get earningsToday; double get earningsWeek; int get tripsToday; int get totalTripsToday; int get tripsWeek; double get codDebt; double get currentBalance; double get codThreshold; List<Map<String, dynamic>> get transactions; BankAccountInfo? get bankAccountInfo;
/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletStateCopyWith<WalletState> get copyWith => _$WalletStateCopyWithImpl<WalletState>(this as WalletState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.earningsToday, earningsToday) || other.earningsToday == earningsToday)&&(identical(other.earningsWeek, earningsWeek) || other.earningsWeek == earningsWeek)&&(identical(other.tripsToday, tripsToday) || other.tripsToday == tripsToday)&&(identical(other.totalTripsToday, totalTripsToday) || other.totalTripsToday == totalTripsToday)&&(identical(other.tripsWeek, tripsWeek) || other.tripsWeek == tripsWeek)&&(identical(other.codDebt, codDebt) || other.codDebt == codDebt)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.codThreshold, codThreshold) || other.codThreshold == codThreshold)&&const DeepCollectionEquality().equals(other.transactions, transactions)&&(identical(other.bankAccountInfo, bankAccountInfo) || other.bankAccountInfo == bankAccountInfo));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,balance,currency,isVerified,lastUpdated,earningsToday,earningsWeek,tripsToday,totalTripsToday,tripsWeek,codDebt,currentBalance,codThreshold,const DeepCollectionEquality().hash(transactions),bankAccountInfo);

@override
String toString() {
  return 'WalletState(isLoading: $isLoading, errorMessage: $errorMessage, balance: $balance, currency: $currency, isVerified: $isVerified, lastUpdated: $lastUpdated, earningsToday: $earningsToday, earningsWeek: $earningsWeek, tripsToday: $tripsToday, totalTripsToday: $totalTripsToday, tripsWeek: $tripsWeek, codDebt: $codDebt, currentBalance: $currentBalance, codThreshold: $codThreshold, transactions: $transactions, bankAccountInfo: $bankAccountInfo)';
}


}

/// @nodoc
abstract mixin class $WalletStateCopyWith<$Res>  {
  factory $WalletStateCopyWith(WalletState value, $Res Function(WalletState) _then) = _$WalletStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String errorMessage, double balance, String currency, bool isVerified, DateTime? lastUpdated, double earningsToday, double earningsWeek, int tripsToday, int totalTripsToday, int tripsWeek, double codDebt, double currentBalance, double codThreshold, List<Map<String, dynamic>> transactions, BankAccountInfo? bankAccountInfo
});




}
/// @nodoc
class _$WalletStateCopyWithImpl<$Res>
    implements $WalletStateCopyWith<$Res> {
  _$WalletStateCopyWithImpl(this._self, this._then);

  final WalletState _self;
  final $Res Function(WalletState) _then;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? errorMessage = null,Object? balance = null,Object? currency = null,Object? isVerified = null,Object? lastUpdated = freezed,Object? earningsToday = null,Object? earningsWeek = null,Object? tripsToday = null,Object? totalTripsToday = null,Object? tripsWeek = null,Object? codDebt = null,Object? currentBalance = null,Object? codThreshold = null,Object? transactions = null,Object? bankAccountInfo = freezed,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,earningsToday: null == earningsToday ? _self.earningsToday : earningsToday // ignore: cast_nullable_to_non_nullable
as double,earningsWeek: null == earningsWeek ? _self.earningsWeek : earningsWeek // ignore: cast_nullable_to_non_nullable
as double,tripsToday: null == tripsToday ? _self.tripsToday : tripsToday // ignore: cast_nullable_to_non_nullable
as int,totalTripsToday: null == totalTripsToday ? _self.totalTripsToday : totalTripsToday // ignore: cast_nullable_to_non_nullable
as int,tripsWeek: null == tripsWeek ? _self.tripsWeek : tripsWeek // ignore: cast_nullable_to_non_nullable
as int,codDebt: null == codDebt ? _self.codDebt : codDebt // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,codThreshold: null == codThreshold ? _self.codThreshold : codThreshold // ignore: cast_nullable_to_non_nullable
as double,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,bankAccountInfo: freezed == bankAccountInfo ? _self.bankAccountInfo : bankAccountInfo // ignore: cast_nullable_to_non_nullable
as BankAccountInfo?,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletState].
extension WalletStatePatterns on WalletState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletState value)  $default,){
final _that = this;
switch (_that) {
case _WalletState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletState value)?  $default,){
final _that = this;
switch (_that) {
case _WalletState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String errorMessage,  double balance,  String currency,  bool isVerified,  DateTime? lastUpdated,  double earningsToday,  double earningsWeek,  int tripsToday,  int totalTripsToday,  int tripsWeek,  double codDebt,  double currentBalance,  double codThreshold,  List<Map<String, dynamic>> transactions,  BankAccountInfo? bankAccountInfo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.balance,_that.currency,_that.isVerified,_that.lastUpdated,_that.earningsToday,_that.earningsWeek,_that.tripsToday,_that.totalTripsToday,_that.tripsWeek,_that.codDebt,_that.currentBalance,_that.codThreshold,_that.transactions,_that.bankAccountInfo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String errorMessage,  double balance,  String currency,  bool isVerified,  DateTime? lastUpdated,  double earningsToday,  double earningsWeek,  int tripsToday,  int totalTripsToday,  int tripsWeek,  double codDebt,  double currentBalance,  double codThreshold,  List<Map<String, dynamic>> transactions,  BankAccountInfo? bankAccountInfo)  $default,) {final _that = this;
switch (_that) {
case _WalletState():
return $default(_that.isLoading,_that.errorMessage,_that.balance,_that.currency,_that.isVerified,_that.lastUpdated,_that.earningsToday,_that.earningsWeek,_that.tripsToday,_that.totalTripsToday,_that.tripsWeek,_that.codDebt,_that.currentBalance,_that.codThreshold,_that.transactions,_that.bankAccountInfo);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String errorMessage,  double balance,  String currency,  bool isVerified,  DateTime? lastUpdated,  double earningsToday,  double earningsWeek,  int tripsToday,  int totalTripsToday,  int tripsWeek,  double codDebt,  double currentBalance,  double codThreshold,  List<Map<String, dynamic>> transactions,  BankAccountInfo? bankAccountInfo)?  $default,) {final _that = this;
switch (_that) {
case _WalletState() when $default != null:
return $default(_that.isLoading,_that.errorMessage,_that.balance,_that.currency,_that.isVerified,_that.lastUpdated,_that.earningsToday,_that.earningsWeek,_that.tripsToday,_that.totalTripsToday,_that.tripsWeek,_that.codDebt,_that.currentBalance,_that.codThreshold,_that.transactions,_that.bankAccountInfo);case _:
  return null;

}
}

}

/// @nodoc


class _WalletState implements WalletState {
  const _WalletState({this.isLoading = false, this.errorMessage = '', this.balance = 0.0, this.currency = 'THB', this.isVerified = false, this.lastUpdated, this.earningsToday = 0.0, this.earningsWeek = 0.0, this.tripsToday = 0, this.totalTripsToday = 0, this.tripsWeek = 0, this.codDebt = 0.0, this.currentBalance = 0.0, this.codThreshold = -500.0, final  List<Map<String, dynamic>> transactions = const [], this.bankAccountInfo}): _transactions = transactions;
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  String errorMessage;
@override@JsonKey() final  double balance;
@override@JsonKey() final  String currency;
@override@JsonKey() final  bool isVerified;
@override final  DateTime? lastUpdated;
// Earnings & trips
@override@JsonKey() final  double earningsToday;
@override@JsonKey() final  double earningsWeek;
@override@JsonKey() final  int tripsToday;
@override@JsonKey() final  int totalTripsToday;
@override@JsonKey() final  int tripsWeek;
@override@JsonKey() final  double codDebt;
@override@JsonKey() final  double currentBalance;
@override@JsonKey() final  double codThreshold;
 final  List<Map<String, dynamic>> _transactions;
@override@JsonKey() List<Map<String, dynamic>> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

@override final  BankAccountInfo? bankAccountInfo;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletStateCopyWith<_WalletState> get copyWith => __$WalletStateCopyWithImpl<_WalletState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isVerified, isVerified) || other.isVerified == isVerified)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.earningsToday, earningsToday) || other.earningsToday == earningsToday)&&(identical(other.earningsWeek, earningsWeek) || other.earningsWeek == earningsWeek)&&(identical(other.tripsToday, tripsToday) || other.tripsToday == tripsToday)&&(identical(other.totalTripsToday, totalTripsToday) || other.totalTripsToday == totalTripsToday)&&(identical(other.tripsWeek, tripsWeek) || other.tripsWeek == tripsWeek)&&(identical(other.codDebt, codDebt) || other.codDebt == codDebt)&&(identical(other.currentBalance, currentBalance) || other.currentBalance == currentBalance)&&(identical(other.codThreshold, codThreshold) || other.codThreshold == codThreshold)&&const DeepCollectionEquality().equals(other._transactions, _transactions)&&(identical(other.bankAccountInfo, bankAccountInfo) || other.bankAccountInfo == bankAccountInfo));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,errorMessage,balance,currency,isVerified,lastUpdated,earningsToday,earningsWeek,tripsToday,totalTripsToday,tripsWeek,codDebt,currentBalance,codThreshold,const DeepCollectionEquality().hash(_transactions),bankAccountInfo);

@override
String toString() {
  return 'WalletState(isLoading: $isLoading, errorMessage: $errorMessage, balance: $balance, currency: $currency, isVerified: $isVerified, lastUpdated: $lastUpdated, earningsToday: $earningsToday, earningsWeek: $earningsWeek, tripsToday: $tripsToday, totalTripsToday: $totalTripsToday, tripsWeek: $tripsWeek, codDebt: $codDebt, currentBalance: $currentBalance, codThreshold: $codThreshold, transactions: $transactions, bankAccountInfo: $bankAccountInfo)';
}


}

/// @nodoc
abstract mixin class _$WalletStateCopyWith<$Res> implements $WalletStateCopyWith<$Res> {
  factory _$WalletStateCopyWith(_WalletState value, $Res Function(_WalletState) _then) = __$WalletStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String errorMessage, double balance, String currency, bool isVerified, DateTime? lastUpdated, double earningsToday, double earningsWeek, int tripsToday, int totalTripsToday, int tripsWeek, double codDebt, double currentBalance, double codThreshold, List<Map<String, dynamic>> transactions, BankAccountInfo? bankAccountInfo
});




}
/// @nodoc
class __$WalletStateCopyWithImpl<$Res>
    implements _$WalletStateCopyWith<$Res> {
  __$WalletStateCopyWithImpl(this._self, this._then);

  final _WalletState _self;
  final $Res Function(_WalletState) _then;

/// Create a copy of WalletState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? errorMessage = null,Object? balance = null,Object? currency = null,Object? isVerified = null,Object? lastUpdated = freezed,Object? earningsToday = null,Object? earningsWeek = null,Object? tripsToday = null,Object? totalTripsToday = null,Object? tripsWeek = null,Object? codDebt = null,Object? currentBalance = null,Object? codThreshold = null,Object? transactions = null,Object? bankAccountInfo = freezed,}) {
  return _then(_WalletState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,errorMessage: null == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String,balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isVerified: null == isVerified ? _self.isVerified : isVerified // ignore: cast_nullable_to_non_nullable
as bool,lastUpdated: freezed == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as DateTime?,earningsToday: null == earningsToday ? _self.earningsToday : earningsToday // ignore: cast_nullable_to_non_nullable
as double,earningsWeek: null == earningsWeek ? _self.earningsWeek : earningsWeek // ignore: cast_nullable_to_non_nullable
as double,tripsToday: null == tripsToday ? _self.tripsToday : tripsToday // ignore: cast_nullable_to_non_nullable
as int,totalTripsToday: null == totalTripsToday ? _self.totalTripsToday : totalTripsToday // ignore: cast_nullable_to_non_nullable
as int,tripsWeek: null == tripsWeek ? _self.tripsWeek : tripsWeek // ignore: cast_nullable_to_non_nullable
as int,codDebt: null == codDebt ? _self.codDebt : codDebt // ignore: cast_nullable_to_non_nullable
as double,currentBalance: null == currentBalance ? _self.currentBalance : currentBalance // ignore: cast_nullable_to_non_nullable
as double,codThreshold: null == codThreshold ? _self.codThreshold : codThreshold // ignore: cast_nullable_to_non_nullable
as double,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>,bankAccountInfo: freezed == bankAccountInfo ? _self.bankAccountInfo : bankAccountInfo // ignore: cast_nullable_to_non_nullable
as BankAccountInfo?,
  ));
}


}

// dart format on
