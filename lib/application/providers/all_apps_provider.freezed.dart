// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'all_apps_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AllAppsState {

 bool get isLoading; bool get isLoadingMore; String? get error; AllAppsData? get data; int get selectedCategoryIndex; int get currentPage;
/// Create a copy of AllAppsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllAppsStateCopyWith<AllAppsState> get copyWith => _$AllAppsStateCopyWithImpl<AllAppsState>(this as AllAppsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AllAppsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.selectedCategoryIndex, selectedCategoryIndex) || other.selectedCategoryIndex == selectedCategoryIndex)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,error,data,selectedCategoryIndex,currentPage);

@override
String toString() {
  return 'AllAppsState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, data: $data, selectedCategoryIndex: $selectedCategoryIndex, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class $AllAppsStateCopyWith<$Res>  {
  factory $AllAppsStateCopyWith(AllAppsState value, $Res Function(AllAppsState) _then) = _$AllAppsStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLoadingMore, String? error, AllAppsData? data, int selectedCategoryIndex, int currentPage
});




}
/// @nodoc
class _$AllAppsStateCopyWithImpl<$Res>
    implements $AllAppsStateCopyWith<$Res> {
  _$AllAppsStateCopyWithImpl(this._self, this._then);

  final AllAppsState _self;
  final $Res Function(AllAppsState) _then;

/// Create a copy of AllAppsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? data = freezed,Object? selectedCategoryIndex = null,Object? currentPage = null,}) {
  return _then(AllAppsState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AllAppsData?,selectedCategoryIndex: null == selectedCategoryIndex ? _self.selectedCategoryIndex : selectedCategoryIndex // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AllAppsState].
extension AllAppsStatePatterns on AllAppsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AllAppsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AllAppsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AllAppsState value)  $default,){
final _that = this;
switch (_that) {
case _AllAppsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AllAppsState value)?  $default,){
final _that = this;
switch (_that) {
case _AllAppsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  String? error,  AllAppsData? data,  int selectedCategoryIndex,  int currentPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AllAppsState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.selectedCategoryIndex,_that.currentPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  String? error,  AllAppsData? data,  int selectedCategoryIndex,  int currentPage)  $default,) {final _that = this;
switch (_that) {
case _AllAppsState():
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.selectedCategoryIndex,_that.currentPage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLoadingMore,  String? error,  AllAppsData? data,  int selectedCategoryIndex,  int currentPage)?  $default,) {final _that = this;
switch (_that) {
case _AllAppsState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.error,_that.data,_that.selectedCategoryIndex,_that.currentPage);case _:
  return null;

}
}

}

/// @nodoc


class _AllAppsState implements AllAppsState {
  const _AllAppsState({this.isLoading = false, this.isLoadingMore = false, this.error, this.data, this.selectedCategoryIndex = 0, this.currentPage = 1});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override final  String? error;
@override final  AllAppsData? data;
@override@JsonKey() final  int selectedCategoryIndex;
@override@JsonKey() final  int currentPage;

/// Create a copy of AllAppsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AllAppsStateCopyWith<_AllAppsState> get copyWith => __$AllAppsStateCopyWithImpl<_AllAppsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AllAppsState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.selectedCategoryIndex, selectedCategoryIndex) || other.selectedCategoryIndex == selectedCategoryIndex)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,error,data,selectedCategoryIndex,currentPage);

@override
String toString() {
  return 'AllAppsState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, data: $data, selectedCategoryIndex: $selectedCategoryIndex, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class _$AllAppsStateCopyWith<$Res> implements $AllAppsStateCopyWith<$Res> {
  factory _$AllAppsStateCopyWith(_AllAppsState value, $Res Function(_AllAppsState) _then) = __$AllAppsStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLoadingMore, String? error, AllAppsData? data, int selectedCategoryIndex, int currentPage
});




}
/// @nodoc
class __$AllAppsStateCopyWithImpl<$Res>
    implements _$AllAppsStateCopyWith<$Res> {
  __$AllAppsStateCopyWithImpl(this._self, this._then);

  final _AllAppsState _self;
  final $Res Function(_AllAppsState) _then;

/// Create a copy of AllAppsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? data = freezed,Object? selectedCategoryIndex = null,Object? currentPage = null,}) {
  return _then(_AllAppsState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AllAppsData?,selectedCategoryIndex: null == selectedCategoryIndex ? _self.selectedCategoryIndex : selectedCategoryIndex // ignore: cast_nullable_to_non_nullable
as int,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
