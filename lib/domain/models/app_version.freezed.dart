// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_version.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppVersion {

/// 版本 ID
 String? get versionId;/// 版本号
 String get versionNo;/// 版本名称
 String? get versionName;/// 描述
 String? get description;/// 发布时间
 String? get releaseTime;/// 包大小
 String? get packageSize;/// 应用 ID
 String? get appId;/// 图标
 String? get icon;/// 类型
 String? get kind;/// 模块
 String? get module;/// 渠道
 String? get channel;/// 架构
 String? get arch;/// 仓库名称
 String? get repoName;/// 安装次数
 int? get installCount;
/// Create a copy of AppVersion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionCopyWith<AppVersion> get copyWith => _$AppVersionCopyWithImpl<AppVersion>(this as AppVersion, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersion&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.versionName, versionName) || other.versionName == versionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installCount, installCount) || other.installCount == installCount));
}


@override
int get hashCode => Object.hash(runtimeType,versionId,versionNo,versionName,description,releaseTime,packageSize,appId,icon,kind,module,channel,arch,repoName,installCount);

@override
String toString() {
  return 'AppVersion(versionId: $versionId, versionNo: $versionNo, versionName: $versionName, description: $description, releaseTime: $releaseTime, packageSize: $packageSize, appId: $appId, icon: $icon, kind: $kind, module: $module, channel: $channel, arch: $arch, repoName: $repoName, installCount: $installCount)';
}


}

/// @nodoc
abstract mixin class $AppVersionCopyWith<$Res>  {
  factory $AppVersionCopyWith(AppVersion value, $Res Function(AppVersion) _then) = _$AppVersionCopyWithImpl;
@useResult
$Res call({
 String? versionId, String versionNo, String? versionName, String? description, String? releaseTime, String? packageSize, String? appId, String? icon, String? kind, String? module, String? channel, String? arch, String? repoName, int? installCount
});




}
/// @nodoc
class _$AppVersionCopyWithImpl<$Res>
    implements $AppVersionCopyWith<$Res> {
  _$AppVersionCopyWithImpl(this._self, this._then);

  final AppVersion _self;
  final $Res Function(AppVersion) _then;

/// Create a copy of AppVersion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? versionId = freezed,Object? versionNo = null,Object? versionName = freezed,Object? description = freezed,Object? releaseTime = freezed,Object? packageSize = freezed,Object? appId = freezed,Object? icon = freezed,Object? kind = freezed,Object? module = freezed,Object? channel = freezed,Object? arch = freezed,Object? repoName = freezed,Object? installCount = freezed,}) {
  return _then(_self.copyWith(
versionId: freezed == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String?,versionNo: null == versionNo ? _self.versionNo : versionNo // ignore: cast_nullable_to_non_nullable
as String,versionName: freezed == versionName ? _self.versionName : versionName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,releaseTime: freezed == releaseTime ? _self.releaseTime : releaseTime // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,installCount: freezed == installCount ? _self.installCount : installCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppVersion].
extension AppVersionPatterns on AppVersion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersion value)  $default,){
final _that = this;
switch (_that) {
case _AppVersion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersion value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? versionId,  String versionNo,  String? versionName,  String? description,  String? releaseTime,  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch,  String? repoName,  int? installCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersion() when $default != null:
return $default(_that.versionId,_that.versionNo,_that.versionName,_that.description,_that.releaseTime,_that.packageSize,_that.appId,_that.icon,_that.kind,_that.module,_that.channel,_that.arch,_that.repoName,_that.installCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? versionId,  String versionNo,  String? versionName,  String? description,  String? releaseTime,  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch,  String? repoName,  int? installCount)  $default,) {final _that = this;
switch (_that) {
case _AppVersion():
return $default(_that.versionId,_that.versionNo,_that.versionName,_that.description,_that.releaseTime,_that.packageSize,_that.appId,_that.icon,_that.kind,_that.module,_that.channel,_that.arch,_that.repoName,_that.installCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? versionId,  String versionNo,  String? versionName,  String? description,  String? releaseTime,  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch,  String? repoName,  int? installCount)?  $default,) {final _that = this;
switch (_that) {
case _AppVersion() when $default != null:
return $default(_that.versionId,_that.versionNo,_that.versionName,_that.description,_that.releaseTime,_that.packageSize,_that.appId,_that.icon,_that.kind,_that.module,_that.channel,_that.arch,_that.repoName,_that.installCount);case _:
  return null;

}
}

}

/// @nodoc


class _AppVersion implements AppVersion {
  const _AppVersion({this.versionId, required this.versionNo, this.versionName, this.description, this.releaseTime, this.packageSize, this.appId, this.icon, this.kind, this.module, this.channel, this.arch, this.repoName, this.installCount});
  

/// 版本 ID
@override final  String? versionId;
/// 版本号
@override final  String versionNo;
/// 版本名称
@override final  String? versionName;
/// 描述
@override final  String? description;
/// 发布时间
@override final  String? releaseTime;
/// 包大小
@override final  String? packageSize;
/// 应用 ID
@override final  String? appId;
/// 图标
@override final  String? icon;
/// 类型
@override final  String? kind;
/// 模块
@override final  String? module;
/// 渠道
@override final  String? channel;
/// 架构
@override final  String? arch;
/// 仓库名称
@override final  String? repoName;
/// 安装次数
@override final  int? installCount;

/// Create a copy of AppVersion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionCopyWith<_AppVersion> get copyWith => __$AppVersionCopyWithImpl<_AppVersion>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersion&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.versionName, versionName) || other.versionName == versionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installCount, installCount) || other.installCount == installCount));
}


@override
int get hashCode => Object.hash(runtimeType,versionId,versionNo,versionName,description,releaseTime,packageSize,appId,icon,kind,module,channel,arch,repoName,installCount);

@override
String toString() {
  return 'AppVersion(versionId: $versionId, versionNo: $versionNo, versionName: $versionName, description: $description, releaseTime: $releaseTime, packageSize: $packageSize, appId: $appId, icon: $icon, kind: $kind, module: $module, channel: $channel, arch: $arch, repoName: $repoName, installCount: $installCount)';
}


}

/// @nodoc
abstract mixin class _$AppVersionCopyWith<$Res> implements $AppVersionCopyWith<$Res> {
  factory _$AppVersionCopyWith(_AppVersion value, $Res Function(_AppVersion) _then) = __$AppVersionCopyWithImpl;
@override @useResult
$Res call({
 String? versionId, String versionNo, String? versionName, String? description, String? releaseTime, String? packageSize, String? appId, String? icon, String? kind, String? module, String? channel, String? arch, String? repoName, int? installCount
});




}
/// @nodoc
class __$AppVersionCopyWithImpl<$Res>
    implements _$AppVersionCopyWith<$Res> {
  __$AppVersionCopyWithImpl(this._self, this._then);

  final _AppVersion _self;
  final $Res Function(_AppVersion) _then;

/// Create a copy of AppVersion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? versionId = freezed,Object? versionNo = null,Object? versionName = freezed,Object? description = freezed,Object? releaseTime = freezed,Object? packageSize = freezed,Object? appId = freezed,Object? icon = freezed,Object? kind = freezed,Object? module = freezed,Object? channel = freezed,Object? arch = freezed,Object? repoName = freezed,Object? installCount = freezed,}) {
  return _then(_AppVersion(
versionId: freezed == versionId ? _self.versionId : versionId // ignore: cast_nullable_to_non_nullable
as String?,versionNo: null == versionNo ? _self.versionNo : versionNo // ignore: cast_nullable_to_non_nullable
as String,versionName: freezed == versionName ? _self.versionName : versionName // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,releaseTime: freezed == releaseTime ? _self.releaseTime : releaseTime // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,installCount: freezed == installCount ? _self.installCount : installCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
