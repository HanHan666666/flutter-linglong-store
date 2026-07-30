// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'custom_category_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomCategoryState {

 bool get isLoading; bool get isLoadingMore; String? get error; CustomCategoryData? get data; String get categoryCode; int get currentPage;
/// Create a copy of CustomCategoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomCategoryStateCopyWith<CustomCategoryState> get copyWith => _$CustomCategoryStateCopyWithImpl<CustomCategoryState>(this as CustomCategoryState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomCategoryState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,error,data,categoryCode,currentPage);

@override
String toString() {
  return 'CustomCategoryState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, data: $data, categoryCode: $categoryCode, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class $CustomCategoryStateCopyWith<$Res>  {
  factory $CustomCategoryStateCopyWith(CustomCategoryState value, $Res Function(CustomCategoryState) _then) = _$CustomCategoryStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLoadingMore, String? error, CustomCategoryData? data, String categoryCode, int currentPage
});




}
/// @nodoc
class _$CustomCategoryStateCopyWithImpl<$Res>
    implements $CustomCategoryStateCopyWith<$Res> {
  _$CustomCategoryStateCopyWithImpl(this._self, this._then);

  final CustomCategoryState _self;
  final $Res Function(CustomCategoryState) _then;

/// Create a copy of CustomCategoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? data = freezed,Object? categoryCode = null,Object? currentPage = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CustomCategoryData?,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomCategoryState].
extension CustomCategoryStatePatterns on CustomCategoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomCategoryState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomCategoryState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomCategoryState value)  $default,){
final _that = this;
switch (_that) {
case _CustomCategoryState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomCategoryState value)?  $default,){
final _that = this;
switch (_that) {
case _CustomCategoryState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  String? error,  CustomCategoryData? data,  String categoryCode,  int currentPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomCategoryState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.categoryCode,_that.currentPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  String? error,  CustomCategoryData? data,  String categoryCode,  int currentPage)  $default,) {final _that = this;
switch (_that) {
case _CustomCategoryState():
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.categoryCode,_that.currentPage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLoadingMore,  String? error,  CustomCategoryData? data,  String categoryCode,  int currentPage)?  $default,) {final _that = this;
switch (_that) {
case _CustomCategoryState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.categoryCode,_that.currentPage);case _:
  return null;

}
}

}

/// @nodoc


class _CustomCategoryState implements CustomCategoryState {
  const _CustomCategoryState({this.isLoading = false, this.isLoadingMore = false, this.error, this.data, this.categoryCode = '', this.currentPage = 1});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override final  String? error;
@override final  CustomCategoryData? data;
@override@JsonKey() final  String categoryCode;
@override@JsonKey() final  int currentPage;

/// Create a copy of CustomCategoryState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomCategoryStateCopyWith<_CustomCategoryState> get copyWith => __$CustomCategoryStateCopyWithImpl<_CustomCategoryState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomCategoryState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.categoryCode, categoryCode) || other.categoryCode == categoryCode)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,error,data,categoryCode,currentPage);

@override
String toString() {
  return 'CustomCategoryState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, data: $data, categoryCode: $categoryCode, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class _$CustomCategoryStateCopyWith<$Res> implements $CustomCategoryStateCopyWith<$Res> {
  factory _$CustomCategoryStateCopyWith(_CustomCategoryState value, $Res Function(_CustomCategoryState) _then) = __$CustomCategoryStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLoadingMore, String? error, CustomCategoryData? data, String categoryCode, int currentPage
});




}
/// @nodoc
class __$CustomCategoryStateCopyWithImpl<$Res>
    implements _$CustomCategoryStateCopyWith<$Res> {
  __$CustomCategoryStateCopyWithImpl(this._self, this._then);

  final _CustomCategoryState _self;
  final $Res Function(_CustomCategoryState) _then;

/// Create a copy of CustomCategoryState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? data = freezed,Object? categoryCode = null,Object? currentPage = null,}) {
  return _then(_CustomCategoryState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as CustomCategoryData?,categoryCode: null == categoryCode ? _self.categoryCode : categoryCode // ignore: cast_nullable_to_non_nullable
as String,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
