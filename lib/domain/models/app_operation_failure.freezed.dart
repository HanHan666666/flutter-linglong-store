// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_operation_failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppOperationFailure {

 AppOperationFailureKind get kind;/// ll-cli JSON 错误码；非 CLI 错误保持为空。
 int? get cliCode;/// 未经本地化和改写的底层诊断，用于日志与错误解决方案查询。
 String? get diagnostic;/// 需要追加发行版提示的稳定业务场景。
 LinuxDistributionGuidanceScenario? get guidanceScenario;
/// Create a copy of AppOperationFailure
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppOperationFailureCopyWith<AppOperationFailure> get copyWith => _$AppOperationFailureCopyWithImpl<AppOperationFailure>(this as AppOperationFailure, _$identity);

  /// Serializes this AppOperationFailure to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppOperationFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.cliCode, cliCode) || other.cliCode == cliCode)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic)&&(identical(other.guidanceScenario, guidanceScenario) || other.guidanceScenario == guidanceScenario));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,cliCode,diagnostic,guidanceScenario);

@override
String toString() {
  return 'AppOperationFailure(kind: $kind, cliCode: $cliCode, diagnostic: $diagnostic, guidanceScenario: $guidanceScenario)';
}


}

/// @nodoc
abstract mixin class $AppOperationFailureCopyWith<$Res>  {
  factory $AppOperationFailureCopyWith(AppOperationFailure value, $Res Function(AppOperationFailure) _then) = _$AppOperationFailureCopyWithImpl;
@useResult
$Res call({
 AppOperationFailureKind kind, int? cliCode, String? diagnostic, LinuxDistributionGuidanceScenario? guidanceScenario
});




}
/// @nodoc
class _$AppOperationFailureCopyWithImpl<$Res>
    implements $AppOperationFailureCopyWith<$Res> {
  _$AppOperationFailureCopyWithImpl(this._self, this._then);

  final AppOperationFailure _self;
  final $Res Function(AppOperationFailure) _then;

/// Create a copy of AppOperationFailure
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? cliCode = freezed,Object? diagnostic = freezed,Object? guidanceScenario = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AppOperationFailureKind,cliCode: freezed == cliCode ? _self.cliCode : cliCode // ignore: cast_nullable_to_non_nullable
as int?,diagnostic: freezed == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String?,guidanceScenario: freezed == guidanceScenario ? _self.guidanceScenario : guidanceScenario // ignore: cast_nullable_to_non_nullable
as LinuxDistributionGuidanceScenario?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppOperationFailure].
extension AppOperationFailurePatterns on AppOperationFailure {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppOperationFailure value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppOperationFailure() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppOperationFailure value)  $default,){
final _that = this;
switch (_that) {
case _AppOperationFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppOperationFailure value)?  $default,){
final _that = this;
switch (_that) {
case _AppOperationFailure() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AppOperationFailureKind kind,  int? cliCode,  String? diagnostic,  LinuxDistributionGuidanceScenario? guidanceScenario)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppOperationFailure() when $default != null:
return $default(_that.kind,_that.cliCode,_that.diagnostic,_that.guidanceScenario);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AppOperationFailureKind kind,  int? cliCode,  String? diagnostic,  LinuxDistributionGuidanceScenario? guidanceScenario)  $default,) {final _that = this;
switch (_that) {
case _AppOperationFailure():
return $default(_that.kind,_that.cliCode,_that.diagnostic,_that.guidanceScenario);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AppOperationFailureKind kind,  int? cliCode,  String? diagnostic,  LinuxDistributionGuidanceScenario? guidanceScenario)?  $default,) {final _that = this;
switch (_that) {
case _AppOperationFailure() when $default != null:
return $default(_that.kind,_that.cliCode,_that.diagnostic,_that.guidanceScenario);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppOperationFailure implements AppOperationFailure {
  const _AppOperationFailure({required this.kind, this.cliCode, this.diagnostic, this.guidanceScenario});
  factory _AppOperationFailure.fromJson(Map<String, dynamic> json) => _$AppOperationFailureFromJson(json);

@override final  AppOperationFailureKind kind;
/// ll-cli JSON 错误码；非 CLI 错误保持为空。
@override final  int? cliCode;
/// 未经本地化和改写的底层诊断，用于日志与错误解决方案查询。
@override final  String? diagnostic;
/// 需要追加发行版提示的稳定业务场景。
@override final  LinuxDistributionGuidanceScenario? guidanceScenario;

/// Create a copy of AppOperationFailure
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppOperationFailureCopyWith<_AppOperationFailure> get copyWith => __$AppOperationFailureCopyWithImpl<_AppOperationFailure>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppOperationFailureToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppOperationFailure&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.cliCode, cliCode) || other.cliCode == cliCode)&&(identical(other.diagnostic, diagnostic) || other.diagnostic == diagnostic)&&(identical(other.guidanceScenario, guidanceScenario) || other.guidanceScenario == guidanceScenario));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,cliCode,diagnostic,guidanceScenario);

@override
String toString() {
  return 'AppOperationFailure(kind: $kind, cliCode: $cliCode, diagnostic: $diagnostic, guidanceScenario: $guidanceScenario)';
}


}

/// @nodoc
abstract mixin class _$AppOperationFailureCopyWith<$Res> implements $AppOperationFailureCopyWith<$Res> {
  factory _$AppOperationFailureCopyWith(_AppOperationFailure value, $Res Function(_AppOperationFailure) _then) = __$AppOperationFailureCopyWithImpl;
@override @useResult
$Res call({
 AppOperationFailureKind kind, int? cliCode, String? diagnostic, LinuxDistributionGuidanceScenario? guidanceScenario
});




}
/// @nodoc
class __$AppOperationFailureCopyWithImpl<$Res>
    implements _$AppOperationFailureCopyWith<$Res> {
  __$AppOperationFailureCopyWithImpl(this._self, this._then);

  final _AppOperationFailure _self;
  final $Res Function(_AppOperationFailure) _then;

/// Create a copy of AppOperationFailure
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? cliCode = freezed,Object? diagnostic = freezed,Object? guidanceScenario = freezed,}) {
  return _then(_AppOperationFailure(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AppOperationFailureKind,cliCode: freezed == cliCode ? _self.cliCode : cliCode // ignore: cast_nullable_to_non_nullable
as int?,diagnostic: freezed == diagnostic ? _self.diagnostic : diagnostic // ignore: cast_nullable_to_non_nullable
as String?,guidanceScenario: freezed == guidanceScenario ? _self.guidanceScenario : guidanceScenario // ignore: cast_nullable_to_non_nullable
as LinuxDistributionGuidanceScenario?,
  ));
}


}

// dart format on
