// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PageParams {

@JsonKey(name: 'pageNo') int get pageNo;@JsonKey(name: 'pageSize') int get pageSize;@JsonKey(name: 'repoName') String get repoName; String? get arch; String? get lan; String? get sort; String? get order;
/// Create a copy of PageParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PageParamsCopyWith<PageParams> get copyWith => _$PageParamsCopyWithImpl<PageParams>(this as PageParams, _$identity);

  /// Serializes this PageParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PageParams&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'PageParams(pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class $PageParamsCopyWith<$Res>  {
  factory $PageParamsCopyWith(PageParams value, $Res Function(PageParams) _then) = _$PageParamsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class _$PageParamsCopyWithImpl<$Res>
    implements $PageParamsCopyWith<$Res> {
  _$PageParamsCopyWithImpl(this._self, this._then);

  final PageParams _self;
  final $Res Function(PageParams) _then;

/// Create a copy of PageParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_self.copyWith(
pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PageParams].
extension PageParamsPatterns on PageParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PageParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PageParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PageParams value)  $default,){
final _that = this;
switch (_that) {
case _PageParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PageParams value)?  $default,){
final _that = this;
switch (_that) {
case _PageParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PageParams() when $default != null:
return $default(_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)  $default,) {final _that = this;
switch (_that) {
case _PageParams():
return $default(_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,) {final _that = this;
switch (_that) {
case _PageParams() when $default != null:
return $default(_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PageParams implements PageParams {
  const _PageParams({@JsonKey(name: 'pageNo') this.pageNo = 1, @JsonKey(name: 'pageSize') this.pageSize = 20, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, this.lan, this.sort, this.order});
  factory _PageParams.fromJson(Map<String, dynamic> json) => _$PageParamsFromJson(json);

@override@JsonKey(name: 'pageNo') final  int pageNo;
@override@JsonKey(name: 'pageSize') final  int pageSize;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override final  String? lan;
@override final  String? sort;
@override final  String? order;

/// Create a copy of PageParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PageParamsCopyWith<_PageParams> get copyWith => __$PageParamsCopyWithImpl<_PageParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PageParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PageParams&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'PageParams(pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class _$PageParamsCopyWith<$Res> implements $PageParamsCopyWith<$Res> {
  factory _$PageParamsCopyWith(_PageParams value, $Res Function(_PageParams) _then) = __$PageParamsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class __$PageParamsCopyWithImpl<$Res>
    implements _$PageParamsCopyWith<$Res> {
  __$PageParamsCopyWithImpl(this._self, this._then);

  final _PageParams _self;
  final $Res Function(_PageParams) _then;

/// Create a copy of PageParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_PageParams(
pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppDetailsBO {

@JsonKey(name: 'appId') String get appId; String? get name; String? get version; String? get channel; String? get module; String? get arch;
/// Create a copy of AppDetailsBO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailsBOCopyWith<AppDetailsBO> get copyWith => _$AppDetailsBOCopyWithImpl<AppDetailsBO>(this as AppDetailsBO, _$identity);

  /// Serializes this AppDetailsBO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailsBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.module, module) || other.module == module)&&(identical(other.arch, arch) || other.arch == arch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,channel,module,arch);

@override
String toString() {
  return 'AppDetailsBO(appId: $appId, name: $name, version: $version, channel: $channel, module: $module, arch: $arch)';
}


}

/// @nodoc
abstract mixin class $AppDetailsBOCopyWith<$Res>  {
  factory $AppDetailsBOCopyWith(AppDetailsBO value, $Res Function(AppDetailsBO) _then) = _$AppDetailsBOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId, String? name, String? version, String? channel, String? module, String? arch
});




}
/// @nodoc
class _$AppDetailsBOCopyWithImpl<$Res>
    implements $AppDetailsBOCopyWith<$Res> {
  _$AppDetailsBOCopyWithImpl(this._self, this._then);

  final AppDetailsBO _self;
  final $Res Function(AppDetailsBO) _then;

/// Create a copy of AppDetailsBO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? name = freezed,Object? version = freezed,Object? channel = freezed,Object? module = freezed,Object? arch = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailsBO].
extension AppDetailsBOPatterns on AppDetailsBO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailsBO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailsBO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailsBO value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailsBO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailsBO value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailsBO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId,  String? name,  String? version,  String? channel,  String? module,  String? arch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailsBO() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.channel,_that.module,_that.arch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId,  String? name,  String? version,  String? channel,  String? module,  String? arch)  $default,) {final _that = this;
switch (_that) {
case _AppDetailsBO():
return $default(_that.appId,_that.name,_that.version,_that.channel,_that.module,_that.arch);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId,  String? name,  String? version,  String? channel,  String? module,  String? arch)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailsBO() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.channel,_that.module,_that.arch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailsBO implements AppDetailsBO {
  const _AppDetailsBO({@JsonKey(name: 'appId') required this.appId, this.name, this.version, this.channel, this.module, this.arch});
  factory _AppDetailsBO.fromJson(Map<String, dynamic> json) => _$AppDetailsBOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override final  String? name;
@override final  String? version;
@override final  String? channel;
@override final  String? module;
@override final  String? arch;

/// Create a copy of AppDetailsBO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailsBOCopyWith<_AppDetailsBO> get copyWith => __$AppDetailsBOCopyWithImpl<_AppDetailsBO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailsBOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailsBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.module, module) || other.module == module)&&(identical(other.arch, arch) || other.arch == arch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,channel,module,arch);

@override
String toString() {
  return 'AppDetailsBO(appId: $appId, name: $name, version: $version, channel: $channel, module: $module, arch: $arch)';
}


}

/// @nodoc
abstract mixin class _$AppDetailsBOCopyWith<$Res> implements $AppDetailsBOCopyWith<$Res> {
  factory _$AppDetailsBOCopyWith(_AppDetailsBO value, $Res Function(_AppDetailsBO) _then) = __$AppDetailsBOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId, String? name, String? version, String? channel, String? module, String? arch
});




}
/// @nodoc
class __$AppDetailsBOCopyWithImpl<$Res>
    implements _$AppDetailsBOCopyWith<$Res> {
  __$AppDetailsBOCopyWithImpl(this._self, this._then);

  final _AppDetailsBO _self;
  final $Res Function(_AppDetailsBO) _then;

/// Create a copy of AppDetailsBO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? name = freezed,Object? version = freezed,Object? channel = freezed,Object? module = freezed,Object? arch = freezed,}) {
  return _then(_AppDetailsBO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CategoryDTO {

@JsonKey(name: 'categoryId') String get categoryId;@JsonKey(name: 'categoryName') String get categoryName;@JsonKey(readValue: _readCategoryIcon) String? get categoryIcon;@JsonKey(readValue: _readCategoryCount) int? get appCount;@JsonKey(name: 'sort') int? get sort;
/// Create a copy of CategoryDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryDTOCopyWith<CategoryDTO> get copyWith => _$CategoryDTOCopyWithImpl<CategoryDTO>(this as CategoryDTO, _$identity);

  /// Serializes this CategoryDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryDTO&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.appCount, appCount) || other.appCount == appCount)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,categoryIcon,appCount,sort);

@override
String toString() {
  return 'CategoryDTO(categoryId: $categoryId, categoryName: $categoryName, categoryIcon: $categoryIcon, appCount: $appCount, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $CategoryDTOCopyWith<$Res>  {
  factory $CategoryDTOCopyWith(CategoryDTO value, $Res Function(CategoryDTO) _then) = _$CategoryDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'categoryId') String categoryId,@JsonKey(name: 'categoryName') String categoryName,@JsonKey(readValue: _readCategoryIcon) String? categoryIcon,@JsonKey(readValue: _readCategoryCount) int? appCount,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class _$CategoryDTOCopyWithImpl<$Res>
    implements $CategoryDTOCopyWith<$Res> {
  _$CategoryDTOCopyWithImpl(this._self, this._then);

  final CategoryDTO _self;
  final $Res Function(CategoryDTO) _then;

/// Create a copy of CategoryDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? categoryName = null,Object? categoryIcon = freezed,Object? appCount = freezed,Object? sort = freezed,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,appCount: freezed == appCount ? _self.appCount : appCount // ignore: cast_nullable_to_non_nullable
as int?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryDTO].
extension CategoryDTOPatterns on CategoryDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryDTO value)  $default,){
final _that = this;
switch (_that) {
case _CategoryDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'categoryId')  String categoryId, @JsonKey(name: 'categoryName')  String categoryName, @JsonKey(readValue: _readCategoryIcon)  String? categoryIcon, @JsonKey(readValue: _readCategoryCount)  int? appCount, @JsonKey(name: 'sort')  int? sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryDTO() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.categoryIcon,_that.appCount,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'categoryId')  String categoryId, @JsonKey(name: 'categoryName')  String categoryName, @JsonKey(readValue: _readCategoryIcon)  String? categoryIcon, @JsonKey(readValue: _readCategoryCount)  int? appCount, @JsonKey(name: 'sort')  int? sort)  $default,) {final _that = this;
switch (_that) {
case _CategoryDTO():
return $default(_that.categoryId,_that.categoryName,_that.categoryIcon,_that.appCount,_that.sort);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'categoryId')  String categoryId, @JsonKey(name: 'categoryName')  String categoryName, @JsonKey(readValue: _readCategoryIcon)  String? categoryIcon, @JsonKey(readValue: _readCategoryCount)  int? appCount, @JsonKey(name: 'sort')  int? sort)?  $default,) {final _that = this;
switch (_that) {
case _CategoryDTO() when $default != null:
return $default(_that.categoryId,_that.categoryName,_that.categoryIcon,_that.appCount,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryDTO implements CategoryDTO {
  const _CategoryDTO({@JsonKey(name: 'categoryId') required this.categoryId, @JsonKey(name: 'categoryName') required this.categoryName, @JsonKey(readValue: _readCategoryIcon) this.categoryIcon, @JsonKey(readValue: _readCategoryCount) this.appCount, @JsonKey(name: 'sort') this.sort});
  factory _CategoryDTO.fromJson(Map<String, dynamic> json) => _$CategoryDTOFromJson(json);

@override@JsonKey(name: 'categoryId') final  String categoryId;
@override@JsonKey(name: 'categoryName') final  String categoryName;
@override@JsonKey(readValue: _readCategoryIcon) final  String? categoryIcon;
@override@JsonKey(readValue: _readCategoryCount) final  int? appCount;
@override@JsonKey(name: 'sort') final  int? sort;

/// Create a copy of CategoryDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryDTOCopyWith<_CategoryDTO> get copyWith => __$CategoryDTOCopyWithImpl<_CategoryDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryDTO&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryIcon, categoryIcon) || other.categoryIcon == categoryIcon)&&(identical(other.appCount, appCount) || other.appCount == appCount)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categoryId,categoryName,categoryIcon,appCount,sort);

@override
String toString() {
  return 'CategoryDTO(categoryId: $categoryId, categoryName: $categoryName, categoryIcon: $categoryIcon, appCount: $appCount, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$CategoryDTOCopyWith<$Res> implements $CategoryDTOCopyWith<$Res> {
  factory _$CategoryDTOCopyWith(_CategoryDTO value, $Res Function(_CategoryDTO) _then) = __$CategoryDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'categoryId') String categoryId,@JsonKey(name: 'categoryName') String categoryName,@JsonKey(readValue: _readCategoryIcon) String? categoryIcon,@JsonKey(readValue: _readCategoryCount) int? appCount,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class __$CategoryDTOCopyWithImpl<$Res>
    implements _$CategoryDTOCopyWith<$Res> {
  __$CategoryDTOCopyWithImpl(this._self, this._then);

  final _CategoryDTO _self;
  final $Res Function(_CategoryDTO) _then;

/// Create a copy of CategoryDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? categoryName = null,Object? categoryIcon = freezed,Object? appCount = freezed,Object? sort = freezed,}) {
  return _then(_CategoryDTO(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,categoryName: null == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String,categoryIcon: freezed == categoryIcon ? _self.categoryIcon : categoryIcon // ignore: cast_nullable_to_non_nullable
as String?,appCount: freezed == appCount ? _self.appCount : appCount // ignore: cast_nullable_to_non_nullable
as int?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CategoryListResponse {

 int get code; String? get message; List<CategoryDTO> get data;
/// Create a copy of CategoryListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryListResponseCopyWith<CategoryListResponse> get copyWith => _$CategoryListResponseCopyWithImpl<CategoryListResponse>(this as CategoryListResponse, _$identity);

  /// Serializes this CategoryListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'CategoryListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CategoryListResponseCopyWith<$Res>  {
  factory $CategoryListResponseCopyWith(CategoryListResponse value, $Res Function(CategoryListResponse) _then) = _$CategoryListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<CategoryDTO> data
});




}
/// @nodoc
class _$CategoryListResponseCopyWithImpl<$Res>
    implements $CategoryListResponseCopyWith<$Res> {
  _$CategoryListResponseCopyWithImpl(this._self, this._then);

  final CategoryListResponse _self;
  final $Res Function(CategoryListResponse) _then;

/// Create a copy of CategoryListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<CategoryDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryListResponse].
extension CategoryListResponsePatterns on CategoryListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryListResponse value)  $default,){
final _that = this;
switch (_that) {
case _CategoryListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<CategoryDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<CategoryDTO> data)  $default,) {final _that = this;
switch (_that) {
case _CategoryListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<CategoryDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _CategoryListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryListResponse implements CategoryListResponse {
  const _CategoryListResponse({required this.code, this.message, required final  List<CategoryDTO> data}): _data = data;
  factory _CategoryListResponse.fromJson(Map<String, dynamic> json) => _$CategoryListResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<CategoryDTO> _data;
@override List<CategoryDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of CategoryListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryListResponseCopyWith<_CategoryListResponse> get copyWith => __$CategoryListResponseCopyWithImpl<_CategoryListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'CategoryListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CategoryListResponseCopyWith<$Res> implements $CategoryListResponseCopyWith<$Res> {
  factory _$CategoryListResponseCopyWith(_CategoryListResponse value, $Res Function(_CategoryListResponse) _then) = __$CategoryListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<CategoryDTO> data
});




}
/// @nodoc
class __$CategoryListResponseCopyWithImpl<$Res>
    implements _$CategoryListResponseCopyWith<$Res> {
  __$CategoryListResponseCopyWithImpl(this._self, this._then);

  final _CategoryListResponse _self;
  final $Res Function(_CategoryListResponse) _then;

/// Create a copy of CategoryListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_CategoryListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<CategoryDTO>,
  ));
}


}


/// @nodoc
mixin _$AppDetailSearchBO {

 String get appId; String get arch;// /app/getAppDetail 会按语言精确过滤截图和标签，必须显式传入 lang。
 String? get lang;
/// Create a copy of AppDetailSearchBO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailSearchBOCopyWith<AppDetailSearchBO> get copyWith => _$AppDetailSearchBOCopyWithImpl<AppDetailSearchBO>(this as AppDetailSearchBO, _$identity);

  /// Serializes this AppDetailSearchBO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailSearchBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lang, lang) || other.lang == lang));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,arch,lang);

@override
String toString() {
  return 'AppDetailSearchBO(appId: $appId, arch: $arch, lang: $lang)';
}


}

/// @nodoc
abstract mixin class $AppDetailSearchBOCopyWith<$Res>  {
  factory $AppDetailSearchBOCopyWith(AppDetailSearchBO value, $Res Function(AppDetailSearchBO) _then) = _$AppDetailSearchBOCopyWithImpl;
@useResult
$Res call({
 String appId, String arch, String? lang
});




}
/// @nodoc
class _$AppDetailSearchBOCopyWithImpl<$Res>
    implements $AppDetailSearchBOCopyWith<$Res> {
  _$AppDetailSearchBOCopyWithImpl(this._self, this._then);

  final AppDetailSearchBO _self;
  final $Res Function(AppDetailSearchBO) _then;

/// Create a copy of AppDetailSearchBO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? arch = null,Object? lang = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailSearchBO].
extension AppDetailSearchBOPatterns on AppDetailSearchBO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailSearchBO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailSearchBO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailSearchBO value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailSearchBO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailSearchBO value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailSearchBO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String arch,  String? lang)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailSearchBO() when $default != null:
return $default(_that.appId,_that.arch,_that.lang);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String arch,  String? lang)  $default,) {final _that = this;
switch (_that) {
case _AppDetailSearchBO():
return $default(_that.appId,_that.arch,_that.lang);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String arch,  String? lang)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailSearchBO() when $default != null:
return $default(_that.appId,_that.arch,_that.lang);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailSearchBO implements AppDetailSearchBO {
  const _AppDetailSearchBO({required this.appId, required this.arch, this.lang});
  factory _AppDetailSearchBO.fromJson(Map<String, dynamic> json) => _$AppDetailSearchBOFromJson(json);

@override final  String appId;
@override final  String arch;
// /app/getAppDetail 会按语言精确过滤截图和标签，必须显式传入 lang。
@override final  String? lang;

/// Create a copy of AppDetailSearchBO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailSearchBOCopyWith<_AppDetailSearchBO> get copyWith => __$AppDetailSearchBOCopyWithImpl<_AppDetailSearchBO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailSearchBOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailSearchBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lang, lang) || other.lang == lang));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,arch,lang);

@override
String toString() {
  return 'AppDetailSearchBO(appId: $appId, arch: $arch, lang: $lang)';
}


}

/// @nodoc
abstract mixin class _$AppDetailSearchBOCopyWith<$Res> implements $AppDetailSearchBOCopyWith<$Res> {
  factory _$AppDetailSearchBOCopyWith(_AppDetailSearchBO value, $Res Function(_AppDetailSearchBO) _then) = __$AppDetailSearchBOCopyWithImpl;
@override @useResult
$Res call({
 String appId, String arch, String? lang
});




}
/// @nodoc
class __$AppDetailSearchBOCopyWithImpl<$Res>
    implements _$AppDetailSearchBOCopyWith<$Res> {
  __$AppDetailSearchBOCopyWithImpl(this._self, this._then);

  final _AppDetailSearchBO _self;
  final $Res Function(_AppDetailSearchBO) _then;

/// Create a copy of AppDetailSearchBO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? arch = null,Object? lang = freezed,}) {
  return _then(_AppDetailSearchBO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,lang: freezed == lang ? _self.lang : lang // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppCommentSearchBO {

@JsonKey(name: 'appId') String get appId;
/// Create a copy of AppCommentSearchBO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCommentSearchBOCopyWith<AppCommentSearchBO> get copyWith => _$AppCommentSearchBOCopyWithImpl<AppCommentSearchBO>(this as AppCommentSearchBO, _$identity);

  /// Serializes this AppCommentSearchBO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppCommentSearchBO&&(identical(other.appId, appId) || other.appId == appId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId);

@override
String toString() {
  return 'AppCommentSearchBO(appId: $appId)';
}


}

/// @nodoc
abstract mixin class $AppCommentSearchBOCopyWith<$Res>  {
  factory $AppCommentSearchBOCopyWith(AppCommentSearchBO value, $Res Function(AppCommentSearchBO) _then) = _$AppCommentSearchBOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId
});




}
/// @nodoc
class _$AppCommentSearchBOCopyWithImpl<$Res>
    implements $AppCommentSearchBOCopyWith<$Res> {
  _$AppCommentSearchBOCopyWithImpl(this._self, this._then);

  final AppCommentSearchBO _self;
  final $Res Function(AppCommentSearchBO) _then;

/// Create a copy of AppCommentSearchBO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppCommentSearchBO].
extension AppCommentSearchBOPatterns on AppCommentSearchBO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppCommentSearchBO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppCommentSearchBO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppCommentSearchBO value)  $default,){
final _that = this;
switch (_that) {
case _AppCommentSearchBO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppCommentSearchBO value)?  $default,){
final _that = this;
switch (_that) {
case _AppCommentSearchBO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppCommentSearchBO() when $default != null:
return $default(_that.appId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId)  $default,) {final _that = this;
switch (_that) {
case _AppCommentSearchBO():
return $default(_that.appId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId)?  $default,) {final _that = this;
switch (_that) {
case _AppCommentSearchBO() when $default != null:
return $default(_that.appId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppCommentSearchBO implements AppCommentSearchBO {
  const _AppCommentSearchBO({@JsonKey(name: 'appId') required this.appId});
  factory _AppCommentSearchBO.fromJson(Map<String, dynamic> json) => _$AppCommentSearchBOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;

/// Create a copy of AppCommentSearchBO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCommentSearchBOCopyWith<_AppCommentSearchBO> get copyWith => __$AppCommentSearchBOCopyWithImpl<_AppCommentSearchBO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppCommentSearchBOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppCommentSearchBO&&(identical(other.appId, appId) || other.appId == appId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId);

@override
String toString() {
  return 'AppCommentSearchBO(appId: $appId)';
}


}

/// @nodoc
abstract mixin class _$AppCommentSearchBOCopyWith<$Res> implements $AppCommentSearchBOCopyWith<$Res> {
  factory _$AppCommentSearchBOCopyWith(_AppCommentSearchBO value, $Res Function(_AppCommentSearchBO) _then) = __$AppCommentSearchBOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId
});




}
/// @nodoc
class __$AppCommentSearchBOCopyWithImpl<$Res>
    implements _$AppCommentSearchBOCopyWith<$Res> {
  __$AppCommentSearchBOCopyWithImpl(this._self, this._then);

  final _AppCommentSearchBO _self;
  final $Res Function(_AppCommentSearchBO) _then;

/// Create a copy of AppCommentSearchBO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,}) {
  return _then(_AppCommentSearchBO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AppCommentSaveBO {

@JsonKey(name: 'appId') String get appId;@JsonKey(name: 'remark') String get remark;@JsonKey(name: 'version') String? get version;@JsonKey(name: 'visit') String? get visit;
/// Create a copy of AppCommentSaveBO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCommentSaveBOCopyWith<AppCommentSaveBO> get copyWith => _$AppCommentSaveBOCopyWithImpl<AppCommentSaveBO>(this as AppCommentSaveBO, _$identity);

  /// Serializes this AppCommentSaveBO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppCommentSaveBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.version, version) || other.version == version)&&(identical(other.visit, visit) || other.visit == visit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,remark,version,visit);

@override
String toString() {
  return 'AppCommentSaveBO(appId: $appId, remark: $remark, version: $version, visit: $visit)';
}


}

/// @nodoc
abstract mixin class $AppCommentSaveBOCopyWith<$Res>  {
  factory $AppCommentSaveBOCopyWith(AppCommentSaveBO value, $Res Function(AppCommentSaveBO) _then) = _$AppCommentSaveBOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'remark') String remark,@JsonKey(name: 'version') String? version,@JsonKey(name: 'visit') String? visit
});




}
/// @nodoc
class _$AppCommentSaveBOCopyWithImpl<$Res>
    implements $AppCommentSaveBOCopyWith<$Res> {
  _$AppCommentSaveBOCopyWithImpl(this._self, this._then);

  final AppCommentSaveBO _self;
  final $Res Function(AppCommentSaveBO) _then;

/// Create a copy of AppCommentSaveBO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? remark = null,Object? version = freezed,Object? visit = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppCommentSaveBO].
extension AppCommentSaveBOPatterns on AppCommentSaveBO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppCommentSaveBO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppCommentSaveBO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppCommentSaveBO value)  $default,){
final _that = this;
switch (_that) {
case _AppCommentSaveBO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppCommentSaveBO value)?  $default,){
final _that = this;
switch (_that) {
case _AppCommentSaveBO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'visit')  String? visit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppCommentSaveBO() when $default != null:
return $default(_that.appId,_that.remark,_that.version,_that.visit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'visit')  String? visit)  $default,) {final _that = this;
switch (_that) {
case _AppCommentSaveBO():
return $default(_that.appId,_that.remark,_that.version,_that.visit);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'visit')  String? visit)?  $default,) {final _that = this;
switch (_that) {
case _AppCommentSaveBO() when $default != null:
return $default(_that.appId,_that.remark,_that.version,_that.visit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppCommentSaveBO implements AppCommentSaveBO {
  const _AppCommentSaveBO({@JsonKey(name: 'appId') required this.appId, @JsonKey(name: 'remark') required this.remark, @JsonKey(name: 'version') this.version, @JsonKey(name: 'visit') this.visit});
  factory _AppCommentSaveBO.fromJson(Map<String, dynamic> json) => _$AppCommentSaveBOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(name: 'remark') final  String remark;
@override@JsonKey(name: 'version') final  String? version;
@override@JsonKey(name: 'visit') final  String? visit;

/// Create a copy of AppCommentSaveBO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCommentSaveBOCopyWith<_AppCommentSaveBO> get copyWith => __$AppCommentSaveBOCopyWithImpl<_AppCommentSaveBO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppCommentSaveBOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppCommentSaveBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.version, version) || other.version == version)&&(identical(other.visit, visit) || other.visit == visit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,remark,version,visit);

@override
String toString() {
  return 'AppCommentSaveBO(appId: $appId, remark: $remark, version: $version, visit: $visit)';
}


}

/// @nodoc
abstract mixin class _$AppCommentSaveBOCopyWith<$Res> implements $AppCommentSaveBOCopyWith<$Res> {
  factory _$AppCommentSaveBOCopyWith(_AppCommentSaveBO value, $Res Function(_AppCommentSaveBO) _then) = __$AppCommentSaveBOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'remark') String remark,@JsonKey(name: 'version') String? version,@JsonKey(name: 'visit') String? visit
});




}
/// @nodoc
class __$AppCommentSaveBOCopyWithImpl<$Res>
    implements _$AppCommentSaveBOCopyWith<$Res> {
  __$AppCommentSaveBOCopyWithImpl(this._self, this._then);

  final _AppCommentSaveBO _self;
  final $Res Function(_AppCommentSaveBO) _then;

/// Create a copy of AppCommentSaveBO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? remark = null,Object? version = freezed,Object? visit = freezed,}) {
  return _then(_AppCommentSaveBO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppCheckVersionBO {

 String get appId; String get arch; String get version;
/// Create a copy of AppCheckVersionBO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCheckVersionBOCopyWith<AppCheckVersionBO> get copyWith => _$AppCheckVersionBOCopyWithImpl<AppCheckVersionBO>(this as AppCheckVersionBO, _$identity);

  /// Serializes this AppCheckVersionBO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppCheckVersionBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,arch,version);

@override
String toString() {
  return 'AppCheckVersionBO(appId: $appId, arch: $arch, version: $version)';
}


}

/// @nodoc
abstract mixin class $AppCheckVersionBOCopyWith<$Res>  {
  factory $AppCheckVersionBOCopyWith(AppCheckVersionBO value, $Res Function(AppCheckVersionBO) _then) = _$AppCheckVersionBOCopyWithImpl;
@useResult
$Res call({
 String appId, String arch, String version
});




}
/// @nodoc
class _$AppCheckVersionBOCopyWithImpl<$Res>
    implements $AppCheckVersionBOCopyWith<$Res> {
  _$AppCheckVersionBOCopyWithImpl(this._self, this._then);

  final AppCheckVersionBO _self;
  final $Res Function(AppCheckVersionBO) _then;

/// Create a copy of AppCheckVersionBO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? arch = null,Object? version = null,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [AppCheckVersionBO].
extension AppCheckVersionBOPatterns on AppCheckVersionBO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppCheckVersionBO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppCheckVersionBO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppCheckVersionBO value)  $default,){
final _that = this;
switch (_that) {
case _AppCheckVersionBO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppCheckVersionBO value)?  $default,){
final _that = this;
switch (_that) {
case _AppCheckVersionBO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String arch,  String version)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppCheckVersionBO() when $default != null:
return $default(_that.appId,_that.arch,_that.version);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String arch,  String version)  $default,) {final _that = this;
switch (_that) {
case _AppCheckVersionBO():
return $default(_that.appId,_that.arch,_that.version);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String arch,  String version)?  $default,) {final _that = this;
switch (_that) {
case _AppCheckVersionBO() when $default != null:
return $default(_that.appId,_that.arch,_that.version);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppCheckVersionBO implements AppCheckVersionBO {
  const _AppCheckVersionBO({required this.appId, required this.arch, required this.version});
  factory _AppCheckVersionBO.fromJson(Map<String, dynamic> json) => _$AppCheckVersionBOFromJson(json);

@override final  String appId;
@override final  String arch;
@override final  String version;

/// Create a copy of AppCheckVersionBO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCheckVersionBOCopyWith<_AppCheckVersionBO> get copyWith => __$AppCheckVersionBOCopyWithImpl<_AppCheckVersionBO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppCheckVersionBOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppCheckVersionBO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.version, version) || other.version == version));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,arch,version);

@override
String toString() {
  return 'AppCheckVersionBO(appId: $appId, arch: $arch, version: $version)';
}


}

/// @nodoc
abstract mixin class _$AppCheckVersionBOCopyWith<$Res> implements $AppCheckVersionBOCopyWith<$Res> {
  factory _$AppCheckVersionBOCopyWith(_AppCheckVersionBO value, $Res Function(_AppCheckVersionBO) _then) = __$AppCheckVersionBOCopyWithImpl;
@override @useResult
$Res call({
 String appId, String arch, String version
});




}
/// @nodoc
class __$AppCheckVersionBOCopyWithImpl<$Res>
    implements _$AppCheckVersionBOCopyWith<$Res> {
  __$AppCheckVersionBOCopyWithImpl(this._self, this._then);

  final _AppCheckVersionBO _self;
  final $Res Function(_AppCheckVersionBO) _then;

/// Create a copy of AppCheckVersionBO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? arch = null,Object? version = null,}) {
  return _then(_AppCheckVersionBO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,arch: null == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AppScreenshotDTO {

@JsonKey(name: 'screenshotKey') String get screenshotUrl;@JsonKey(name: 'lan') String? get language;
/// Create a copy of AppScreenshotDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppScreenshotDTOCopyWith<AppScreenshotDTO> get copyWith => _$AppScreenshotDTOCopyWithImpl<AppScreenshotDTO>(this as AppScreenshotDTO, _$identity);

  /// Serializes this AppScreenshotDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppScreenshotDTO&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,screenshotUrl,language);

@override
String toString() {
  return 'AppScreenshotDTO(screenshotUrl: $screenshotUrl, language: $language)';
}


}

/// @nodoc
abstract mixin class $AppScreenshotDTOCopyWith<$Res>  {
  factory $AppScreenshotDTOCopyWith(AppScreenshotDTO value, $Res Function(AppScreenshotDTO) _then) = _$AppScreenshotDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'screenshotKey') String screenshotUrl,@JsonKey(name: 'lan') String? language
});




}
/// @nodoc
class _$AppScreenshotDTOCopyWithImpl<$Res>
    implements $AppScreenshotDTOCopyWith<$Res> {
  _$AppScreenshotDTOCopyWithImpl(this._self, this._then);

  final AppScreenshotDTO _self;
  final $Res Function(AppScreenshotDTO) _then;

/// Create a copy of AppScreenshotDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? screenshotUrl = null,Object? language = freezed,}) {
  return _then(_self.copyWith(
screenshotUrl: null == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppScreenshotDTO].
extension AppScreenshotDTOPatterns on AppScreenshotDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppScreenshotDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppScreenshotDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppScreenshotDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppScreenshotDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppScreenshotDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppScreenshotDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'screenshotKey')  String screenshotUrl, @JsonKey(name: 'lan')  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppScreenshotDTO() when $default != null:
return $default(_that.screenshotUrl,_that.language);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'screenshotKey')  String screenshotUrl, @JsonKey(name: 'lan')  String? language)  $default,) {final _that = this;
switch (_that) {
case _AppScreenshotDTO():
return $default(_that.screenshotUrl,_that.language);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'screenshotKey')  String screenshotUrl, @JsonKey(name: 'lan')  String? language)?  $default,) {final _that = this;
switch (_that) {
case _AppScreenshotDTO() when $default != null:
return $default(_that.screenshotUrl,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppScreenshotDTO implements AppScreenshotDTO {
  const _AppScreenshotDTO({@JsonKey(name: 'screenshotKey') required this.screenshotUrl, @JsonKey(name: 'lan') this.language});
  factory _AppScreenshotDTO.fromJson(Map<String, dynamic> json) => _$AppScreenshotDTOFromJson(json);

@override@JsonKey(name: 'screenshotKey') final  String screenshotUrl;
@override@JsonKey(name: 'lan') final  String? language;

/// Create a copy of AppScreenshotDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppScreenshotDTOCopyWith<_AppScreenshotDTO> get copyWith => __$AppScreenshotDTOCopyWithImpl<_AppScreenshotDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppScreenshotDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppScreenshotDTO&&(identical(other.screenshotUrl, screenshotUrl) || other.screenshotUrl == screenshotUrl)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,screenshotUrl,language);

@override
String toString() {
  return 'AppScreenshotDTO(screenshotUrl: $screenshotUrl, language: $language)';
}


}

/// @nodoc
abstract mixin class _$AppScreenshotDTOCopyWith<$Res> implements $AppScreenshotDTOCopyWith<$Res> {
  factory _$AppScreenshotDTOCopyWith(_AppScreenshotDTO value, $Res Function(_AppScreenshotDTO) _then) = __$AppScreenshotDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'screenshotKey') String screenshotUrl,@JsonKey(name: 'lan') String? language
});




}
/// @nodoc
class __$AppScreenshotDTOCopyWithImpl<$Res>
    implements _$AppScreenshotDTOCopyWith<$Res> {
  __$AppScreenshotDTOCopyWithImpl(this._self, this._then);

  final _AppScreenshotDTO _self;
  final $Res Function(_AppScreenshotDTO) _then;

/// Create a copy of AppScreenshotDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? screenshotUrl = null,Object? language = freezed,}) {
  return _then(_AppScreenshotDTO(
screenshotUrl: null == screenshotUrl ? _self.screenshotUrl : screenshotUrl // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppTagDTO {

@JsonKey(name: 'name') String get name;@JsonKey(name: 'lan') String? get language;
/// Create a copy of AppTagDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppTagDTOCopyWith<AppTagDTO> get copyWith => _$AppTagDTOCopyWithImpl<AppTagDTO>(this as AppTagDTO, _$identity);

  /// Serializes this AppTagDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppTagDTO&&(identical(other.name, name) || other.name == name)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,language);

@override
String toString() {
  return 'AppTagDTO(name: $name, language: $language)';
}


}

/// @nodoc
abstract mixin class $AppTagDTOCopyWith<$Res>  {
  factory $AppTagDTOCopyWith(AppTagDTO value, $Res Function(AppTagDTO) _then) = _$AppTagDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'lan') String? language
});




}
/// @nodoc
class _$AppTagDTOCopyWithImpl<$Res>
    implements $AppTagDTOCopyWith<$Res> {
  _$AppTagDTOCopyWithImpl(this._self, this._then);

  final AppTagDTO _self;
  final $Res Function(AppTagDTO) _then;

/// Create a copy of AppTagDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? language = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppTagDTO].
extension AppTagDTOPatterns on AppTagDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppTagDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppTagDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppTagDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppTagDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppTagDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppTagDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'lan')  String? language)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppTagDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'lan')  String? language)  $default,) {final _that = this;
switch (_that) {
case _AppTagDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'name')  String name, @JsonKey(name: 'lan')  String? language)?  $default,) {final _that = this;
switch (_that) {
case _AppTagDTO() when $default != null:
return $default(_that.name,_that.language);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppTagDTO implements AppTagDTO {
  const _AppTagDTO({@JsonKey(name: 'name') required this.name, @JsonKey(name: 'lan') this.language});
  factory _AppTagDTO.fromJson(Map<String, dynamic> json) => _$AppTagDTOFromJson(json);

@override@JsonKey(name: 'name') final  String name;
@override@JsonKey(name: 'lan') final  String? language;

/// Create a copy of AppTagDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppTagDTOCopyWith<_AppTagDTO> get copyWith => __$AppTagDTOCopyWithImpl<_AppTagDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppTagDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppTagDTO&&(identical(other.name, name) || other.name == name)&&(identical(other.language, language) || other.language == language));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,language);

@override
String toString() {
  return 'AppTagDTO(name: $name, language: $language)';
}


}

/// @nodoc
abstract mixin class _$AppTagDTOCopyWith<$Res> implements $AppTagDTOCopyWith<$Res> {
  factory _$AppTagDTOCopyWith(_AppTagDTO value, $Res Function(_AppTagDTO) _then) = __$AppTagDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'name') String name,@JsonKey(name: 'lan') String? language
});




}
/// @nodoc
class __$AppTagDTOCopyWithImpl<$Res>
    implements _$AppTagDTOCopyWith<$Res> {
  __$AppTagDTOCopyWithImpl(this._self, this._then);

  final _AppTagDTO _self;
  final $Res Function(_AppTagDTO) _then;

/// Create a copy of AppTagDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? language = freezed,}) {
  return _then(_AppTagDTO(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppCommentDTO {

@JsonKey(name: 'id') String get id;@JsonKey(name: 'appId') String get appId;@JsonKey(name: 'version') String? get version;@JsonKey(name: 'remark') String get remark;@JsonKey(name: 'visit') String? get visit;@JsonKey(name: 'clientIp') String? get clientIp;@JsonKey(name: 'agreeNum') int get agreeNum;@JsonKey(name: 'disagreeNum') int get disagreeNum;@JsonKey(name: 'createTime') String? get createTime;@JsonKey(name: 'updateTime') String? get updateTime;@JsonKey(name: 'isDelete') String? get isDelete;
/// Create a copy of AppCommentDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCommentDTOCopyWith<AppCommentDTO> get copyWith => _$AppCommentDTOCopyWithImpl<AppCommentDTO>(this as AppCommentDTO, _$identity);

  /// Serializes this AppCommentDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppCommentDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.version, version) || other.version == version)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.visit, visit) || other.visit == visit)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&(identical(other.agreeNum, agreeNum) || other.agreeNum == agreeNum)&&(identical(other.disagreeNum, disagreeNum) || other.disagreeNum == disagreeNum)&&(identical(other.createTime, createTime) || other.createTime == createTime)&&(identical(other.updateTime, updateTime) || other.updateTime == updateTime)&&(identical(other.isDelete, isDelete) || other.isDelete == isDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,version,remark,visit,clientIp,agreeNum,disagreeNum,createTime,updateTime,isDelete);

@override
String toString() {
  return 'AppCommentDTO(id: $id, appId: $appId, version: $version, remark: $remark, visit: $visit, clientIp: $clientIp, agreeNum: $agreeNum, disagreeNum: $disagreeNum, createTime: $createTime, updateTime: $updateTime, isDelete: $isDelete)';
}


}

/// @nodoc
abstract mixin class $AppCommentDTOCopyWith<$Res>  {
  factory $AppCommentDTOCopyWith(AppCommentDTO value, $Res Function(AppCommentDTO) _then) = _$AppCommentDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'appId') String appId,@JsonKey(name: 'version') String? version,@JsonKey(name: 'remark') String remark,@JsonKey(name: 'visit') String? visit,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'agreeNum') int agreeNum,@JsonKey(name: 'disagreeNum') int disagreeNum,@JsonKey(name: 'createTime') String? createTime,@JsonKey(name: 'updateTime') String? updateTime,@JsonKey(name: 'isDelete') String? isDelete
});




}
/// @nodoc
class _$AppCommentDTOCopyWithImpl<$Res>
    implements $AppCommentDTOCopyWith<$Res> {
  _$AppCommentDTOCopyWithImpl(this._self, this._then);

  final AppCommentDTO _self;
  final $Res Function(AppCommentDTO) _then;

/// Create a copy of AppCommentDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? version = freezed,Object? remark = null,Object? visit = freezed,Object? clientIp = freezed,Object? agreeNum = null,Object? disagreeNum = null,Object? createTime = freezed,Object? updateTime = freezed,Object? isDelete = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,agreeNum: null == agreeNum ? _self.agreeNum : agreeNum // ignore: cast_nullable_to_non_nullable
as int,disagreeNum: null == disagreeNum ? _self.disagreeNum : disagreeNum // ignore: cast_nullable_to_non_nullable
as int,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,updateTime: freezed == updateTime ? _self.updateTime : updateTime // ignore: cast_nullable_to_non_nullable
as String?,isDelete: freezed == isDelete ? _self.isDelete : isDelete // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppCommentDTO].
extension AppCommentDTOPatterns on AppCommentDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppCommentDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppCommentDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppCommentDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppCommentDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppCommentDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppCommentDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'appId')  String appId, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'visit')  String? visit, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'agreeNum')  int agreeNum, @JsonKey(name: 'disagreeNum')  int disagreeNum, @JsonKey(name: 'createTime')  String? createTime, @JsonKey(name: 'updateTime')  String? updateTime, @JsonKey(name: 'isDelete')  String? isDelete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppCommentDTO() when $default != null:
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.visit,_that.clientIp,_that.agreeNum,_that.disagreeNum,_that.createTime,_that.updateTime,_that.isDelete);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'appId')  String appId, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'visit')  String? visit, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'agreeNum')  int agreeNum, @JsonKey(name: 'disagreeNum')  int disagreeNum, @JsonKey(name: 'createTime')  String? createTime, @JsonKey(name: 'updateTime')  String? updateTime, @JsonKey(name: 'isDelete')  String? isDelete)  $default,) {final _that = this;
switch (_that) {
case _AppCommentDTO():
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.visit,_that.clientIp,_that.agreeNum,_that.disagreeNum,_that.createTime,_that.updateTime,_that.isDelete);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String id, @JsonKey(name: 'appId')  String appId, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'remark')  String remark, @JsonKey(name: 'visit')  String? visit, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'agreeNum')  int agreeNum, @JsonKey(name: 'disagreeNum')  int disagreeNum, @JsonKey(name: 'createTime')  String? createTime, @JsonKey(name: 'updateTime')  String? updateTime, @JsonKey(name: 'isDelete')  String? isDelete)?  $default,) {final _that = this;
switch (_that) {
case _AppCommentDTO() when $default != null:
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.visit,_that.clientIp,_that.agreeNum,_that.disagreeNum,_that.createTime,_that.updateTime,_that.isDelete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppCommentDTO implements AppCommentDTO {
  const _AppCommentDTO({@JsonKey(name: 'id') required this.id, @JsonKey(name: 'appId') required this.appId, @JsonKey(name: 'version') this.version, @JsonKey(name: 'remark') required this.remark, @JsonKey(name: 'visit') this.visit, @JsonKey(name: 'clientIp') this.clientIp, @JsonKey(name: 'agreeNum') this.agreeNum = 0, @JsonKey(name: 'disagreeNum') this.disagreeNum = 0, @JsonKey(name: 'createTime') this.createTime, @JsonKey(name: 'updateTime') this.updateTime, @JsonKey(name: 'isDelete') this.isDelete});
  factory _AppCommentDTO.fromJson(Map<String, dynamic> json) => _$AppCommentDTOFromJson(json);

@override@JsonKey(name: 'id') final  String id;
@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(name: 'version') final  String? version;
@override@JsonKey(name: 'remark') final  String remark;
@override@JsonKey(name: 'visit') final  String? visit;
@override@JsonKey(name: 'clientIp') final  String? clientIp;
@override@JsonKey(name: 'agreeNum') final  int agreeNum;
@override@JsonKey(name: 'disagreeNum') final  int disagreeNum;
@override@JsonKey(name: 'createTime') final  String? createTime;
@override@JsonKey(name: 'updateTime') final  String? updateTime;
@override@JsonKey(name: 'isDelete') final  String? isDelete;

/// Create a copy of AppCommentDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCommentDTOCopyWith<_AppCommentDTO> get copyWith => __$AppCommentDTOCopyWithImpl<_AppCommentDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppCommentDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppCommentDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.version, version) || other.version == version)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.visit, visit) || other.visit == visit)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&(identical(other.agreeNum, agreeNum) || other.agreeNum == agreeNum)&&(identical(other.disagreeNum, disagreeNum) || other.disagreeNum == disagreeNum)&&(identical(other.createTime, createTime) || other.createTime == createTime)&&(identical(other.updateTime, updateTime) || other.updateTime == updateTime)&&(identical(other.isDelete, isDelete) || other.isDelete == isDelete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,appId,version,remark,visit,clientIp,agreeNum,disagreeNum,createTime,updateTime,isDelete);

@override
String toString() {
  return 'AppCommentDTO(id: $id, appId: $appId, version: $version, remark: $remark, visit: $visit, clientIp: $clientIp, agreeNum: $agreeNum, disagreeNum: $disagreeNum, createTime: $createTime, updateTime: $updateTime, isDelete: $isDelete)';
}


}

/// @nodoc
abstract mixin class _$AppCommentDTOCopyWith<$Res> implements $AppCommentDTOCopyWith<$Res> {
  factory _$AppCommentDTOCopyWith(_AppCommentDTO value, $Res Function(_AppCommentDTO) _then) = __$AppCommentDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String id,@JsonKey(name: 'appId') String appId,@JsonKey(name: 'version') String? version,@JsonKey(name: 'remark') String remark,@JsonKey(name: 'visit') String? visit,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'agreeNum') int agreeNum,@JsonKey(name: 'disagreeNum') int disagreeNum,@JsonKey(name: 'createTime') String? createTime,@JsonKey(name: 'updateTime') String? updateTime,@JsonKey(name: 'isDelete') String? isDelete
});




}
/// @nodoc
class __$AppCommentDTOCopyWithImpl<$Res>
    implements _$AppCommentDTOCopyWith<$Res> {
  __$AppCommentDTOCopyWithImpl(this._self, this._then);

  final _AppCommentDTO _self;
  final $Res Function(_AppCommentDTO) _then;

/// Create a copy of AppCommentDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? version = freezed,Object? remark = null,Object? visit = freezed,Object? clientIp = freezed,Object? agreeNum = null,Object? disagreeNum = null,Object? createTime = freezed,Object? updateTime = freezed,Object? isDelete = freezed,}) {
  return _then(_AppCommentDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,visit: freezed == visit ? _self.visit : visit // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,agreeNum: null == agreeNum ? _self.agreeNum : agreeNum // ignore: cast_nullable_to_non_nullable
as int,disagreeNum: null == disagreeNum ? _self.disagreeNum : disagreeNum // ignore: cast_nullable_to_non_nullable
as int,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,updateTime: freezed == updateTime ? _self.updateTime : updateTime // ignore: cast_nullable_to_non_nullable
as String?,isDelete: freezed == isDelete ? _self.isDelete : isDelete // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppDetailDTO {

@JsonKey(name: 'appId') String get appId;@JsonKey(name: 'zhName') String get appName;@JsonKey(name: 'version') String get appVersion;@JsonKey(name: 'icon') String? get appIcon;@JsonKey(name: 'description') String? get appDesc;@JsonKey(name: 'kind') String? get appKind;@JsonKey(name: 'runtime') String? get appRuntime;@JsonKey(name: 'module') String? get appModule;@JsonKey(name: 'base') String? get appBase; String? get arch; String? get channel;@JsonKey(name: 'devName') String? get developerName;@JsonKey(name: 'categoryName') String? get categoryName;@JsonKey(name: 'categoryId') String? get categoryId;@JsonKey(name: 'installCount') int? get downloadTimes;@JsonKey(name: 'size') String? get packageSize;@JsonKey(name: 'appScreenshotList') List<AppScreenshotDTO>? get screenshotList;@JsonKey(name: 'appTagList') List<AppTagDTO>? get tagList;@JsonKey(name: 'descInfo') String? get detailDescription;@JsonKey(name: 'repoName') String? get repoName;@JsonKey(name: 'repoUrl') String? get repoUrl;@JsonKey(name: 'homePage') String? get homePage;@JsonKey(name: 'license') String? get license;@JsonKey(name: 'releaseNote') String? get releaseNote;
/// Create a copy of AppDetailDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailDTOCopyWith<AppDetailDTO> get copyWith => _$AppDetailDTOCopyWithImpl<AppDetailDTO>(this as AppDetailDTO, _$identity);

  /// Serializes this AppDetailDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.appDesc, appDesc) || other.appDesc == appDesc)&&(identical(other.appKind, appKind) || other.appKind == appKind)&&(identical(other.appRuntime, appRuntime) || other.appRuntime == appRuntime)&&(identical(other.appModule, appModule) || other.appModule == appModule)&&(identical(other.appBase, appBase) || other.appBase == appBase)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&const DeepCollectionEquality().equals(other.screenshotList, screenshotList)&&const DeepCollectionEquality().equals(other.tagList, tagList)&&(identical(other.detailDescription, detailDescription) || other.detailDescription == detailDescription)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.repoUrl, repoUrl) || other.repoUrl == repoUrl)&&(identical(other.homePage, homePage) || other.homePage == homePage)&&(identical(other.license, license) || other.license == license)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appId,appName,appVersion,appIcon,appDesc,appKind,appRuntime,appModule,appBase,arch,channel,developerName,categoryName,categoryId,downloadTimes,packageSize,const DeepCollectionEquality().hash(screenshotList),const DeepCollectionEquality().hash(tagList),detailDescription,repoName,repoUrl,homePage,license,releaseNote]);

@override
String toString() {
  return 'AppDetailDTO(appId: $appId, appName: $appName, appVersion: $appVersion, appIcon: $appIcon, appDesc: $appDesc, appKind: $appKind, appRuntime: $appRuntime, appModule: $appModule, appBase: $appBase, arch: $arch, channel: $channel, developerName: $developerName, categoryName: $categoryName, categoryId: $categoryId, downloadTimes: $downloadTimes, packageSize: $packageSize, screenshotList: $screenshotList, tagList: $tagList, detailDescription: $detailDescription, repoName: $repoName, repoUrl: $repoUrl, homePage: $homePage, license: $license, releaseNote: $releaseNote)';
}


}

/// @nodoc
abstract mixin class $AppDetailDTOCopyWith<$Res>  {
  factory $AppDetailDTOCopyWith(AppDetailDTO value, $Res Function(AppDetailDTO) _then) = _$AppDetailDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'zhName') String appName,@JsonKey(name: 'version') String appVersion,@JsonKey(name: 'icon') String? appIcon,@JsonKey(name: 'description') String? appDesc,@JsonKey(name: 'kind') String? appKind,@JsonKey(name: 'runtime') String? appRuntime,@JsonKey(name: 'module') String? appModule,@JsonKey(name: 'base') String? appBase, String? arch, String? channel,@JsonKey(name: 'devName') String? developerName,@JsonKey(name: 'categoryName') String? categoryName,@JsonKey(name: 'categoryId') String? categoryId,@JsonKey(name: 'installCount') int? downloadTimes,@JsonKey(name: 'size') String? packageSize,@JsonKey(name: 'appScreenshotList') List<AppScreenshotDTO>? screenshotList,@JsonKey(name: 'appTagList') List<AppTagDTO>? tagList,@JsonKey(name: 'descInfo') String? detailDescription,@JsonKey(name: 'repoName') String? repoName,@JsonKey(name: 'repoUrl') String? repoUrl,@JsonKey(name: 'homePage') String? homePage,@JsonKey(name: 'license') String? license,@JsonKey(name: 'releaseNote') String? releaseNote
});




}
/// @nodoc
class _$AppDetailDTOCopyWithImpl<$Res>
    implements $AppDetailDTOCopyWith<$Res> {
  _$AppDetailDTOCopyWithImpl(this._self, this._then);

  final AppDetailDTO _self;
  final $Res Function(AppDetailDTO) _then;

/// Create a copy of AppDetailDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? appName = null,Object? appVersion = null,Object? appIcon = freezed,Object? appDesc = freezed,Object? appKind = freezed,Object? appRuntime = freezed,Object? appModule = freezed,Object? appBase = freezed,Object? arch = freezed,Object? channel = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? categoryId = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,Object? screenshotList = freezed,Object? tagList = freezed,Object? detailDescription = freezed,Object? repoName = freezed,Object? repoUrl = freezed,Object? homePage = freezed,Object? license = freezed,Object? releaseNote = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appIcon: freezed == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String?,appDesc: freezed == appDesc ? _self.appDesc : appDesc // ignore: cast_nullable_to_non_nullable
as String?,appKind: freezed == appKind ? _self.appKind : appKind // ignore: cast_nullable_to_non_nullable
as String?,appRuntime: freezed == appRuntime ? _self.appRuntime : appRuntime // ignore: cast_nullable_to_non_nullable
as String?,appModule: freezed == appModule ? _self.appModule : appModule // ignore: cast_nullable_to_non_nullable
as String?,appBase: freezed == appBase ? _self.appBase : appBase // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,screenshotList: freezed == screenshotList ? _self.screenshotList : screenshotList // ignore: cast_nullable_to_non_nullable
as List<AppScreenshotDTO>?,tagList: freezed == tagList ? _self.tagList : tagList // ignore: cast_nullable_to_non_nullable
as List<AppTagDTO>?,detailDescription: freezed == detailDescription ? _self.detailDescription : detailDescription // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repoUrl: freezed == repoUrl ? _self.repoUrl : repoUrl // ignore: cast_nullable_to_non_nullable
as String?,homePage: freezed == homePage ? _self.homePage : homePage // ignore: cast_nullable_to_non_nullable
as String?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailDTO].
extension AppDetailDTOPatterns on AppDetailDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'zhName')  String appName, @JsonKey(name: 'version')  String appVersion, @JsonKey(name: 'icon')  String? appIcon, @JsonKey(name: 'description')  String? appDesc, @JsonKey(name: 'kind')  String? appKind, @JsonKey(name: 'runtime')  String? appRuntime, @JsonKey(name: 'module')  String? appModule, @JsonKey(name: 'base')  String? appBase,  String? arch,  String? channel, @JsonKey(name: 'devName')  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(name: 'categoryId')  String? categoryId, @JsonKey(name: 'installCount')  int? downloadTimes, @JsonKey(name: 'size')  String? packageSize, @JsonKey(name: 'appScreenshotList')  List<AppScreenshotDTO>? screenshotList, @JsonKey(name: 'appTagList')  List<AppTagDTO>? tagList, @JsonKey(name: 'descInfo')  String? detailDescription, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'repoUrl')  String? repoUrl, @JsonKey(name: 'homePage')  String? homePage, @JsonKey(name: 'license')  String? license, @JsonKey(name: 'releaseNote')  String? releaseNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.appRuntime,_that.appModule,_that.appBase,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshotList,_that.tagList,_that.detailDescription,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'zhName')  String appName, @JsonKey(name: 'version')  String appVersion, @JsonKey(name: 'icon')  String? appIcon, @JsonKey(name: 'description')  String? appDesc, @JsonKey(name: 'kind')  String? appKind, @JsonKey(name: 'runtime')  String? appRuntime, @JsonKey(name: 'module')  String? appModule, @JsonKey(name: 'base')  String? appBase,  String? arch,  String? channel, @JsonKey(name: 'devName')  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(name: 'categoryId')  String? categoryId, @JsonKey(name: 'installCount')  int? downloadTimes, @JsonKey(name: 'size')  String? packageSize, @JsonKey(name: 'appScreenshotList')  List<AppScreenshotDTO>? screenshotList, @JsonKey(name: 'appTagList')  List<AppTagDTO>? tagList, @JsonKey(name: 'descInfo')  String? detailDescription, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'repoUrl')  String? repoUrl, @JsonKey(name: 'homePage')  String? homePage, @JsonKey(name: 'license')  String? license, @JsonKey(name: 'releaseNote')  String? releaseNote)  $default,) {final _that = this;
switch (_that) {
case _AppDetailDTO():
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.appRuntime,_that.appModule,_that.appBase,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshotList,_that.tagList,_that.detailDescription,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'zhName')  String appName, @JsonKey(name: 'version')  String appVersion, @JsonKey(name: 'icon')  String? appIcon, @JsonKey(name: 'description')  String? appDesc, @JsonKey(name: 'kind')  String? appKind, @JsonKey(name: 'runtime')  String? appRuntime, @JsonKey(name: 'module')  String? appModule, @JsonKey(name: 'base')  String? appBase,  String? arch,  String? channel, @JsonKey(name: 'devName')  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(name: 'categoryId')  String? categoryId, @JsonKey(name: 'installCount')  int? downloadTimes, @JsonKey(name: 'size')  String? packageSize, @JsonKey(name: 'appScreenshotList')  List<AppScreenshotDTO>? screenshotList, @JsonKey(name: 'appTagList')  List<AppTagDTO>? tagList, @JsonKey(name: 'descInfo')  String? detailDescription, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'repoUrl')  String? repoUrl, @JsonKey(name: 'homePage')  String? homePage, @JsonKey(name: 'license')  String? license, @JsonKey(name: 'releaseNote')  String? releaseNote)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.appRuntime,_that.appModule,_that.appBase,_that.arch,_that.channel,_that.developerName,_that.categoryName,_that.categoryId,_that.downloadTimes,_that.packageSize,_that.screenshotList,_that.tagList,_that.detailDescription,_that.repoName,_that.repoUrl,_that.homePage,_that.license,_that.releaseNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailDTO implements AppDetailDTO {
  const _AppDetailDTO({@JsonKey(name: 'appId') required this.appId, @JsonKey(name: 'zhName') required this.appName, @JsonKey(name: 'version') required this.appVersion, @JsonKey(name: 'icon') this.appIcon, @JsonKey(name: 'description') this.appDesc, @JsonKey(name: 'kind') this.appKind, @JsonKey(name: 'runtime') this.appRuntime, @JsonKey(name: 'module') this.appModule, @JsonKey(name: 'base') this.appBase, this.arch, this.channel, @JsonKey(name: 'devName') this.developerName, @JsonKey(name: 'categoryName') this.categoryName, @JsonKey(name: 'categoryId') this.categoryId, @JsonKey(name: 'installCount') this.downloadTimes, @JsonKey(name: 'size') this.packageSize, @JsonKey(name: 'appScreenshotList') final  List<AppScreenshotDTO>? screenshotList, @JsonKey(name: 'appTagList') final  List<AppTagDTO>? tagList, @JsonKey(name: 'descInfo') this.detailDescription, @JsonKey(name: 'repoName') this.repoName, @JsonKey(name: 'repoUrl') this.repoUrl, @JsonKey(name: 'homePage') this.homePage, @JsonKey(name: 'license') this.license, @JsonKey(name: 'releaseNote') this.releaseNote}): _screenshotList = screenshotList,_tagList = tagList;
  factory _AppDetailDTO.fromJson(Map<String, dynamic> json) => _$AppDetailDTOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(name: 'zhName') final  String appName;
@override@JsonKey(name: 'version') final  String appVersion;
@override@JsonKey(name: 'icon') final  String? appIcon;
@override@JsonKey(name: 'description') final  String? appDesc;
@override@JsonKey(name: 'kind') final  String? appKind;
@override@JsonKey(name: 'runtime') final  String? appRuntime;
@override@JsonKey(name: 'module') final  String? appModule;
@override@JsonKey(name: 'base') final  String? appBase;
@override final  String? arch;
@override final  String? channel;
@override@JsonKey(name: 'devName') final  String? developerName;
@override@JsonKey(name: 'categoryName') final  String? categoryName;
@override@JsonKey(name: 'categoryId') final  String? categoryId;
@override@JsonKey(name: 'installCount') final  int? downloadTimes;
@override@JsonKey(name: 'size') final  String? packageSize;
 final  List<AppScreenshotDTO>? _screenshotList;
@override@JsonKey(name: 'appScreenshotList') List<AppScreenshotDTO>? get screenshotList {
  final value = _screenshotList;
  if (value == null) return null;
  if (_screenshotList is EqualUnmodifiableListView) return _screenshotList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<AppTagDTO>? _tagList;
@override@JsonKey(name: 'appTagList') List<AppTagDTO>? get tagList {
  final value = _tagList;
  if (value == null) return null;
  if (_tagList is EqualUnmodifiableListView) return _tagList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'descInfo') final  String? detailDescription;
@override@JsonKey(name: 'repoName') final  String? repoName;
@override@JsonKey(name: 'repoUrl') final  String? repoUrl;
@override@JsonKey(name: 'homePage') final  String? homePage;
@override@JsonKey(name: 'license') final  String? license;
@override@JsonKey(name: 'releaseNote') final  String? releaseNote;

/// Create a copy of AppDetailDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailDTOCopyWith<_AppDetailDTO> get copyWith => __$AppDetailDTOCopyWithImpl<_AppDetailDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.appDesc, appDesc) || other.appDesc == appDesc)&&(identical(other.appKind, appKind) || other.appKind == appKind)&&(identical(other.appRuntime, appRuntime) || other.appRuntime == appRuntime)&&(identical(other.appModule, appModule) || other.appModule == appModule)&&(identical(other.appBase, appBase) || other.appBase == appBase)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&const DeepCollectionEquality().equals(other._screenshotList, _screenshotList)&&const DeepCollectionEquality().equals(other._tagList, _tagList)&&(identical(other.detailDescription, detailDescription) || other.detailDescription == detailDescription)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.repoUrl, repoUrl) || other.repoUrl == repoUrl)&&(identical(other.homePage, homePage) || other.homePage == homePage)&&(identical(other.license, license) || other.license == license)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,appId,appName,appVersion,appIcon,appDesc,appKind,appRuntime,appModule,appBase,arch,channel,developerName,categoryName,categoryId,downloadTimes,packageSize,const DeepCollectionEquality().hash(_screenshotList),const DeepCollectionEquality().hash(_tagList),detailDescription,repoName,repoUrl,homePage,license,releaseNote]);

@override
String toString() {
  return 'AppDetailDTO(appId: $appId, appName: $appName, appVersion: $appVersion, appIcon: $appIcon, appDesc: $appDesc, appKind: $appKind, appRuntime: $appRuntime, appModule: $appModule, appBase: $appBase, arch: $arch, channel: $channel, developerName: $developerName, categoryName: $categoryName, categoryId: $categoryId, downloadTimes: $downloadTimes, packageSize: $packageSize, screenshotList: $screenshotList, tagList: $tagList, detailDescription: $detailDescription, repoName: $repoName, repoUrl: $repoUrl, homePage: $homePage, license: $license, releaseNote: $releaseNote)';
}


}

/// @nodoc
abstract mixin class _$AppDetailDTOCopyWith<$Res> implements $AppDetailDTOCopyWith<$Res> {
  factory _$AppDetailDTOCopyWith(_AppDetailDTO value, $Res Function(_AppDetailDTO) _then) = __$AppDetailDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'zhName') String appName,@JsonKey(name: 'version') String appVersion,@JsonKey(name: 'icon') String? appIcon,@JsonKey(name: 'description') String? appDesc,@JsonKey(name: 'kind') String? appKind,@JsonKey(name: 'runtime') String? appRuntime,@JsonKey(name: 'module') String? appModule,@JsonKey(name: 'base') String? appBase, String? arch, String? channel,@JsonKey(name: 'devName') String? developerName,@JsonKey(name: 'categoryName') String? categoryName,@JsonKey(name: 'categoryId') String? categoryId,@JsonKey(name: 'installCount') int? downloadTimes,@JsonKey(name: 'size') String? packageSize,@JsonKey(name: 'appScreenshotList') List<AppScreenshotDTO>? screenshotList,@JsonKey(name: 'appTagList') List<AppTagDTO>? tagList,@JsonKey(name: 'descInfo') String? detailDescription,@JsonKey(name: 'repoName') String? repoName,@JsonKey(name: 'repoUrl') String? repoUrl,@JsonKey(name: 'homePage') String? homePage,@JsonKey(name: 'license') String? license,@JsonKey(name: 'releaseNote') String? releaseNote
});




}
/// @nodoc
class __$AppDetailDTOCopyWithImpl<$Res>
    implements _$AppDetailDTOCopyWith<$Res> {
  __$AppDetailDTOCopyWithImpl(this._self, this._then);

  final _AppDetailDTO _self;
  final $Res Function(_AppDetailDTO) _then;

/// Create a copy of AppDetailDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? appName = null,Object? appVersion = null,Object? appIcon = freezed,Object? appDesc = freezed,Object? appKind = freezed,Object? appRuntime = freezed,Object? appModule = freezed,Object? appBase = freezed,Object? arch = freezed,Object? channel = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? categoryId = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,Object? screenshotList = freezed,Object? tagList = freezed,Object? detailDescription = freezed,Object? repoName = freezed,Object? repoUrl = freezed,Object? homePage = freezed,Object? license = freezed,Object? releaseNote = freezed,}) {
  return _then(_AppDetailDTO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,appVersion: null == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String,appIcon: freezed == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String?,appDesc: freezed == appDesc ? _self.appDesc : appDesc // ignore: cast_nullable_to_non_nullable
as String?,appKind: freezed == appKind ? _self.appKind : appKind // ignore: cast_nullable_to_non_nullable
as String?,appRuntime: freezed == appRuntime ? _self.appRuntime : appRuntime // ignore: cast_nullable_to_non_nullable
as String?,appModule: freezed == appModule ? _self.appModule : appModule // ignore: cast_nullable_to_non_nullable
as String?,appBase: freezed == appBase ? _self.appBase : appBase // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,screenshotList: freezed == screenshotList ? _self._screenshotList : screenshotList // ignore: cast_nullable_to_non_nullable
as List<AppScreenshotDTO>?,tagList: freezed == tagList ? _self._tagList : tagList // ignore: cast_nullable_to_non_nullable
as List<AppTagDTO>?,detailDescription: freezed == detailDescription ? _self.detailDescription : detailDescription // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repoUrl: freezed == repoUrl ? _self.repoUrl : repoUrl // ignore: cast_nullable_to_non_nullable
as String?,homePage: freezed == homePage ? _self.homePage : homePage // ignore: cast_nullable_to_non_nullable
as String?,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppDetailResponse {

 int get code; String? get message;/// 后端返回 Map<String, List<AppDetailDTO>> 格式
/// 使用 dynamic 以支持自动解析
 Map<String, dynamic>? get data;
/// Create a copy of AppDetailResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailResponseCopyWith<AppDetailResponse> get copyWith => _$AppDetailResponseCopyWithImpl<AppDetailResponse>(this as AppDetailResponse, _$identity);

  /// Serializes this AppDetailResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AppDetailResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppDetailResponseCopyWith<$Res>  {
  factory $AppDetailResponseCopyWith(AppDetailResponse value, $Res Function(AppDetailResponse) _then) = _$AppDetailResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class _$AppDetailResponseCopyWithImpl<$Res>
    implements $AppDetailResponseCopyWith<$Res> {
  _$AppDetailResponseCopyWithImpl(this._self, this._then);

  final AppDetailResponse _self;
  final $Res Function(AppDetailResponse) _then;

/// Create a copy of AppDetailResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailResponse].
extension AppDetailResponsePatterns on AppDetailResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  Map<String, dynamic>? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  Map<String, dynamic>? data)  $default,) {final _that = this;
switch (_that) {
case _AppDetailResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  Map<String, dynamic>? data)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailResponse implements AppDetailResponse {
  const _AppDetailResponse({required this.code, this.message, final  Map<String, dynamic>? data}): _data = data;
  factory _AppDetailResponse.fromJson(Map<String, dynamic> json) => _$AppDetailResponseFromJson(json);

@override final  int code;
@override final  String? message;
/// 后端返回 Map<String, List<AppDetailDTO>> 格式
/// 使用 dynamic 以支持自动解析
 final  Map<String, dynamic>? _data;
/// 后端返回 Map<String, List<AppDetailDTO>> 格式
/// 使用 dynamic 以支持自动解析
@override Map<String, dynamic>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AppDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailResponseCopyWith<_AppDetailResponse> get copyWith => __$AppDetailResponseCopyWithImpl<_AppDetailResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AppDetailResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppDetailResponseCopyWith<$Res> implements $AppDetailResponseCopyWith<$Res> {
  factory _$AppDetailResponseCopyWith(_AppDetailResponse value, $Res Function(_AppDetailResponse) _then) = __$AppDetailResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, Map<String, dynamic>? data
});




}
/// @nodoc
class __$AppDetailResponseCopyWithImpl<$Res>
    implements _$AppDetailResponseCopyWith<$Res> {
  __$AppDetailResponseCopyWithImpl(this._self, this._then);

  final _AppDetailResponse _self;
  final $Res Function(_AppDetailResponse) _then;

/// Create a copy of AppDetailResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_AppDetailResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$AppDetailMapResponse {

 int get code; String? get message; Map<String, List<AppDetailDTO>>? get data;
/// Create a copy of AppDetailMapResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailMapResponseCopyWith<AppDetailMapResponse> get copyWith => _$AppDetailMapResponseCopyWithImpl<AppDetailMapResponse>(this as AppDetailMapResponse, _$identity);

  /// Serializes this AppDetailMapResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailMapResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AppDetailMapResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppDetailMapResponseCopyWith<$Res>  {
  factory $AppDetailMapResponseCopyWith(AppDetailMapResponse value, $Res Function(AppDetailMapResponse) _then) = _$AppDetailMapResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, Map<String, List<AppDetailDTO>>? data
});




}
/// @nodoc
class _$AppDetailMapResponseCopyWithImpl<$Res>
    implements $AppDetailMapResponseCopyWith<$Res> {
  _$AppDetailMapResponseCopyWithImpl(this._self, this._then);

  final AppDetailMapResponse _self;
  final $Res Function(AppDetailMapResponse) _then;

/// Create a copy of AppDetailMapResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, List<AppDetailDTO>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailMapResponse].
extension AppDetailMapResponsePatterns on AppDetailMapResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailMapResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailMapResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailMapResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailMapResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailMapResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailMapResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  Map<String, List<AppDetailDTO>>? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailMapResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  Map<String, List<AppDetailDTO>>? data)  $default,) {final _that = this;
switch (_that) {
case _AppDetailMapResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  Map<String, List<AppDetailDTO>>? data)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailMapResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailMapResponse implements AppDetailMapResponse {
  const _AppDetailMapResponse({required this.code, this.message, final  Map<String, List<AppDetailDTO>>? data}): _data = data;
  factory _AppDetailMapResponse.fromJson(Map<String, dynamic> json) => _$AppDetailMapResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  Map<String, List<AppDetailDTO>>? _data;
@override Map<String, List<AppDetailDTO>>? get data {
  final value = _data;
  if (value == null) return null;
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of AppDetailMapResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailMapResponseCopyWith<_AppDetailMapResponse> get copyWith => __$AppDetailMapResponseCopyWithImpl<_AppDetailMapResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailMapResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailMapResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AppDetailMapResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppDetailMapResponseCopyWith<$Res> implements $AppDetailMapResponseCopyWith<$Res> {
  factory _$AppDetailMapResponseCopyWith(_AppDetailMapResponse value, $Res Function(_AppDetailMapResponse) _then) = __$AppDetailMapResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, Map<String, List<AppDetailDTO>>? data
});




}
/// @nodoc
class __$AppDetailMapResponseCopyWithImpl<$Res>
    implements _$AppDetailMapResponseCopyWith<$Res> {
  __$AppDetailMapResponseCopyWithImpl(this._self, this._then);

  final _AppDetailMapResponse _self;
  final $Res Function(_AppDetailMapResponse) _then;

/// Create a copy of AppDetailMapResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_AppDetailMapResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, List<AppDetailDTO>>?,
  ));
}


}


/// @nodoc
mixin _$AppDetailListResponse {

 int get code; String? get message; List<AppDetailDTO> get data;
/// Create a copy of AppDetailListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppDetailListResponseCopyWith<AppDetailListResponse> get copyWith => _$AppDetailListResponseCopyWithImpl<AppDetailListResponse>(this as AppDetailListResponse, _$identity);

  /// Serializes this AppDetailListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppDetailListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AppDetailListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppDetailListResponseCopyWith<$Res>  {
  factory $AppDetailListResponseCopyWith(AppDetailListResponse value, $Res Function(AppDetailListResponse) _then) = _$AppDetailListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<AppDetailDTO> data
});




}
/// @nodoc
class _$AppDetailListResponseCopyWithImpl<$Res>
    implements $AppDetailListResponseCopyWith<$Res> {
  _$AppDetailListResponseCopyWithImpl(this._self, this._then);

  final AppDetailListResponse _self;
  final $Res Function(AppDetailListResponse) _then;

/// Create a copy of AppDetailListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<AppDetailDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppDetailListResponse].
extension AppDetailListResponsePatterns on AppDetailListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppDetailListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppDetailListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppDetailListResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppDetailListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppDetailListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppDetailListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppDetailDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppDetailListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppDetailDTO> data)  $default,) {final _that = this;
switch (_that) {
case _AppDetailListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<AppDetailDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _AppDetailListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppDetailListResponse implements AppDetailListResponse {
  const _AppDetailListResponse({required this.code, this.message, final  List<AppDetailDTO> data = const []}): _data = data;
  factory _AppDetailListResponse.fromJson(Map<String, dynamic> json) => _$AppDetailListResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<AppDetailDTO> _data;
@override@JsonKey() List<AppDetailDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of AppDetailListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppDetailListResponseCopyWith<_AppDetailListResponse> get copyWith => __$AppDetailListResponseCopyWithImpl<_AppDetailListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppDetailListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppDetailListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AppDetailListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppDetailListResponseCopyWith<$Res> implements $AppDetailListResponseCopyWith<$Res> {
  factory _$AppDetailListResponseCopyWith(_AppDetailListResponse value, $Res Function(_AppDetailListResponse) _then) = __$AppDetailListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<AppDetailDTO> data
});




}
/// @nodoc
class __$AppDetailListResponseCopyWithImpl<$Res>
    implements _$AppDetailListResponseCopyWith<$Res> {
  __$AppDetailListResponseCopyWithImpl(this._self, this._then);

  final _AppDetailListResponse _self;
  final $Res Function(_AppDetailListResponse) _then;

/// Create a copy of AppDetailListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_AppDetailListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AppDetailDTO>,
  ));
}


}


/// @nodoc
mixin _$AppCommentListResponse {

 int get code; String? get message; List<AppCommentDTO> get data;
/// Create a copy of AppCommentListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCommentListResponseCopyWith<AppCommentListResponse> get copyWith => _$AppCommentListResponseCopyWithImpl<AppCommentListResponse>(this as AppCommentListResponse, _$identity);

  /// Serializes this AppCommentListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppCommentListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AppCommentListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppCommentListResponseCopyWith<$Res>  {
  factory $AppCommentListResponseCopyWith(AppCommentListResponse value, $Res Function(AppCommentListResponse) _then) = _$AppCommentListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<AppCommentDTO> data
});




}
/// @nodoc
class _$AppCommentListResponseCopyWithImpl<$Res>
    implements $AppCommentListResponseCopyWith<$Res> {
  _$AppCommentListResponseCopyWithImpl(this._self, this._then);

  final AppCommentListResponse _self;
  final $Res Function(AppCommentListResponse) _then;

/// Create a copy of AppCommentListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<AppCommentDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppCommentListResponse].
extension AppCommentListResponsePatterns on AppCommentListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppCommentListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppCommentListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppCommentListResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppCommentListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppCommentListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppCommentListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppCommentDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppCommentListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppCommentDTO> data)  $default,) {final _that = this;
switch (_that) {
case _AppCommentListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<AppCommentDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _AppCommentListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppCommentListResponse implements AppCommentListResponse {
  const _AppCommentListResponse({required this.code, this.message, final  List<AppCommentDTO> data = const []}): _data = data;
  factory _AppCommentListResponse.fromJson(Map<String, dynamic> json) => _$AppCommentListResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<AppCommentDTO> _data;
@override@JsonKey() List<AppCommentDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of AppCommentListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCommentListResponseCopyWith<_AppCommentListResponse> get copyWith => __$AppCommentListResponseCopyWithImpl<_AppCommentListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppCommentListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppCommentListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AppCommentListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppCommentListResponseCopyWith<$Res> implements $AppCommentListResponseCopyWith<$Res> {
  factory _$AppCommentListResponseCopyWith(_AppCommentListResponse value, $Res Function(_AppCommentListResponse) _then) = __$AppCommentListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<AppCommentDTO> data
});




}
/// @nodoc
class __$AppCommentListResponseCopyWithImpl<$Res>
    implements _$AppCommentListResponseCopyWith<$Res> {
  __$AppCommentListResponseCopyWithImpl(this._self, this._then);

  final _AppCommentListResponse _self;
  final $Res Function(_AppCommentListResponse) _then;

/// Create a copy of AppCommentListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_AppCommentListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AppCommentDTO>,
  ));
}


}


/// @nodoc
mixin _$BooleanResponse {

 int get code; String? get message; bool? get data;
/// Create a copy of BooleanResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BooleanResponseCopyWith<BooleanResponse> get copyWith => _$BooleanResponseCopyWithImpl<BooleanResponse>(this as BooleanResponse, _$identity);

  /// Serializes this BooleanResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BooleanResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'BooleanResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $BooleanResponseCopyWith<$Res>  {
  factory $BooleanResponseCopyWith(BooleanResponse value, $Res Function(BooleanResponse) _then) = _$BooleanResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, bool? data
});




}
/// @nodoc
class _$BooleanResponseCopyWithImpl<$Res>
    implements $BooleanResponseCopyWith<$Res> {
  _$BooleanResponseCopyWithImpl(this._self, this._then);

  final BooleanResponse _self;
  final $Res Function(BooleanResponse) _then;

/// Create a copy of BooleanResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [BooleanResponse].
extension BooleanResponsePatterns on BooleanResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BooleanResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BooleanResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BooleanResponse value)  $default,){
final _that = this;
switch (_that) {
case _BooleanResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BooleanResponse value)?  $default,){
final _that = this;
switch (_that) {
case _BooleanResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  bool? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BooleanResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  bool? data)  $default,) {final _that = this;
switch (_that) {
case _BooleanResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  bool? data)?  $default,) {final _that = this;
switch (_that) {
case _BooleanResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BooleanResponse implements BooleanResponse {
  const _BooleanResponse({required this.code, this.message, this.data});
  factory _BooleanResponse.fromJson(Map<String, dynamic> json) => _$BooleanResponseFromJson(json);

@override final  int code;
@override final  String? message;
@override final  bool? data;

/// Create a copy of BooleanResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BooleanResponseCopyWith<_BooleanResponse> get copyWith => __$BooleanResponseCopyWithImpl<_BooleanResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BooleanResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BooleanResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'BooleanResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BooleanResponseCopyWith<$Res> implements $BooleanResponseCopyWith<$Res> {
  factory _$BooleanResponseCopyWith(_BooleanResponse value, $Res Function(_BooleanResponse) _then) = __$BooleanResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, bool? data
});




}
/// @nodoc
class __$BooleanResponseCopyWithImpl<$Res>
    implements _$BooleanResponseCopyWith<$Res> {
  __$BooleanResponseCopyWithImpl(this._self, this._then);

  final _BooleanResponse _self;
  final $Res Function(_BooleanResponse) _then;

/// Create a copy of BooleanResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_BooleanResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$AppListItemDTO {

@JsonKey(name: 'appId') String get appId;@JsonKey(readValue: _readAppName) String get appName;@JsonKey(readValue: _readAppVersion) String? get appVersion;@JsonKey(readValue: _readAppIcon) String? get appIcon;@JsonKey(readValue: _readAppDescription) String? get appDesc;@JsonKey(readValue: _readAppKind) String? get appKind;@JsonKey(readValue: _readDeveloperName) String? get developerName;@JsonKey(name: 'categoryName') String? get categoryName;@JsonKey(readValue: _readDownloadCount) int? get downloadTimes;@JsonKey(readValue: _readPackageSize) String? get packageSize;
/// Create a copy of AppListItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppListItemDTOCopyWith<AppListItemDTO> get copyWith => _$AppListItemDTOCopyWithImpl<AppListItemDTO>(this as AppListItemDTO, _$identity);

  /// Serializes this AppListItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppListItemDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.appDesc, appDesc) || other.appDesc == appDesc)&&(identical(other.appKind, appKind) || other.appKind == appKind)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,appName,appVersion,appIcon,appDesc,appKind,developerName,categoryName,downloadTimes,packageSize);

@override
String toString() {
  return 'AppListItemDTO(appId: $appId, appName: $appName, appVersion: $appVersion, appIcon: $appIcon, appDesc: $appDesc, appKind: $appKind, developerName: $developerName, categoryName: $categoryName, downloadTimes: $downloadTimes, packageSize: $packageSize)';
}


}

/// @nodoc
abstract mixin class $AppListItemDTOCopyWith<$Res>  {
  factory $AppListItemDTOCopyWith(AppListItemDTO value, $Res Function(AppListItemDTO) _then) = _$AppListItemDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(readValue: _readAppName) String appName,@JsonKey(readValue: _readAppVersion) String? appVersion,@JsonKey(readValue: _readAppIcon) String? appIcon,@JsonKey(readValue: _readAppDescription) String? appDesc,@JsonKey(readValue: _readAppKind) String? appKind,@JsonKey(readValue: _readDeveloperName) String? developerName,@JsonKey(name: 'categoryName') String? categoryName,@JsonKey(readValue: _readDownloadCount) int? downloadTimes,@JsonKey(readValue: _readPackageSize) String? packageSize
});




}
/// @nodoc
class _$AppListItemDTOCopyWithImpl<$Res>
    implements $AppListItemDTOCopyWith<$Res> {
  _$AppListItemDTOCopyWithImpl(this._self, this._then);

  final AppListItemDTO _self;
  final $Res Function(AppListItemDTO) _then;

/// Create a copy of AppListItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? appName = null,Object? appVersion = freezed,Object? appIcon = freezed,Object? appDesc = freezed,Object? appKind = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,appIcon: freezed == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String?,appDesc: freezed == appDesc ? _self.appDesc : appDesc // ignore: cast_nullable_to_non_nullable
as String?,appKind: freezed == appKind ? _self.appKind : appKind // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppListItemDTO].
extension AppListItemDTOPatterns on AppListItemDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppListItemDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppListItemDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppListItemDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppListItemDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppListItemDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppListItemDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(readValue: _readAppName)  String appName, @JsonKey(readValue: _readAppVersion)  String? appVersion, @JsonKey(readValue: _readAppIcon)  String? appIcon, @JsonKey(readValue: _readAppDescription)  String? appDesc, @JsonKey(readValue: _readAppKind)  String? appKind, @JsonKey(readValue: _readDeveloperName)  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(readValue: _readDownloadCount)  int? downloadTimes, @JsonKey(readValue: _readPackageSize)  String? packageSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppListItemDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.developerName,_that.categoryName,_that.downloadTimes,_that.packageSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(readValue: _readAppName)  String appName, @JsonKey(readValue: _readAppVersion)  String? appVersion, @JsonKey(readValue: _readAppIcon)  String? appIcon, @JsonKey(readValue: _readAppDescription)  String? appDesc, @JsonKey(readValue: _readAppKind)  String? appKind, @JsonKey(readValue: _readDeveloperName)  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(readValue: _readDownloadCount)  int? downloadTimes, @JsonKey(readValue: _readPackageSize)  String? packageSize)  $default,) {final _that = this;
switch (_that) {
case _AppListItemDTO():
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.developerName,_that.categoryName,_that.downloadTimes,_that.packageSize);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId, @JsonKey(readValue: _readAppName)  String appName, @JsonKey(readValue: _readAppVersion)  String? appVersion, @JsonKey(readValue: _readAppIcon)  String? appIcon, @JsonKey(readValue: _readAppDescription)  String? appDesc, @JsonKey(readValue: _readAppKind)  String? appKind, @JsonKey(readValue: _readDeveloperName)  String? developerName, @JsonKey(name: 'categoryName')  String? categoryName, @JsonKey(readValue: _readDownloadCount)  int? downloadTimes, @JsonKey(readValue: _readPackageSize)  String? packageSize)?  $default,) {final _that = this;
switch (_that) {
case _AppListItemDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.appVersion,_that.appIcon,_that.appDesc,_that.appKind,_that.developerName,_that.categoryName,_that.downloadTimes,_that.packageSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppListItemDTO implements AppListItemDTO {
  const _AppListItemDTO({@JsonKey(name: 'appId') required this.appId, @JsonKey(readValue: _readAppName) required this.appName, @JsonKey(readValue: _readAppVersion) this.appVersion, @JsonKey(readValue: _readAppIcon) this.appIcon, @JsonKey(readValue: _readAppDescription) this.appDesc, @JsonKey(readValue: _readAppKind) this.appKind, @JsonKey(readValue: _readDeveloperName) this.developerName, @JsonKey(name: 'categoryName') this.categoryName, @JsonKey(readValue: _readDownloadCount) this.downloadTimes, @JsonKey(readValue: _readPackageSize) this.packageSize});
  factory _AppListItemDTO.fromJson(Map<String, dynamic> json) => _$AppListItemDTOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(readValue: _readAppName) final  String appName;
@override@JsonKey(readValue: _readAppVersion) final  String? appVersion;
@override@JsonKey(readValue: _readAppIcon) final  String? appIcon;
@override@JsonKey(readValue: _readAppDescription) final  String? appDesc;
@override@JsonKey(readValue: _readAppKind) final  String? appKind;
@override@JsonKey(readValue: _readDeveloperName) final  String? developerName;
@override@JsonKey(name: 'categoryName') final  String? categoryName;
@override@JsonKey(readValue: _readDownloadCount) final  int? downloadTimes;
@override@JsonKey(readValue: _readPackageSize) final  String? packageSize;

/// Create a copy of AppListItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppListItemDTOCopyWith<_AppListItemDTO> get copyWith => __$AppListItemDTOCopyWithImpl<_AppListItemDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppListItemDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppListItemDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion)&&(identical(other.appIcon, appIcon) || other.appIcon == appIcon)&&(identical(other.appDesc, appDesc) || other.appDesc == appDesc)&&(identical(other.appKind, appKind) || other.appKind == appKind)&&(identical(other.developerName, developerName) || other.developerName == developerName)&&(identical(other.categoryName, categoryName) || other.categoryName == categoryName)&&(identical(other.downloadTimes, downloadTimes) || other.downloadTimes == downloadTimes)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,appName,appVersion,appIcon,appDesc,appKind,developerName,categoryName,downloadTimes,packageSize);

@override
String toString() {
  return 'AppListItemDTO(appId: $appId, appName: $appName, appVersion: $appVersion, appIcon: $appIcon, appDesc: $appDesc, appKind: $appKind, developerName: $developerName, categoryName: $categoryName, downloadTimes: $downloadTimes, packageSize: $packageSize)';
}


}

/// @nodoc
abstract mixin class _$AppListItemDTOCopyWith<$Res> implements $AppListItemDTOCopyWith<$Res> {
  factory _$AppListItemDTOCopyWith(_AppListItemDTO value, $Res Function(_AppListItemDTO) _then) = __$AppListItemDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(readValue: _readAppName) String appName,@JsonKey(readValue: _readAppVersion) String? appVersion,@JsonKey(readValue: _readAppIcon) String? appIcon,@JsonKey(readValue: _readAppDescription) String? appDesc,@JsonKey(readValue: _readAppKind) String? appKind,@JsonKey(readValue: _readDeveloperName) String? developerName,@JsonKey(name: 'categoryName') String? categoryName,@JsonKey(readValue: _readDownloadCount) int? downloadTimes,@JsonKey(readValue: _readPackageSize) String? packageSize
});




}
/// @nodoc
class __$AppListItemDTOCopyWithImpl<$Res>
    implements _$AppListItemDTOCopyWith<$Res> {
  __$AppListItemDTOCopyWithImpl(this._self, this._then);

  final _AppListItemDTO _self;
  final $Res Function(_AppListItemDTO) _then;

/// Create a copy of AppListItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? appName = null,Object? appVersion = freezed,Object? appIcon = freezed,Object? appDesc = freezed,Object? appKind = freezed,Object? developerName = freezed,Object? categoryName = freezed,Object? downloadTimes = freezed,Object? packageSize = freezed,}) {
  return _then(_AppListItemDTO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,appIcon: freezed == appIcon ? _self.appIcon : appIcon // ignore: cast_nullable_to_non_nullable
as String?,appDesc: freezed == appDesc ? _self.appDesc : appDesc // ignore: cast_nullable_to_non_nullable
as String?,appKind: freezed == appKind ? _self.appKind : appKind // ignore: cast_nullable_to_non_nullable
as String?,developerName: freezed == developerName ? _self.developerName : developerName // ignore: cast_nullable_to_non_nullable
as String?,categoryName: freezed == categoryName ? _self.categoryName : categoryName // ignore: cast_nullable_to_non_nullable
as String?,downloadTimes: freezed == downloadTimes ? _self.downloadTimes : downloadTimes // ignore: cast_nullable_to_non_nullable
as int?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppListPagedData {

 List<AppListItemDTO> get records; int get total;@JsonKey(name: 'size') int get size;@JsonKey(name: 'current') int get current; int get pages;
/// Create a copy of AppListPagedData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppListPagedDataCopyWith<AppListPagedData> get copyWith => _$AppListPagedDataCopyWithImpl<AppListPagedData>(this as AppListPagedData, _$identity);

  /// Serializes this AppListPagedData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppListPagedData&&const DeepCollectionEquality().equals(other.records, records)&&(identical(other.total, total) || other.total == total)&&(identical(other.size, size) || other.size == size)&&(identical(other.current, current) || other.current == current)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(records),total,size,current,pages);

@override
String toString() {
  return 'AppListPagedData(records: $records, total: $total, size: $size, current: $current, pages: $pages)';
}


}

/// @nodoc
abstract mixin class $AppListPagedDataCopyWith<$Res>  {
  factory $AppListPagedDataCopyWith(AppListPagedData value, $Res Function(AppListPagedData) _then) = _$AppListPagedDataCopyWithImpl;
@useResult
$Res call({
 List<AppListItemDTO> records, int total,@JsonKey(name: 'size') int size,@JsonKey(name: 'current') int current, int pages
});




}
/// @nodoc
class _$AppListPagedDataCopyWithImpl<$Res>
    implements $AppListPagedDataCopyWith<$Res> {
  _$AppListPagedDataCopyWithImpl(this._self, this._then);

  final AppListPagedData _self;
  final $Res Function(AppListPagedData) _then;

/// Create a copy of AppListPagedData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? records = null,Object? total = null,Object? size = null,Object? current = null,Object? pages = null,}) {
  return _then(_self.copyWith(
records: null == records ? _self.records : records // ignore: cast_nullable_to_non_nullable
as List<AppListItemDTO>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AppListPagedData].
extension AppListPagedDataPatterns on AppListPagedData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppListPagedData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppListPagedData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppListPagedData value)  $default,){
final _that = this;
switch (_that) {
case _AppListPagedData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppListPagedData value)?  $default,){
final _that = this;
switch (_that) {
case _AppListPagedData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<AppListItemDTO> records,  int total, @JsonKey(name: 'size')  int size, @JsonKey(name: 'current')  int current,  int pages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppListPagedData() when $default != null:
return $default(_that.records,_that.total,_that.size,_that.current,_that.pages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<AppListItemDTO> records,  int total, @JsonKey(name: 'size')  int size, @JsonKey(name: 'current')  int current,  int pages)  $default,) {final _that = this;
switch (_that) {
case _AppListPagedData():
return $default(_that.records,_that.total,_that.size,_that.current,_that.pages);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<AppListItemDTO> records,  int total, @JsonKey(name: 'size')  int size, @JsonKey(name: 'current')  int current,  int pages)?  $default,) {final _that = this;
switch (_that) {
case _AppListPagedData() when $default != null:
return $default(_that.records,_that.total,_that.size,_that.current,_that.pages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppListPagedData implements AppListPagedData {
  const _AppListPagedData({required final  List<AppListItemDTO> records, required this.total, @JsonKey(name: 'size') required this.size, @JsonKey(name: 'current') required this.current, required this.pages}): _records = records;
  factory _AppListPagedData.fromJson(Map<String, dynamic> json) => _$AppListPagedDataFromJson(json);

 final  List<AppListItemDTO> _records;
@override List<AppListItemDTO> get records {
  if (_records is EqualUnmodifiableListView) return _records;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_records);
}

@override final  int total;
@override@JsonKey(name: 'size') final  int size;
@override@JsonKey(name: 'current') final  int current;
@override final  int pages;

/// Create a copy of AppListPagedData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppListPagedDataCopyWith<_AppListPagedData> get copyWith => __$AppListPagedDataCopyWithImpl<_AppListPagedData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppListPagedDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppListPagedData&&const DeepCollectionEquality().equals(other._records, _records)&&(identical(other.total, total) || other.total == total)&&(identical(other.size, size) || other.size == size)&&(identical(other.current, current) || other.current == current)&&(identical(other.pages, pages) || other.pages == pages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_records),total,size,current,pages);

@override
String toString() {
  return 'AppListPagedData(records: $records, total: $total, size: $size, current: $current, pages: $pages)';
}


}

/// @nodoc
abstract mixin class _$AppListPagedDataCopyWith<$Res> implements $AppListPagedDataCopyWith<$Res> {
  factory _$AppListPagedDataCopyWith(_AppListPagedData value, $Res Function(_AppListPagedData) _then) = __$AppListPagedDataCopyWithImpl;
@override @useResult
$Res call({
 List<AppListItemDTO> records, int total,@JsonKey(name: 'size') int size,@JsonKey(name: 'current') int current, int pages
});




}
/// @nodoc
class __$AppListPagedDataCopyWithImpl<$Res>
    implements _$AppListPagedDataCopyWith<$Res> {
  __$AppListPagedDataCopyWithImpl(this._self, this._then);

  final _AppListPagedData _self;
  final $Res Function(_AppListPagedData) _then;

/// Create a copy of AppListPagedData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? records = null,Object? total = null,Object? size = null,Object? current = null,Object? pages = null,}) {
  return _then(_AppListPagedData(
records: null == records ? _self._records : records // ignore: cast_nullable_to_non_nullable
as List<AppListItemDTO>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as int,pages: null == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$AppListResponse {

 int get code; String? get message; AppListPagedData? get data;
/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppListResponseCopyWith<AppListResponse> get copyWith => _$AppListResponseCopyWithImpl<AppListResponse>(this as AppListResponse, _$identity);

  /// Serializes this AppListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'AppListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppListResponseCopyWith<$Res>  {
  factory $AppListResponseCopyWith(AppListResponse value, $Res Function(AppListResponse) _then) = _$AppListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, AppListPagedData? data
});


$AppListPagedDataCopyWith<$Res>? get data;

}
/// @nodoc
class _$AppListResponseCopyWithImpl<$Res>
    implements $AppListResponseCopyWith<$Res> {
  _$AppListResponseCopyWithImpl(this._self, this._then);

  final AppListResponse _self;
  final $Res Function(AppListResponse) _then;

/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AppListPagedData?,
  ));
}
/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppListPagedDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $AppListPagedDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppListResponse].
extension AppListResponsePatterns on AppListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppListResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  AppListPagedData? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  AppListPagedData? data)  $default,) {final _that = this;
switch (_that) {
case _AppListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  AppListPagedData? data)?  $default,) {final _that = this;
switch (_that) {
case _AppListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppListResponse implements AppListResponse {
  const _AppListResponse({required this.code, this.message, this.data});
  factory _AppListResponse.fromJson(Map<String, dynamic> json) => _$AppListResponseFromJson(json);

@override final  int code;
@override final  String? message;
@override final  AppListPagedData? data;

/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppListResponseCopyWith<_AppListResponse> get copyWith => __$AppListResponseCopyWithImpl<_AppListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'AppListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppListResponseCopyWith<$Res> implements $AppListResponseCopyWith<$Res> {
  factory _$AppListResponseCopyWith(_AppListResponse value, $Res Function(_AppListResponse) _then) = __$AppListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, AppListPagedData? data
});


@override $AppListPagedDataCopyWith<$Res>? get data;

}
/// @nodoc
class __$AppListResponseCopyWithImpl<$Res>
    implements _$AppListResponseCopyWith<$Res> {
  __$AppListResponseCopyWithImpl(this._self, this._then);

  final _AppListResponse _self;
  final $Res Function(_AppListResponse) _then;

/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_AppListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AppListPagedData?,
  ));
}

/// Create a copy of AppListResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppListPagedDataCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $AppListPagedDataCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$AppListArrayResponse {

 int get code; String? get message; List<AppListItemDTO> get data;
/// Create a copy of AppListArrayResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppListArrayResponseCopyWith<AppListArrayResponse> get copyWith => _$AppListArrayResponseCopyWithImpl<AppListArrayResponse>(this as AppListArrayResponse, _$identity);

  /// Serializes this AppListArrayResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppListArrayResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'AppListArrayResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $AppListArrayResponseCopyWith<$Res>  {
  factory $AppListArrayResponseCopyWith(AppListArrayResponse value, $Res Function(AppListArrayResponse) _then) = _$AppListArrayResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<AppListItemDTO> data
});




}
/// @nodoc
class _$AppListArrayResponseCopyWithImpl<$Res>
    implements $AppListArrayResponseCopyWith<$Res> {
  _$AppListArrayResponseCopyWithImpl(this._self, this._then);

  final AppListArrayResponse _self;
  final $Res Function(AppListArrayResponse) _then;

/// Create a copy of AppListArrayResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<AppListItemDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppListArrayResponse].
extension AppListArrayResponsePatterns on AppListArrayResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppListArrayResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppListArrayResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppListArrayResponse value)  $default,){
final _that = this;
switch (_that) {
case _AppListArrayResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppListArrayResponse value)?  $default,){
final _that = this;
switch (_that) {
case _AppListArrayResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppListItemDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppListArrayResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppListItemDTO> data)  $default,) {final _that = this;
switch (_that) {
case _AppListArrayResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<AppListItemDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _AppListArrayResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppListArrayResponse implements AppListArrayResponse {
  const _AppListArrayResponse({required this.code, this.message, final  List<AppListItemDTO> data = const []}): _data = data;
  factory _AppListArrayResponse.fromJson(Map<String, dynamic> json) => _$AppListArrayResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<AppListItemDTO> _data;
@override@JsonKey() List<AppListItemDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of AppListArrayResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppListArrayResponseCopyWith<_AppListArrayResponse> get copyWith => __$AppListArrayResponseCopyWithImpl<_AppListArrayResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppListArrayResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppListArrayResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'AppListArrayResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$AppListArrayResponseCopyWith<$Res> implements $AppListArrayResponseCopyWith<$Res> {
  factory _$AppListArrayResponseCopyWith(_AppListArrayResponse value, $Res Function(_AppListArrayResponse) _then) = __$AppListArrayResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<AppListItemDTO> data
});




}
/// @nodoc
class __$AppListArrayResponseCopyWithImpl<$Res>
    implements _$AppListArrayResponseCopyWith<$Res> {
  __$AppListArrayResponseCopyWithImpl(this._self, this._then);

  final _AppListArrayResponse _self;
  final $Res Function(_AppListArrayResponse) _then;

/// Create a copy of AppListArrayResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_AppListArrayResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AppListItemDTO>,
  ));
}


}


/// @nodoc
mixin _$SearchAppListRequest {

/// 搜索关键词，后端字段名为 `name`
@JsonKey(name: 'name') String get keyword;@JsonKey(name: 'pageNo') int get pageNo;@JsonKey(name: 'pageSize') int get pageSize;@JsonKey(name: 'repoName') String get repoName; String? get arch; String? get lan; String? get sort; String? get order;
/// Create a copy of SearchAppListRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchAppListRequestCopyWith<SearchAppListRequest> get copyWith => _$SearchAppListRequestCopyWithImpl<SearchAppListRequest>(this as SearchAppListRequest, _$identity);

  /// Serializes this SearchAppListRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchAppListRequest&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyword,pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'SearchAppListRequest(keyword: $keyword, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class $SearchAppListRequestCopyWith<$Res>  {
  factory $SearchAppListRequestCopyWith(SearchAppListRequest value, $Res Function(SearchAppListRequest) _then) = _$SearchAppListRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'name') String keyword,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class _$SearchAppListRequestCopyWithImpl<$Res>
    implements $SearchAppListRequestCopyWith<$Res> {
  _$SearchAppListRequestCopyWithImpl(this._self, this._then);

  final SearchAppListRequest _self;
  final $Res Function(SearchAppListRequest) _then;

/// Create a copy of SearchAppListRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyword = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_self.copyWith(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchAppListRequest].
extension SearchAppListRequestPatterns on SearchAppListRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchAppListRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchAppListRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchAppListRequest value)  $default,){
final _that = this;
switch (_that) {
case _SearchAppListRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchAppListRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SearchAppListRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String keyword, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchAppListRequest() when $default != null:
return $default(_that.keyword,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'name')  String keyword, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)  $default,) {final _that = this;
switch (_that) {
case _SearchAppListRequest():
return $default(_that.keyword,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'name')  String keyword, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,) {final _that = this;
switch (_that) {
case _SearchAppListRequest() when $default != null:
return $default(_that.keyword,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchAppListRequest implements SearchAppListRequest {
  const _SearchAppListRequest({@JsonKey(name: 'name') required this.keyword, @JsonKey(name: 'pageNo') this.pageNo = 1, @JsonKey(name: 'pageSize') this.pageSize = 20, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, this.lan, this.sort, this.order});
  factory _SearchAppListRequest.fromJson(Map<String, dynamic> json) => _$SearchAppListRequestFromJson(json);

/// 搜索关键词，后端字段名为 `name`
@override@JsonKey(name: 'name') final  String keyword;
@override@JsonKey(name: 'pageNo') final  int pageNo;
@override@JsonKey(name: 'pageSize') final  int pageSize;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override final  String? lan;
@override final  String? sort;
@override final  String? order;

/// Create a copy of SearchAppListRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchAppListRequestCopyWith<_SearchAppListRequest> get copyWith => __$SearchAppListRequestCopyWithImpl<_SearchAppListRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchAppListRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchAppListRequest&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyword,pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'SearchAppListRequest(keyword: $keyword, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class _$SearchAppListRequestCopyWith<$Res> implements $SearchAppListRequestCopyWith<$Res> {
  factory _$SearchAppListRequestCopyWith(_SearchAppListRequest value, $Res Function(_SearchAppListRequest) _then) = __$SearchAppListRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'name') String keyword,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class __$SearchAppListRequestCopyWithImpl<$Res>
    implements _$SearchAppListRequestCopyWith<$Res> {
  __$SearchAppListRequestCopyWithImpl(this._self, this._then);

  final _SearchAppListRequest _self;
  final $Res Function(_SearchAppListRequest) _then;

/// Create a copy of SearchAppListRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyword = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_SearchAppListRequest(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppWelcomeSearchRequest {

 String? get appId; String? get name;@JsonKey(name: 'repoName') String get repoName; String? get arch; String? get lan; String? get categoryId;@JsonKey(name: 'pageNo') int? get pageNo;@JsonKey(name: 'pageSize') int? get pageSize;
/// Create a copy of AppWelcomeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppWelcomeSearchRequestCopyWith<AppWelcomeSearchRequest> get copyWith => _$AppWelcomeSearchRequestCopyWithImpl<AppWelcomeSearchRequest>(this as AppWelcomeSearchRequest, _$identity);

  /// Serializes this AppWelcomeSearchRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppWelcomeSearchRequest&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,repoName,arch,lan,categoryId,pageNo,pageSize);

@override
String toString() {
  return 'AppWelcomeSearchRequest(appId: $appId, name: $name, repoName: $repoName, arch: $arch, lan: $lan, categoryId: $categoryId, pageNo: $pageNo, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class $AppWelcomeSearchRequestCopyWith<$Res>  {
  factory $AppWelcomeSearchRequestCopyWith(AppWelcomeSearchRequest value, $Res Function(AppWelcomeSearchRequest) _then) = _$AppWelcomeSearchRequestCopyWithImpl;
@useResult
$Res call({
 String? appId, String? name,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? categoryId,@JsonKey(name: 'pageNo') int? pageNo,@JsonKey(name: 'pageSize') int? pageSize
});




}
/// @nodoc
class _$AppWelcomeSearchRequestCopyWithImpl<$Res>
    implements $AppWelcomeSearchRequestCopyWith<$Res> {
  _$AppWelcomeSearchRequestCopyWithImpl(this._self, this._then);

  final AppWelcomeSearchRequest _self;
  final $Res Function(AppWelcomeSearchRequest) _then;

/// Create a copy of AppWelcomeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = freezed,Object? name = freezed,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? categoryId = freezed,Object? pageNo = freezed,Object? pageSize = freezed,}) {
  return _then(_self.copyWith(
appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,pageNo: freezed == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int?,pageSize: freezed == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppWelcomeSearchRequest].
extension AppWelcomeSearchRequestPatterns on AppWelcomeSearchRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppWelcomeSearchRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppWelcomeSearchRequest value)  $default,){
final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppWelcomeSearchRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? appId,  String? name, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? categoryId, @JsonKey(name: 'pageNo')  int? pageNo, @JsonKey(name: 'pageSize')  int? pageSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest() when $default != null:
return $default(_that.appId,_that.name,_that.repoName,_that.arch,_that.lan,_that.categoryId,_that.pageNo,_that.pageSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? appId,  String? name, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? categoryId, @JsonKey(name: 'pageNo')  int? pageNo, @JsonKey(name: 'pageSize')  int? pageSize)  $default,) {final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest():
return $default(_that.appId,_that.name,_that.repoName,_that.arch,_that.lan,_that.categoryId,_that.pageNo,_that.pageSize);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? appId,  String? name, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? categoryId, @JsonKey(name: 'pageNo')  int? pageNo, @JsonKey(name: 'pageSize')  int? pageSize)?  $default,) {final _that = this;
switch (_that) {
case _AppWelcomeSearchRequest() when $default != null:
return $default(_that.appId,_that.name,_that.repoName,_that.arch,_that.lan,_that.categoryId,_that.pageNo,_that.pageSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppWelcomeSearchRequest implements AppWelcomeSearchRequest {
  const _AppWelcomeSearchRequest({this.appId, this.name, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, this.lan, this.categoryId, @JsonKey(name: 'pageNo') this.pageNo, @JsonKey(name: 'pageSize') this.pageSize});
  factory _AppWelcomeSearchRequest.fromJson(Map<String, dynamic> json) => _$AppWelcomeSearchRequestFromJson(json);

@override final  String? appId;
@override final  String? name;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override final  String? lan;
@override final  String? categoryId;
@override@JsonKey(name: 'pageNo') final  int? pageNo;
@override@JsonKey(name: 'pageSize') final  int? pageSize;

/// Create a copy of AppWelcomeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppWelcomeSearchRequestCopyWith<_AppWelcomeSearchRequest> get copyWith => __$AppWelcomeSearchRequestCopyWithImpl<_AppWelcomeSearchRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppWelcomeSearchRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppWelcomeSearchRequest&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,repoName,arch,lan,categoryId,pageNo,pageSize);

@override
String toString() {
  return 'AppWelcomeSearchRequest(appId: $appId, name: $name, repoName: $repoName, arch: $arch, lan: $lan, categoryId: $categoryId, pageNo: $pageNo, pageSize: $pageSize)';
}


}

/// @nodoc
abstract mixin class _$AppWelcomeSearchRequestCopyWith<$Res> implements $AppWelcomeSearchRequestCopyWith<$Res> {
  factory _$AppWelcomeSearchRequestCopyWith(_AppWelcomeSearchRequest value, $Res Function(_AppWelcomeSearchRequest) _then) = __$AppWelcomeSearchRequestCopyWithImpl;
@override @useResult
$Res call({
 String? appId, String? name,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? categoryId,@JsonKey(name: 'pageNo') int? pageNo,@JsonKey(name: 'pageSize') int? pageSize
});




}
/// @nodoc
class __$AppWelcomeSearchRequestCopyWithImpl<$Res>
    implements _$AppWelcomeSearchRequestCopyWith<$Res> {
  __$AppWelcomeSearchRequestCopyWithImpl(this._self, this._then);

  final _AppWelcomeSearchRequest _self;
  final $Res Function(_AppWelcomeSearchRequest) _then;

/// Create a copy of AppWelcomeSearchRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = freezed,Object? name = freezed,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? categoryId = freezed,Object? pageNo = freezed,Object? pageSize = freezed,}) {
  return _then(_AppWelcomeSearchRequest(
appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,pageNo: freezed == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int?,pageSize: freezed == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CarouselDTO {

@JsonKey(readValue: _readBannerId) String get carouselId;@JsonKey(readValue: _readBannerTitle) String get carouselTitle;@JsonKey(readValue: _readBannerTargetUrl) String? get carouselUrl;@JsonKey(readValue: _readBannerImage) String get carouselImage;@JsonKey(readValue: _readBannerDescription) String? get carouselDesc;@JsonKey(name: 'sort') int? get sort;
/// Create a copy of CarouselDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CarouselDTOCopyWith<CarouselDTO> get copyWith => _$CarouselDTOCopyWithImpl<CarouselDTO>(this as CarouselDTO, _$identity);

  /// Serializes this CarouselDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CarouselDTO&&(identical(other.carouselId, carouselId) || other.carouselId == carouselId)&&(identical(other.carouselTitle, carouselTitle) || other.carouselTitle == carouselTitle)&&(identical(other.carouselUrl, carouselUrl) || other.carouselUrl == carouselUrl)&&(identical(other.carouselImage, carouselImage) || other.carouselImage == carouselImage)&&(identical(other.carouselDesc, carouselDesc) || other.carouselDesc == carouselDesc)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,carouselId,carouselTitle,carouselUrl,carouselImage,carouselDesc,sort);

@override
String toString() {
  return 'CarouselDTO(carouselId: $carouselId, carouselTitle: $carouselTitle, carouselUrl: $carouselUrl, carouselImage: $carouselImage, carouselDesc: $carouselDesc, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $CarouselDTOCopyWith<$Res>  {
  factory $CarouselDTOCopyWith(CarouselDTO value, $Res Function(CarouselDTO) _then) = _$CarouselDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: _readBannerId) String carouselId,@JsonKey(readValue: _readBannerTitle) String carouselTitle,@JsonKey(readValue: _readBannerTargetUrl) String? carouselUrl,@JsonKey(readValue: _readBannerImage) String carouselImage,@JsonKey(readValue: _readBannerDescription) String? carouselDesc,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class _$CarouselDTOCopyWithImpl<$Res>
    implements $CarouselDTOCopyWith<$Res> {
  _$CarouselDTOCopyWithImpl(this._self, this._then);

  final CarouselDTO _self;
  final $Res Function(CarouselDTO) _then;

/// Create a copy of CarouselDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? carouselId = null,Object? carouselTitle = null,Object? carouselUrl = freezed,Object? carouselImage = null,Object? carouselDesc = freezed,Object? sort = freezed,}) {
  return _then(_self.copyWith(
carouselId: null == carouselId ? _self.carouselId : carouselId // ignore: cast_nullable_to_non_nullable
as String,carouselTitle: null == carouselTitle ? _self.carouselTitle : carouselTitle // ignore: cast_nullable_to_non_nullable
as String,carouselUrl: freezed == carouselUrl ? _self.carouselUrl : carouselUrl // ignore: cast_nullable_to_non_nullable
as String?,carouselImage: null == carouselImage ? _self.carouselImage : carouselImage // ignore: cast_nullable_to_non_nullable
as String,carouselDesc: freezed == carouselDesc ? _self.carouselDesc : carouselDesc // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CarouselDTO].
extension CarouselDTOPatterns on CarouselDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CarouselDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CarouselDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CarouselDTO value)  $default,){
final _that = this;
switch (_that) {
case _CarouselDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CarouselDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CarouselDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readBannerId)  String carouselId, @JsonKey(readValue: _readBannerTitle)  String carouselTitle, @JsonKey(readValue: _readBannerTargetUrl)  String? carouselUrl, @JsonKey(readValue: _readBannerImage)  String carouselImage, @JsonKey(readValue: _readBannerDescription)  String? carouselDesc, @JsonKey(name: 'sort')  int? sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CarouselDTO() when $default != null:
return $default(_that.carouselId,_that.carouselTitle,_that.carouselUrl,_that.carouselImage,_that.carouselDesc,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: _readBannerId)  String carouselId, @JsonKey(readValue: _readBannerTitle)  String carouselTitle, @JsonKey(readValue: _readBannerTargetUrl)  String? carouselUrl, @JsonKey(readValue: _readBannerImage)  String carouselImage, @JsonKey(readValue: _readBannerDescription)  String? carouselDesc, @JsonKey(name: 'sort')  int? sort)  $default,) {final _that = this;
switch (_that) {
case _CarouselDTO():
return $default(_that.carouselId,_that.carouselTitle,_that.carouselUrl,_that.carouselImage,_that.carouselDesc,_that.sort);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: _readBannerId)  String carouselId, @JsonKey(readValue: _readBannerTitle)  String carouselTitle, @JsonKey(readValue: _readBannerTargetUrl)  String? carouselUrl, @JsonKey(readValue: _readBannerImage)  String carouselImage, @JsonKey(readValue: _readBannerDescription)  String? carouselDesc, @JsonKey(name: 'sort')  int? sort)?  $default,) {final _that = this;
switch (_that) {
case _CarouselDTO() when $default != null:
return $default(_that.carouselId,_that.carouselTitle,_that.carouselUrl,_that.carouselImage,_that.carouselDesc,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CarouselDTO implements CarouselDTO {
  const _CarouselDTO({@JsonKey(readValue: _readBannerId) required this.carouselId, @JsonKey(readValue: _readBannerTitle) required this.carouselTitle, @JsonKey(readValue: _readBannerTargetUrl) this.carouselUrl, @JsonKey(readValue: _readBannerImage) required this.carouselImage, @JsonKey(readValue: _readBannerDescription) this.carouselDesc, @JsonKey(name: 'sort') this.sort});
  factory _CarouselDTO.fromJson(Map<String, dynamic> json) => _$CarouselDTOFromJson(json);

@override@JsonKey(readValue: _readBannerId) final  String carouselId;
@override@JsonKey(readValue: _readBannerTitle) final  String carouselTitle;
@override@JsonKey(readValue: _readBannerTargetUrl) final  String? carouselUrl;
@override@JsonKey(readValue: _readBannerImage) final  String carouselImage;
@override@JsonKey(readValue: _readBannerDescription) final  String? carouselDesc;
@override@JsonKey(name: 'sort') final  int? sort;

/// Create a copy of CarouselDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CarouselDTOCopyWith<_CarouselDTO> get copyWith => __$CarouselDTOCopyWithImpl<_CarouselDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CarouselDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CarouselDTO&&(identical(other.carouselId, carouselId) || other.carouselId == carouselId)&&(identical(other.carouselTitle, carouselTitle) || other.carouselTitle == carouselTitle)&&(identical(other.carouselUrl, carouselUrl) || other.carouselUrl == carouselUrl)&&(identical(other.carouselImage, carouselImage) || other.carouselImage == carouselImage)&&(identical(other.carouselDesc, carouselDesc) || other.carouselDesc == carouselDesc)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,carouselId,carouselTitle,carouselUrl,carouselImage,carouselDesc,sort);

@override
String toString() {
  return 'CarouselDTO(carouselId: $carouselId, carouselTitle: $carouselTitle, carouselUrl: $carouselUrl, carouselImage: $carouselImage, carouselDesc: $carouselDesc, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$CarouselDTOCopyWith<$Res> implements $CarouselDTOCopyWith<$Res> {
  factory _$CarouselDTOCopyWith(_CarouselDTO value, $Res Function(_CarouselDTO) _then) = __$CarouselDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: _readBannerId) String carouselId,@JsonKey(readValue: _readBannerTitle) String carouselTitle,@JsonKey(readValue: _readBannerTargetUrl) String? carouselUrl,@JsonKey(readValue: _readBannerImage) String carouselImage,@JsonKey(readValue: _readBannerDescription) String? carouselDesc,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class __$CarouselDTOCopyWithImpl<$Res>
    implements _$CarouselDTOCopyWith<$Res> {
  __$CarouselDTOCopyWithImpl(this._self, this._then);

  final _CarouselDTO _self;
  final $Res Function(_CarouselDTO) _then;

/// Create a copy of CarouselDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? carouselId = null,Object? carouselTitle = null,Object? carouselUrl = freezed,Object? carouselImage = null,Object? carouselDesc = freezed,Object? sort = freezed,}) {
  return _then(_CarouselDTO(
carouselId: null == carouselId ? _self.carouselId : carouselId // ignore: cast_nullable_to_non_nullable
as String,carouselTitle: null == carouselTitle ? _self.carouselTitle : carouselTitle // ignore: cast_nullable_to_non_nullable
as String,carouselUrl: freezed == carouselUrl ? _self.carouselUrl : carouselUrl // ignore: cast_nullable_to_non_nullable
as String?,carouselImage: null == carouselImage ? _self.carouselImage : carouselImage // ignore: cast_nullable_to_non_nullable
as String,carouselDesc: freezed == carouselDesc ? _self.carouselDesc : carouselDesc // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CarouselListResponse {

 int get code; String? get message; List<CarouselDTO> get data;
/// Create a copy of CarouselListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CarouselListResponseCopyWith<CarouselListResponse> get copyWith => _$CarouselListResponseCopyWithImpl<CarouselListResponse>(this as CarouselListResponse, _$identity);

  /// Serializes this CarouselListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CarouselListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'CarouselListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CarouselListResponseCopyWith<$Res>  {
  factory $CarouselListResponseCopyWith(CarouselListResponse value, $Res Function(CarouselListResponse) _then) = _$CarouselListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<CarouselDTO> data
});




}
/// @nodoc
class _$CarouselListResponseCopyWithImpl<$Res>
    implements $CarouselListResponseCopyWith<$Res> {
  _$CarouselListResponseCopyWithImpl(this._self, this._then);

  final CarouselListResponse _self;
  final $Res Function(CarouselListResponse) _then;

/// Create a copy of CarouselListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<CarouselDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [CarouselListResponse].
extension CarouselListResponsePatterns on CarouselListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CarouselListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CarouselListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CarouselListResponse value)  $default,){
final _that = this;
switch (_that) {
case _CarouselListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CarouselListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CarouselListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<CarouselDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CarouselListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<CarouselDTO> data)  $default,) {final _that = this;
switch (_that) {
case _CarouselListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<CarouselDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _CarouselListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CarouselListResponse implements CarouselListResponse {
  const _CarouselListResponse({required this.code, this.message, required final  List<CarouselDTO> data}): _data = data;
  factory _CarouselListResponse.fromJson(Map<String, dynamic> json) => _$CarouselListResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<CarouselDTO> _data;
@override List<CarouselDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of CarouselListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CarouselListResponseCopyWith<_CarouselListResponse> get copyWith => __$CarouselListResponseCopyWithImpl<_CarouselListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CarouselListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CarouselListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'CarouselListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CarouselListResponseCopyWith<$Res> implements $CarouselListResponseCopyWith<$Res> {
  factory _$CarouselListResponseCopyWith(_CarouselListResponse value, $Res Function(_CarouselListResponse) _then) = __$CarouselListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<CarouselDTO> data
});




}
/// @nodoc
class __$CarouselListResponseCopyWithImpl<$Res>
    implements _$CarouselListResponseCopyWith<$Res> {
  __$CarouselListResponseCopyWithImpl(this._self, this._then);

  final _CarouselListResponse _self;
  final $Res Function(_CarouselListResponse) _then;

/// Create a copy of CarouselListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_CarouselListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<CarouselDTO>,
  ));
}


}


/// @nodoc
mixin _$AppVersionListRequest {

@JsonKey(name: 'appId') String get appId;@JsonKey(name: 'repoName') String get repoName; String? get arch;@JsonKey(name: 'pageNo') int get pageNo;@JsonKey(name: 'pageSize') int get pageSize; String? get lan;
/// Create a copy of AppVersionListRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionListRequestCopyWith<AppVersionListRequest> get copyWith => _$AppVersionListRequestCopyWithImpl<AppVersionListRequest>(this as AppVersionListRequest, _$identity);

  /// Serializes this AppVersionListRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionListRequest&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.lan, lan) || other.lan == lan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,repoName,arch,pageNo,pageSize,lan);

@override
String toString() {
  return 'AppVersionListRequest(appId: $appId, repoName: $repoName, arch: $arch, pageNo: $pageNo, pageSize: $pageSize, lan: $lan)';
}


}

/// @nodoc
abstract mixin class $AppVersionListRequestCopyWith<$Res>  {
  factory $AppVersionListRequestCopyWith(AppVersionListRequest value, $Res Function(AppVersionListRequest) _then) = _$AppVersionListRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'repoName') String repoName, String? arch,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize, String? lan
});




}
/// @nodoc
class _$AppVersionListRequestCopyWithImpl<$Res>
    implements $AppVersionListRequestCopyWith<$Res> {
  _$AppVersionListRequestCopyWithImpl(this._self, this._then);

  final AppVersionListRequest _self;
  final $Res Function(AppVersionListRequest) _then;

/// Create a copy of AppVersionListRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? repoName = null,Object? arch = freezed,Object? pageNo = null,Object? pageSize = null,Object? lan = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppVersionListRequest].
extension AppVersionListRequestPatterns on AppVersionListRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionListRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionListRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionListRequest value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionListRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionListRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionListRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'repoName')  String repoName,  String? arch, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize,  String? lan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionListRequest() when $default != null:
return $default(_that.appId,_that.repoName,_that.arch,_that.pageNo,_that.pageSize,_that.lan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'repoName')  String repoName,  String? arch, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize,  String? lan)  $default,) {final _that = this;
switch (_that) {
case _AppVersionListRequest():
return $default(_that.appId,_that.repoName,_that.arch,_that.pageNo,_that.pageSize,_that.lan);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'repoName')  String repoName,  String? arch, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize,  String? lan)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionListRequest() when $default != null:
return $default(_that.appId,_that.repoName,_that.arch,_that.pageNo,_that.pageSize,_that.lan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppVersionListRequest implements AppVersionListRequest {
  const _AppVersionListRequest({@JsonKey(name: 'appId') required this.appId, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, @JsonKey(name: 'pageNo') this.pageNo = 1, @JsonKey(name: 'pageSize') this.pageSize = 20, this.lan});
  factory _AppVersionListRequest.fromJson(Map<String, dynamic> json) => _$AppVersionListRequestFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override@JsonKey(name: 'pageNo') final  int pageNo;
@override@JsonKey(name: 'pageSize') final  int pageSize;
@override final  String? lan;

/// Create a copy of AppVersionListRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionListRequestCopyWith<_AppVersionListRequest> get copyWith => __$AppVersionListRequestCopyWithImpl<_AppVersionListRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppVersionListRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionListRequest&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.lan, lan) || other.lan == lan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,repoName,arch,pageNo,pageSize,lan);

@override
String toString() {
  return 'AppVersionListRequest(appId: $appId, repoName: $repoName, arch: $arch, pageNo: $pageNo, pageSize: $pageSize, lan: $lan)';
}


}

/// @nodoc
abstract mixin class _$AppVersionListRequestCopyWith<$Res> implements $AppVersionListRequestCopyWith<$Res> {
  factory _$AppVersionListRequestCopyWith(_AppVersionListRequest value, $Res Function(_AppVersionListRequest) _then) = __$AppVersionListRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'repoName') String repoName, String? arch,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize, String? lan
});




}
/// @nodoc
class __$AppVersionListRequestCopyWithImpl<$Res>
    implements _$AppVersionListRequestCopyWith<$Res> {
  __$AppVersionListRequestCopyWithImpl(this._self, this._then);

  final _AppVersionListRequest _self;
  final $Res Function(_AppVersionListRequest) _then;

/// Create a copy of AppVersionListRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? repoName = null,Object? arch = freezed,Object? pageNo = null,Object? pageSize = null,Object? lan = freezed,}) {
  return _then(_AppVersionListRequest(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AppVersionDTO {

@JsonKey(name: 'id') String? get versionId;@JsonKey(name: 'version') String get versionNo;@JsonKey(name: 'zhName') String? get versionName; String? get description;@JsonKey(readValue: _readVersionReleaseTime) String? get releaseTime;@JsonKey(name: 'size') String? get packageSize; String? get appId; String? get icon; String? get kind; String? get module; String? get channel; String? get arch;@JsonKey(name: 'repoName') String? get repoName;@JsonKey(readValue: _readVersionInstallCount) int? get installCount;
/// Create a copy of AppVersionDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppVersionDTOCopyWith<AppVersionDTO> get copyWith => _$AppVersionDTOCopyWithImpl<AppVersionDTO>(this as AppVersionDTO, _$identity);

  /// Serializes this AppVersionDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppVersionDTO&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.versionName, versionName) || other.versionName == versionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installCount, installCount) || other.installCount == installCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,versionId,versionNo,versionName,description,releaseTime,packageSize,appId,icon,kind,module,channel,arch,repoName,installCount);

@override
String toString() {
  return 'AppVersionDTO(versionId: $versionId, versionNo: $versionNo, versionName: $versionName, description: $description, releaseTime: $releaseTime, packageSize: $packageSize, appId: $appId, icon: $icon, kind: $kind, module: $module, channel: $channel, arch: $arch, repoName: $repoName, installCount: $installCount)';
}


}

/// @nodoc
abstract mixin class $AppVersionDTOCopyWith<$Res>  {
  factory $AppVersionDTOCopyWith(AppVersionDTO value, $Res Function(AppVersionDTO) _then) = _$AppVersionDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id') String? versionId,@JsonKey(name: 'version') String versionNo,@JsonKey(name: 'zhName') String? versionName, String? description,@JsonKey(readValue: _readVersionReleaseTime) String? releaseTime,@JsonKey(name: 'size') String? packageSize, String? appId, String? icon, String? kind, String? module, String? channel, String? arch,@JsonKey(name: 'repoName') String? repoName,@JsonKey(readValue: _readVersionInstallCount) int? installCount
});




}
/// @nodoc
class _$AppVersionDTOCopyWithImpl<$Res>
    implements $AppVersionDTOCopyWith<$Res> {
  _$AppVersionDTOCopyWithImpl(this._self, this._then);

  final AppVersionDTO _self;
  final $Res Function(AppVersionDTO) _then;

/// Create a copy of AppVersionDTO
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


/// Adds pattern-matching-related methods to [AppVersionDTO].
extension AppVersionDTOPatterns on AppVersionDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppVersionDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppVersionDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppVersionDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppVersionDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppVersionDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppVersionDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? versionId, @JsonKey(name: 'version')  String versionNo, @JsonKey(name: 'zhName')  String? versionName,  String? description, @JsonKey(readValue: _readVersionReleaseTime)  String? releaseTime, @JsonKey(name: 'size')  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(readValue: _readVersionInstallCount)  int? installCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppVersionDTO() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id')  String? versionId, @JsonKey(name: 'version')  String versionNo, @JsonKey(name: 'zhName')  String? versionName,  String? description, @JsonKey(readValue: _readVersionReleaseTime)  String? releaseTime, @JsonKey(name: 'size')  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(readValue: _readVersionInstallCount)  int? installCount)  $default,) {final _that = this;
switch (_that) {
case _AppVersionDTO():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id')  String? versionId, @JsonKey(name: 'version')  String versionNo, @JsonKey(name: 'zhName')  String? versionName,  String? description, @JsonKey(readValue: _readVersionReleaseTime)  String? releaseTime, @JsonKey(name: 'size')  String? packageSize,  String? appId,  String? icon,  String? kind,  String? module,  String? channel,  String? arch, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(readValue: _readVersionInstallCount)  int? installCount)?  $default,) {final _that = this;
switch (_that) {
case _AppVersionDTO() when $default != null:
return $default(_that.versionId,_that.versionNo,_that.versionName,_that.description,_that.releaseTime,_that.packageSize,_that.appId,_that.icon,_that.kind,_that.module,_that.channel,_that.arch,_that.repoName,_that.installCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppVersionDTO implements AppVersionDTO {
  const _AppVersionDTO({@JsonKey(name: 'id') this.versionId, @JsonKey(name: 'version') required this.versionNo, @JsonKey(name: 'zhName') this.versionName, this.description, @JsonKey(readValue: _readVersionReleaseTime) this.releaseTime, @JsonKey(name: 'size') this.packageSize, this.appId, this.icon, this.kind, this.module, this.channel, this.arch, @JsonKey(name: 'repoName') this.repoName, @JsonKey(readValue: _readVersionInstallCount) this.installCount});
  factory _AppVersionDTO.fromJson(Map<String, dynamic> json) => _$AppVersionDTOFromJson(json);

@override@JsonKey(name: 'id') final  String? versionId;
@override@JsonKey(name: 'version') final  String versionNo;
@override@JsonKey(name: 'zhName') final  String? versionName;
@override final  String? description;
@override@JsonKey(readValue: _readVersionReleaseTime) final  String? releaseTime;
@override@JsonKey(name: 'size') final  String? packageSize;
@override final  String? appId;
@override final  String? icon;
@override final  String? kind;
@override final  String? module;
@override final  String? channel;
@override final  String? arch;
@override@JsonKey(name: 'repoName') final  String? repoName;
@override@JsonKey(readValue: _readVersionInstallCount) final  int? installCount;

/// Create a copy of AppVersionDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppVersionDTOCopyWith<_AppVersionDTO> get copyWith => __$AppVersionDTOCopyWithImpl<_AppVersionDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppVersionDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppVersionDTO&&(identical(other.versionId, versionId) || other.versionId == versionId)&&(identical(other.versionNo, versionNo) || other.versionNo == versionNo)&&(identical(other.versionName, versionName) || other.versionName == versionName)&&(identical(other.description, description) || other.description == description)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.installCount, installCount) || other.installCount == installCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,versionId,versionNo,versionName,description,releaseTime,packageSize,appId,icon,kind,module,channel,arch,repoName,installCount);

@override
String toString() {
  return 'AppVersionDTO(versionId: $versionId, versionNo: $versionNo, versionName: $versionName, description: $description, releaseTime: $releaseTime, packageSize: $packageSize, appId: $appId, icon: $icon, kind: $kind, module: $module, channel: $channel, arch: $arch, repoName: $repoName, installCount: $installCount)';
}


}

/// @nodoc
abstract mixin class _$AppVersionDTOCopyWith<$Res> implements $AppVersionDTOCopyWith<$Res> {
  factory _$AppVersionDTOCopyWith(_AppVersionDTO value, $Res Function(_AppVersionDTO) _then) = __$AppVersionDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id') String? versionId,@JsonKey(name: 'version') String versionNo,@JsonKey(name: 'zhName') String? versionName, String? description,@JsonKey(readValue: _readVersionReleaseTime) String? releaseTime,@JsonKey(name: 'size') String? packageSize, String? appId, String? icon, String? kind, String? module, String? channel, String? arch,@JsonKey(name: 'repoName') String? repoName,@JsonKey(readValue: _readVersionInstallCount) int? installCount
});




}
/// @nodoc
class __$AppVersionDTOCopyWithImpl<$Res>
    implements _$AppVersionDTOCopyWith<$Res> {
  __$AppVersionDTOCopyWithImpl(this._self, this._then);

  final _AppVersionDTO _self;
  final $Res Function(_AppVersionDTO) _then;

/// Create a copy of AppVersionDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? versionId = freezed,Object? versionNo = null,Object? versionName = freezed,Object? description = freezed,Object? releaseTime = freezed,Object? packageSize = freezed,Object? appId = freezed,Object? icon = freezed,Object? kind = freezed,Object? module = freezed,Object? channel = freezed,Object? arch = freezed,Object? repoName = freezed,Object? installCount = freezed,}) {
  return _then(_AppVersionDTO(
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


/// @nodoc
mixin _$VersionListResponse {

 int get code; String? get message; List<AppVersionDTO> get data;
/// Create a copy of VersionListResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VersionListResponseCopyWith<VersionListResponse> get copyWith => _$VersionListResponseCopyWithImpl<VersionListResponse>(this as VersionListResponse, _$identity);

  /// Serializes this VersionListResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VersionListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'VersionListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $VersionListResponseCopyWith<$Res>  {
  factory $VersionListResponseCopyWith(VersionListResponse value, $Res Function(VersionListResponse) _then) = _$VersionListResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<AppVersionDTO> data
});




}
/// @nodoc
class _$VersionListResponseCopyWithImpl<$Res>
    implements $VersionListResponseCopyWith<$Res> {
  _$VersionListResponseCopyWithImpl(this._self, this._then);

  final VersionListResponse _self;
  final $Res Function(VersionListResponse) _then;

/// Create a copy of VersionListResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<AppVersionDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [VersionListResponse].
extension VersionListResponsePatterns on VersionListResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VersionListResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VersionListResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VersionListResponse value)  $default,){
final _that = this;
switch (_that) {
case _VersionListResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VersionListResponse value)?  $default,){
final _that = this;
switch (_that) {
case _VersionListResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppVersionDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VersionListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppVersionDTO> data)  $default,) {final _that = this;
switch (_that) {
case _VersionListResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<AppVersionDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _VersionListResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VersionListResponse implements VersionListResponse {
  const _VersionListResponse({required this.code, this.message, final  List<AppVersionDTO> data = const []}): _data = data;
  factory _VersionListResponse.fromJson(Map<String, dynamic> json) => _$VersionListResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<AppVersionDTO> _data;
@override@JsonKey() List<AppVersionDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of VersionListResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VersionListResponseCopyWith<_VersionListResponse> get copyWith => __$VersionListResponseCopyWithImpl<_VersionListResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VersionListResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VersionListResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'VersionListResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$VersionListResponseCopyWith<$Res> implements $VersionListResponseCopyWith<$Res> {
  factory _$VersionListResponseCopyWith(_VersionListResponse value, $Res Function(_VersionListResponse) _then) = __$VersionListResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<AppVersionDTO> data
});




}
/// @nodoc
class __$VersionListResponseCopyWithImpl<$Res>
    implements _$VersionListResponseCopyWith<$Res> {
  __$VersionListResponseCopyWithImpl(this._self, this._then);

  final _VersionListResponse _self;
  final $Res Function(_VersionListResponse) _then;

/// Create a copy of VersionListResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_VersionListResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AppVersionDTO>,
  ));
}


}


/// @nodoc
mixin _$CheckUpdateResponse {

 int get code; String? get message; AppUpdateInfoDTO? get data;
/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckUpdateResponseCopyWith<CheckUpdateResponse> get copyWith => _$CheckUpdateResponseCopyWithImpl<CheckUpdateResponse>(this as CheckUpdateResponse, _$identity);

  /// Serializes this CheckUpdateResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckUpdateResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'CheckUpdateResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CheckUpdateResponseCopyWith<$Res>  {
  factory $CheckUpdateResponseCopyWith(CheckUpdateResponse value, $Res Function(CheckUpdateResponse) _then) = _$CheckUpdateResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, AppUpdateInfoDTO? data
});


$AppUpdateInfoDTOCopyWith<$Res>? get data;

}
/// @nodoc
class _$CheckUpdateResponseCopyWithImpl<$Res>
    implements $CheckUpdateResponseCopyWith<$Res> {
  _$CheckUpdateResponseCopyWithImpl(this._self, this._then);

  final CheckUpdateResponse _self;
  final $Res Function(CheckUpdateResponse) _then;

/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AppUpdateInfoDTO?,
  ));
}
/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUpdateInfoDTOCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $AppUpdateInfoDTOCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [CheckUpdateResponse].
extension CheckUpdateResponsePatterns on CheckUpdateResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckUpdateResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckUpdateResponse value)  $default,){
final _that = this;
switch (_that) {
case _CheckUpdateResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckUpdateResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CheckUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  AppUpdateInfoDTO? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckUpdateResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  AppUpdateInfoDTO? data)  $default,) {final _that = this;
switch (_that) {
case _CheckUpdateResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  AppUpdateInfoDTO? data)?  $default,) {final _that = this;
switch (_that) {
case _CheckUpdateResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckUpdateResponse implements CheckUpdateResponse {
  const _CheckUpdateResponse({required this.code, this.message, this.data});
  factory _CheckUpdateResponse.fromJson(Map<String, dynamic> json) => _$CheckUpdateResponseFromJson(json);

@override final  int code;
@override final  String? message;
@override final  AppUpdateInfoDTO? data;

/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckUpdateResponseCopyWith<_CheckUpdateResponse> get copyWith => __$CheckUpdateResponseCopyWithImpl<_CheckUpdateResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckUpdateResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckUpdateResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'CheckUpdateResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CheckUpdateResponseCopyWith<$Res> implements $CheckUpdateResponseCopyWith<$Res> {
  factory _$CheckUpdateResponseCopyWith(_CheckUpdateResponse value, $Res Function(_CheckUpdateResponse) _then) = __$CheckUpdateResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, AppUpdateInfoDTO? data
});


@override $AppUpdateInfoDTOCopyWith<$Res>? get data;

}
/// @nodoc
class __$CheckUpdateResponseCopyWithImpl<$Res>
    implements _$CheckUpdateResponseCopyWith<$Res> {
  __$CheckUpdateResponseCopyWithImpl(this._self, this._then);

  final _CheckUpdateResponse _self;
  final $Res Function(_CheckUpdateResponse) _then;

/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_CheckUpdateResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as AppUpdateInfoDTO?,
  ));
}

/// Create a copy of CheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppUpdateInfoDTOCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $AppUpdateInfoDTOCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$BatchCheckUpdateResponse {

 int get code; String? get message; List<AppUpdateInfoDTO> get data;
/// Create a copy of BatchCheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchCheckUpdateResponseCopyWith<BatchCheckUpdateResponse> get copyWith => _$BatchCheckUpdateResponseCopyWithImpl<BatchCheckUpdateResponse>(this as BatchCheckUpdateResponse, _$identity);

  /// Serializes this BatchCheckUpdateResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchCheckUpdateResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'BatchCheckUpdateResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $BatchCheckUpdateResponseCopyWith<$Res>  {
  factory $BatchCheckUpdateResponseCopyWith(BatchCheckUpdateResponse value, $Res Function(BatchCheckUpdateResponse) _then) = _$BatchCheckUpdateResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<AppUpdateInfoDTO> data
});




}
/// @nodoc
class _$BatchCheckUpdateResponseCopyWithImpl<$Res>
    implements $BatchCheckUpdateResponseCopyWith<$Res> {
  _$BatchCheckUpdateResponseCopyWithImpl(this._self, this._then);

  final BatchCheckUpdateResponse _self;
  final $Res Function(BatchCheckUpdateResponse) _then;

/// Create a copy of BatchCheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<AppUpdateInfoDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [BatchCheckUpdateResponse].
extension BatchCheckUpdateResponsePatterns on BatchCheckUpdateResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BatchCheckUpdateResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BatchCheckUpdateResponse value)  $default,){
final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BatchCheckUpdateResponse value)?  $default,){
final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppUpdateInfoDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<AppUpdateInfoDTO> data)  $default,) {final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<AppUpdateInfoDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _BatchCheckUpdateResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BatchCheckUpdateResponse implements BatchCheckUpdateResponse {
  const _BatchCheckUpdateResponse({required this.code, this.message, final  List<AppUpdateInfoDTO> data = const []}): _data = data;
  factory _BatchCheckUpdateResponse.fromJson(Map<String, dynamic> json) => _$BatchCheckUpdateResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<AppUpdateInfoDTO> _data;
@override@JsonKey() List<AppUpdateInfoDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of BatchCheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BatchCheckUpdateResponseCopyWith<_BatchCheckUpdateResponse> get copyWith => __$BatchCheckUpdateResponseCopyWithImpl<_BatchCheckUpdateResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchCheckUpdateResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BatchCheckUpdateResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'BatchCheckUpdateResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$BatchCheckUpdateResponseCopyWith<$Res> implements $BatchCheckUpdateResponseCopyWith<$Res> {
  factory _$BatchCheckUpdateResponseCopyWith(_BatchCheckUpdateResponse value, $Res Function(_BatchCheckUpdateResponse) _then) = __$BatchCheckUpdateResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<AppUpdateInfoDTO> data
});




}
/// @nodoc
class __$BatchCheckUpdateResponseCopyWithImpl<$Res>
    implements _$BatchCheckUpdateResponseCopyWith<$Res> {
  __$BatchCheckUpdateResponseCopyWithImpl(this._self, this._then);

  final _BatchCheckUpdateResponse _self;
  final $Res Function(_BatchCheckUpdateResponse) _then;

/// Create a copy of BatchCheckUpdateResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_BatchCheckUpdateResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<AppUpdateInfoDTO>,
  ));
}


}


/// @nodoc
mixin _$AppUpdateInfoDTO {

@JsonKey(name: 'appId') String get appId;@JsonKey(name: 'appName') String get appName;@JsonKey(name: 'latestVersion') String get latestVersion;@JsonKey(name: 'currentVersion') String? get currentVersion;@JsonKey(name: 'releaseNote') String? get releaseNote;@JsonKey(name: 'releaseTime') String? get releaseTime;@JsonKey(name: 'packageSize') String? get packageSize;@JsonKey(name: 'needUpdate') bool get needUpdate;@JsonKey(name: 'forceUpdate') bool get forceUpdate;
/// Create a copy of AppUpdateInfoDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateInfoDTOCopyWith<AppUpdateInfoDTO> get copyWith => _$AppUpdateInfoDTOCopyWithImpl<AppUpdateInfoDTO>(this as AppUpdateInfoDTO, _$identity);

  /// Serializes this AppUpdateInfoDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateInfoDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&(identical(other.currentVersion, currentVersion) || other.currentVersion == currentVersion)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.needUpdate, needUpdate) || other.needUpdate == needUpdate)&&(identical(other.forceUpdate, forceUpdate) || other.forceUpdate == forceUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,appName,latestVersion,currentVersion,releaseNote,releaseTime,packageSize,needUpdate,forceUpdate);

@override
String toString() {
  return 'AppUpdateInfoDTO(appId: $appId, appName: $appName, latestVersion: $latestVersion, currentVersion: $currentVersion, releaseNote: $releaseNote, releaseTime: $releaseTime, packageSize: $packageSize, needUpdate: $needUpdate, forceUpdate: $forceUpdate)';
}


}

/// @nodoc
abstract mixin class $AppUpdateInfoDTOCopyWith<$Res>  {
  factory $AppUpdateInfoDTOCopyWith(AppUpdateInfoDTO value, $Res Function(AppUpdateInfoDTO) _then) = _$AppUpdateInfoDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'appName') String appName,@JsonKey(name: 'latestVersion') String latestVersion,@JsonKey(name: 'currentVersion') String? currentVersion,@JsonKey(name: 'releaseNote') String? releaseNote,@JsonKey(name: 'releaseTime') String? releaseTime,@JsonKey(name: 'packageSize') String? packageSize,@JsonKey(name: 'needUpdate') bool needUpdate,@JsonKey(name: 'forceUpdate') bool forceUpdate
});




}
/// @nodoc
class _$AppUpdateInfoDTOCopyWithImpl<$Res>
    implements $AppUpdateInfoDTOCopyWith<$Res> {
  _$AppUpdateInfoDTOCopyWithImpl(this._self, this._then);

  final AppUpdateInfoDTO _self;
  final $Res Function(AppUpdateInfoDTO) _then;

/// Create a copy of AppUpdateInfoDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? appName = null,Object? latestVersion = null,Object? currentVersion = freezed,Object? releaseNote = freezed,Object? releaseTime = freezed,Object? packageSize = freezed,Object? needUpdate = null,Object? forceUpdate = null,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,currentVersion: freezed == currentVersion ? _self.currentVersion : currentVersion // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,releaseTime: freezed == releaseTime ? _self.releaseTime : releaseTime // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,needUpdate: null == needUpdate ? _self.needUpdate : needUpdate // ignore: cast_nullable_to_non_nullable
as bool,forceUpdate: null == forceUpdate ? _self.forceUpdate : forceUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUpdateInfoDTO].
extension AppUpdateInfoDTOPatterns on AppUpdateInfoDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUpdateInfoDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUpdateInfoDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUpdateInfoDTO value)  $default,){
final _that = this;
switch (_that) {
case _AppUpdateInfoDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUpdateInfoDTO value)?  $default,){
final _that = this;
switch (_that) {
case _AppUpdateInfoDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'appName')  String appName, @JsonKey(name: 'latestVersion')  String latestVersion, @JsonKey(name: 'currentVersion')  String? currentVersion, @JsonKey(name: 'releaseNote')  String? releaseNote, @JsonKey(name: 'releaseTime')  String? releaseTime, @JsonKey(name: 'packageSize')  String? packageSize, @JsonKey(name: 'needUpdate')  bool needUpdate, @JsonKey(name: 'forceUpdate')  bool forceUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUpdateInfoDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.latestVersion,_that.currentVersion,_that.releaseNote,_that.releaseTime,_that.packageSize,_that.needUpdate,_that.forceUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'appName')  String appName, @JsonKey(name: 'latestVersion')  String latestVersion, @JsonKey(name: 'currentVersion')  String? currentVersion, @JsonKey(name: 'releaseNote')  String? releaseNote, @JsonKey(name: 'releaseTime')  String? releaseTime, @JsonKey(name: 'packageSize')  String? packageSize, @JsonKey(name: 'needUpdate')  bool needUpdate, @JsonKey(name: 'forceUpdate')  bool forceUpdate)  $default,) {final _that = this;
switch (_that) {
case _AppUpdateInfoDTO():
return $default(_that.appId,_that.appName,_that.latestVersion,_that.currentVersion,_that.releaseNote,_that.releaseTime,_that.packageSize,_that.needUpdate,_that.forceUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String appId, @JsonKey(name: 'appName')  String appName, @JsonKey(name: 'latestVersion')  String latestVersion, @JsonKey(name: 'currentVersion')  String? currentVersion, @JsonKey(name: 'releaseNote')  String? releaseNote, @JsonKey(name: 'releaseTime')  String? releaseTime, @JsonKey(name: 'packageSize')  String? packageSize, @JsonKey(name: 'needUpdate')  bool needUpdate, @JsonKey(name: 'forceUpdate')  bool forceUpdate)?  $default,) {final _that = this;
switch (_that) {
case _AppUpdateInfoDTO() when $default != null:
return $default(_that.appId,_that.appName,_that.latestVersion,_that.currentVersion,_that.releaseNote,_that.releaseTime,_that.packageSize,_that.needUpdate,_that.forceUpdate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppUpdateInfoDTO implements AppUpdateInfoDTO {
  const _AppUpdateInfoDTO({@JsonKey(name: 'appId') required this.appId, @JsonKey(name: 'appName') required this.appName, @JsonKey(name: 'latestVersion') required this.latestVersion, @JsonKey(name: 'currentVersion') this.currentVersion, @JsonKey(name: 'releaseNote') this.releaseNote, @JsonKey(name: 'releaseTime') this.releaseTime, @JsonKey(name: 'packageSize') this.packageSize, @JsonKey(name: 'needUpdate') this.needUpdate = false, @JsonKey(name: 'forceUpdate') this.forceUpdate = false});
  factory _AppUpdateInfoDTO.fromJson(Map<String, dynamic> json) => _$AppUpdateInfoDTOFromJson(json);

@override@JsonKey(name: 'appId') final  String appId;
@override@JsonKey(name: 'appName') final  String appName;
@override@JsonKey(name: 'latestVersion') final  String latestVersion;
@override@JsonKey(name: 'currentVersion') final  String? currentVersion;
@override@JsonKey(name: 'releaseNote') final  String? releaseNote;
@override@JsonKey(name: 'releaseTime') final  String? releaseTime;
@override@JsonKey(name: 'packageSize') final  String? packageSize;
@override@JsonKey(name: 'needUpdate') final  bool needUpdate;
@override@JsonKey(name: 'forceUpdate') final  bool forceUpdate;

/// Create a copy of AppUpdateInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUpdateInfoDTOCopyWith<_AppUpdateInfoDTO> get copyWith => __$AppUpdateInfoDTOCopyWithImpl<_AppUpdateInfoDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppUpdateInfoDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUpdateInfoDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.latestVersion, latestVersion) || other.latestVersion == latestVersion)&&(identical(other.currentVersion, currentVersion) || other.currentVersion == currentVersion)&&(identical(other.releaseNote, releaseNote) || other.releaseNote == releaseNote)&&(identical(other.releaseTime, releaseTime) || other.releaseTime == releaseTime)&&(identical(other.packageSize, packageSize) || other.packageSize == packageSize)&&(identical(other.needUpdate, needUpdate) || other.needUpdate == needUpdate)&&(identical(other.forceUpdate, forceUpdate) || other.forceUpdate == forceUpdate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,appName,latestVersion,currentVersion,releaseNote,releaseTime,packageSize,needUpdate,forceUpdate);

@override
String toString() {
  return 'AppUpdateInfoDTO(appId: $appId, appName: $appName, latestVersion: $latestVersion, currentVersion: $currentVersion, releaseNote: $releaseNote, releaseTime: $releaseTime, packageSize: $packageSize, needUpdate: $needUpdate, forceUpdate: $forceUpdate)';
}


}

/// @nodoc
abstract mixin class _$AppUpdateInfoDTOCopyWith<$Res> implements $AppUpdateInfoDTOCopyWith<$Res> {
  factory _$AppUpdateInfoDTOCopyWith(_AppUpdateInfoDTO value, $Res Function(_AppUpdateInfoDTO) _then) = __$AppUpdateInfoDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String appId,@JsonKey(name: 'appName') String appName,@JsonKey(name: 'latestVersion') String latestVersion,@JsonKey(name: 'currentVersion') String? currentVersion,@JsonKey(name: 'releaseNote') String? releaseNote,@JsonKey(name: 'releaseTime') String? releaseTime,@JsonKey(name: 'packageSize') String? packageSize,@JsonKey(name: 'needUpdate') bool needUpdate,@JsonKey(name: 'forceUpdate') bool forceUpdate
});




}
/// @nodoc
class __$AppUpdateInfoDTOCopyWithImpl<$Res>
    implements _$AppUpdateInfoDTOCopyWith<$Res> {
  __$AppUpdateInfoDTOCopyWithImpl(this._self, this._then);

  final _AppUpdateInfoDTO _self;
  final $Res Function(_AppUpdateInfoDTO) _then;

/// Create a copy of AppUpdateInfoDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? appName = null,Object? latestVersion = null,Object? currentVersion = freezed,Object? releaseNote = freezed,Object? releaseTime = freezed,Object? packageSize = freezed,Object? needUpdate = null,Object? forceUpdate = null,}) {
  return _then(_AppUpdateInfoDTO(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,latestVersion: null == latestVersion ? _self.latestVersion : latestVersion // ignore: cast_nullable_to_non_nullable
as String,currentVersion: freezed == currentVersion ? _self.currentVersion : currentVersion // ignore: cast_nullable_to_non_nullable
as String?,releaseNote: freezed == releaseNote ? _self.releaseNote : releaseNote // ignore: cast_nullable_to_non_nullable
as String?,releaseTime: freezed == releaseTime ? _self.releaseTime : releaseTime // ignore: cast_nullable_to_non_nullable
as String?,packageSize: freezed == packageSize ? _self.packageSize : packageSize // ignore: cast_nullable_to_non_nullable
as String?,needUpdate: null == needUpdate ? _self.needUpdate : needUpdate // ignore: cast_nullable_to_non_nullable
as bool,forceUpdate: null == forceUpdate ? _self.forceUpdate : forceUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SidebarMenuRuleDTO {

@JsonKey(name: 'sortBy') String? get sortBy;@JsonKey(name: 'sortOrder') String? get sortOrder;@JsonKey(name: 'filterMinScore') int? get filterMinScore;
/// Create a copy of SidebarMenuRuleDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SidebarMenuRuleDTOCopyWith<SidebarMenuRuleDTO> get copyWith => _$SidebarMenuRuleDTOCopyWithImpl<SidebarMenuRuleDTO>(this as SidebarMenuRuleDTO, _$identity);

  /// Serializes this SidebarMenuRuleDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SidebarMenuRuleDTO&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.filterMinScore, filterMinScore) || other.filterMinScore == filterMinScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sortBy,sortOrder,filterMinScore);

@override
String toString() {
  return 'SidebarMenuRuleDTO(sortBy: $sortBy, sortOrder: $sortOrder, filterMinScore: $filterMinScore)';
}


}

/// @nodoc
abstract mixin class $SidebarMenuRuleDTOCopyWith<$Res>  {
  factory $SidebarMenuRuleDTOCopyWith(SidebarMenuRuleDTO value, $Res Function(SidebarMenuRuleDTO) _then) = _$SidebarMenuRuleDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sortBy') String? sortBy,@JsonKey(name: 'sortOrder') String? sortOrder,@JsonKey(name: 'filterMinScore') int? filterMinScore
});




}
/// @nodoc
class _$SidebarMenuRuleDTOCopyWithImpl<$Res>
    implements $SidebarMenuRuleDTOCopyWith<$Res> {
  _$SidebarMenuRuleDTOCopyWithImpl(this._self, this._then);

  final SidebarMenuRuleDTO _self;
  final $Res Function(SidebarMenuRuleDTO) _then;

/// Create a copy of SidebarMenuRuleDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sortBy = freezed,Object? sortOrder = freezed,Object? filterMinScore = freezed,}) {
  return _then(_self.copyWith(
sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String?,filterMinScore: freezed == filterMinScore ? _self.filterMinScore : filterMinScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SidebarMenuRuleDTO].
extension SidebarMenuRuleDTOPatterns on SidebarMenuRuleDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SidebarMenuRuleDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SidebarMenuRuleDTO value)  $default,){
final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SidebarMenuRuleDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'sortBy')  String? sortBy, @JsonKey(name: 'sortOrder')  String? sortOrder, @JsonKey(name: 'filterMinScore')  int? filterMinScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO() when $default != null:
return $default(_that.sortBy,_that.sortOrder,_that.filterMinScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'sortBy')  String? sortBy, @JsonKey(name: 'sortOrder')  String? sortOrder, @JsonKey(name: 'filterMinScore')  int? filterMinScore)  $default,) {final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO():
return $default(_that.sortBy,_that.sortOrder,_that.filterMinScore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'sortBy')  String? sortBy, @JsonKey(name: 'sortOrder')  String? sortOrder, @JsonKey(name: 'filterMinScore')  int? filterMinScore)?  $default,) {final _that = this;
switch (_that) {
case _SidebarMenuRuleDTO() when $default != null:
return $default(_that.sortBy,_that.sortOrder,_that.filterMinScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SidebarMenuRuleDTO implements SidebarMenuRuleDTO {
  const _SidebarMenuRuleDTO({@JsonKey(name: 'sortBy') this.sortBy, @JsonKey(name: 'sortOrder') this.sortOrder, @JsonKey(name: 'filterMinScore') this.filterMinScore});
  factory _SidebarMenuRuleDTO.fromJson(Map<String, dynamic> json) => _$SidebarMenuRuleDTOFromJson(json);

@override@JsonKey(name: 'sortBy') final  String? sortBy;
@override@JsonKey(name: 'sortOrder') final  String? sortOrder;
@override@JsonKey(name: 'filterMinScore') final  int? filterMinScore;

/// Create a copy of SidebarMenuRuleDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SidebarMenuRuleDTOCopyWith<_SidebarMenuRuleDTO> get copyWith => __$SidebarMenuRuleDTOCopyWithImpl<_SidebarMenuRuleDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SidebarMenuRuleDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SidebarMenuRuleDTO&&(identical(other.sortBy, sortBy) || other.sortBy == sortBy)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.filterMinScore, filterMinScore) || other.filterMinScore == filterMinScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sortBy,sortOrder,filterMinScore);

@override
String toString() {
  return 'SidebarMenuRuleDTO(sortBy: $sortBy, sortOrder: $sortOrder, filterMinScore: $filterMinScore)';
}


}

/// @nodoc
abstract mixin class _$SidebarMenuRuleDTOCopyWith<$Res> implements $SidebarMenuRuleDTOCopyWith<$Res> {
  factory _$SidebarMenuRuleDTOCopyWith(_SidebarMenuRuleDTO value, $Res Function(_SidebarMenuRuleDTO) _then) = __$SidebarMenuRuleDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sortBy') String? sortBy,@JsonKey(name: 'sortOrder') String? sortOrder,@JsonKey(name: 'filterMinScore') int? filterMinScore
});




}
/// @nodoc
class __$SidebarMenuRuleDTOCopyWithImpl<$Res>
    implements _$SidebarMenuRuleDTOCopyWith<$Res> {
  __$SidebarMenuRuleDTOCopyWithImpl(this._self, this._then);

  final _SidebarMenuRuleDTO _self;
  final $Res Function(_SidebarMenuRuleDTO) _then;

/// Create a copy of SidebarMenuRuleDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sortBy = freezed,Object? sortOrder = freezed,Object? filterMinScore = freezed,}) {
  return _then(_SidebarMenuRuleDTO(
sortBy: freezed == sortBy ? _self.sortBy : sortBy // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as String?,filterMinScore: freezed == filterMinScore ? _self.filterMinScore : filterMinScore // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SidebarMenuDTO {

@JsonKey(name: 'code') String get menuCode;@JsonKey(name: 'name') String get menuName;@JsonKey(name: 'icon') String? get menuIcon;@JsonKey(name: 'activeIcon') String? get activeMenuIcon;@JsonKey(name: 'sortNo') int? get sortOrder;@JsonKey(name: 'enabled') bool get enabled;@JsonKey(name: 'categoryIds') List<String> get categoryIds;@JsonKey(name: 'rule') SidebarMenuRuleDTO? get rule;
/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SidebarMenuDTOCopyWith<SidebarMenuDTO> get copyWith => _$SidebarMenuDTOCopyWithImpl<SidebarMenuDTO>(this as SidebarMenuDTO, _$identity);

  /// Serializes this SidebarMenuDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SidebarMenuDTO&&(identical(other.menuCode, menuCode) || other.menuCode == menuCode)&&(identical(other.menuName, menuName) || other.menuName == menuName)&&(identical(other.menuIcon, menuIcon) || other.menuIcon == menuIcon)&&(identical(other.activeMenuIcon, activeMenuIcon) || other.activeMenuIcon == activeMenuIcon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.rule, rule) || other.rule == rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuCode,menuName,menuIcon,activeMenuIcon,sortOrder,enabled,const DeepCollectionEquality().hash(categoryIds),rule);

@override
String toString() {
  return 'SidebarMenuDTO(menuCode: $menuCode, menuName: $menuName, menuIcon: $menuIcon, activeMenuIcon: $activeMenuIcon, sortOrder: $sortOrder, enabled: $enabled, categoryIds: $categoryIds, rule: $rule)';
}


}

/// @nodoc
abstract mixin class $SidebarMenuDTOCopyWith<$Res>  {
  factory $SidebarMenuDTOCopyWith(SidebarMenuDTO value, $Res Function(SidebarMenuDTO) _then) = _$SidebarMenuDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'code') String menuCode,@JsonKey(name: 'name') String menuName,@JsonKey(name: 'icon') String? menuIcon,@JsonKey(name: 'activeIcon') String? activeMenuIcon,@JsonKey(name: 'sortNo') int? sortOrder,@JsonKey(name: 'enabled') bool enabled,@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'rule') SidebarMenuRuleDTO? rule
});


$SidebarMenuRuleDTOCopyWith<$Res>? get rule;

}
/// @nodoc
class _$SidebarMenuDTOCopyWithImpl<$Res>
    implements $SidebarMenuDTOCopyWith<$Res> {
  _$SidebarMenuDTOCopyWithImpl(this._self, this._then);

  final SidebarMenuDTO _self;
  final $Res Function(SidebarMenuDTO) _then;

/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menuCode = null,Object? menuName = null,Object? menuIcon = freezed,Object? activeMenuIcon = freezed,Object? sortOrder = freezed,Object? enabled = null,Object? categoryIds = null,Object? rule = freezed,}) {
  return _then(_self.copyWith(
menuCode: null == menuCode ? _self.menuCode : menuCode // ignore: cast_nullable_to_non_nullable
as String,menuName: null == menuName ? _self.menuName : menuName // ignore: cast_nullable_to_non_nullable
as String,menuIcon: freezed == menuIcon ? _self.menuIcon : menuIcon // ignore: cast_nullable_to_non_nullable
as String?,activeMenuIcon: freezed == activeMenuIcon ? _self.activeMenuIcon : activeMenuIcon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,rule: freezed == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as SidebarMenuRuleDTO?,
  ));
}
/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SidebarMenuRuleDTOCopyWith<$Res>? get rule {
    if (_self.rule == null) {
    return null;
  }

  return $SidebarMenuRuleDTOCopyWith<$Res>(_self.rule!, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// Adds pattern-matching-related methods to [SidebarMenuDTO].
extension SidebarMenuDTOPatterns on SidebarMenuDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SidebarMenuDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SidebarMenuDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SidebarMenuDTO value)  $default,){
final _that = this;
switch (_that) {
case _SidebarMenuDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SidebarMenuDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SidebarMenuDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'code')  String menuCode, @JsonKey(name: 'name')  String menuName, @JsonKey(name: 'icon')  String? menuIcon, @JsonKey(name: 'activeIcon')  String? activeMenuIcon, @JsonKey(name: 'sortNo')  int? sortOrder, @JsonKey(name: 'enabled')  bool enabled, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'rule')  SidebarMenuRuleDTO? rule)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SidebarMenuDTO() when $default != null:
return $default(_that.menuCode,_that.menuName,_that.menuIcon,_that.activeMenuIcon,_that.sortOrder,_that.enabled,_that.categoryIds,_that.rule);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'code')  String menuCode, @JsonKey(name: 'name')  String menuName, @JsonKey(name: 'icon')  String? menuIcon, @JsonKey(name: 'activeIcon')  String? activeMenuIcon, @JsonKey(name: 'sortNo')  int? sortOrder, @JsonKey(name: 'enabled')  bool enabled, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'rule')  SidebarMenuRuleDTO? rule)  $default,) {final _that = this;
switch (_that) {
case _SidebarMenuDTO():
return $default(_that.menuCode,_that.menuName,_that.menuIcon,_that.activeMenuIcon,_that.sortOrder,_that.enabled,_that.categoryIds,_that.rule);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'code')  String menuCode, @JsonKey(name: 'name')  String menuName, @JsonKey(name: 'icon')  String? menuIcon, @JsonKey(name: 'activeIcon')  String? activeMenuIcon, @JsonKey(name: 'sortNo')  int? sortOrder, @JsonKey(name: 'enabled')  bool enabled, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'rule')  SidebarMenuRuleDTO? rule)?  $default,) {final _that = this;
switch (_that) {
case _SidebarMenuDTO() when $default != null:
return $default(_that.menuCode,_that.menuName,_that.menuIcon,_that.activeMenuIcon,_that.sortOrder,_that.enabled,_that.categoryIds,_that.rule);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SidebarMenuDTO implements SidebarMenuDTO {
  const _SidebarMenuDTO({@JsonKey(name: 'code') required this.menuCode, @JsonKey(name: 'name') required this.menuName, @JsonKey(name: 'icon') this.menuIcon, @JsonKey(name: 'activeIcon') this.activeMenuIcon, @JsonKey(name: 'sortNo') this.sortOrder, @JsonKey(name: 'enabled') this.enabled = true, @JsonKey(name: 'categoryIds') final  List<String> categoryIds = const [], @JsonKey(name: 'rule') this.rule}): _categoryIds = categoryIds;
  factory _SidebarMenuDTO.fromJson(Map<String, dynamic> json) => _$SidebarMenuDTOFromJson(json);

@override@JsonKey(name: 'code') final  String menuCode;
@override@JsonKey(name: 'name') final  String menuName;
@override@JsonKey(name: 'icon') final  String? menuIcon;
@override@JsonKey(name: 'activeIcon') final  String? activeMenuIcon;
@override@JsonKey(name: 'sortNo') final  int? sortOrder;
@override@JsonKey(name: 'enabled') final  bool enabled;
 final  List<String> _categoryIds;
@override@JsonKey(name: 'categoryIds') List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override@JsonKey(name: 'rule') final  SidebarMenuRuleDTO? rule;

/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SidebarMenuDTOCopyWith<_SidebarMenuDTO> get copyWith => __$SidebarMenuDTOCopyWithImpl<_SidebarMenuDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SidebarMenuDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SidebarMenuDTO&&(identical(other.menuCode, menuCode) || other.menuCode == menuCode)&&(identical(other.menuName, menuName) || other.menuName == menuName)&&(identical(other.menuIcon, menuIcon) || other.menuIcon == menuIcon)&&(identical(other.activeMenuIcon, activeMenuIcon) || other.activeMenuIcon == activeMenuIcon)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.rule, rule) || other.rule == rule));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuCode,menuName,menuIcon,activeMenuIcon,sortOrder,enabled,const DeepCollectionEquality().hash(_categoryIds),rule);

@override
String toString() {
  return 'SidebarMenuDTO(menuCode: $menuCode, menuName: $menuName, menuIcon: $menuIcon, activeMenuIcon: $activeMenuIcon, sortOrder: $sortOrder, enabled: $enabled, categoryIds: $categoryIds, rule: $rule)';
}


}

/// @nodoc
abstract mixin class _$SidebarMenuDTOCopyWith<$Res> implements $SidebarMenuDTOCopyWith<$Res> {
  factory _$SidebarMenuDTOCopyWith(_SidebarMenuDTO value, $Res Function(_SidebarMenuDTO) _then) = __$SidebarMenuDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'code') String menuCode,@JsonKey(name: 'name') String menuName,@JsonKey(name: 'icon') String? menuIcon,@JsonKey(name: 'activeIcon') String? activeMenuIcon,@JsonKey(name: 'sortNo') int? sortOrder,@JsonKey(name: 'enabled') bool enabled,@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'rule') SidebarMenuRuleDTO? rule
});


@override $SidebarMenuRuleDTOCopyWith<$Res>? get rule;

}
/// @nodoc
class __$SidebarMenuDTOCopyWithImpl<$Res>
    implements _$SidebarMenuDTOCopyWith<$Res> {
  __$SidebarMenuDTOCopyWithImpl(this._self, this._then);

  final _SidebarMenuDTO _self;
  final $Res Function(_SidebarMenuDTO) _then;

/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menuCode = null,Object? menuName = null,Object? menuIcon = freezed,Object? activeMenuIcon = freezed,Object? sortOrder = freezed,Object? enabled = null,Object? categoryIds = null,Object? rule = freezed,}) {
  return _then(_SidebarMenuDTO(
menuCode: null == menuCode ? _self.menuCode : menuCode // ignore: cast_nullable_to_non_nullable
as String,menuName: null == menuName ? _self.menuName : menuName // ignore: cast_nullable_to_non_nullable
as String,menuIcon: freezed == menuIcon ? _self.menuIcon : menuIcon // ignore: cast_nullable_to_non_nullable
as String?,activeMenuIcon: freezed == activeMenuIcon ? _self.activeMenuIcon : activeMenuIcon // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: freezed == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int?,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,rule: freezed == rule ? _self.rule : rule // ignore: cast_nullable_to_non_nullable
as SidebarMenuRuleDTO?,
  ));
}

/// Create a copy of SidebarMenuDTO
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SidebarMenuRuleDTOCopyWith<$Res>? get rule {
    if (_self.rule == null) {
    return null;
  }

  return $SidebarMenuRuleDTOCopyWith<$Res>(_self.rule!, (value) {
    return _then(_self.copyWith(rule: value));
  });
}
}


/// @nodoc
mixin _$SidebarConfigResponse {

 int get code; String? get message; SidebarConfigDTO? get data;
/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SidebarConfigResponseCopyWith<SidebarConfigResponse> get copyWith => _$SidebarConfigResponseCopyWithImpl<SidebarConfigResponse>(this as SidebarConfigResponse, _$identity);

  /// Serializes this SidebarConfigResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SidebarConfigResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'SidebarConfigResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $SidebarConfigResponseCopyWith<$Res>  {
  factory $SidebarConfigResponseCopyWith(SidebarConfigResponse value, $Res Function(SidebarConfigResponse) _then) = _$SidebarConfigResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, SidebarConfigDTO? data
});


$SidebarConfigDTOCopyWith<$Res>? get data;

}
/// @nodoc
class _$SidebarConfigResponseCopyWithImpl<$Res>
    implements $SidebarConfigResponseCopyWith<$Res> {
  _$SidebarConfigResponseCopyWithImpl(this._self, this._then);

  final SidebarConfigResponse _self;
  final $Res Function(SidebarConfigResponse) _then;

/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SidebarConfigDTO?,
  ));
}
/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SidebarConfigDTOCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $SidebarConfigDTOCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// Adds pattern-matching-related methods to [SidebarConfigResponse].
extension SidebarConfigResponsePatterns on SidebarConfigResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SidebarConfigResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SidebarConfigResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SidebarConfigResponse value)  $default,){
final _that = this;
switch (_that) {
case _SidebarConfigResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SidebarConfigResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SidebarConfigResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  SidebarConfigDTO? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SidebarConfigResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  SidebarConfigDTO? data)  $default,) {final _that = this;
switch (_that) {
case _SidebarConfigResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  SidebarConfigDTO? data)?  $default,) {final _that = this;
switch (_that) {
case _SidebarConfigResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SidebarConfigResponse implements SidebarConfigResponse {
  const _SidebarConfigResponse({required this.code, this.message, this.data});
  factory _SidebarConfigResponse.fromJson(Map<String, dynamic> json) => _$SidebarConfigResponseFromJson(json);

@override final  int code;
@override final  String? message;
@override final  SidebarConfigDTO? data;

/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SidebarConfigResponseCopyWith<_SidebarConfigResponse> get copyWith => __$SidebarConfigResponseCopyWithImpl<_SidebarConfigResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SidebarConfigResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SidebarConfigResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.data, data) || other.data == data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,data);

@override
String toString() {
  return 'SidebarConfigResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$SidebarConfigResponseCopyWith<$Res> implements $SidebarConfigResponseCopyWith<$Res> {
  factory _$SidebarConfigResponseCopyWith(_SidebarConfigResponse value, $Res Function(_SidebarConfigResponse) _then) = __$SidebarConfigResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, SidebarConfigDTO? data
});


@override $SidebarConfigDTOCopyWith<$Res>? get data;

}
/// @nodoc
class __$SidebarConfigResponseCopyWithImpl<$Res>
    implements _$SidebarConfigResponseCopyWith<$Res> {
  __$SidebarConfigResponseCopyWithImpl(this._self, this._then);

  final _SidebarConfigResponse _self;
  final $Res Function(_SidebarConfigResponse) _then;

/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = freezed,}) {
  return _then(_SidebarConfigResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as SidebarConfigDTO?,
  ));
}

/// Create a copy of SidebarConfigResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SidebarConfigDTOCopyWith<$Res>? get data {
    if (_self.data == null) {
    return null;
  }

  return $SidebarConfigDTOCopyWith<$Res>(_self.data!, (value) {
    return _then(_self.copyWith(data: value));
  });
}
}


/// @nodoc
mixin _$SidebarConfigDTO {

@JsonKey(name: 'menus') List<SidebarMenuDTO> get menus;
/// Create a copy of SidebarConfigDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SidebarConfigDTOCopyWith<SidebarConfigDTO> get copyWith => _$SidebarConfigDTOCopyWithImpl<SidebarConfigDTO>(this as SidebarConfigDTO, _$identity);

  /// Serializes this SidebarConfigDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SidebarConfigDTO&&const DeepCollectionEquality().equals(other.menus, menus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(menus));

@override
String toString() {
  return 'SidebarConfigDTO(menus: $menus)';
}


}

/// @nodoc
abstract mixin class $SidebarConfigDTOCopyWith<$Res>  {
  factory $SidebarConfigDTOCopyWith(SidebarConfigDTO value, $Res Function(SidebarConfigDTO) _then) = _$SidebarConfigDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'menus') List<SidebarMenuDTO> menus
});




}
/// @nodoc
class _$SidebarConfigDTOCopyWithImpl<$Res>
    implements $SidebarConfigDTOCopyWith<$Res> {
  _$SidebarConfigDTOCopyWithImpl(this._self, this._then);

  final SidebarConfigDTO _self;
  final $Res Function(SidebarConfigDTO) _then;

/// Create a copy of SidebarConfigDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menus = null,}) {
  return _then(_self.copyWith(
menus: null == menus ? _self.menus : menus // ignore: cast_nullable_to_non_nullable
as List<SidebarMenuDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SidebarConfigDTO].
extension SidebarConfigDTOPatterns on SidebarConfigDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SidebarConfigDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SidebarConfigDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SidebarConfigDTO value)  $default,){
final _that = this;
switch (_that) {
case _SidebarConfigDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SidebarConfigDTO value)?  $default,){
final _that = this;
switch (_that) {
case _SidebarConfigDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'menus')  List<SidebarMenuDTO> menus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SidebarConfigDTO() when $default != null:
return $default(_that.menus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'menus')  List<SidebarMenuDTO> menus)  $default,) {final _that = this;
switch (_that) {
case _SidebarConfigDTO():
return $default(_that.menus);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'menus')  List<SidebarMenuDTO> menus)?  $default,) {final _that = this;
switch (_that) {
case _SidebarConfigDTO() when $default != null:
return $default(_that.menus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SidebarConfigDTO implements SidebarConfigDTO {
  const _SidebarConfigDTO({@JsonKey(name: 'menus') final  List<SidebarMenuDTO> menus = const []}): _menus = menus;
  factory _SidebarConfigDTO.fromJson(Map<String, dynamic> json) => _$SidebarConfigDTOFromJson(json);

 final  List<SidebarMenuDTO> _menus;
@override@JsonKey(name: 'menus') List<SidebarMenuDTO> get menus {
  if (_menus is EqualUnmodifiableListView) return _menus;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_menus);
}


/// Create a copy of SidebarConfigDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SidebarConfigDTOCopyWith<_SidebarConfigDTO> get copyWith => __$SidebarConfigDTOCopyWithImpl<_SidebarConfigDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SidebarConfigDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SidebarConfigDTO&&const DeepCollectionEquality().equals(other._menus, _menus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_menus));

@override
String toString() {
  return 'SidebarConfigDTO(menus: $menus)';
}


}

/// @nodoc
abstract mixin class _$SidebarConfigDTOCopyWith<$Res> implements $SidebarConfigDTOCopyWith<$Res> {
  factory _$SidebarConfigDTOCopyWith(_SidebarConfigDTO value, $Res Function(_SidebarConfigDTO) _then) = __$SidebarConfigDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'menus') List<SidebarMenuDTO> menus
});




}
/// @nodoc
class __$SidebarConfigDTOCopyWithImpl<$Res>
    implements _$SidebarConfigDTOCopyWith<$Res> {
  __$SidebarConfigDTOCopyWithImpl(this._self, this._then);

  final _SidebarConfigDTO _self;
  final $Res Function(_SidebarConfigDTO) _then;

/// Create a copy of SidebarConfigDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menus = null,}) {
  return _then(_SidebarConfigDTO(
menus: null == menus ? _self._menus : menus // ignore: cast_nullable_to_non_nullable
as List<SidebarMenuDTO>,
  ));
}


}


/// @nodoc
mixin _$SidebarAppsRequest {

@JsonKey(name: 'menuCode') String get menuCode;@JsonKey(name: 'pageNo') int get pageNo;@JsonKey(name: 'pageSize') int get pageSize;@JsonKey(name: 'repoName') String get repoName; String? get arch; String? get lan;@JsonKey(name: 'sortType') String? get sortType;@JsonKey(name: 'filter') bool? get filter;
/// Create a copy of SidebarAppsRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SidebarAppsRequestCopyWith<SidebarAppsRequest> get copyWith => _$SidebarAppsRequestCopyWithImpl<SidebarAppsRequest>(this as SidebarAppsRequest, _$identity);

  /// Serializes this SidebarAppsRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SidebarAppsRequest&&(identical(other.menuCode, menuCode) || other.menuCode == menuCode)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sortType, sortType) || other.sortType == sortType)&&(identical(other.filter, filter) || other.filter == filter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuCode,pageNo,pageSize,repoName,arch,lan,sortType,filter);

@override
String toString() {
  return 'SidebarAppsRequest(menuCode: $menuCode, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sortType: $sortType, filter: $filter)';
}


}

/// @nodoc
abstract mixin class $SidebarAppsRequestCopyWith<$Res>  {
  factory $SidebarAppsRequestCopyWith(SidebarAppsRequest value, $Res Function(SidebarAppsRequest) _then) = _$SidebarAppsRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'menuCode') String menuCode,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan,@JsonKey(name: 'sortType') String? sortType,@JsonKey(name: 'filter') bool? filter
});




}
/// @nodoc
class _$SidebarAppsRequestCopyWithImpl<$Res>
    implements $SidebarAppsRequestCopyWith<$Res> {
  _$SidebarAppsRequestCopyWithImpl(this._self, this._then);

  final SidebarAppsRequest _self;
  final $Res Function(SidebarAppsRequest) _then;

/// Create a copy of SidebarAppsRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menuCode = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sortType = freezed,Object? filter = freezed,}) {
  return _then(_self.copyWith(
menuCode: null == menuCode ? _self.menuCode : menuCode // ignore: cast_nullable_to_non_nullable
as String,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sortType: freezed == sortType ? _self.sortType : sortType // ignore: cast_nullable_to_non_nullable
as String?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SidebarAppsRequest].
extension SidebarAppsRequestPatterns on SidebarAppsRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SidebarAppsRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SidebarAppsRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SidebarAppsRequest value)  $default,){
final _that = this;
switch (_that) {
case _SidebarAppsRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SidebarAppsRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SidebarAppsRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'menuCode')  String menuCode, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan, @JsonKey(name: 'sortType')  String? sortType, @JsonKey(name: 'filter')  bool? filter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SidebarAppsRequest() when $default != null:
return $default(_that.menuCode,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sortType,_that.filter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'menuCode')  String menuCode, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan, @JsonKey(name: 'sortType')  String? sortType, @JsonKey(name: 'filter')  bool? filter)  $default,) {final _that = this;
switch (_that) {
case _SidebarAppsRequest():
return $default(_that.menuCode,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sortType,_that.filter);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'menuCode')  String menuCode, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan, @JsonKey(name: 'sortType')  String? sortType, @JsonKey(name: 'filter')  bool? filter)?  $default,) {final _that = this;
switch (_that) {
case _SidebarAppsRequest() when $default != null:
return $default(_that.menuCode,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sortType,_that.filter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SidebarAppsRequest implements SidebarAppsRequest {
  const _SidebarAppsRequest({@JsonKey(name: 'menuCode') required this.menuCode, @JsonKey(name: 'pageNo') this.pageNo = 1, @JsonKey(name: 'pageSize') this.pageSize = 20, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, this.lan, @JsonKey(name: 'sortType') this.sortType, @JsonKey(name: 'filter') this.filter});
  factory _SidebarAppsRequest.fromJson(Map<String, dynamic> json) => _$SidebarAppsRequestFromJson(json);

@override@JsonKey(name: 'menuCode') final  String menuCode;
@override@JsonKey(name: 'pageNo') final  int pageNo;
@override@JsonKey(name: 'pageSize') final  int pageSize;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override final  String? lan;
@override@JsonKey(name: 'sortType') final  String? sortType;
@override@JsonKey(name: 'filter') final  bool? filter;

/// Create a copy of SidebarAppsRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SidebarAppsRequestCopyWith<_SidebarAppsRequest> get copyWith => __$SidebarAppsRequestCopyWithImpl<_SidebarAppsRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SidebarAppsRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SidebarAppsRequest&&(identical(other.menuCode, menuCode) || other.menuCode == menuCode)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sortType, sortType) || other.sortType == sortType)&&(identical(other.filter, filter) || other.filter == filter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuCode,pageNo,pageSize,repoName,arch,lan,sortType,filter);

@override
String toString() {
  return 'SidebarAppsRequest(menuCode: $menuCode, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sortType: $sortType, filter: $filter)';
}


}

/// @nodoc
abstract mixin class _$SidebarAppsRequestCopyWith<$Res> implements $SidebarAppsRequestCopyWith<$Res> {
  factory _$SidebarAppsRequestCopyWith(_SidebarAppsRequest value, $Res Function(_SidebarAppsRequest) _then) = __$SidebarAppsRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'menuCode') String menuCode,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan,@JsonKey(name: 'sortType') String? sortType,@JsonKey(name: 'filter') bool? filter
});




}
/// @nodoc
class __$SidebarAppsRequestCopyWithImpl<$Res>
    implements _$SidebarAppsRequestCopyWith<$Res> {
  __$SidebarAppsRequestCopyWithImpl(this._self, this._then);

  final _SidebarAppsRequest _self;
  final $Res Function(_SidebarAppsRequest) _then;

/// Create a copy of SidebarAppsRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menuCode = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sortType = freezed,Object? filter = freezed,}) {
  return _then(_SidebarAppsRequest(
menuCode: null == menuCode ? _self.menuCode : menuCode // ignore: cast_nullable_to_non_nullable
as String,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sortType: freezed == sortType ? _self.sortType : sortType // ignore: cast_nullable_to_non_nullable
as String?,filter: freezed == filter ? _self.filter : filter // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$CustomMenuCategoryDTO {

@JsonKey(name: 'menuId') String get menuId;@JsonKey(name: 'menuName') String get menuName;@JsonKey(name: 'menuIcon') String? get menuIcon;@JsonKey(name: 'categoryIds') List<String> get categoryIds;@JsonKey(name: 'sort') int? get sort;
/// Create a copy of CustomMenuCategoryDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomMenuCategoryDTOCopyWith<CustomMenuCategoryDTO> get copyWith => _$CustomMenuCategoryDTOCopyWithImpl<CustomMenuCategoryDTO>(this as CustomMenuCategoryDTO, _$identity);

  /// Serializes this CustomMenuCategoryDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomMenuCategoryDTO&&(identical(other.menuId, menuId) || other.menuId == menuId)&&(identical(other.menuName, menuName) || other.menuName == menuName)&&(identical(other.menuIcon, menuIcon) || other.menuIcon == menuIcon)&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuId,menuName,menuIcon,const DeepCollectionEquality().hash(categoryIds),sort);

@override
String toString() {
  return 'CustomMenuCategoryDTO(menuId: $menuId, menuName: $menuName, menuIcon: $menuIcon, categoryIds: $categoryIds, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $CustomMenuCategoryDTOCopyWith<$Res>  {
  factory $CustomMenuCategoryDTOCopyWith(CustomMenuCategoryDTO value, $Res Function(CustomMenuCategoryDTO) _then) = _$CustomMenuCategoryDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'menuId') String menuId,@JsonKey(name: 'menuName') String menuName,@JsonKey(name: 'menuIcon') String? menuIcon,@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class _$CustomMenuCategoryDTOCopyWithImpl<$Res>
    implements $CustomMenuCategoryDTOCopyWith<$Res> {
  _$CustomMenuCategoryDTOCopyWithImpl(this._self, this._then);

  final CustomMenuCategoryDTO _self;
  final $Res Function(CustomMenuCategoryDTO) _then;

/// Create a copy of CustomMenuCategoryDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? menuId = null,Object? menuName = null,Object? menuIcon = freezed,Object? categoryIds = null,Object? sort = freezed,}) {
  return _then(_self.copyWith(
menuId: null == menuId ? _self.menuId : menuId // ignore: cast_nullable_to_non_nullable
as String,menuName: null == menuName ? _self.menuName : menuName // ignore: cast_nullable_to_non_nullable
as String,menuIcon: freezed == menuIcon ? _self.menuIcon : menuIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomMenuCategoryDTO].
extension CustomMenuCategoryDTOPatterns on CustomMenuCategoryDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomMenuCategoryDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomMenuCategoryDTO value)  $default,){
final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomMenuCategoryDTO value)?  $default,){
final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'menuId')  String menuId, @JsonKey(name: 'menuName')  String menuName, @JsonKey(name: 'menuIcon')  String? menuIcon, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'sort')  int? sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO() when $default != null:
return $default(_that.menuId,_that.menuName,_that.menuIcon,_that.categoryIds,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'menuId')  String menuId, @JsonKey(name: 'menuName')  String menuName, @JsonKey(name: 'menuIcon')  String? menuIcon, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'sort')  int? sort)  $default,) {final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO():
return $default(_that.menuId,_that.menuName,_that.menuIcon,_that.categoryIds,_that.sort);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'menuId')  String menuId, @JsonKey(name: 'menuName')  String menuName, @JsonKey(name: 'menuIcon')  String? menuIcon, @JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'sort')  int? sort)?  $default,) {final _that = this;
switch (_that) {
case _CustomMenuCategoryDTO() when $default != null:
return $default(_that.menuId,_that.menuName,_that.menuIcon,_that.categoryIds,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomMenuCategoryDTO implements CustomMenuCategoryDTO {
  const _CustomMenuCategoryDTO({@JsonKey(name: 'menuId') required this.menuId, @JsonKey(name: 'menuName') required this.menuName, @JsonKey(name: 'menuIcon') this.menuIcon, @JsonKey(name: 'categoryIds') required final  List<String> categoryIds, @JsonKey(name: 'sort') this.sort}): _categoryIds = categoryIds;
  factory _CustomMenuCategoryDTO.fromJson(Map<String, dynamic> json) => _$CustomMenuCategoryDTOFromJson(json);

@override@JsonKey(name: 'menuId') final  String menuId;
@override@JsonKey(name: 'menuName') final  String menuName;
@override@JsonKey(name: 'menuIcon') final  String? menuIcon;
 final  List<String> _categoryIds;
@override@JsonKey(name: 'categoryIds') List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override@JsonKey(name: 'sort') final  int? sort;

/// Create a copy of CustomMenuCategoryDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomMenuCategoryDTOCopyWith<_CustomMenuCategoryDTO> get copyWith => __$CustomMenuCategoryDTOCopyWithImpl<_CustomMenuCategoryDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomMenuCategoryDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomMenuCategoryDTO&&(identical(other.menuId, menuId) || other.menuId == menuId)&&(identical(other.menuName, menuName) || other.menuName == menuName)&&(identical(other.menuIcon, menuIcon) || other.menuIcon == menuIcon)&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,menuId,menuName,menuIcon,const DeepCollectionEquality().hash(_categoryIds),sort);

@override
String toString() {
  return 'CustomMenuCategoryDTO(menuId: $menuId, menuName: $menuName, menuIcon: $menuIcon, categoryIds: $categoryIds, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$CustomMenuCategoryDTOCopyWith<$Res> implements $CustomMenuCategoryDTOCopyWith<$Res> {
  factory _$CustomMenuCategoryDTOCopyWith(_CustomMenuCategoryDTO value, $Res Function(_CustomMenuCategoryDTO) _then) = __$CustomMenuCategoryDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'menuId') String menuId,@JsonKey(name: 'menuName') String menuName,@JsonKey(name: 'menuIcon') String? menuIcon,@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'sort') int? sort
});




}
/// @nodoc
class __$CustomMenuCategoryDTOCopyWithImpl<$Res>
    implements _$CustomMenuCategoryDTOCopyWith<$Res> {
  __$CustomMenuCategoryDTOCopyWithImpl(this._self, this._then);

  final _CustomMenuCategoryDTO _self;
  final $Res Function(_CustomMenuCategoryDTO) _then;

/// Create a copy of CustomMenuCategoryDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? menuId = null,Object? menuName = null,Object? menuIcon = freezed,Object? categoryIds = null,Object? sort = freezed,}) {
  return _then(_CustomMenuCategoryDTO(
menuId: null == menuId ? _self.menuId : menuId // ignore: cast_nullable_to_non_nullable
as String,menuName: null == menuName ? _self.menuName : menuName // ignore: cast_nullable_to_non_nullable
as String,menuIcon: freezed == menuIcon ? _self.menuIcon : menuIcon // ignore: cast_nullable_to_non_nullable
as String?,categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$CustomMenuCategoryResponse {

 int get code; String? get message; List<CustomMenuCategoryDTO> get data;
/// Create a copy of CustomMenuCategoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomMenuCategoryResponseCopyWith<CustomMenuCategoryResponse> get copyWith => _$CustomMenuCategoryResponseCopyWithImpl<CustomMenuCategoryResponse>(this as CustomMenuCategoryResponse, _$identity);

  /// Serializes this CustomMenuCategoryResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomMenuCategoryResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'CustomMenuCategoryResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class $CustomMenuCategoryResponseCopyWith<$Res>  {
  factory $CustomMenuCategoryResponseCopyWith(CustomMenuCategoryResponse value, $Res Function(CustomMenuCategoryResponse) _then) = _$CustomMenuCategoryResponseCopyWithImpl;
@useResult
$Res call({
 int code, String? message, List<CustomMenuCategoryDTO> data
});




}
/// @nodoc
class _$CustomMenuCategoryResponseCopyWithImpl<$Res>
    implements $CustomMenuCategoryResponseCopyWith<$Res> {
  _$CustomMenuCategoryResponseCopyWithImpl(this._self, this._then);

  final CustomMenuCategoryResponse _self;
  final $Res Function(CustomMenuCategoryResponse) _then;

/// Create a copy of CustomMenuCategoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as List<CustomMenuCategoryDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomMenuCategoryResponse].
extension CustomMenuCategoryResponsePatterns on CustomMenuCategoryResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomMenuCategoryResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomMenuCategoryResponse value)  $default,){
final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomMenuCategoryResponse value)?  $default,){
final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  String? message,  List<CustomMenuCategoryDTO> data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  String? message,  List<CustomMenuCategoryDTO> data)  $default,) {final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse():
return $default(_that.code,_that.message,_that.data);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  String? message,  List<CustomMenuCategoryDTO> data)?  $default,) {final _that = this;
switch (_that) {
case _CustomMenuCategoryResponse() when $default != null:
return $default(_that.code,_that.message,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomMenuCategoryResponse implements CustomMenuCategoryResponse {
  const _CustomMenuCategoryResponse({required this.code, this.message, required final  List<CustomMenuCategoryDTO> data}): _data = data;
  factory _CustomMenuCategoryResponse.fromJson(Map<String, dynamic> json) => _$CustomMenuCategoryResponseFromJson(json);

@override final  int code;
@override final  String? message;
 final  List<CustomMenuCategoryDTO> _data;
@override List<CustomMenuCategoryDTO> get data {
  if (_data is EqualUnmodifiableListView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_data);
}


/// Create a copy of CustomMenuCategoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomMenuCategoryResponseCopyWith<_CustomMenuCategoryResponse> get copyWith => __$CustomMenuCategoryResponseCopyWithImpl<_CustomMenuCategoryResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomMenuCategoryResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomMenuCategoryResponse&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._data, _data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,const DeepCollectionEquality().hash(_data));

@override
String toString() {
  return 'CustomMenuCategoryResponse(code: $code, message: $message, data: $data)';
}


}

/// @nodoc
abstract mixin class _$CustomMenuCategoryResponseCopyWith<$Res> implements $CustomMenuCategoryResponseCopyWith<$Res> {
  factory _$CustomMenuCategoryResponseCopyWith(_CustomMenuCategoryResponse value, $Res Function(_CustomMenuCategoryResponse) _then) = __$CustomMenuCategoryResponseCopyWithImpl;
@override @useResult
$Res call({
 int code, String? message, List<CustomMenuCategoryDTO> data
});




}
/// @nodoc
class __$CustomMenuCategoryResponseCopyWithImpl<$Res>
    implements _$CustomMenuCategoryResponseCopyWith<$Res> {
  __$CustomMenuCategoryResponseCopyWithImpl(this._self, this._then);

  final _CustomMenuCategoryResponse _self;
  final $Res Function(_CustomMenuCategoryResponse) _then;

/// Create a copy of CustomMenuCategoryResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = freezed,Object? data = null,}) {
  return _then(_CustomMenuCategoryResponse(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as List<CustomMenuCategoryDTO>,
  ));
}


}


/// @nodoc
mixin _$AppsByCategoryRequest {

@JsonKey(name: 'categoryIds') List<String> get categoryIds;@JsonKey(name: 'pageNo') int get pageNo;@JsonKey(name: 'pageSize') int get pageSize;@JsonKey(name: 'repoName') String get repoName; String? get arch; String? get lan; String? get sort; String? get order;
/// Create a copy of AppsByCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppsByCategoryRequestCopyWith<AppsByCategoryRequest> get copyWith => _$AppsByCategoryRequestCopyWithImpl<AppsByCategoryRequest>(this as AppsByCategoryRequest, _$identity);

  /// Serializes this AppsByCategoryRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppsByCategoryRequest&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIds),pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'AppsByCategoryRequest(categoryIds: $categoryIds, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class $AppsByCategoryRequestCopyWith<$Res>  {
  factory $AppsByCategoryRequestCopyWith(AppsByCategoryRequest value, $Res Function(AppsByCategoryRequest) _then) = _$AppsByCategoryRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class _$AppsByCategoryRequestCopyWithImpl<$Res>
    implements $AppsByCategoryRequestCopyWith<$Res> {
  _$AppsByCategoryRequestCopyWithImpl(this._self, this._then);

  final AppsByCategoryRequest _self;
  final $Res Function(AppsByCategoryRequest) _then;

/// Create a copy of AppsByCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIds = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_self.copyWith(
categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppsByCategoryRequest].
extension AppsByCategoryRequestPatterns on AppsByCategoryRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppsByCategoryRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppsByCategoryRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppsByCategoryRequest value)  $default,){
final _that = this;
switch (_that) {
case _AppsByCategoryRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppsByCategoryRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AppsByCategoryRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppsByCategoryRequest() when $default != null:
return $default(_that.categoryIds,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)  $default,) {final _that = this;
switch (_that) {
case _AppsByCategoryRequest():
return $default(_that.categoryIds,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'categoryIds')  List<String> categoryIds, @JsonKey(name: 'pageNo')  int pageNo, @JsonKey(name: 'pageSize')  int pageSize, @JsonKey(name: 'repoName')  String repoName,  String? arch,  String? lan,  String? sort,  String? order)?  $default,) {final _that = this;
switch (_that) {
case _AppsByCategoryRequest() when $default != null:
return $default(_that.categoryIds,_that.pageNo,_that.pageSize,_that.repoName,_that.arch,_that.lan,_that.sort,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppsByCategoryRequest implements AppsByCategoryRequest {
  const _AppsByCategoryRequest({@JsonKey(name: 'categoryIds') required final  List<String> categoryIds, @JsonKey(name: 'pageNo') this.pageNo = 1, @JsonKey(name: 'pageSize') this.pageSize = 20, @JsonKey(name: 'repoName') this.repoName = AppConfig.defaultStoreRepoName, this.arch, this.lan, this.sort, this.order}): _categoryIds = categoryIds;
  factory _AppsByCategoryRequest.fromJson(Map<String, dynamic> json) => _$AppsByCategoryRequestFromJson(json);

 final  List<String> _categoryIds;
@override@JsonKey(name: 'categoryIds') List<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableListView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categoryIds);
}

@override@JsonKey(name: 'pageNo') final  int pageNo;
@override@JsonKey(name: 'pageSize') final  int pageSize;
@override@JsonKey(name: 'repoName') final  String repoName;
@override final  String? arch;
@override final  String? lan;
@override final  String? sort;
@override final  String? order;

/// Create a copy of AppsByCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppsByCategoryRequestCopyWith<_AppsByCategoryRequest> get copyWith => __$AppsByCategoryRequestCopyWithImpl<_AppsByCategoryRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppsByCategoryRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppsByCategoryRequest&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.pageNo, pageNo) || other.pageNo == pageNo)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.lan, lan) || other.lan == lan)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIds),pageNo,pageSize,repoName,arch,lan,sort,order);

@override
String toString() {
  return 'AppsByCategoryRequest(categoryIds: $categoryIds, pageNo: $pageNo, pageSize: $pageSize, repoName: $repoName, arch: $arch, lan: $lan, sort: $sort, order: $order)';
}


}

/// @nodoc
abstract mixin class _$AppsByCategoryRequestCopyWith<$Res> implements $AppsByCategoryRequestCopyWith<$Res> {
  factory _$AppsByCategoryRequestCopyWith(_AppsByCategoryRequest value, $Res Function(_AppsByCategoryRequest) _then) = __$AppsByCategoryRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'categoryIds') List<String> categoryIds,@JsonKey(name: 'pageNo') int pageNo,@JsonKey(name: 'pageSize') int pageSize,@JsonKey(name: 'repoName') String repoName, String? arch, String? lan, String? sort, String? order
});




}
/// @nodoc
class __$AppsByCategoryRequestCopyWithImpl<$Res>
    implements _$AppsByCategoryRequestCopyWith<$Res> {
  __$AppsByCategoryRequestCopyWithImpl(this._self, this._then);

  final _AppsByCategoryRequest _self;
  final $Res Function(_AppsByCategoryRequest) _then;

/// Create a copy of AppsByCategoryRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIds = null,Object? pageNo = null,Object? pageSize = null,Object? repoName = null,Object? arch = freezed,Object? lan = freezed,Object? sort = freezed,Object? order = freezed,}) {
  return _then(_AppsByCategoryRequest(
categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as List<String>,pageNo: null == pageNo ? _self.pageNo : pageNo // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,repoName: null == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,lan: freezed == lan ? _self.lan : lan // ignore: cast_nullable_to_non_nullable
as String?,sort: freezed == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as String?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SaveVisitRecordRequest {

@JsonKey(name: 'visitorId') String? get visitorId;@JsonKey(name: 'clientIp') String? get clientIp;@JsonKey(name: 'arch') String? get arch;@JsonKey(name: 'llVersion') String? get llVersion;@JsonKey(name: 'llBinVersion') String? get llBinVersion;@JsonKey(name: 'detailMsg') String? get detailMsg;@JsonKey(name: 'osVersion') String? get osVersion;@JsonKey(name: 'repoName') String? get repoName;@JsonKey(name: 'appVersion') String? get appVersion;
/// Create a copy of SaveVisitRecordRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveVisitRecordRequestCopyWith<SaveVisitRecordRequest> get copyWith => _$SaveVisitRecordRequestCopyWithImpl<SaveVisitRecordRequest>(this as SaveVisitRecordRequest, _$identity);

  /// Serializes this SaveVisitRecordRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveVisitRecordRequest&&(identical(other.visitorId, visitorId) || other.visitorId == visitorId)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.llVersion, llVersion) || other.llVersion == llVersion)&&(identical(other.llBinVersion, llBinVersion) || other.llBinVersion == llBinVersion)&&(identical(other.detailMsg, detailMsg) || other.detailMsg == detailMsg)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitorId,clientIp,arch,llVersion,llBinVersion,detailMsg,osVersion,repoName,appVersion);

@override
String toString() {
  return 'SaveVisitRecordRequest(visitorId: $visitorId, clientIp: $clientIp, arch: $arch, llVersion: $llVersion, llBinVersion: $llBinVersion, detailMsg: $detailMsg, osVersion: $osVersion, repoName: $repoName, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class $SaveVisitRecordRequestCopyWith<$Res>  {
  factory $SaveVisitRecordRequestCopyWith(SaveVisitRecordRequest value, $Res Function(SaveVisitRecordRequest) _then) = _$SaveVisitRecordRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'visitorId') String? visitorId,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'arch') String? arch,@JsonKey(name: 'llVersion') String? llVersion,@JsonKey(name: 'llBinVersion') String? llBinVersion,@JsonKey(name: 'detailMsg') String? detailMsg,@JsonKey(name: 'osVersion') String? osVersion,@JsonKey(name: 'repoName') String? repoName,@JsonKey(name: 'appVersion') String? appVersion
});




}
/// @nodoc
class _$SaveVisitRecordRequestCopyWithImpl<$Res>
    implements $SaveVisitRecordRequestCopyWith<$Res> {
  _$SaveVisitRecordRequestCopyWithImpl(this._self, this._then);

  final SaveVisitRecordRequest _self;
  final $Res Function(SaveVisitRecordRequest) _then;

/// Create a copy of SaveVisitRecordRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visitorId = freezed,Object? clientIp = freezed,Object? arch = freezed,Object? llVersion = freezed,Object? llBinVersion = freezed,Object? detailMsg = freezed,Object? osVersion = freezed,Object? repoName = freezed,Object? appVersion = freezed,}) {
  return _then(_self.copyWith(
visitorId: freezed == visitorId ? _self.visitorId : visitorId // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,llVersion: freezed == llVersion ? _self.llVersion : llVersion // ignore: cast_nullable_to_non_nullable
as String?,llBinVersion: freezed == llBinVersion ? _self.llBinVersion : llBinVersion // ignore: cast_nullable_to_non_nullable
as String?,detailMsg: freezed == detailMsg ? _self.detailMsg : detailMsg // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SaveVisitRecordRequest].
extension SaveVisitRecordRequestPatterns on SaveVisitRecordRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveVisitRecordRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveVisitRecordRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveVisitRecordRequest value)  $default,){
final _that = this;
switch (_that) {
case _SaveVisitRecordRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveVisitRecordRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SaveVisitRecordRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'llVersion')  String? llVersion, @JsonKey(name: 'llBinVersion')  String? llBinVersion, @JsonKey(name: 'detailMsg')  String? detailMsg, @JsonKey(name: 'osVersion')  String? osVersion, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'appVersion')  String? appVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveVisitRecordRequest() when $default != null:
return $default(_that.visitorId,_that.clientIp,_that.arch,_that.llVersion,_that.llBinVersion,_that.detailMsg,_that.osVersion,_that.repoName,_that.appVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'llVersion')  String? llVersion, @JsonKey(name: 'llBinVersion')  String? llBinVersion, @JsonKey(name: 'detailMsg')  String? detailMsg, @JsonKey(name: 'osVersion')  String? osVersion, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'appVersion')  String? appVersion)  $default,) {final _that = this;
switch (_that) {
case _SaveVisitRecordRequest():
return $default(_that.visitorId,_that.clientIp,_that.arch,_that.llVersion,_that.llBinVersion,_that.detailMsg,_that.osVersion,_that.repoName,_that.appVersion);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'llVersion')  String? llVersion, @JsonKey(name: 'llBinVersion')  String? llBinVersion, @JsonKey(name: 'detailMsg')  String? detailMsg, @JsonKey(name: 'osVersion')  String? osVersion, @JsonKey(name: 'repoName')  String? repoName, @JsonKey(name: 'appVersion')  String? appVersion)?  $default,) {final _that = this;
switch (_that) {
case _SaveVisitRecordRequest() when $default != null:
return $default(_that.visitorId,_that.clientIp,_that.arch,_that.llVersion,_that.llBinVersion,_that.detailMsg,_that.osVersion,_that.repoName,_that.appVersion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveVisitRecordRequest implements SaveVisitRecordRequest {
  const _SaveVisitRecordRequest({@JsonKey(name: 'visitorId') this.visitorId, @JsonKey(name: 'clientIp') this.clientIp, @JsonKey(name: 'arch') this.arch, @JsonKey(name: 'llVersion') this.llVersion, @JsonKey(name: 'llBinVersion') this.llBinVersion, @JsonKey(name: 'detailMsg') this.detailMsg, @JsonKey(name: 'osVersion') this.osVersion, @JsonKey(name: 'repoName') this.repoName, @JsonKey(name: 'appVersion') this.appVersion});
  factory _SaveVisitRecordRequest.fromJson(Map<String, dynamic> json) => _$SaveVisitRecordRequestFromJson(json);

@override@JsonKey(name: 'visitorId') final  String? visitorId;
@override@JsonKey(name: 'clientIp') final  String? clientIp;
@override@JsonKey(name: 'arch') final  String? arch;
@override@JsonKey(name: 'llVersion') final  String? llVersion;
@override@JsonKey(name: 'llBinVersion') final  String? llBinVersion;
@override@JsonKey(name: 'detailMsg') final  String? detailMsg;
@override@JsonKey(name: 'osVersion') final  String? osVersion;
@override@JsonKey(name: 'repoName') final  String? repoName;
@override@JsonKey(name: 'appVersion') final  String? appVersion;

/// Create a copy of SaveVisitRecordRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveVisitRecordRequestCopyWith<_SaveVisitRecordRequest> get copyWith => __$SaveVisitRecordRequestCopyWithImpl<_SaveVisitRecordRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveVisitRecordRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveVisitRecordRequest&&(identical(other.visitorId, visitorId) || other.visitorId == visitorId)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.llVersion, llVersion) || other.llVersion == llVersion)&&(identical(other.llBinVersion, llBinVersion) || other.llBinVersion == llBinVersion)&&(identical(other.detailMsg, detailMsg) || other.detailMsg == detailMsg)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&(identical(other.appVersion, appVersion) || other.appVersion == appVersion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitorId,clientIp,arch,llVersion,llBinVersion,detailMsg,osVersion,repoName,appVersion);

@override
String toString() {
  return 'SaveVisitRecordRequest(visitorId: $visitorId, clientIp: $clientIp, arch: $arch, llVersion: $llVersion, llBinVersion: $llBinVersion, detailMsg: $detailMsg, osVersion: $osVersion, repoName: $repoName, appVersion: $appVersion)';
}


}

/// @nodoc
abstract mixin class _$SaveVisitRecordRequestCopyWith<$Res> implements $SaveVisitRecordRequestCopyWith<$Res> {
  factory _$SaveVisitRecordRequestCopyWith(_SaveVisitRecordRequest value, $Res Function(_SaveVisitRecordRequest) _then) = __$SaveVisitRecordRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'visitorId') String? visitorId,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'arch') String? arch,@JsonKey(name: 'llVersion') String? llVersion,@JsonKey(name: 'llBinVersion') String? llBinVersion,@JsonKey(name: 'detailMsg') String? detailMsg,@JsonKey(name: 'osVersion') String? osVersion,@JsonKey(name: 'repoName') String? repoName,@JsonKey(name: 'appVersion') String? appVersion
});




}
/// @nodoc
class __$SaveVisitRecordRequestCopyWithImpl<$Res>
    implements _$SaveVisitRecordRequestCopyWith<$Res> {
  __$SaveVisitRecordRequestCopyWithImpl(this._self, this._then);

  final _SaveVisitRecordRequest _self;
  final $Res Function(_SaveVisitRecordRequest) _then;

/// Create a copy of SaveVisitRecordRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visitorId = freezed,Object? clientIp = freezed,Object? arch = freezed,Object? llVersion = freezed,Object? llBinVersion = freezed,Object? detailMsg = freezed,Object? osVersion = freezed,Object? repoName = freezed,Object? appVersion = freezed,}) {
  return _then(_SaveVisitRecordRequest(
visitorId: freezed == visitorId ? _self.visitorId : visitorId // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,llVersion: freezed == llVersion ? _self.llVersion : llVersion // ignore: cast_nullable_to_non_nullable
as String?,llBinVersion: freezed == llBinVersion ? _self.llBinVersion : llBinVersion // ignore: cast_nullable_to_non_nullable
as String?,detailMsg: freezed == detailMsg ? _self.detailMsg : detailMsg // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,appVersion: freezed == appVersion ? _self.appVersion : appVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InstalledRecordItemDTO {

@JsonKey(name: 'appId') String? get appId;@JsonKey(name: 'name') String? get name;@JsonKey(name: 'version') String? get version;@JsonKey(name: 'arch') String? get arch;@JsonKey(name: 'module') String? get module;@JsonKey(name: 'channel') String? get channel;
/// Create a copy of InstalledRecordItemDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstalledRecordItemDTOCopyWith<InstalledRecordItemDTO> get copyWith => _$InstalledRecordItemDTOCopyWithImpl<InstalledRecordItemDTO>(this as InstalledRecordItemDTO, _$identity);

  /// Serializes this InstalledRecordItemDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstalledRecordItemDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,arch,module,channel);

@override
String toString() {
  return 'InstalledRecordItemDTO(appId: $appId, name: $name, version: $version, arch: $arch, module: $module, channel: $channel)';
}


}

/// @nodoc
abstract mixin class $InstalledRecordItemDTOCopyWith<$Res>  {
  factory $InstalledRecordItemDTOCopyWith(InstalledRecordItemDTO value, $Res Function(InstalledRecordItemDTO) _then) = _$InstalledRecordItemDTOCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'appId') String? appId,@JsonKey(name: 'name') String? name,@JsonKey(name: 'version') String? version,@JsonKey(name: 'arch') String? arch,@JsonKey(name: 'module') String? module,@JsonKey(name: 'channel') String? channel
});




}
/// @nodoc
class _$InstalledRecordItemDTOCopyWithImpl<$Res>
    implements $InstalledRecordItemDTOCopyWith<$Res> {
  _$InstalledRecordItemDTOCopyWithImpl(this._self, this._then);

  final InstalledRecordItemDTO _self;
  final $Res Function(InstalledRecordItemDTO) _then;

/// Create a copy of InstalledRecordItemDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = freezed,Object? name = freezed,Object? version = freezed,Object? arch = freezed,Object? module = freezed,Object? channel = freezed,}) {
  return _then(_self.copyWith(
appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InstalledRecordItemDTO].
extension InstalledRecordItemDTOPatterns on InstalledRecordItemDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstalledRecordItemDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstalledRecordItemDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstalledRecordItemDTO value)  $default,){
final _that = this;
switch (_that) {
case _InstalledRecordItemDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstalledRecordItemDTO value)?  $default,){
final _that = this;
switch (_that) {
case _InstalledRecordItemDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String? appId, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'module')  String? module, @JsonKey(name: 'channel')  String? channel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstalledRecordItemDTO() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.module,_that.channel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'appId')  String? appId, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'module')  String? module, @JsonKey(name: 'channel')  String? channel)  $default,) {final _that = this;
switch (_that) {
case _InstalledRecordItemDTO():
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.module,_that.channel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'appId')  String? appId, @JsonKey(name: 'name')  String? name, @JsonKey(name: 'version')  String? version, @JsonKey(name: 'arch')  String? arch, @JsonKey(name: 'module')  String? module, @JsonKey(name: 'channel')  String? channel)?  $default,) {final _that = this;
switch (_that) {
case _InstalledRecordItemDTO() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.arch,_that.module,_that.channel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstalledRecordItemDTO implements InstalledRecordItemDTO {
  const _InstalledRecordItemDTO({@JsonKey(name: 'appId') this.appId, @JsonKey(name: 'name') this.name, @JsonKey(name: 'version') this.version, @JsonKey(name: 'arch') this.arch, @JsonKey(name: 'module') this.module, @JsonKey(name: 'channel') this.channel});
  factory _InstalledRecordItemDTO.fromJson(Map<String, dynamic> json) => _$InstalledRecordItemDTOFromJson(json);

@override@JsonKey(name: 'appId') final  String? appId;
@override@JsonKey(name: 'name') final  String? name;
@override@JsonKey(name: 'version') final  String? version;
@override@JsonKey(name: 'arch') final  String? arch;
@override@JsonKey(name: 'module') final  String? module;
@override@JsonKey(name: 'channel') final  String? channel;

/// Create a copy of InstalledRecordItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstalledRecordItemDTOCopyWith<_InstalledRecordItemDTO> get copyWith => __$InstalledRecordItemDTOCopyWithImpl<_InstalledRecordItemDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstalledRecordItemDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstalledRecordItemDTO&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.module, module) || other.module == module)&&(identical(other.channel, channel) || other.channel == channel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,name,version,arch,module,channel);

@override
String toString() {
  return 'InstalledRecordItemDTO(appId: $appId, name: $name, version: $version, arch: $arch, module: $module, channel: $channel)';
}


}

/// @nodoc
abstract mixin class _$InstalledRecordItemDTOCopyWith<$Res> implements $InstalledRecordItemDTOCopyWith<$Res> {
  factory _$InstalledRecordItemDTOCopyWith(_InstalledRecordItemDTO value, $Res Function(_InstalledRecordItemDTO) _then) = __$InstalledRecordItemDTOCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'appId') String? appId,@JsonKey(name: 'name') String? name,@JsonKey(name: 'version') String? version,@JsonKey(name: 'arch') String? arch,@JsonKey(name: 'module') String? module,@JsonKey(name: 'channel') String? channel
});




}
/// @nodoc
class __$InstalledRecordItemDTOCopyWithImpl<$Res>
    implements _$InstalledRecordItemDTOCopyWith<$Res> {
  __$InstalledRecordItemDTOCopyWithImpl(this._self, this._then);

  final _InstalledRecordItemDTO _self;
  final $Res Function(_InstalledRecordItemDTO) _then;

/// Create a copy of InstalledRecordItemDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = freezed,Object? name = freezed,Object? version = freezed,Object? arch = freezed,Object? module = freezed,Object? channel = freezed,}) {
  return _then(_InstalledRecordItemDTO(
appId: freezed == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,module: freezed == module ? _self.module : module // ignore: cast_nullable_to_non_nullable
as String?,channel: freezed == channel ? _self.channel : channel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SaveInstalledRecordRequest {

@JsonKey(name: 'visitorId') String? get visitorId;@JsonKey(name: 'clientIp') String? get clientIp;@JsonKey(name: 'addedItems') List<InstalledRecordItemDTO> get addedItems;@JsonKey(name: 'removedItems') List<InstalledRecordItemDTO> get removedItems;
/// Create a copy of SaveInstalledRecordRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveInstalledRecordRequestCopyWith<SaveInstalledRecordRequest> get copyWith => _$SaveInstalledRecordRequestCopyWithImpl<SaveInstalledRecordRequest>(this as SaveInstalledRecordRequest, _$identity);

  /// Serializes this SaveInstalledRecordRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveInstalledRecordRequest&&(identical(other.visitorId, visitorId) || other.visitorId == visitorId)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&const DeepCollectionEquality().equals(other.addedItems, addedItems)&&const DeepCollectionEquality().equals(other.removedItems, removedItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitorId,clientIp,const DeepCollectionEquality().hash(addedItems),const DeepCollectionEquality().hash(removedItems));

@override
String toString() {
  return 'SaveInstalledRecordRequest(visitorId: $visitorId, clientIp: $clientIp, addedItems: $addedItems, removedItems: $removedItems)';
}


}

/// @nodoc
abstract mixin class $SaveInstalledRecordRequestCopyWith<$Res>  {
  factory $SaveInstalledRecordRequestCopyWith(SaveInstalledRecordRequest value, $Res Function(SaveInstalledRecordRequest) _then) = _$SaveInstalledRecordRequestCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'visitorId') String? visitorId,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'addedItems') List<InstalledRecordItemDTO> addedItems,@JsonKey(name: 'removedItems') List<InstalledRecordItemDTO> removedItems
});




}
/// @nodoc
class _$SaveInstalledRecordRequestCopyWithImpl<$Res>
    implements $SaveInstalledRecordRequestCopyWith<$Res> {
  _$SaveInstalledRecordRequestCopyWithImpl(this._self, this._then);

  final SaveInstalledRecordRequest _self;
  final $Res Function(SaveInstalledRecordRequest) _then;

/// Create a copy of SaveInstalledRecordRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visitorId = freezed,Object? clientIp = freezed,Object? addedItems = null,Object? removedItems = null,}) {
  return _then(_self.copyWith(
visitorId: freezed == visitorId ? _self.visitorId : visitorId // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,addedItems: null == addedItems ? _self.addedItems : addedItems // ignore: cast_nullable_to_non_nullable
as List<InstalledRecordItemDTO>,removedItems: null == removedItems ? _self.removedItems : removedItems // ignore: cast_nullable_to_non_nullable
as List<InstalledRecordItemDTO>,
  ));
}

}


/// Adds pattern-matching-related methods to [SaveInstalledRecordRequest].
extension SaveInstalledRecordRequestPatterns on SaveInstalledRecordRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SaveInstalledRecordRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SaveInstalledRecordRequest value)  $default,){
final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SaveInstalledRecordRequest value)?  $default,){
final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'addedItems')  List<InstalledRecordItemDTO> addedItems, @JsonKey(name: 'removedItems')  List<InstalledRecordItemDTO> removedItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest() when $default != null:
return $default(_that.visitorId,_that.clientIp,_that.addedItems,_that.removedItems);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'addedItems')  List<InstalledRecordItemDTO> addedItems, @JsonKey(name: 'removedItems')  List<InstalledRecordItemDTO> removedItems)  $default,) {final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest():
return $default(_that.visitorId,_that.clientIp,_that.addedItems,_that.removedItems);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'visitorId')  String? visitorId, @JsonKey(name: 'clientIp')  String? clientIp, @JsonKey(name: 'addedItems')  List<InstalledRecordItemDTO> addedItems, @JsonKey(name: 'removedItems')  List<InstalledRecordItemDTO> removedItems)?  $default,) {final _that = this;
switch (_that) {
case _SaveInstalledRecordRequest() when $default != null:
return $default(_that.visitorId,_that.clientIp,_that.addedItems,_that.removedItems);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SaveInstalledRecordRequest implements SaveInstalledRecordRequest {
  const _SaveInstalledRecordRequest({@JsonKey(name: 'visitorId') this.visitorId, @JsonKey(name: 'clientIp') this.clientIp, @JsonKey(name: 'addedItems') final  List<InstalledRecordItemDTO> addedItems = const [], @JsonKey(name: 'removedItems') final  List<InstalledRecordItemDTO> removedItems = const []}): _addedItems = addedItems,_removedItems = removedItems;
  factory _SaveInstalledRecordRequest.fromJson(Map<String, dynamic> json) => _$SaveInstalledRecordRequestFromJson(json);

@override@JsonKey(name: 'visitorId') final  String? visitorId;
@override@JsonKey(name: 'clientIp') final  String? clientIp;
 final  List<InstalledRecordItemDTO> _addedItems;
@override@JsonKey(name: 'addedItems') List<InstalledRecordItemDTO> get addedItems {
  if (_addedItems is EqualUnmodifiableListView) return _addedItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_addedItems);
}

 final  List<InstalledRecordItemDTO> _removedItems;
@override@JsonKey(name: 'removedItems') List<InstalledRecordItemDTO> get removedItems {
  if (_removedItems is EqualUnmodifiableListView) return _removedItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_removedItems);
}


/// Create a copy of SaveInstalledRecordRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SaveInstalledRecordRequestCopyWith<_SaveInstalledRecordRequest> get copyWith => __$SaveInstalledRecordRequestCopyWithImpl<_SaveInstalledRecordRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SaveInstalledRecordRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SaveInstalledRecordRequest&&(identical(other.visitorId, visitorId) || other.visitorId == visitorId)&&(identical(other.clientIp, clientIp) || other.clientIp == clientIp)&&const DeepCollectionEquality().equals(other._addedItems, _addedItems)&&const DeepCollectionEquality().equals(other._removedItems, _removedItems));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,visitorId,clientIp,const DeepCollectionEquality().hash(_addedItems),const DeepCollectionEquality().hash(_removedItems));

@override
String toString() {
  return 'SaveInstalledRecordRequest(visitorId: $visitorId, clientIp: $clientIp, addedItems: $addedItems, removedItems: $removedItems)';
}


}

/// @nodoc
abstract mixin class _$SaveInstalledRecordRequestCopyWith<$Res> implements $SaveInstalledRecordRequestCopyWith<$Res> {
  factory _$SaveInstalledRecordRequestCopyWith(_SaveInstalledRecordRequest value, $Res Function(_SaveInstalledRecordRequest) _then) = __$SaveInstalledRecordRequestCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'visitorId') String? visitorId,@JsonKey(name: 'clientIp') String? clientIp,@JsonKey(name: 'addedItems') List<InstalledRecordItemDTO> addedItems,@JsonKey(name: 'removedItems') List<InstalledRecordItemDTO> removedItems
});




}
/// @nodoc
class __$SaveInstalledRecordRequestCopyWithImpl<$Res>
    implements _$SaveInstalledRecordRequestCopyWith<$Res> {
  __$SaveInstalledRecordRequestCopyWithImpl(this._self, this._then);

  final _SaveInstalledRecordRequest _self;
  final $Res Function(_SaveInstalledRecordRequest) _then;

/// Create a copy of SaveInstalledRecordRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visitorId = freezed,Object? clientIp = freezed,Object? addedItems = null,Object? removedItems = null,}) {
  return _then(_SaveInstalledRecordRequest(
visitorId: freezed == visitorId ? _self.visitorId : visitorId // ignore: cast_nullable_to_non_nullable
as String?,clientIp: freezed == clientIp ? _self.clientIp : clientIp // ignore: cast_nullable_to_non_nullable
as String?,addedItems: null == addedItems ? _self._addedItems : addedItems // ignore: cast_nullable_to_non_nullable
as List<InstalledRecordItemDTO>,removedItems: null == removedItems ? _self._removedItems : removedItems // ignore: cast_nullable_to_non_nullable
as List<InstalledRecordItemDTO>,
  ));
}


}

// dart format on
