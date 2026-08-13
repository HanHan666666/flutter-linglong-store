// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'global_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserPreferences {

/// 是否自动检查更新
 bool get autoCheckUpdate;/// 是否显示Beta版本应用
 bool get showBetaApps;/// 是否显示系统应用
 bool get showSystemApps;/// 是否启用通知
 bool get enableNotifications;/// 是否启用桌面快捷方式创建
 bool get autoCreateShortcut;/// 下载并发数
 int get downloadConcurrency;/// 安装后自动运行
 bool get autoRunAfterInstall;/// 是否精简模式
 bool get compactMode;/// 用户手动字号倍率，始终叠加在系统字号基础上。
 double get fontScaleFactor;/// 用户手动字重微调档位，始终叠加在系统字重基础上。
 AppFontWeightAdjustment get fontWeightAdjustment;/// 首页自定义配置
 List<String> get customCategories;
/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserPreferencesCopyWith<UserPreferences> get copyWith => _$UserPreferencesCopyWithImpl<UserPreferences>(this as UserPreferences, _$identity);

  /// Serializes this UserPreferences to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserPreferences&&(identical(other.autoCheckUpdate, autoCheckUpdate) || other.autoCheckUpdate == autoCheckUpdate)&&(identical(other.showBetaApps, showBetaApps) || other.showBetaApps == showBetaApps)&&(identical(other.showSystemApps, showSystemApps) || other.showSystemApps == showSystemApps)&&(identical(other.enableNotifications, enableNotifications) || other.enableNotifications == enableNotifications)&&(identical(other.autoCreateShortcut, autoCreateShortcut) || other.autoCreateShortcut == autoCreateShortcut)&&(identical(other.downloadConcurrency, downloadConcurrency) || other.downloadConcurrency == downloadConcurrency)&&(identical(other.autoRunAfterInstall, autoRunAfterInstall) || other.autoRunAfterInstall == autoRunAfterInstall)&&(identical(other.compactMode, compactMode) || other.compactMode == compactMode)&&(identical(other.fontScaleFactor, fontScaleFactor) || other.fontScaleFactor == fontScaleFactor)&&(identical(other.fontWeightAdjustment, fontWeightAdjustment) || other.fontWeightAdjustment == fontWeightAdjustment)&&const DeepCollectionEquality().equals(other.customCategories, customCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoCheckUpdate,showBetaApps,showSystemApps,enableNotifications,autoCreateShortcut,downloadConcurrency,autoRunAfterInstall,compactMode,fontScaleFactor,fontWeightAdjustment,const DeepCollectionEquality().hash(customCategories));

@override
String toString() {
  return 'UserPreferences(autoCheckUpdate: $autoCheckUpdate, showBetaApps: $showBetaApps, showSystemApps: $showSystemApps, enableNotifications: $enableNotifications, autoCreateShortcut: $autoCreateShortcut, downloadConcurrency: $downloadConcurrency, autoRunAfterInstall: $autoRunAfterInstall, compactMode: $compactMode, fontScaleFactor: $fontScaleFactor, fontWeightAdjustment: $fontWeightAdjustment, customCategories: $customCategories)';
}


}

/// @nodoc
abstract mixin class $UserPreferencesCopyWith<$Res>  {
  factory $UserPreferencesCopyWith(UserPreferences value, $Res Function(UserPreferences) _then) = _$UserPreferencesCopyWithImpl;
@useResult
$Res call({
 bool autoCheckUpdate, bool showBetaApps, bool showSystemApps, bool enableNotifications, bool autoCreateShortcut, int downloadConcurrency, bool autoRunAfterInstall, bool compactMode, double fontScaleFactor, AppFontWeightAdjustment fontWeightAdjustment, List<String> customCategories
});




}
/// @nodoc
class _$UserPreferencesCopyWithImpl<$Res>
    implements $UserPreferencesCopyWith<$Res> {
  _$UserPreferencesCopyWithImpl(this._self, this._then);

  final UserPreferences _self;
  final $Res Function(UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? autoCheckUpdate = null,Object? showBetaApps = null,Object? showSystemApps = null,Object? enableNotifications = null,Object? autoCreateShortcut = null,Object? downloadConcurrency = null,Object? autoRunAfterInstall = null,Object? compactMode = null,Object? fontScaleFactor = null,Object? fontWeightAdjustment = null,Object? customCategories = null,}) {
  return _then(UserPreferences(
autoCheckUpdate: null == autoCheckUpdate ? _self.autoCheckUpdate : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,showBetaApps: null == showBetaApps ? _self.showBetaApps : showBetaApps // ignore: cast_nullable_to_non_nullable
as bool,showSystemApps: null == showSystemApps ? _self.showSystemApps : showSystemApps // ignore: cast_nullable_to_non_nullable
as bool,enableNotifications: null == enableNotifications ? _self.enableNotifications : enableNotifications // ignore: cast_nullable_to_non_nullable
as bool,autoCreateShortcut: null == autoCreateShortcut ? _self.autoCreateShortcut : autoCreateShortcut // ignore: cast_nullable_to_non_nullable
as bool,downloadConcurrency: null == downloadConcurrency ? _self.downloadConcurrency : downloadConcurrency // ignore: cast_nullable_to_non_nullable
as int,autoRunAfterInstall: null == autoRunAfterInstall ? _self.autoRunAfterInstall : autoRunAfterInstall // ignore: cast_nullable_to_non_nullable
as bool,compactMode: null == compactMode ? _self.compactMode : compactMode // ignore: cast_nullable_to_non_nullable
as bool,fontScaleFactor: null == fontScaleFactor ? _self.fontScaleFactor : fontScaleFactor // ignore: cast_nullable_to_non_nullable
as double,fontWeightAdjustment: null == fontWeightAdjustment ? _self.fontWeightAdjustment : fontWeightAdjustment // ignore: cast_nullable_to_non_nullable
as AppFontWeightAdjustment,customCategories: null == customCategories ? _self.customCategories : customCategories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [UserPreferences].
extension UserPreferencesPatterns on UserPreferences {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserPreferences value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserPreferences value)  $default,){
final _that = this;
switch (_that) {
case _UserPreferences():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserPreferences value)?  $default,){
final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool autoCheckUpdate,  bool showBetaApps,  bool showSystemApps,  bool enableNotifications,  bool autoCreateShortcut,  int downloadConcurrency,  bool autoRunAfterInstall,  bool compactMode,  double fontScaleFactor,  AppFontWeightAdjustment fontWeightAdjustment,  List<String> customCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.autoCheckUpdate,_that.showBetaApps,_that.showSystemApps,_that.enableNotifications,_that.autoCreateShortcut,_that.downloadConcurrency,_that.autoRunAfterInstall,_that.compactMode,_that.fontScaleFactor,_that.fontWeightAdjustment,_that.customCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool autoCheckUpdate,  bool showBetaApps,  bool showSystemApps,  bool enableNotifications,  bool autoCreateShortcut,  int downloadConcurrency,  bool autoRunAfterInstall,  bool compactMode,  double fontScaleFactor,  AppFontWeightAdjustment fontWeightAdjustment,  List<String> customCategories)  $default,) {final _that = this;
switch (_that) {
case _UserPreferences():
return $default(_that.autoCheckUpdate,_that.showBetaApps,_that.showSystemApps,_that.enableNotifications,_that.autoCreateShortcut,_that.downloadConcurrency,_that.autoRunAfterInstall,_that.compactMode,_that.fontScaleFactor,_that.fontWeightAdjustment,_that.customCategories);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool autoCheckUpdate,  bool showBetaApps,  bool showSystemApps,  bool enableNotifications,  bool autoCreateShortcut,  int downloadConcurrency,  bool autoRunAfterInstall,  bool compactMode,  double fontScaleFactor,  AppFontWeightAdjustment fontWeightAdjustment,  List<String> customCategories)?  $default,) {final _that = this;
switch (_that) {
case _UserPreferences() when $default != null:
return $default(_that.autoCheckUpdate,_that.showBetaApps,_that.showSystemApps,_that.enableNotifications,_that.autoCreateShortcut,_that.downloadConcurrency,_that.autoRunAfterInstall,_that.compactMode,_that.fontScaleFactor,_that.fontWeightAdjustment,_that.customCategories);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserPreferences implements UserPreferences {
  const _UserPreferences({this.autoCheckUpdate = true, this.showBetaApps = false, this.showSystemApps = false, this.enableNotifications = true, this.autoCreateShortcut = true, this.downloadConcurrency = 3, this.autoRunAfterInstall = false, this.compactMode = false, this.fontScaleFactor = kDefaultUserFontScaleFactor, this.fontWeightAdjustment = AppFontWeightAdjustment.normal,  List<String> customCategories = const []}): _customCategories = customCategories;
  factory _UserPreferences.fromJson(Map<String, dynamic> json) => _$UserPreferencesFromJson(json);

/// 是否自动检查更新
@override@JsonKey() final  bool autoCheckUpdate;
/// 是否显示Beta版本应用
@override@JsonKey() final  bool showBetaApps;
/// 是否显示系统应用
@override@JsonKey() final  bool showSystemApps;
/// 是否启用通知
@override@JsonKey() final  bool enableNotifications;
/// 是否启用桌面快捷方式创建
@override@JsonKey() final  bool autoCreateShortcut;
/// 下载并发数
@override@JsonKey() final  int downloadConcurrency;
/// 安装后自动运行
@override@JsonKey() final  bool autoRunAfterInstall;
/// 是否精简模式
@override@JsonKey() final  bool compactMode;
/// 用户手动字号倍率，始终叠加在系统字号基础上。
@override@JsonKey() final  double fontScaleFactor;
/// 用户手动字重微调档位，始终叠加在系统字重基础上。
@override@JsonKey() final  AppFontWeightAdjustment fontWeightAdjustment;
/// 首页自定义配置
 final  List<String> _customCategories;
/// 首页自定义配置
@override@JsonKey() List<String> get customCategories {
  if (_customCategories is EqualUnmodifiableListView) return _customCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_customCategories);
}


/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserPreferencesCopyWith<_UserPreferences> get copyWith => __$UserPreferencesCopyWithImpl<_UserPreferences>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserPreferencesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserPreferences&&(identical(other.autoCheckUpdate, autoCheckUpdate) || other.autoCheckUpdate == autoCheckUpdate)&&(identical(other.showBetaApps, showBetaApps) || other.showBetaApps == showBetaApps)&&(identical(other.showSystemApps, showSystemApps) || other.showSystemApps == showSystemApps)&&(identical(other.enableNotifications, enableNotifications) || other.enableNotifications == enableNotifications)&&(identical(other.autoCreateShortcut, autoCreateShortcut) || other.autoCreateShortcut == autoCreateShortcut)&&(identical(other.downloadConcurrency, downloadConcurrency) || other.downloadConcurrency == downloadConcurrency)&&(identical(other.autoRunAfterInstall, autoRunAfterInstall) || other.autoRunAfterInstall == autoRunAfterInstall)&&(identical(other.compactMode, compactMode) || other.compactMode == compactMode)&&(identical(other.fontScaleFactor, fontScaleFactor) || other.fontScaleFactor == fontScaleFactor)&&(identical(other.fontWeightAdjustment, fontWeightAdjustment) || other.fontWeightAdjustment == fontWeightAdjustment)&&const DeepCollectionEquality().equals(other._customCategories, _customCategories));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoCheckUpdate,showBetaApps,showSystemApps,enableNotifications,autoCreateShortcut,downloadConcurrency,autoRunAfterInstall,compactMode,fontScaleFactor,fontWeightAdjustment,const DeepCollectionEquality().hash(_customCategories));

@override
String toString() {
  return 'UserPreferences(autoCheckUpdate: $autoCheckUpdate, showBetaApps: $showBetaApps, showSystemApps: $showSystemApps, enableNotifications: $enableNotifications, autoCreateShortcut: $autoCreateShortcut, downloadConcurrency: $downloadConcurrency, autoRunAfterInstall: $autoRunAfterInstall, compactMode: $compactMode, fontScaleFactor: $fontScaleFactor, fontWeightAdjustment: $fontWeightAdjustment, customCategories: $customCategories)';
}


}

/// @nodoc
abstract mixin class _$UserPreferencesCopyWith<$Res> implements $UserPreferencesCopyWith<$Res> {
  factory _$UserPreferencesCopyWith(_UserPreferences value, $Res Function(_UserPreferences) _then) = __$UserPreferencesCopyWithImpl;
@override @useResult
$Res call({
 bool autoCheckUpdate, bool showBetaApps, bool showSystemApps, bool enableNotifications, bool autoCreateShortcut, int downloadConcurrency, bool autoRunAfterInstall, bool compactMode, double fontScaleFactor, AppFontWeightAdjustment fontWeightAdjustment, List<String> customCategories
});




}
/// @nodoc
class __$UserPreferencesCopyWithImpl<$Res>
    implements _$UserPreferencesCopyWith<$Res> {
  __$UserPreferencesCopyWithImpl(this._self, this._then);

  final _UserPreferences _self;
  final $Res Function(_UserPreferences) _then;

/// Create a copy of UserPreferences
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? autoCheckUpdate = null,Object? showBetaApps = null,Object? showSystemApps = null,Object? enableNotifications = null,Object? autoCreateShortcut = null,Object? downloadConcurrency = null,Object? autoRunAfterInstall = null,Object? compactMode = null,Object? fontScaleFactor = null,Object? fontWeightAdjustment = null,Object? customCategories = null,}) {
  return _then(_UserPreferences(
autoCheckUpdate: null == autoCheckUpdate ? _self.autoCheckUpdate : autoCheckUpdate // ignore: cast_nullable_to_non_nullable
as bool,showBetaApps: null == showBetaApps ? _self.showBetaApps : showBetaApps // ignore: cast_nullable_to_non_nullable
as bool,showSystemApps: null == showSystemApps ? _self.showSystemApps : showSystemApps // ignore: cast_nullable_to_non_nullable
as bool,enableNotifications: null == enableNotifications ? _self.enableNotifications : enableNotifications // ignore: cast_nullable_to_non_nullable
as bool,autoCreateShortcut: null == autoCreateShortcut ? _self.autoCreateShortcut : autoCreateShortcut // ignore: cast_nullable_to_non_nullable
as bool,downloadConcurrency: null == downloadConcurrency ? _self.downloadConcurrency : downloadConcurrency // ignore: cast_nullable_to_non_nullable
as int,autoRunAfterInstall: null == autoRunAfterInstall ? _self.autoRunAfterInstall : autoRunAfterInstall // ignore: cast_nullable_to_non_nullable
as bool,compactMode: null == compactMode ? _self.compactMode : compactMode // ignore: cast_nullable_to_non_nullable
as bool,fontScaleFactor: null == fontScaleFactor ? _self.fontScaleFactor : fontScaleFactor // ignore: cast_nullable_to_non_nullable
as double,fontWeightAdjustment: null == fontWeightAdjustment ? _self.fontWeightAdjustment : fontWeightAdjustment // ignore: cast_nullable_to_non_nullable
as AppFontWeightAdjustment,customCategories: null == customCategories ? _self._customCategories : customCategories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
