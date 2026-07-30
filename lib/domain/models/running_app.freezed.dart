// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'running_app.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RunningApp {

/// 稳定唯一键，和 Rust 版本保持一致，使用 containerId。
 String get id;/// 应用 ID，如 org.deepin.calculator。
 String get appId;/// 展示名称；优先使用 list 结果中的名称，缺失时回退为 appId。
 String get name;/// 运行中的版本号。
 String get version;/// 架构，如 x86_64。
 String get arch;/// 渠道，如 main。
 String get channel;/// 来源，通常取 runtime 前缀。
 String get source; int get pid;/// 容器 ID，来自 `ll-cli --json ps`。
 String get containerId; String? get icon;
/// Create a copy of RunningApp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RunningAppCopyWith<RunningApp> get copyWith => _$RunningAppCopyWithImpl<RunningApp>(this as RunningApp, _$identity);

  /// Serializes this RunningApp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RunningApp&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.source, source) || other.source == source)&&(identical(other.pid, pid) || other.pid == pid)&&(identical(other.containerId, containerId) || other.containerId == containerId)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,name,version,arch,channel,source,pid,containerId,icon);

@override
String toString() {
  return 'RunningApp(id: $id, appId: $appId, name: $name, version: $version, arch: $arch, channel: $channel, source: $source, pid: $pid, containerId: $containerId, icon: $icon)';
}


}

/// @nodoc
abstract mixin class $RunningAppCopyWith<$Res>  {
  factory $RunningAppCopyWith(RunningApp value, $Res Function(RunningApp) _then) = _$RunningAppCopyWithImpl;
@useResult
$Res call({
 String id, String appId, String name, String version, String arch, String channel, String source, int pid, String containerId, String? icon
});




}
/// @nodoc
class _$RunningAppCopyWithImpl<$Res>
    implements $RunningAppCopyWith<$Res> {
  _$RunningAppCopyWithImpl(this._self, this._then);

  final RunningApp _self;
  final $Res Function(RunningApp) _then;

/// Create a copy of RunningApp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? name = null,Object? version = null,Object? arch = null,Object? channel = null,Object? source = null,Object? pid = null,Object? containerId = null,Object? icon = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,pid: null == pid ? _self.pid : pid // ignore: cast_nullable_to_non_nullable
as int,containerId: null == containerId ? _self.containerId : containerId // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [RunningApp].
extension RunningAppPatterns on RunningApp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RunningApp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RunningApp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RunningApp value)  $default,){
final _that = this;
switch (_that) {
case _RunningApp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RunningApp value)?  $default,){
final _that = this;
switch (_that) {
case _RunningApp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String appId,  String name,  String version,  String arch,  String channel,  String source,  int pid,  String containerId,  String? icon)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RunningApp() when $default != null:
return $default(_that.id,_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.source,_that.pid,_that.containerId,_that.icon);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String appId,  String name,  String version,  String arch,  String channel,  String source,  int pid,  String containerId,  String? icon)  $default,) {final _that = this;
switch (_that) {
case _RunningApp():
return $default(_that.id,_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.source,_that.pid,_that.containerId,_that.icon);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String appId,  String name,  String version,  String arch,  String channel,  String source,  int pid,  String containerId,  String? icon)?  $default,) {final _that = this;
switch (_that) {
case _RunningApp() when $default != null:
return $default(_that.id,_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.source,_that.pid,_that.containerId,_that.icon);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RunningApp implements RunningApp {
  const _RunningApp({required this.id, required this.appId, required this.name, required this.version, required this.arch, required this.channel, required this.source, required this.pid, required this.containerId, this.icon});
  factory _RunningApp.fromJson(Map<String, dynamic> json) => _$RunningAppFromJson(json);

/// 稳定唯一键，和 Rust 版本保持一致，使用 containerId。
@override final  String id;
/// 应用 ID，如 org.deepin.calculator。
@override final  String appId;
/// 展示名称；优先使用 list 结果中的名称，缺失时回退为 appId。
@override final  String name;
/// 运行中的版本号。
@override final  String version;
/// 架构，如 x86_64。
@override final  String arch;
/// 渠道，如 main。
@override final  String channel;
/// 来源，通常取 runtime 前缀。
@override final  String source;
@override final  int pid;
/// 容器 ID，来自 `ll-cli --json ps`。
@override final  String containerId;
@override final  String? icon;

/// Create a copy of RunningApp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RunningAppCopyWith<_RunningApp> get copyWith => __$RunningAppCopyWithImpl<_RunningApp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RunningAppToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RunningApp&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.source, source) || other.source == source)&&(identical(other.pid, pid) || other.pid == pid)&&(identical(other.containerId, containerId) || other.containerId == containerId)&&(identical(other.icon, icon) || other.icon == icon));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,name,version,arch,channel,source,pid,containerId,icon);

@override
String toString() {
  return 'RunningApp(id: $id, appId: $appId, name: $name, version: $version, arch: $arch, channel: $channel, source: $source, pid: $pid, containerId: $containerId, icon: $icon)';
}


}

/// @nodoc
abstract mixin class _$RunningAppCopyWith<$Res> implements $RunningAppCopyWith<$Res> {
  factory _$RunningAppCopyWith(_RunningApp value, $Res Function(_RunningApp) _then) = __$RunningAppCopyWithImpl;
@override @useResult
$Res call({
 String id, String appId, String name, String version, String arch, String channel, String source, int pid, String containerId, String? icon
});




}
/// @nodoc
class __$RunningAppCopyWithImpl<$Res>
    implements _$RunningAppCopyWith<$Res> {
  __$RunningAppCopyWithImpl(this._self, this._then);

  final _RunningApp _self;
  final $Res Function(_RunningApp) _then;

/// Create a copy of RunningApp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? name = null,Object? version = null,Object? arch = null,Object? channel = null,Object? source = null,Object? pid = null,Object? containerId = null,Object? icon = freezed,}) {
  return _then(_RunningApp(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,channel: null == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,pid: null == pid ? _self.pid : pid // ignore: cast_nullable_to_non_nullable
as int,containerId: null == containerId ? _self.containerId : containerId // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
