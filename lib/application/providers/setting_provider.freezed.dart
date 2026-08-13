// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'setting_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingState {

/// 缓存大小（字节）
 int get cacheSize;/// 应用版本
 String? get appVersion;/// 是否正在清除缓存
 dynamic get isClearingCache;/// 启动时检履商店版本更新
 bool get checkVersionOnStartup;/// 已安装列表中显示基础运行服务
 bool get showBaseService;/// Linux 渲染模式偏好，仅影响下次启动时的渲染决策。
 LinuxRendererPreference get rendererPreference;/// 是否正在清理基础服务
 bool get isPruningBaseService;
/// Create a copy of SettingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingStateCopyWith<SettingState> get copyWith => _$SettingStateCopyWithImpl<SettingState>(this as SettingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingState&&(identical(other.cacheSize, cacheSize) || other.cacheSize == cacheSize)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&const DeepCollectionEquality().equals(other.isClearingCache, isClearingCache)&&(identical(other.checkVersionOnStartup, checkVersionOnStartup) || other.checkVersionOnStartup == checkVersionOnStartup)&&(identical(other.showBaseService, showBaseService) || other.showBaseService == showBaseService)&&(identical(other.rendererPreference, rendererPreference) || other.rendererPreference == rendererPreference)&&(identical(other.isPruningBaseService, isPruningBaseService) || other.isPruningBaseService == isPruningBaseService));
}


@override
int get hashCode => Object.hash(runtimeType,cacheSize,appVersion,const DeepCollectionEquality().hash(isClearingCache),checkVersionOnStartup,showBaseService,rendererPreference,isPruningBaseService);

@override
String toString() {
  return 'SettingState(cacheSize: $cacheSize, appVersion: $appVersion, isClearingCache: $isClearingCache, checkVersionOnStartup: $checkVersionOnStartup, showBaseService: $showBaseService, rendererPreference: $rendererPreference, isPruningBaseService: $isPruningBaseService)';
}


}

/// @nodoc
abstract mixin class $SettingStateCopyWith<$Res>  {
  factory $SettingStateCopyWith(SettingState value, $Res Function(SettingState) _then) = _$SettingStateCopyWithImpl;
@useResult
$Res call({
 int cacheSize, String? appVersion, dynamic isClearingCache, bool checkVersionOnStartup, bool showBaseService, LinuxRendererPreference rendererPreference, bool isPruningBaseService
});




}
/// @nodoc
class _$SettingStateCopyWithImpl<$Res>
    implements $SettingStateCopyWith<$Res> {
  _$SettingStateCopyWithImpl(this._self, this._then);

  final SettingState _self;
  final $Res Function(SettingState) _then;

/// Create a copy of SettingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cacheSize = null,Object? appVersion = freezed,Object? isClearingCache = freezed,Object? checkVersionOnStartup = null,Object? showBaseService = null,Object? rendererPreference = null,Object? isPruningBaseService = null,}) {
  return _then(SettingState(
cacheSize: null == cacheSize ? _self.cacheSize : cacheSize // ignore: cast_nullable_to_non_nullable
as int,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,isClearingCache: freezed == isClearingCache ? _self.isClearingCache : isClearingCache // ignore: cast_nullable_to_non_nullable
as dynamic,checkVersionOnStartup: null == checkVersionOnStartup ? _self.checkVersionOnStartup : checkVersionOnStartup // ignore: cast_nullable_to_non_nullable
as bool,showBaseService: null == showBaseService ? _self.showBaseService : showBaseService // ignore: cast_nullable_to_non_nullable
as bool,rendererPreference: null == rendererPreference ? _self.rendererPreference : rendererPreference // ignore: cast_nullable_to_non_nullable
as LinuxRendererPreference,isPruningBaseService: null == isPruningBaseService ? _self.isPruningBaseService : isPruningBaseService // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SettingState].
extension SettingStatePatterns on SettingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingState value)  $default,){
final _that = this;
switch (_that) {
case _SettingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cacheSize,  String? appVersion,  dynamic isClearingCache,  bool checkVersionOnStartup,  bool showBaseService,  LinuxRendererPreference rendererPreference,  bool isPruningBaseService)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingState() when $default != null:
return $default(_that.cacheSize,_that.appVersion,_that.isClearingCache,_that.checkVersionOnStartup,_that.showBaseService,_that.rendererPreference,_that.isPruningBaseService);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cacheSize,  String? appVersion,  dynamic isClearingCache,  bool checkVersionOnStartup,  bool showBaseService,  LinuxRendererPreference rendererPreference,  bool isPruningBaseService)  $default,) {final _that = this;
switch (_that) {
case _SettingState():
return $default(_that.cacheSize,_that.appVersion,_that.isClearingCache,_that.checkVersionOnStartup,_that.showBaseService,_that.rendererPreference,_that.isPruningBaseService);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cacheSize,  String? appVersion,  dynamic isClearingCache,  bool checkVersionOnStartup,  bool showBaseService,  LinuxRendererPreference rendererPreference,  bool isPruningBaseService)?  $default,) {final _that = this;
switch (_that) {
case _SettingState() when $default != null:
return $default(_that.cacheSize,_that.appVersion,_that.isClearingCache,_that.checkVersionOnStartup,_that.showBaseService,_that.rendererPreference,_that.isPruningBaseService);case _:
  return null;

}
}

}

/// @nodoc


class _SettingState implements SettingState {
  const _SettingState({this.cacheSize = 0, this.appVersion, this.isClearingCache = false, this.checkVersionOnStartup = true, this.showBaseService = false, this.rendererPreference = LinuxRendererPreference.auto, this.isPruningBaseService = false});
  

/// 缓存大小（字节）
@override@JsonKey() final  int cacheSize;
/// 应用版本
@override final  String? appVersion;
/// 是否正在清除缓存
@override@JsonKey() final  dynamic isClearingCache;
/// 启动时检履商店版本更新
@override@JsonKey() final  bool checkVersionOnStartup;
/// 已安装列表中显示基础运行服务
@override@JsonKey() final  bool showBaseService;
/// Linux 渲染模式偏好，仅影响下次启动时的渲染决策。
@override@JsonKey() final  LinuxRendererPreference rendererPreference;
/// 是否正在清理基础服务
@override@JsonKey() final  bool isPruningBaseService;

/// Create a copy of SettingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingStateCopyWith<_SettingState> get copyWith => __$SettingStateCopyWithImpl<_SettingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingState&&(identical(other.cacheSize, cacheSize) || other.cacheSize == cacheSize)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&const DeepCollectionEquality().equals(other.isClearingCache, isClearingCache)&&(identical(other.checkVersionOnStartup, checkVersionOnStartup) || other.checkVersionOnStartup == checkVersionOnStartup)&&(identical(other.showBaseService, showBaseService) || other.showBaseService == showBaseService)&&(identical(other.rendererPreference, rendererPreference) || other.rendererPreference == rendererPreference)&&(identical(other.isPruningBaseService, isPruningBaseService) || other.isPruningBaseService == isPruningBaseService));
}


@override
int get hashCode => Object.hash(runtimeType,cacheSize,appVersion,const DeepCollectionEquality().hash(isClearingCache),checkVersionOnStartup,showBaseService,rendererPreference,isPruningBaseService);

@override
String toString() {
  return 'SettingState(cacheSize: $cacheSize, appVersion: $appVersion, isClearingCache: $isClearingCache, checkVersionOnStartup: $checkVersionOnStartup, showBaseService: $showBaseService, rendererPreference: $rendererPreference, isPruningBaseService: $isPruningBaseService)';
}


}

/// @nodoc
abstract mixin class _$SettingStateCopyWith<$Res> implements $SettingStateCopyWith<$Res> {
  factory _$SettingStateCopyWith(_SettingState value, $Res Function(_SettingState) _then) = __$SettingStateCopyWithImpl;
@override @useResult
$Res call({
 int cacheSize, String? appVersion, dynamic isClearingCache, bool checkVersionOnStartup, bool showBaseService, LinuxRendererPreference rendererPreference, bool isPruningBaseService
});




}
/// @nodoc
class __$SettingStateCopyWithImpl<$Res>
    implements _$SettingStateCopyWith<$Res> {
  __$SettingStateCopyWithImpl(this._self, this._then);

  final _SettingState _self;
  final $Res Function(_SettingState) _then;

/// Create a copy of SettingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cacheSize = null,Object? appVersion = freezed,Object? isClearingCache = freezed,Object? checkVersionOnStartup = null,Object? showBaseService = null,Object? rendererPreference = null,Object? isPruningBaseService = null,}) {
  return _then(_SettingState(
cacheSize: null == cacheSize ? _self.cacheSize : cacheSize // ignore: cast_nullable_to_non_nullable
as int,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,isClearingCache: freezed == isClearingCache ? _self.isClearingCache : isClearingCache // ignore: cast_nullable_to_non_nullable
as dynamic,checkVersionOnStartup: null == checkVersionOnStartup ? _self.checkVersionOnStartup : checkVersionOnStartup // ignore: cast_nullable_to_non_nullable
as bool,showBaseService: null == showBaseService ? _self.showBaseService : showBaseService // ignore: cast_nullable_to_non_nullable
as bool,rendererPreference: null == rendererPreference ? _self.rendererPreference : rendererPreference // ignore: cast_nullable_to_non_nullable
as LinuxRendererPreference,isPruningBaseService: null == isPruningBaseService ? _self.isPruningBaseService : isPruningBaseService // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
