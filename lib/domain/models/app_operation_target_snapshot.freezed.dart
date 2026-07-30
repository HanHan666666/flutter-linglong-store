// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_operation_target_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppOperationTargetSnapshot {

/// 应用主身份。
 String get appId;/// 入队时的用户可见名称。
 String get displayName;/// 入队时的图标地址，仅供历史界面展示。
 String? get icon;/// 本机实例架构，用于多实例精确恢复。
 String? get arch;/// 本机实例渠道，用于多实例精确恢复。
 String? get channel;/// 本机实例模块，用于多实例精确恢复。
 String? get module;/// 本机实例仓库，用于多实例精确恢复。
 String? get repoName;/// 更新开始前已安装的版本。
 String? get installedVersion;/// 更新成功后应当出现的版本。
 String? get expectedVersion;/// 显式版本安装传给 ll-cli 的版本参数。
 String? get requestedInstallVersion;
/// Create a copy of AppOperationTargetSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppOperationTargetSnapshotCopyWith<AppOperationTargetSnapshot> get copyWith => _$AppOperationTargetSnapshotCopyWithImpl<AppOperationTargetSnapshot>(this as AppOperationTargetSnapshot, _$identity);

  /// Serializes this AppOperationTargetSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppOperationTargetSnapshot&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.module, module) || other.module == module)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.expectedVersion, expectedVersion) || other.expectedVersion == expectedVersion)&&(identical(other.requestedInstallVersion, requestedInstallVersion) || other.requestedInstallVersion == requestedInstallVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,displayName,icon,arch,channel,module,repoName,installedVersion,expectedVersion,requestedInstallVersion);

@override
String toString() {
  return 'AppOperationTargetSnapshot(appId: $appId, displayName: $displayName, icon: $icon, arch: $arch, channel: $channel, module: $module, repoName: $repoName, installedVersion: $installedVersion, expectedVersion: $expectedVersion, requestedInstallVersion: $requestedInstallVersion)';
}


}

/// @nodoc
abstract mixin class $AppOperationTargetSnapshotCopyWith<$Res>  {
  factory $AppOperationTargetSnapshotCopyWith(AppOperationTargetSnapshot value, $Res Function(AppOperationTargetSnapshot) _then) = _$AppOperationTargetSnapshotCopyWithImpl;
@useResult
$Res call({
 String appId, String displayName, String? icon, String? arch, String? channel, String? module, String? repoName, String? installedVersion, String? expectedVersion, String? requestedInstallVersion
});




}
/// @nodoc
class _$AppOperationTargetSnapshotCopyWithImpl<$Res>
    implements $AppOperationTargetSnapshotCopyWith<$Res> {
  _$AppOperationTargetSnapshotCopyWithImpl(this._self, this._then);

  final AppOperationTargetSnapshot _self;
  final $Res Function(AppOperationTargetSnapshot) _then;

/// Create a copy of AppOperationTargetSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? displayName = null,Object? icon = freezed,Object? arch = freezed,Object? channel = freezed,Object? module = freezed,Object? repoName = freezed,Object? installedVersion = freezed,Object? expectedVersion = freezed,Object? requestedInstallVersion = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,installedVersion: freezed == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String?,expectedVersion: freezed == expectedVersion ? _self.expectedVersion : expectedVersion // ignore: cast_nullable_to_non_nullable
as String?,requestedInstallVersion: freezed == requestedInstallVersion ? _self.requestedInstallVersion : requestedInstallVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppOperationTargetSnapshot].
extension AppOperationTargetSnapshotPatterns on AppOperationTargetSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppOperationTargetSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppOperationTargetSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppOperationTargetSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String displayName,  String? icon,  String? arch,  String? channel,  String? module,  String? repoName,  String? installedVersion,  String? expectedVersion,  String? requestedInstallVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot() when $default != null:
return $default(_that.appId,_that.displayName,_that.icon,_that.arch,_that.channel,_that.module,_that.repoName,_that.installedVersion,_that.expectedVersion,_that.requestedInstallVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String displayName,  String? icon,  String? arch,  String? channel,  String? module,  String? repoName,  String? installedVersion,  String? expectedVersion,  String? requestedInstallVersion)  $default,) {final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot():
return $default(_that.appId,_that.displayName,_that.icon,_that.arch,_that.channel,_that.module,_that.repoName,_that.installedVersion,_that.expectedVersion,_that.requestedInstallVersion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String displayName,  String? icon,  String? arch,  String? channel,  String? module,  String? repoName,  String? installedVersion,  String? expectedVersion,  String? requestedInstallVersion)?  $default,) {final _that = this;
switch (_that) {
case _AppOperationTargetSnapshot() when $default != null:
return $default(_that.appId,_that.displayName,_that.icon,_that.arch,_that.channel,_that.module,_that.repoName,_that.installedVersion,_that.expectedVersion,_that.requestedInstallVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppOperationTargetSnapshot implements AppOperationTargetSnapshot {
  const _AppOperationTargetSnapshot({required this.appId, required this.displayName, this.icon, this.arch, this.channel, this.module, this.repoName, this.installedVersion, this.expectedVersion, this.requestedInstallVersion});
  factory _AppOperationTargetSnapshot.fromJson(Map<String, dynamic> json) => _$AppOperationTargetSnapshotFromJson(json);

/// 应用主身份。
@override final  String appId;
/// 入队时的用户可见名称。
@override final  String displayName;
/// 入队时的图标地址，仅供历史界面展示。
@override final  String? icon;
/// 本机实例架构，用于多实例精确恢复。
@override final  String? arch;
/// 本机实例渠道，用于多实例精确恢复。
@override final  String? channel;
/// 本机实例模块，用于多实例精确恢复。
@override final  String? module;
/// 本机实例仓库，用于多实例精确恢复。
@override final  String? repoName;
/// 更新开始前已安装的版本。
@override final  String? installedVersion;
/// 更新成功后应当出现的版本。
@override final  String? expectedVersion;
/// 显式版本安装传给 ll-cli 的版本参数。
@override final  String? requestedInstallVersion;

/// Create a copy of AppOperationTargetSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppOperationTargetSnapshotCopyWith<_AppOperationTargetSnapshot> get copyWith => __$AppOperationTargetSnapshotCopyWithImpl<_AppOperationTargetSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppOperationTargetSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppOperationTargetSnapshot&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.module, module) || other.module == module)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installedVersion, installedVersion) || other.installedVersion == installedVersion)&&(identical(other.expectedVersion, expectedVersion) || other.expectedVersion == expectedVersion)&&(identical(other.requestedInstallVersion, requestedInstallVersion) || other.requestedInstallVersion == requestedInstallVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,displayName,icon,arch,channel,module,repoName,installedVersion,expectedVersion,requestedInstallVersion);

@override
String toString() {
  return 'AppOperationTargetSnapshot(appId: $appId, displayName: $displayName, icon: $icon, arch: $arch, channel: $channel, module: $module, repoName: $repoName, installedVersion: $installedVersion, expectedVersion: $expectedVersion, requestedInstallVersion: $requestedInstallVersion)';
}


}

/// @nodoc
abstract mixin class _$AppOperationTargetSnapshotCopyWith<$Res> implements $AppOperationTargetSnapshotCopyWith<$Res> {
  factory _$AppOperationTargetSnapshotCopyWith(_AppOperationTargetSnapshot value, $Res Function(_AppOperationTargetSnapshot) _then) = __$AppOperationTargetSnapshotCopyWithImpl;
@override @useResult
$Res call({
 String appId, String displayName, String? icon, String? arch, String? channel, String? module, String? repoName, String? installedVersion, String? expectedVersion, String? requestedInstallVersion
});




}
/// @nodoc
class __$AppOperationTargetSnapshotCopyWithImpl<$Res>
    implements _$AppOperationTargetSnapshotCopyWith<$Res> {
  __$AppOperationTargetSnapshotCopyWithImpl(this._self, this._then);

  final _AppOperationTargetSnapshot _self;
  final $Res Function(_AppOperationTargetSnapshot) _then;

/// Create a copy of AppOperationTargetSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? displayName = null,Object? icon = freezed,Object? arch = freezed,Object? channel = freezed,Object? module = freezed,Object? repoName = freezed,Object? installedVersion = freezed,Object? expectedVersion = freezed,Object? requestedInstallVersion = freezed,}) {
  return _then(_AppOperationTargetSnapshot(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,installedVersion: freezed == installedVersion ? _self.installedVersion : installedVersion // ignore: cast_nullable_to_non_nullable
as String?,expectedVersion: freezed == expectedVersion ? _self.expectedVersion : expectedVersion // ignore: cast_nullable_to_non_nullable
as String?,requestedInstallVersion: freezed == requestedInstallVersion ? _self.requestedInstallVersion : requestedInstallVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
