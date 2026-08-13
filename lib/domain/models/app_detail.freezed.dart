// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppDetail {

/// 应用 ID
 String get appId;/// 应用名称
 String get name;/// 应用版本
 String get version;/// 应用图标 URL
 String? get icon;/// 简短描述
 String? get description;/// 详细描述
 String? get detailDescription;/// 应用类型
 String? get kind;/// 运行时
 String? get runtime;/// 模块
 String? get module;/// 基础镜像
 String? get base;/// 架构
 String? get arch;/// 发布渠道
 String? get channel;/// 开发者名称
 String? get developerName;/// 分类名称
 String? get categoryName;/// 分类 ID
 String? get categoryId;/// 下载次数
 int? get downloadTimes;/// 包大小
 String? get packageSize;/// 截图列表
 List<AppScreenshot> get screenshots;/// 标签列表
 List<AppTag> get tags;/// 仓库名称
 String? get repoName;/// 仓库 URL
 String? get repoUrl;/// 主页 URL
 String? get homePage;/// 许可证
 String? get license;/// 更新日志
 String? get releaseNote;
/// Create a copy of AppDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailCopyWith<AppDetail> get copyWith => _$AppDetailCopyWithImpl<AppDetail>(this as AppDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetail&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.description, description) || other.description == description)&&(identical(other.detailDescription, detailDescription) || other.detailDescription == detailDescription)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.runtime, runtime) || other.runtime == runtime)&&(identical(other.module, module) || other.module == module)&&(identical(other.base, base) || other.base == base)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&const DeepCollectionEquality().equals(other.screenshots, screenshots)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.repoUrl, repoUrl) || other.repoUrl == repoUrl)&&(identical(other.homePage, homePage) || other.homePage == homePage)&&(identical(other.license, license) || other.license == license)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote));
}


@override
int get hashCode => Object.hashAll([runtimeType,appId,name,version,icon,description,detailDescription,kind,runtime,module,base,arch,channel,developerName,categoryName,categoryId,downloadTimes,packageSize,const DeepCollectionEquality().hash(screenshots),const DeepCollectionEquality().hash(tags),repoName,repoUrl,homePage,license,releaseNote]);

@override
String toString() {
  return 'AppDetail(appId: $appId, name: $name, version: $version, icon: $icon, description: $description, detailDescription: $detailDescription, kind: $kind, runtime: $runtime, module: $module, base: $base, arch: $arch, channel: $channel, developerName: $developerName, categoryName: $categoryName, categoryId: $categoryId, downloadTimes: $downloadTimes, packageSize: $packageSize, screenshots: $screenshots, tags: $tags, repoName: $repoName, repoUrl: $repoUrl, homePage: $homePage, license: $license, releaseNote: $releaseNote)';
}


}

/// @nodoc
abstract mixin class $AppDetailCopyWith<$Res>  {
  factory $AppDetailCopyWith(AppDetail value, $Res Function(AppDetail) _then) = _$AppDetailCopyWithImpl;
@useResult
$Res call({
 String appId, String name, String version, String? icon, String? description, String? detailDescription, String? kind, String? runtime, String? module, String? base, String? arch, String? channel, String? developerName, String? categoryName, String? categoryId, int? downloadTimes, String? packageSize, List<AppScreenshot> screenshots, List<AppTag> tags, String? repoName, String? repoUrl, String? homePage, String? license, String? releaseNote
});




}
/// @nodoc
class _$AppDetailCopyWithImpl<$Res>
    implements $AppDetailCopyWith<$Res> {
  _$AppDetailCopyWithImpl(this._self, this._then);

  final AppDetail _self;
  final $Res Function(AppDetail) _then;

/// Create a copy of AppDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? icon = freezed,Object? description = freezed,Object? detailDescription = freezed,Object? kind = freezed,Object? runtime = freezed,Object? module = freezed,Object? base = freezed,Object? arch = freezed,Object? channel = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? categoryId = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,Object? screenshots = null,Object? tags = null,Object? repoName = freezed,Object? repoUrl = freezed,Object? homePage = freezed,Object? license = freezed,Object? releaseNote = freezed,}) {
  return _then(AppDetail(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,detailDescription: freezed == detailDescription ? _self.detailDescription : detailDescription // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,runtime: freezed == runtime ? _self.runtime : runtime // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,base: freezed == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,screenshots: null == screenshots ? _self.screenshots : screenshots // ignore: cast_nullable_to_non_nullable
as List<AppScreenshot>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<AppTag>,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repoUrl: freezed == repoUrl ? _self.repoUrl : repoUrl // ignore: cast_nullable_to_non_nullable
as String?,homePage: freezed == homePage ? _self.homePage : homePage // ignore: cast_nullable_to_non_nullable
as String?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetail].
extension AppDetailPatterns on AppDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetail value)  $default,){
final _that = this;
switch (_that) {
case _AppDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetail value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? icon,  String? description,  String? detailDescription,  String? kind,  String? runtime,  String? module,  String? base,  String? arch,  String? channel,  String? developerName,  String? categoryName,  String? categoryId,  int? downloadTimes,  String? packageSize,  List<AppScreenshot> screenshots,  List<AppTag> tags,  String? repoName,  String? repoUrl,  String? homePage,  String? license,  String? releaseNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetail() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.icon,_that.description,_that.detailDescription,_that.kind,_that.runtime,_that.module,_that.base,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshots,_that.tags,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? icon,  String? description,  String? detailDescription,  String? kind,  String? runtime,  String? module,  String? base,  String? arch,  String? channel,  String? developerName,  String? categoryName,  String? categoryId,  int? downloadTimes,  String? packageSize,  List<AppScreenshot> screenshots,  List<AppTag> tags,  String? repoName,  String? repoUrl,  String? homePage,  String? license,  String? releaseNote)  $default,) {final _that = this;
switch (_that) {
case _AppDetail():
return $default(_that.appId,_that.name,_that.version,_that.icon,_that.description,_that.detailDescription,_that.kind,_that.runtime,_that.module,_that.base,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshots,_that.tags,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String name,  String version,  String? icon,  String? description,  String? detailDescription,  String? kind,  String? runtime,  String? module,  String? base,  String? arch,  String? channel,  String? developerName,  String? categoryName,  String? categoryId,  int? downloadTimes,  String? packageSize,  List<AppScreenshot> screenshots,  List<AppTag> tags,  String? repoName,  String? repoUrl,  String? homePage,  String? license,  String? releaseNote)?  $default,) {final _that = this;
switch (_that) {
case _AppDetail() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.icon,_that.description,_that.detailDescription,_that.kind,_that.runtime,_that.module,_that.base,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshots,_that.tags,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);case _:
  return null;

}
}

}

/// @nodoc


class _AppDetail implements AppDetail {
  const _AppDetail({required this.appId, required this.name, required this.version, this.icon, this.description, this.detailDescription, this.kind, this.runtime, this.module, this.base, this.arch, this.channel, this.developerName, this.categoryName, this.categoryId, this.downloadTimes, this.packageSize,  List<AppScreenshot> screenshots = const [],  List<AppTag> tags = const [], this.repoName, this.repoUrl, this.homePage, this.license, this.releaseNote}): _screenshots = screenshots,_tags = tags;
  

/// 应用 ID
@override final  String appId;
/// 应用名称
@override final  String name;
/// 应用版本
@override final  String version;
/// 应用图标 URL
@override final  String? icon;
/// 简短描述
@override final  String? description;
/// 详细描述
@override final  String? detailDescription;
/// 应用类型
@override final  String? kind;
/// 运行时
@override final  String? runtime;
/// 模块
@override final  String? module;
/// 基础镜像
@override final  String? base;
/// 架构
@override final  String? arch;
/// 发布渠道
@override final  String? channel;
/// 开发者名称
@override final  String? developerName;
/// 分类名称
@override final  String? categoryName;
/// 分类 ID
@override final  String? categoryId;
/// 下载次数
@override final  int? downloadTimes;
/// 包大小
@override final  String? packageSize;
/// 截图列表
 final  List<AppScreenshot> _screenshots;
/// 截图列表
@override@JsonKey() List<AppScreenshot> get screenshots {
  if (_screenshots is EqualUnmodifiableListView) return _screenshots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_screenshots);
}

/// 标签列表
 final  List<AppTag> _tags;
/// 标签列表
@override@JsonKey() List<AppTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// 仓库名称
@override final  String? repoName;
/// 仓库 URL
@override final  String? repoUrl;
/// 主页 URL
@override final  String? homePage;
/// 许可证
@override final  String? license;
/// 更新日志
@override final  String? releaseNote;

/// Create a copy of AppDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailCopyWith<_AppDetail> get copyWith => __$AppDetailCopyWithImpl<_AppDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetail&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.description, description) || other.description == description)&&(identical(other.detailDescription, detailDescription) || other.detailDescription == detailDescription)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.runtime, runtime) || other.runtime == runtime)&&(identical(other.module, module) || other.module == module)&&(identical(other.base, base) || other.base == base)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&const DeepCollectionEquality().equals(other._screenshots, _screenshots)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.repoUrl, repoUrl) || other.repoUrl == repoUrl)&&(identical(other.homePage, homePage) || other.homePage == homePage)&&(identical(other.license, license) || other.license == license)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote));
}


@override
int get hashCode => Object.hashAll([runtimeType,appId,name,version,icon,description,detailDescription,kind,runtime,module,base,arch,channel,developerName,categoryName,categoryId,downloadTimes,packageSize,const DeepCollectionEquality().hash(_screenshots),const DeepCollectionEquality().hash(_tags),repoName,repoUrl,homePage,license,releaseNote]);

@override
String toString() {
  return 'AppDetail(appId: $appId, name: $name, version: $version, icon: $icon, description: $description, detailDescription: $detailDescription, kind: $kind, runtime: $runtime, module: $module, base: $base, arch: $arch, channel: $channel, developerName: $developerName, categoryName: $categoryName, categoryId: $categoryId, downloadTimes: $downloadTimes, packageSize: $packageSize, screenshots: $screenshots, tags: $tags, repoName: $repoName, repoUrl: $repoUrl, homePage: $homePage, license: $license, releaseNote: $releaseNote)';
}


}

/// @nodoc
abstract mixin class _$AppDetailCopyWith<$Res> implements $AppDetailCopyWith<$Res> {
  factory _$AppDetailCopyWith(_AppDetail value, $Res Function(_AppDetail) _then) = __$AppDetailCopyWithImpl;
@override @useResult
$Res call({
 String appId, String name, String version, String? icon, String? description, String? detailDescription, String? kind, String? runtime, String? module, String? base, String? arch, String? channel, String? developerName, String? categoryName, String? categoryId, int? downloadTimes, String? packageSize, List<AppScreenshot> screenshots, List<AppTag> tags, String? repoName, String? repoUrl, String? homePage, String? license, String? releaseNote
});




}
/// @nodoc
class __$AppDetailCopyWithImpl<$Res>
    implements _$AppDetailCopyWith<$Res> {
  __$AppDetailCopyWithImpl(this._self, this._then);

  final _AppDetail _self;
  final $Res Function(_AppDetail) _then;

/// Create a copy of AppDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? icon = freezed,Object? description = freezed,Object? detailDescription = freezed,Object? kind = freezed,Object? runtime = freezed,Object? module = freezed,Object? base = freezed,Object? arch = freezed,Object? channel = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? categoryId = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,Object? screenshots = null,Object? tags = null,Object? repoName = freezed,Object? repoUrl = freezed,Object? homePage = freezed,Object? license = freezed,Object? releaseNote = freezed,}) {
  return _then(_AppDetail(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,detailDescription: freezed == detailDescription ? _self.detailDescription : detailDescription // ignore: cast_nullable_to_non_nullable
as String?,kind: freezed == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String?,runtime: freezed == runtime ? _self.runtime : runtime // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,base: freezed == base ? _self.base : base // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,screenshots: null == screenshots ? _self._screenshots : screenshots // ignore: cast_nullable_to_non_nullable
as List<AppScreenshot>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<AppTag>,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repoUrl: freezed == repoUrl ? _self.repoUrl : repoUrl // ignore: cast_nullable_to_non_nullable
as String?,homePage: freezed == homePage ? _self.homePage : homePage // ignore: cast_nullable_to_non_nullable
as String?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AppScreenshot {

/// 截图 URL
 String get url;/// 截图描述
 String? get description;
/// Create a copy of AppScreenshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppScreenshotCopyWith<AppScreenshot> get copyWith => _$AppScreenshotCopyWithImpl<AppScreenshot>(this as AppScreenshot, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppScreenshot&&(identical(other.url, url) || other.url == url)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,url,description);

@override
String toString() {
  return 'AppScreenshot(url: $url, description: $description)';
}


}

/// @nodoc
abstract mixin class $AppScreenshotCopyWith<$Res>  {
  factory $AppScreenshotCopyWith(AppScreenshot value, $Res Function(AppScreenshot) _then) = _$AppScreenshotCopyWithImpl;
@useResult
$Res call({
 String url, String? description
});




}
/// @nodoc
class _$AppScreenshotCopyWithImpl<$Res>
    implements $AppScreenshotCopyWith<$Res> {
  _$AppScreenshotCopyWithImpl(this._self, this._then);

  final AppScreenshot _self;
  final $Res Function(AppScreenshot) _then;

/// Create a copy of AppScreenshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? description = freezed,}) {
  return _then(AppScreenshot(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppScreenshot].
extension AppScreenshotPatterns on AppScreenshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppScreenshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppScreenshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppScreenshot value)  $default,){
final _that = this;
switch (_that) {
case _AppScreenshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppScreenshot value)?  $default,){
final _that = this;
switch (_that) {
case _AppScreenshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppScreenshot() when $default != null:
return $default(_that.url,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  String? description)  $default,) {final _that = this;
switch (_that) {
case _AppScreenshot():
return $default(_that.url,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _AppScreenshot() when $default != null:
return $default(_that.url,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _AppScreenshot implements AppScreenshot {
  const _AppScreenshot({required this.url, this.description});
  

/// 截图 URL
@override final  String url;
/// 截图描述
@override final  String? description;

/// Create a copy of AppScreenshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppScreenshotCopyWith<_AppScreenshot> get copyWith => __$AppScreenshotCopyWithImpl<_AppScreenshot>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppScreenshot&&(identical(other.url, url) || other.url == url)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,url,description);

@override
String toString() {
  return 'AppScreenshot(url: $url, description: $description)';
}


}

/// @nodoc
abstract mixin class _$AppScreenshotCopyWith<$Res> implements $AppScreenshotCopyWith<$Res> {
  factory _$AppScreenshotCopyWith(_AppScreenshot value, $Res Function(_AppScreenshot) _then) = __$AppScreenshotCopyWithImpl;
@override @useResult
$Res call({
 String url, String? description
});




}
/// @nodoc
class __$AppScreenshotCopyWithImpl<$Res>
    implements _$AppScreenshotCopyWith<$Res> {
  __$AppScreenshotCopyWithImpl(this._self, this._then);

  final _AppScreenshot _self;
  final $Res Function(_AppScreenshot) _then;

/// Create a copy of AppScreenshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? description = freezed,}) {
  return _then(_AppScreenshot(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$AppTag {

/// 标签名称
 String get name;/// 标签语言（如 zh_CN、en_US）
///
/// 设计原因：标签搜索需精确匹配名称+语言，禁止根据界面文本猜测标签身份；
/// 后端契约保证详情接口返回的每个标签都带 lan 字段，故此处设为 required。
 String get language;
/// Create a copy of AppTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppTagCopyWith<AppTag> get copyWith => _$AppTagCopyWithImpl<AppTag>(this as AppTag, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppTag&&(identical(other.name, name) || other.name == name)&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,name,language);

@override
String toString() {
  return 'AppTag(name: $name, language: $language)';
}


}

/// @nodoc
abstract mixin class $AppTagCopyWith<$Res>  {
  factory $AppTagCopyWith(AppTag value, $Res Function(AppTag) _then) = _$AppTagCopyWithImpl;
@useResult
$Res call({
 String name, String language
});




}
/// @nodoc
class _$AppTagCopyWithImpl<$Res>
    implements $AppTagCopyWith<$Res> {
  _$AppTagCopyWithImpl(this._self, this._then);

  final AppTag _self;
  final $Res Function(AppTag) _then;

/// Create a copy of AppTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? language = null,}) {
  return _then(AppTag(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppTag].
extension AppTagPatterns on AppTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppTag value)  $default,){
final _that = this;
switch (_that) {
case _AppTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppTag value)?  $default,){
final _that = this;
switch (_that) {
case _AppTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppTag() when $default != null:
return $default(_that.name,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String language)  $default,) {final _that = this;
switch (_that) {
case _AppTag():
return $default(_that.name,_that.language);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String language)?  $default,) {final _that = this;
switch (_that) {
case _AppTag() when $default != null:
return $default(_that.name,_that.language);case _:
  return null;

}
}

}

/// @nodoc


class _AppTag implements AppTag {
  const _AppTag({required this.name, required this.language});
  

/// 标签名称
@override final  String name;
/// 标签语言（如 zh_CN、en_US）
///
/// 设计原因：标签搜索需精确匹配名称+语言，禁止根据界面文本猜测标签身份；
/// 后端契约保证详情接口返回的每个标签都带 lan 字段，故此处设为 required。
@override final  String language;

/// Create a copy of AppTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppTagCopyWith<_AppTag> get copyWith => __$AppTagCopyWithImpl<_AppTag>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppTag&&(identical(other.name, name) || other.name == name)&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,name,language);

@override
String toString() {
  return 'AppTag(name: $name, language: $language)';
}


}

/// @nodoc
abstract mixin class _$AppTagCopyWith<$Res> implements $AppTagCopyWith<$Res> {
  factory _$AppTagCopyWith(_AppTag value, $Res Function(_AppTag) _then) = __$AppTagCopyWithImpl;
@override @useResult
$Res call({
 String name, String language
});




}
/// @nodoc
class __$AppTagCopyWithImpl<$Res>
    implements _$AppTagCopyWith<$Res> {
  __$AppTagCopyWithImpl(this._self, this._then);

  final _AppTag _self;
  final $Res Function(_AppTag) _then;

/// Create a copy of AppTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? language = null,}) {
  return _then(_AppTag(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
