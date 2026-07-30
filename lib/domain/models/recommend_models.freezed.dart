// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommend_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BannerInfo {

 String get id; String get title; String get imageUrl; String get version; String? get arch; String? get targetAppId; String? get targetUrl; String? get description;
/// Create a copy of BannerInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BannerInfoCopyWith<BannerInfo> get copyWith => _$BannerInfoCopyWithImpl<BannerInfo>(this as BannerInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BannerInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.targetAppId, targetAppId) || other.targetAppId == targetAppId)&&(identical(other.targetUrl, targetUrl) || other.targetUrl == targetUrl)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,version,arch,targetAppId,targetUrl,description);

@override
String toString() {
  return 'BannerInfo(id: $id, title: $title, imageUrl: $imageUrl, version: $version, arch: $arch, targetAppId: $targetAppId, targetUrl: $targetUrl, description: $description)';
}


}

/// @nodoc
abstract mixin class $BannerInfoCopyWith<$Res>  {
  factory $BannerInfoCopyWith(BannerInfo value, $Res Function(BannerInfo) _then) = _$BannerInfoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String imageUrl, String version, String? arch, String? targetAppId, String? targetUrl, String? description
});




}
/// @nodoc
class _$BannerInfoCopyWithImpl<$Res>
    implements $BannerInfoCopyWith<$Res> {
  _$BannerInfoCopyWithImpl(this._self, this._then);

  final BannerInfo _self;
  final $Res Function(BannerInfo) _then;

/// Create a copy of BannerInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? version = null,Object? arch = freezed,Object? targetAppId = freezed,Object? targetUrl = freezed,Object? description = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,targetAppId: freezed == targetAppId ? _self.targetAppId : targetAppId // ignore: cast_nullable_to_non_nullable
as String?,targetUrl: freezed == targetUrl ? _self.targetUrl : targetUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BannerInfo].
extension BannerInfoPatterns on BannerInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BannerInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BannerInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BannerInfo value)  $default,){
final _that = this;
switch (_that) {
case _BannerInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BannerInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BannerInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String imageUrl,  String version,  String? arch,  String? targetAppId,  String? targetUrl,  String? description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BannerInfo() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.version,_that.arch,_that.targetAppId,_that.targetUrl,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String imageUrl,  String version,  String? arch,  String? targetAppId,  String? targetUrl,  String? description)  $default,) {final _that = this;
switch (_that) {
case _BannerInfo():
return $default(_that.id,_that.title,_that.imageUrl,_that.version,_that.arch,_that.targetAppId,_that.targetUrl,_that.description);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String imageUrl,  String version,  String? arch,  String? targetAppId,  String? targetUrl,  String? description)?  $default,) {final _that = this;
switch (_that) {
case _BannerInfo() when $default != null:
return $default(_that.id,_that.title,_that.imageUrl,_that.version,_that.arch,_that.targetAppId,_that.targetUrl,_that.description);case _:
  return null;

}
}

}

/// @nodoc


class _BannerInfo implements BannerInfo {
  const _BannerInfo({required this.id, required this.title, required this.imageUrl, this.version = '', this.arch, this.targetAppId, this.targetUrl, this.description});
  

@override final  String id;
@override final  String title;
@override final  String imageUrl;
@override@JsonKey() final  String version;
@override final  String? arch;
@override final  String? targetAppId;
@override final  String? targetUrl;
@override final  String? description;

/// Create a copy of BannerInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BannerInfoCopyWith<_BannerInfo> get copyWith => __$BannerInfoCopyWithImpl<_BannerInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BannerInfo&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.targetAppId, targetAppId) || other.targetAppId == targetAppId)&&(identical(other.targetUrl, targetUrl) || other.targetUrl == targetUrl)&&(identical(other.description, description) || other.description == description));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,imageUrl,version,arch,targetAppId,targetUrl,description);

@override
String toString() {
  return 'BannerInfo(id: $id, title: $title, imageUrl: $imageUrl, version: $version, arch: $arch, targetAppId: $targetAppId, targetUrl: $targetUrl, description: $description)';
}


}

/// @nodoc
abstract mixin class _$BannerInfoCopyWith<$Res> implements $BannerInfoCopyWith<$Res> {
  factory _$BannerInfoCopyWith(_BannerInfo value, $Res Function(_BannerInfo) _then) = __$BannerInfoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String imageUrl, String version, String? arch, String? targetAppId, String? targetUrl, String? description
});




}
/// @nodoc
class __$BannerInfoCopyWithImpl<$Res>
    implements _$BannerInfoCopyWith<$Res> {
  __$BannerInfoCopyWithImpl(this._self, this._then);

  final _BannerInfo _self;
  final $Res Function(_BannerInfo) _then;

/// Create a copy of BannerInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? imageUrl = null,Object? version = null,Object? arch = freezed,Object? targetAppId = freezed,Object? targetUrl = freezed,Object? description = freezed,}) {
  return _then(_BannerInfo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,imageUrl: null == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,targetAppId: freezed == targetAppId ? _self.targetAppId : targetAppId // ignore: cast_nullable_to_non_nullable
as String?,targetUrl: freezed == targetUrl ? _self.targetUrl : targetUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CategoryInfo {

 String get code; String get name; String? get icon; int? get appCount;
/// Create a copy of CategoryInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryInfoCopyWith<CategoryInfo> get copyWith => _$CategoryInfoCopyWithImpl<CategoryInfo>(this as CategoryInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.appCount, appCount) || other.appCount == appCount));
}


@override
int get hashCode => Object.hash(runtimeType,code,name,icon,appCount);

@override
String toString() {
  return 'CategoryInfo(code: $code, name: $name, icon: $icon, appCount: $appCount)';
}


}

/// @nodoc
abstract mixin class $CategoryInfoCopyWith<$Res>  {
  factory $CategoryInfoCopyWith(CategoryInfo value, $Res Function(CategoryInfo) _then) = _$CategoryInfoCopyWithImpl;
@useResult
$Res call({
 String code, String name, String? icon, int? appCount
});




}
/// @nodoc
class _$CategoryInfoCopyWithImpl<$Res>
    implements $CategoryInfoCopyWith<$Res> {
  _$CategoryInfoCopyWithImpl(this._self, this._then);

  final CategoryInfo _self;
  final $Res Function(CategoryInfo) _then;

/// Create a copy of CategoryInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? name = null,Object? icon = freezed,Object? appCount = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,appCount: freezed == appCount ? _self.appCount : appCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryInfo].
extension CategoryInfoPatterns on CategoryInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryInfo value)  $default,){
final _that = this;
switch (_that) {
case _CategoryInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryInfo value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String name,  String? icon,  int? appCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryInfo() when $default != null:
return $default(_that.code,_that.name,_that.icon,_that.appCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String name,  String? icon,  int? appCount)  $default,) {final _that = this;
switch (_that) {
case _CategoryInfo():
return $default(_that.code,_that.name,_that.icon,_that.appCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String name,  String? icon,  int? appCount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryInfo() when $default != null:
return $default(_that.code,_that.name,_that.icon,_that.appCount);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryInfo implements CategoryInfo {
  const _CategoryInfo({required this.code, required this.name, this.icon, this.appCount});
  

@override final  String code;
@override final  String name;
@override final  String? icon;
@override final  int? appCount;

/// Create a copy of CategoryInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryInfoCopyWith<_CategoryInfo> get copyWith => __$CategoryInfoCopyWithImpl<_CategoryInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryInfo&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.appCount, appCount) || other.appCount == appCount));
}


@override
int get hashCode => Object.hash(runtimeType,code,name,icon,appCount);

@override
String toString() {
  return 'CategoryInfo(code: $code, name: $name, icon: $icon, appCount: $appCount)';
}


}

/// @nodoc
abstract mixin class _$CategoryInfoCopyWith<$Res> implements $CategoryInfoCopyWith<$Res> {
  factory _$CategoryInfoCopyWith(_CategoryInfo value, $Res Function(_CategoryInfo) _then) = __$CategoryInfoCopyWithImpl;
@override @useResult
$Res call({
 String code, String name, String? icon, int? appCount
});




}
/// @nodoc
class __$CategoryInfoCopyWithImpl<$Res>
    implements _$CategoryInfoCopyWith<$Res> {
  __$CategoryInfoCopyWithImpl(this._self, this._then);

  final _CategoryInfo _self;
  final $Res Function(_CategoryInfo) _then;

/// Create a copy of CategoryInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? name = null,Object? icon = freezed,Object? appCount = freezed,}) {
  return _then(_CategoryInfo(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,appCount: freezed == appCount ? _self.appCount : appCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$RecommendAppInfo {

 String get appId; String get name; String get version; String? get description; String? get icon; String? get developer; String? get category; String? get size; String? get arch;// 详情页需要沿用列表入口的精确身份字段，避免回退匹配到错误条目。
 String? get module;// 详情页需要沿用列表入口的精确身份字段，避免回退匹配到错误条目。
 String? get repoName; double? get rating; int? get downloadCount; bool get isInstalled; bool get hasUpdate;
/// Create a copy of RecommendAppInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendAppInfoCopyWith<RecommendAppInfo> get copyWith => _$RecommendAppInfoCopyWithImpl<RecommendAppInfo>(this as RecommendAppInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendAppInfo&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.category, category) || other.category == category)&&(identical(other.size, size) || other.size == size)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.module, module) || other.module == module)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.isInstalled, isInstalled) || other.isInstalled == isInstalled)&&(identical(other.hasUpdate, hasUpdate) || other.hasUpdate == hasUpdate));
}


@override
int get hashCode => Object.hash(runtimeType,appId,name,version,description,icon,developer,category,size,arch,module,repoName,rating,downloadCount,isInstalled,hasUpdate);

@override
String toString() {
  return 'RecommendAppInfo(appId: $appId, name: $name, version: $version, description: $description, icon: $icon, developer: $developer, category: $category, size: $size, arch: $arch, module: $module, repoName: $repoName, rating: $rating, downloadCount: $downloadCount, isInstalled: $isInstalled, hasUpdate: $hasUpdate)';
}


}

/// @nodoc
abstract mixin class $RecommendAppInfoCopyWith<$Res>  {
  factory $RecommendAppInfoCopyWith(RecommendAppInfo value, $Res Function(RecommendAppInfo) _then) = _$RecommendAppInfoCopyWithImpl;
@useResult
$Res call({
 String appId, String name, String version, String? description, String? icon, String? developer, String? category, String? size, String? arch, String? module, String? repoName, double? rating, int? downloadCount, bool isInstalled, bool hasUpdate
});




}
/// @nodoc
class _$RecommendAppInfoCopyWithImpl<$Res>
    implements $RecommendAppInfoCopyWith<$Res> {
  _$RecommendAppInfoCopyWithImpl(this._self, this._then);

  final RecommendAppInfo _self;
  final $Res Function(RecommendAppInfo) _then;

/// Create a copy of RecommendAppInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? description = freezed,Object? icon = freezed,Object? developer = freezed,Object? category = freezed,Object? size = freezed,Object? arch = freezed,Object? module = freezed,Object? repoName = freezed,Object? rating = freezed,Object? downloadCount = freezed,Object? isInstalled = null,Object? hasUpdate = null,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,downloadCount: freezed == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int?,isInstalled: null == isInstalled ? _self.isInstalled : isInstalled // ignore: cast_nullable_to_non_nullable
as bool,hasUpdate: null == hasUpdate ? _self.hasUpdate : hasUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendAppInfo].
extension RecommendAppInfoPatterns on RecommendAppInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendAppInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendAppInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendAppInfo value)  $default,){
final _that = this;
switch (_that) {
case _RecommendAppInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendAppInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendAppInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  String? module,  String? repoName,  double? rating,  int? downloadCount,  bool isInstalled,  bool hasUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendAppInfo() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.module,_that.repoName,_that.rating,_that.downloadCount,_that.isInstalled,_that.hasUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  String? module,  String? repoName,  double? rating,  int? downloadCount,  bool isInstalled,  bool hasUpdate)  $default,) {final _that = this;
switch (_that) {
case _RecommendAppInfo():
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.module,_that.repoName,_that.rating,_that.downloadCount,_that.isInstalled,_that.hasUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  String? module,  String? repoName,  double? rating,  int? downloadCount,  bool isInstalled,  bool hasUpdate)?  $default,) {final _that = this;
switch (_that) {
case _RecommendAppInfo() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.module,_that.repoName,_that.rating,_that.downloadCount,_that.isInstalled,_that.hasUpdate);case _:
  return null;

}
}

}

/// @nodoc


class _RecommendAppInfo implements RecommendAppInfo {
  const _RecommendAppInfo({required this.appId, required this.name, required this.version, this.description, this.icon, this.developer, this.category, this.size, this.arch, this.module, this.repoName, this.rating, this.downloadCount, this.isInstalled = false, this.hasUpdate = false});
  

@override final  String appId;
@override final  String name;
@override final  String version;
@override final  String? description;
@override final  String? icon;
@override final  String? developer;
@override final  String? category;
@override final  String? size;
@override final  String? arch;
// 详情页需要沿用列表入口的精确身份字段，避免回退匹配到错误条目。
@override final  String? module;
// 详情页需要沿用列表入口的精确身份字段，避免回退匹配到错误条目。
@override final  String? repoName;
@override final  double? rating;
@override final  int? downloadCount;
@override@JsonKey() final  bool isInstalled;
@override@JsonKey() final  bool hasUpdate;

/// Create a copy of RecommendAppInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendAppInfoCopyWith<_RecommendAppInfo> get copyWith => __$RecommendAppInfoCopyWithImpl<_RecommendAppInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendAppInfo&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.category, category) || other.category == category)&&(identical(other.size, size) || other.size == size)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.module, module) || other.module == module)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.isInstalled, isInstalled) || other.isInstalled == isInstalled)&&(identical(other.hasUpdate, hasUpdate) || other.hasUpdate == hasUpdate));
}


@override
int get hashCode => Object.hash(runtimeType,appId,name,version,description,icon,developer,category,size,arch,module,repoName,rating,downloadCount,isInstalled,hasUpdate);

@override
String toString() {
  return 'RecommendAppInfo(appId: $appId, name: $name, version: $version, description: $description, icon: $icon, developer: $developer, category: $category, size: $size, arch: $arch, module: $module, repoName: $repoName, rating: $rating, downloadCount: $downloadCount, isInstalled: $isInstalled, hasUpdate: $hasUpdate)';
}


}

/// @nodoc
abstract mixin class _$RecommendAppInfoCopyWith<$Res> implements $RecommendAppInfoCopyWith<$Res> {
  factory _$RecommendAppInfoCopyWith(_RecommendAppInfo value, $Res Function(_RecommendAppInfo) _then) = __$RecommendAppInfoCopyWithImpl;
@override @useResult
$Res call({
 String appId, String name, String version, String? description, String? icon, String? developer, String? category, String? size, String? arch, String? module, String? repoName, double? rating, int? downloadCount, bool isInstalled, bool hasUpdate
});




}
/// @nodoc
class __$RecommendAppInfoCopyWithImpl<$Res>
    implements _$RecommendAppInfoCopyWith<$Res> {
  __$RecommendAppInfoCopyWithImpl(this._self, this._then);

  final _RecommendAppInfo _self;
  final $Res Function(_RecommendAppInfo) _then;

/// Create a copy of RecommendAppInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? description = freezed,Object? icon = freezed,Object? developer = freezed,Object? category = freezed,Object? size = freezed,Object? arch = freezed,Object? module = freezed,Object? repoName = freezed,Object? rating = freezed,Object? downloadCount = freezed,Object? isInstalled = null,Object? hasUpdate = null,}) {
  return _then(_RecommendAppInfo(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,downloadCount: freezed == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int?,isInstalled: null == isInstalled ? _self.isInstalled : isInstalled // ignore: cast_nullable_to_non_nullable
as bool,hasUpdate: null == hasUpdate ? _self.hasUpdate : hasUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RecommendState {

 bool get isLoading; bool get isLoadingMore; bool get hasHydratedFromCache; String? get error; RecommendData? get data; int get currentPage;
/// Create a copy of RecommendState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendStateCopyWith<RecommendState> get copyWith => _$RecommendStateCopyWithImpl<RecommendState>(this as RecommendState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasHydratedFromCache, hasHydratedFromCache) || other.hasHydratedFromCache == hasHydratedFromCache)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,hasHydratedFromCache,error,data,currentPage);

@override
String toString() {
  return 'RecommendState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasHydratedFromCache: $hasHydratedFromCache, error: $error, data: $data, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class $RecommendStateCopyWith<$Res>  {
  factory $RecommendStateCopyWith(RecommendState value, $Res Function(RecommendState) _then) = _$RecommendStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, bool isLoadingMore, bool hasHydratedFromCache, String? error, RecommendData? data, int currentPage
});




}
/// @nodoc
class _$RecommendStateCopyWithImpl<$Res>
    implements $RecommendStateCopyWith<$Res> {
  _$RecommendStateCopyWithImpl(this._self, this._then);

  final RecommendState _self;
  final $Res Function(RecommendState) _then;

/// Create a copy of RecommendState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? hasHydratedFromCache = null,Object? error = freezed,Object? data = freezed,Object? currentPage = null,}) {
  return _then(_self.copyWith(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasHydratedFromCache: null == hasHydratedFromCache ? _self.hasHydratedFromCache : hasHydratedFromCache // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RecommendData?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendState].
extension RecommendStatePatterns on RecommendState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendState value)  $default,){
final _that = this;
switch (_that) {
case _RecommendState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendState value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  bool hasHydratedFromCache,  String? error,  RecommendData? data,  int currentPage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.hasHydratedFromCache,_that.error,_that.data,_that.currentPage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  bool isLoadingMore,  bool hasHydratedFromCache,  String? error,  RecommendData? data,  int currentPage)  $default,) {final _that = this;
switch (_that) {
case _RecommendState():
return $default(_that.isLoading,_that.isLoadingMore,_that.hasHydratedFromCache,_that.error,_that.data,_that.currentPage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  bool isLoadingMore,  bool hasHydratedFromCache,  String? error,  RecommendData? data,  int currentPage)?  $default,) {final _that = this;
switch (_that) {
case _RecommendState() when $default != null:
return $default(_that.isLoading,_that.isLoadingMore,_that.hasHydratedFromCache,_that.error,_that.data,_that.currentPage);case _:
  return null;

}
}

}

/// @nodoc


class _RecommendState implements RecommendState {
  const _RecommendState({this.isLoading = false, this.isLoadingMore = false, this.hasHydratedFromCache = false, this.error, this.data, this.currentPage = 1});
  

@override@JsonKey() final  bool isLoading;
@override@JsonKey() final  bool isLoadingMore;
@override@JsonKey() final  bool hasHydratedFromCache;
@override final  String? error;
@override final  RecommendData? data;
@override@JsonKey() final  int currentPage;

/// Create a copy of RecommendState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendStateCopyWith<_RecommendState> get copyWith => __$RecommendStateCopyWithImpl<_RecommendState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.hasHydratedFromCache, hasHydratedFromCache) || other.hasHydratedFromCache == hasHydratedFromCache)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,isLoadingMore,hasHydratedFromCache,error,data,currentPage);

@override
String toString() {
  return 'RecommendState(isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasHydratedFromCache: $hasHydratedFromCache, error: $error, data: $data, currentPage: $currentPage)';
}


}

/// @nodoc
abstract mixin class _$RecommendStateCopyWith<$Res> implements $RecommendStateCopyWith<$Res> {
  factory _$RecommendStateCopyWith(_RecommendState value, $Res Function(_RecommendState) _then) = __$RecommendStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, bool isLoadingMore, bool hasHydratedFromCache, String? error, RecommendData? data, int currentPage
});




}
/// @nodoc
class __$RecommendStateCopyWithImpl<$Res>
    implements _$RecommendStateCopyWith<$Res> {
  __$RecommendStateCopyWithImpl(this._self, this._then);

  final _RecommendState _self;
  final $Res Function(_RecommendState) _then;

/// Create a copy of RecommendState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? isLoadingMore = null,Object? hasHydratedFromCache = null,Object? error = freezed,Object? data = freezed,Object? currentPage = null,}) {
  return _then(_RecommendState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,hasHydratedFromCache: null == hasHydratedFromCache ? _self.hasHydratedFromCache : hasHydratedFromCache // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RecommendData?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
