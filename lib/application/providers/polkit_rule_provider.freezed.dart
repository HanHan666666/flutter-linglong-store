// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'polkit_rule_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PasswordFreeInstallState {

/// 事务阶段。
 PasswordFreeInstallPhase get phase;/// 最近一次由特权操作确认的配置；没有缓存时为关闭。
 bool get enabled;/// 上一次修改尚未获得可靠结果，或结果未能完整写回缓存。
 bool get needsSync;/// 最近一次失败类型；用于错误详情展示。
 PolkitRuleFailureKind? get lastFailureKind;/// 最近一次失败的诊断摘要；用于可复制错误详情。
 String? get lastDiagnostic;
/// Create a copy of PasswordFreeInstallState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PasswordFreeInstallStateCopyWith<PasswordFreeInstallState> get copyWith => _$PasswordFreeInstallStateCopyWithImpl<PasswordFreeInstallState>(this as PasswordFreeInstallState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PasswordFreeInstallState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.needsSync, needsSync) || other.needsSync == needsSync)&&(identical(other.lastFailureKind, lastFailureKind) || other.lastFailureKind == lastFailureKind)&&(identical(other.lastDiagnostic, lastDiagnostic) || other.lastDiagnostic == lastDiagnostic));
}


@override
int get hashCode => Object.hash(runtimeType,phase,enabled,needsSync,lastFailureKind,lastDiagnostic);

@override
String toString() {
  return 'PasswordFreeInstallState(phase: $phase, enabled: $enabled, needsSync: $needsSync, lastFailureKind: $lastFailureKind, lastDiagnostic: $lastDiagnostic)';
}


}

/// @nodoc
abstract mixin class $PasswordFreeInstallStateCopyWith<$Res>  {
  factory $PasswordFreeInstallStateCopyWith(PasswordFreeInstallState value, $Res Function(PasswordFreeInstallState) _then) = _$PasswordFreeInstallStateCopyWithImpl;
@useResult
$Res call({
 PasswordFreeInstallPhase phase, bool enabled, bool needsSync, PolkitRuleFailureKind? lastFailureKind, String? lastDiagnostic
});




}
/// @nodoc
class _$PasswordFreeInstallStateCopyWithImpl<$Res>
    implements $PasswordFreeInstallStateCopyWith<$Res> {
  _$PasswordFreeInstallStateCopyWithImpl(this._self, this._then);

  final PasswordFreeInstallState _self;
  final $Res Function(PasswordFreeInstallState) _then;

/// Create a copy of PasswordFreeInstallState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? enabled = null,Object? needsSync = null,Object? lastFailureKind = freezed,Object? lastDiagnostic = freezed,}) {
  return _then(PasswordFreeInstallState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PasswordFreeInstallPhase,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,needsSync: null == needsSync ? _self.needsSync : needsSync // ignore: cast_nullable_to_non_nullable
as bool,lastFailureKind: freezed == lastFailureKind ? _self.lastFailureKind : lastFailureKind // ignore: cast_nullable_to_non_nullable
as PolkitRuleFailureKind?,lastDiagnostic: freezed == lastDiagnostic ? _self.lastDiagnostic : lastDiagnostic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PasswordFreeInstallState].
extension PasswordFreeInstallStatePatterns on PasswordFreeInstallState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PasswordFreeInstallState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PasswordFreeInstallState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PasswordFreeInstallState value)  $default,){
final _that = this;
switch (_that) {
case _PasswordFreeInstallState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PasswordFreeInstallState value)?  $default,){
final _that = this;
switch (_that) {
case _PasswordFreeInstallState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PasswordFreeInstallPhase phase,  bool enabled,  bool needsSync,  PolkitRuleFailureKind? lastFailureKind,  String? lastDiagnostic)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PasswordFreeInstallState() when $default != null:
return $default(_that.phase,_that.enabled,_that.needsSync,_that.lastFailureKind,_that.lastDiagnostic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PasswordFreeInstallPhase phase,  bool enabled,  bool needsSync,  PolkitRuleFailureKind? lastFailureKind,  String? lastDiagnostic)  $default,) {final _that = this;
switch (_that) {
case _PasswordFreeInstallState():
return $default(_that.phase,_that.enabled,_that.needsSync,_that.lastFailureKind,_that.lastDiagnostic);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PasswordFreeInstallPhase phase,  bool enabled,  bool needsSync,  PolkitRuleFailureKind? lastFailureKind,  String? lastDiagnostic)?  $default,) {final _that = this;
switch (_that) {
case _PasswordFreeInstallState() when $default != null:
return $default(_that.phase,_that.enabled,_that.needsSync,_that.lastFailureKind,_that.lastDiagnostic);case _:
  return null;

}
}

}

/// @nodoc


class _PasswordFreeInstallState extends PasswordFreeInstallState {
  const _PasswordFreeInstallState({this.phase = PasswordFreeInstallPhase.ready, this.enabled = false, this.needsSync = false, this.lastFailureKind, this.lastDiagnostic}): super._();
  

/// 事务阶段。
@override@JsonKey() final  PasswordFreeInstallPhase phase;
/// 最近一次由特权操作确认的配置；没有缓存时为关闭。
@override@JsonKey() final  bool enabled;
/// 上一次修改尚未获得可靠结果，或结果未能完整写回缓存。
@override@JsonKey() final  bool needsSync;
/// 最近一次失败类型；用于错误详情展示。
@override final  PolkitRuleFailureKind? lastFailureKind;
/// 最近一次失败的诊断摘要；用于可复制错误详情。
@override final  String? lastDiagnostic;

/// Create a copy of PasswordFreeInstallState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PasswordFreeInstallStateCopyWith<_PasswordFreeInstallState> get copyWith => __$PasswordFreeInstallStateCopyWithImpl<_PasswordFreeInstallState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PasswordFreeInstallState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.needsSync, needsSync) || other.needsSync == needsSync)&&(identical(other.lastFailureKind, lastFailureKind) || other.lastFailureKind == lastFailureKind)&&(identical(other.lastDiagnostic, lastDiagnostic) || other.lastDiagnostic == lastDiagnostic));
}


@override
int get hashCode => Object.hash(runtimeType,phase,enabled,needsSync,lastFailureKind,lastDiagnostic);

@override
String toString() {
  return 'PasswordFreeInstallState(phase: $phase, enabled: $enabled, needsSync: $needsSync, lastFailureKind: $lastFailureKind, lastDiagnostic: $lastDiagnostic)';
}


}

/// @nodoc
abstract mixin class _$PasswordFreeInstallStateCopyWith<$Res> implements $PasswordFreeInstallStateCopyWith<$Res> {
  factory _$PasswordFreeInstallStateCopyWith(_PasswordFreeInstallState value, $Res Function(_PasswordFreeInstallState) _then) = __$PasswordFreeInstallStateCopyWithImpl;
@override @useResult
$Res call({
 PasswordFreeInstallPhase phase, bool enabled, bool needsSync, PolkitRuleFailureKind? lastFailureKind, String? lastDiagnostic
});




}
/// @nodoc
class __$PasswordFreeInstallStateCopyWithImpl<$Res>
    implements _$PasswordFreeInstallStateCopyWith<$Res> {
  __$PasswordFreeInstallStateCopyWithImpl(this._self, this._then);

  final _PasswordFreeInstallState _self;
  final $Res Function(_PasswordFreeInstallState) _then;

/// Create a copy of PasswordFreeInstallState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? enabled = null,Object? needsSync = null,Object? lastFailureKind = freezed,Object? lastDiagnostic = freezed,}) {
  return _then(_PasswordFreeInstallState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PasswordFreeInstallPhase,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,needsSync: null == needsSync ? _self.needsSync : needsSync // ignore: cast_nullable_to_non_nullable
as bool,lastFailureKind: freezed == lastFailureKind ? _self.lastFailureKind : lastFailureKind // ignore: cast_nullable_to_non_nullable
as PolkitRuleFailureKind?,lastDiagnostic: freezed == lastDiagnostic ? _self.lastDiagnostic : lastDiagnostic // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
