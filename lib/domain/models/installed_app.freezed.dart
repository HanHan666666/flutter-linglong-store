// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'installed_app.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstalledApp {

@JsonKey(name: 'app_id') String get appId; String get name; String get version; String? get arch; String? get channel; String? get description; String? get icon; String? get kind; String? get module; String? get runtime; String? get size;@JsonKey(name: 'repo_name') String? get repoName;
/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstalledAppCopyWith<InstalledApp> get copyWith => _$InstalledAppCopyWithImpl<InstalledApp>(this as InstalledApp, _$identity);

  /// Serializes this InstalledApp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstalledApp&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.runtime, runtime) || other.runtime == runtime)&&(identical(other.size, size) || other.size == size)&&(identical(other.repoName, repoName) || other.repoName == repoName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,arch,channel,description,icon,kind,module,runtime,size,repoName);

@override
String toString() {
  return 'InstalledApp(appId: $appId, name: $name, version: $version, arch: $arch, channel: $channel, description: $description, icon: $icon, kind: $kind, module: $module, runtime: $runtime, size: $size, repoName: $repoName)';
}


}

/// @nodoc
abstract mixin class $InstalledAppCopyWith<$Res>  {
  factory $InstalledAppCopyWith(InstalledApp value, $Res Function(InstalledApp) _then) = _$InstalledAppCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'app_id') String appId, String name, String version, String? arch, String? channel, String? description, String? icon, String? kind, String? module, String? runtime, String? size,@JsonKey(name: 'repo_name') String? repoName
});




}
/// @nodoc
class _$InstalledAppCopyWithImpl<$Res>
    implements $InstalledAppCopyWith<$Res> {
  _$InstalledAppCopyWithImpl(this._self, this._then);

  final InstalledApp _self;
  final $Res Function(InstalledApp) _then;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? arch = freezed,Object? channel = freezed,Object? description = freezed,Object? icon = freezed,Object? kind = freezed,Object? module = freezed,Object? runtime = freezed,Object? size = freezed,Object? repoName = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,runtime: freezed == runtime ? _self.runtime : runtime // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstalledApp].
extension InstalledAppPatterns on InstalledApp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstalledApp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstalledApp value)  $default,){
final _that = this;
switch (_that) {
case _InstalledApp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstalledApp value)?  $default,){
final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'app_id')  String appId,  String name,  String version,  String? arch,  String? channel,  String? description,  String? icon,  String? kind,  String? module,  String? runtime,  String? size, @JsonKey(name: 'repo_name')  String? repoName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.description,_that.icon,_that.kind,_that.module,_that.runtime,_that.size,_that.repoName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'app_id')  String appId,  String name,  String version,  String? arch,  String? channel,  String? description,  String? icon,  String? kind,  String? module,  String? runtime,  String? size, @JsonKey(name: 'repo_name')  String? repoName)  $default,) {final _that = this;
switch (_that) {
case _InstalledApp():
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.description,_that.icon,_that.kind,_that.module,_that.runtime,_that.size,_that.repoName);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'app_id')  String appId,  String name,  String version,  String? arch,  String? channel,  String? description,  String? icon,  String? kind,  String? module,  String? runtime,  String? size, @JsonKey(name: 'repo_name')  String? repoName)?  $default,) {final _that = this;
switch (_that) {
case _InstalledApp() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.channel,_that.description,_that.icon,_that.kind,_that.module,_that.runtime,_that.size,_that.repoName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstalledApp implements InstalledApp {
  const _InstalledApp({@JsonKey(name: 'app_id') required this.appId, required this.name, required this.version, this.arch, this.channel, this.description, this.icon, this.kind, this.module, this.runtime, this.size, @JsonKey(name: 'repo_name') this.repoName});
  factory _InstalledApp.fromJson(Map<String, dynamic> json) => _$InstalledAppFromJson(json);

@override@JsonKey(name: 'app_id') final  String appId;
@override final  String name;
@override final  String version;
@override final  String? arch;
@override final  String? channel;
@override final  String? description;
@override final  String? icon;
@override final  String? kind;
@override final  String? module;
@override final  String? runtime;
@override final  String? size;
@override@JsonKey(name: 'repo_name') final  String? repoName;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstalledAppCopyWith<_InstalledApp> get copyWith => __$InstalledAppCopyWithImpl<_InstalledApp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstalledAppToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstalledApp&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.runtime, runtime) || other.runtime == runtime)&&(identical(other.size, size) || other.size == size)&&(identical(other.repoName, repoName) || other.repoName == repoName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,arch,channel,description,icon,kind,module,runtime,size,repoName);

@override
String toString() {
  return 'InstalledApp(appId: $appId, name: $name, version: $version, arch: $arch, channel: $channel, description: $description, icon: $icon, kind: $kind, module: $module, runtime: $runtime, size: $size, repoName: $repoName)';
}


}

/// @nodoc
abstract mixin class _$InstalledAppCopyWith<$Res> implements $InstalledAppCopyWith<$Res> {
  factory _$InstalledAppCopyWith(_InstalledApp value, $Res Function(_InstalledApp) _then) = __$InstalledAppCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'app_id') String appId, String name, String version, String? arch, String? channel, String? description, String? icon, String? kind, String? module, String? runtime, String? size,@JsonKey(name: 'repo_name') String? repoName
});




}
/// @nodoc
class __$InstalledAppCopyWithImpl<$Res>
    implements _$InstalledAppCopyWith<$Res> {
  __$InstalledAppCopyWithImpl(this._self, this._then);

  final _InstalledApp _self;
  final $Res Function(_InstalledApp) _then;

/// Create a copy of InstalledApp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? arch = freezed,Object? channel = freezed,Object? description = freezed,Object? icon = freezed,Object? kind = freezed,Object? module = freezed,Object? runtime = freezed,Object? size = freezed,Object? repoName = freezed,}) {
  return _then(_InstalledApp(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,runtime: freezed == runtime ? _self.runtime : runtime // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
