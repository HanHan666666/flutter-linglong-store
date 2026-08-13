// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ranking_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RankingAppInfo {

 String get appId; String get name; String get version; String? get description; String? get icon; String? get developer; String? get category; String? get size; String? get arch; double? get rating; int? get downloadCount; String? get createTime; int get rank; bool get isInstalled; bool get hasUpdate;
/// Create a copy of RankingAppInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingAppInfoCopyWith<RankingAppInfo> get copyWith => _$RankingAppInfoCopyWithImpl<RankingAppInfo>(this as RankingAppInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingAppInfo&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.category, category) || other.category == category)&&(identical(other.size, size) || other.size == size)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.createTime, createTime) || other.createTime == createTime)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.isInstalled, isInstalled) || other.isInstalled == isInstalled)&&(identical(other.hasUpdate, hasUpdate) || other.hasUpdate == hasUpdate));
}


@override
int get hashCode => Object.hash(runtimeType,appId,name,version,description,icon,developer,category,size,arch,rating,downloadCount,createTime,rank,isInstalled,hasUpdate);

@override
String toString() {
  return 'RankingAppInfo(appId: $appId, name: $name, version: $version, description: $description, icon: $icon, developer: $developer, category: $category, size: $size, arch: $arch, rating: $rating, downloadCount: $downloadCount, createTime: $createTime, rank: $rank, isInstalled: $isInstalled, hasUpdate: $hasUpdate)';
}


}

/// @nodoc
abstract mixin class $RankingAppInfoCopyWith<$Res>  {
  factory $RankingAppInfoCopyWith(RankingAppInfo value, $Res Function(RankingAppInfo) _then) = _$RankingAppInfoCopyWithImpl;
@useResult
$Res call({
 String appId, String name, String version, String? description, String? icon, String? developer, String? category, String? size, String? arch, double? rating, int? downloadCount, String? createTime, int rank, bool isInstalled, bool hasUpdate
});




}
/// @nodoc
class _$RankingAppInfoCopyWithImpl<$Res>
    implements $RankingAppInfoCopyWith<$Res> {
  _$RankingAppInfoCopyWithImpl(this._self, this._then);

  final RankingAppInfo _self;
  final $Res Function(RankingAppInfo) _then;

/// Create a copy of RankingAppInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? description = freezed,Object? icon = freezed,Object? developer = freezed,Object? category = freezed,Object? size = freezed,Object? arch = freezed,Object? rating = freezed,Object? downloadCount = freezed,Object? createTime = freezed,Object? rank = null,Object? isInstalled = null,Object? hasUpdate = null,}) {
  return _then(RankingAppInfo(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,downloadCount: freezed == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int?,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,isInstalled: null == isInstalled ? _self.isInstalled : isInstalled // ignore: cast_nullable_to_non_nullable
as bool,hasUpdate: null == hasUpdate ? _self.hasUpdate : hasUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingAppInfo].
extension RankingAppInfoPatterns on RankingAppInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingAppInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingAppInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingAppInfo value)  $default,){
final _that = this;
switch (_that) {
case _RankingAppInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingAppInfo value)?  $default,){
final _that = this;
switch (_that) {
case _RankingAppInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  double? rating,  int? downloadCount,  String? createTime,  int rank,  bool isInstalled,  bool hasUpdate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingAppInfo() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.rating,_that.downloadCount,_that.createTime,_that.rank,_that.isInstalled,_that.hasUpdate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  double? rating,  int? downloadCount,  String? createTime,  int rank,  bool isInstalled,  bool hasUpdate)  $default,) {final _that = this;
switch (_that) {
case _RankingAppInfo():
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.rating,_that.downloadCount,_that.createTime,_that.rank,_that.isInstalled,_that.hasUpdate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  String name,  String version,  String? description,  String? icon,  String? developer,  String? category,  String? size,  String? arch,  double? rating,  int? downloadCount,  String? createTime,  int rank,  bool isInstalled,  bool hasUpdate)?  $default,) {final _that = this;
switch (_that) {
case _RankingAppInfo() when $default != null:
return $default(_that.appId,_that.name,_that.version,_that.description,_that.icon,_that.developer,_that.category,_that.size,_that.arch,_that.rating,_that.downloadCount,_that.createTime,_that.rank,_that.isInstalled,_that.hasUpdate);case _:
  return null;

}
}

}

/// @nodoc


class _RankingAppInfo implements RankingAppInfo {
  const _RankingAppInfo({required this.appId, required this.name, required this.version, this.description, this.icon, this.developer, this.category, this.size, this.arch, this.rating, this.downloadCount, this.createTime, required this.rank, this.isInstalled = false, this.hasUpdate = false});
  

@override final  String appId;
@override final  String name;
@override final  String version;
@override final  String? description;
@override final  String? icon;
@override final  String? developer;
@override final  String? category;
@override final  String? size;
@override final  String? arch;
@override final  double? rating;
@override final  int? downloadCount;
@override final  String? createTime;
@override final  int rank;
@override@JsonKey() final  bool isInstalled;
@override@JsonKey() final  bool hasUpdate;

/// Create a copy of RankingAppInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingAppInfoCopyWith<_RankingAppInfo> get copyWith => __$RankingAppInfoCopyWithImpl<_RankingAppInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingAppInfo&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.name, name) || other.name == name)&&(identical(other.version, version) || other.version == version)&&(identical(other.description, description) || other.description == description)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.developer, developer) || other.developer == developer)&&(identical(other.category, category) || other.category == category)&&(identical(other.size, size) || other.size == size)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.downloadCount, downloadCount) || other.downloadCount == downloadCount)&&(identical(other.createTime, createTime) || other.createTime == createTime)&&(identical(other.rank, rank) || other.rank == rank)&&(identical(other.isInstalled, isInstalled) || other.isInstalled == isInstalled)&&(identical(other.hasUpdate, hasUpdate) || other.hasUpdate == hasUpdate));
}


@override
int get hashCode => Object.hash(runtimeType,appId,name,version,description,icon,developer,category,size,arch,rating,downloadCount,createTime,rank,isInstalled,hasUpdate);

@override
String toString() {
  return 'RankingAppInfo(appId: $appId, name: $name, version: $version, description: $description, icon: $icon, developer: $developer, category: $category, size: $size, arch: $arch, rating: $rating, downloadCount: $downloadCount, createTime: $createTime, rank: $rank, isInstalled: $isInstalled, hasUpdate: $hasUpdate)';
}


}

/// @nodoc
abstract mixin class _$RankingAppInfoCopyWith<$Res> implements $RankingAppInfoCopyWith<$Res> {
  factory _$RankingAppInfoCopyWith(_RankingAppInfo value, $Res Function(_RankingAppInfo) _then) = __$RankingAppInfoCopyWithImpl;
@override @useResult
$Res call({
 String appId, String name, String version, String? description, String? icon, String? developer, String? category, String? size, String? arch, double? rating, int? downloadCount, String? createTime, int rank, bool isInstalled, bool hasUpdate
});




}
/// @nodoc
class __$RankingAppInfoCopyWithImpl<$Res>
    implements _$RankingAppInfoCopyWith<$Res> {
  __$RankingAppInfoCopyWithImpl(this._self, this._then);

  final _RankingAppInfo _self;
  final $Res Function(_RankingAppInfo) _then;

/// Create a copy of RankingAppInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? name = null,Object? version = null,Object? description = freezed,Object? icon = freezed,Object? developer = freezed,Object? category = freezed,Object? size = freezed,Object? arch = freezed,Object? rating = freezed,Object? downloadCount = freezed,Object? createTime = freezed,Object? rank = null,Object? isInstalled = null,Object? hasUpdate = null,}) {
  return _then(_RankingAppInfo(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,developer: freezed == developer ? _self.developer : developer // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,rating: freezed == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double?,downloadCount: freezed == downloadCount ? _self.downloadCount : downloadCount // ignore: cast_nullable_to_non_nullable
as int?,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,rank: null == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as int,isInstalled: null == isInstalled ? _self.isInstalled : isInstalled // ignore: cast_nullable_to_non_nullable
as bool,hasUpdate: null == hasUpdate ? _self.hasUpdate : hasUpdate // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$RankingState {

 bool get isLoading; String? get error; RankingData? get data; RankingType get selectedType;
/// Create a copy of RankingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingStateCopyWith<RankingState> get copyWith => _$RankingStateCopyWithImpl<RankingState>(this as RankingState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.selectedType, selectedType) || other.selectedType == selectedType));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,data,selectedType);

@override
String toString() {
  return 'RankingState(isLoading: $isLoading, error: $error, data: $data, selectedType: $selectedType)';
}


}

/// @nodoc
abstract mixin class $RankingStateCopyWith<$Res>  {
  factory $RankingStateCopyWith(RankingState value, $Res Function(RankingState) _then) = _$RankingStateCopyWithImpl;
@useResult
$Res call({
 bool isLoading, String? error, RankingData? data, RankingType selectedType
});




}
/// @nodoc
class _$RankingStateCopyWithImpl<$Res>
    implements $RankingStateCopyWith<$Res> {
  _$RankingStateCopyWithImpl(this._self, this._then);

  final RankingState _self;
  final $Res Function(RankingState) _then;

/// Create a copy of RankingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLoading = null,Object? error = freezed,Object? data = freezed,Object? selectedType = null,}) {
  return _then(RankingState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RankingData?,selectedType: null == selectedType ? _self.selectedType : selectedType // ignore: cast_nullable_to_non_nullable
as RankingType,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingState].
extension RankingStatePatterns on RankingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingState value)  $default,){
final _that = this;
switch (_that) {
case _RankingState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingState value)?  $default,){
final _that = this;
switch (_that) {
case _RankingState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  RankingData? data,  RankingType selectedType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingState() when $default != null:
return $default(_that.isLoading,_that.error,_that.data,_that.selectedType);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLoading,  String? error,  RankingData? data,  RankingType selectedType)  $default,) {final _that = this;
switch (_that) {
case _RankingState():
return $default(_that.isLoading,_that.error,_that.data,_that.selectedType);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLoading,  String? error,  RankingData? data,  RankingType selectedType)?  $default,) {final _that = this;
switch (_that) {
case _RankingState() when $default != null:
return $default(_that.isLoading,_that.error,_that.data,_that.selectedType);case _:
  return null;

}
}

}

/// @nodoc


class _RankingState implements RankingState {
  const _RankingState({this.isLoading = false, this.error, this.data, this.selectedType = RankingType.rising});
  

@override@JsonKey() final  bool isLoading;
@override final  String? error;
@override final  RankingData? data;
@override@JsonKey() final  RankingType selectedType;

/// Create a copy of RankingState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingStateCopyWith<_RankingState> get copyWith => __$RankingStateCopyWithImpl<_RankingState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingState&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.error, error) || other.error == error)&&(identical(other.data, data) || other.data == data)&&(identical(other.selectedType, selectedType) || other.selectedType == selectedType));
}


@override
int get hashCode => Object.hash(runtimeType,isLoading,error,data,selectedType);

@override
String toString() {
  return 'RankingState(isLoading: $isLoading, error: $error, data: $data, selectedType: $selectedType)';
}


}

/// @nodoc
abstract mixin class _$RankingStateCopyWith<$Res> implements $RankingStateCopyWith<$Res> {
  factory _$RankingStateCopyWith(_RankingState value, $Res Function(_RankingState) _then) = __$RankingStateCopyWithImpl;
@override @useResult
$Res call({
 bool isLoading, String? error, RankingData? data, RankingType selectedType
});




}
/// @nodoc
class __$RankingStateCopyWithImpl<$Res>
    implements _$RankingStateCopyWith<$Res> {
  __$RankingStateCopyWithImpl(this._self, this._then);

  final _RankingState _self;
  final $Res Function(_RankingState) _then;

/// Create a copy of RankingState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLoading = null,Object? error = freezed,Object? data = freezed,Object? selectedType = null,}) {
  return _then(_RankingState(
isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as RankingData?,selectedType: null == selectedType ? _self.selectedType : selectedType // ignore: cast_nullable_to_non_nullable
as RankingType,
  ));
}


}

// dart format on
