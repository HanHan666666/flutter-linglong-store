// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppComment {

/// 评论 ID
 String get id;/// 应用 ID
 String get appId;/// 关联版本号
 String? get version;/// 评论内容
 String get remark;/// 赞同数
 int get agreeNum;/// 反对数
 int get disagreeNum;/// 创建时间
 String? get createTime;
/// Create a copy of AppComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppCommentCopyWith<AppComment> get copyWith => _$AppCommentCopyWithImpl<AppComment>(this as AppComment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppComment&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.version, version) || other.version == version)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.agreeNum, agreeNum) || other.agreeNum == agreeNum)&&(identical(other.disagreeNum, disagreeNum) || other.disagreeNum == disagreeNum)&&(identical(other.createTime, createTime) || other.createTime == createTime));
}


@override
int get hashCode => Object.hash(runtimeType,id,appId,version,remark,agreeNum,disagreeNum,createTime);

@override
String toString() {
  return 'AppComment(id: $id, appId: $appId, version: $version, remark: $remark, agreeNum: $agreeNum, disagreeNum: $disagreeNum, createTime: $createTime)';
}


}

/// @nodoc
abstract mixin class $AppCommentCopyWith<$Res>  {
  factory $AppCommentCopyWith(AppComment value, $Res Function(AppComment) _then) = _$AppCommentCopyWithImpl;
@useResult
$Res call({
 String id, String appId, String? version, String remark, int agreeNum, int disagreeNum, String? createTime
});




}
/// @nodoc
class _$AppCommentCopyWithImpl<$Res>
    implements $AppCommentCopyWith<$Res> {
  _$AppCommentCopyWithImpl(this._self, this._then);

  final AppComment _self;
  final $Res Function(AppComment) _then;

/// Create a copy of AppComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? version = freezed,Object? remark = null,Object? agreeNum = null,Object? disagreeNum = null,Object? createTime = freezed,}) {
  return _then(AppComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,agreeNum: null == agreeNum ? _self.agreeNum : agreeNum // ignore: cast_nullable_to_non_nullable
as int,disagreeNum: null == disagreeNum ? _self.disagreeNum : disagreeNum // ignore: cast_nullable_to_non_nullable
as int,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppComment].
extension AppCommentPatterns on AppComment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppComment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppComment value)  $default,){
final _that = this;
switch (_that) {
case _AppComment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppComment value)?  $default,){
final _that = this;
switch (_that) {
case _AppComment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String appId,  String? version,  String remark,  int agreeNum,  int disagreeNum,  String? createTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppComment() when $default != null:
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.agreeNum,_that.disagreeNum,_that.createTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String appId,  String? version,  String remark,  int agreeNum,  int disagreeNum,  String? createTime)  $default,) {final _that = this;
switch (_that) {
case _AppComment():
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.agreeNum,_that.disagreeNum,_that.createTime);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String appId,  String? version,  String remark,  int agreeNum,  int disagreeNum,  String? createTime)?  $default,) {final _that = this;
switch (_that) {
case _AppComment() when $default != null:
return $default(_that.id,_that.appId,_that.version,_that.remark,_that.agreeNum,_that.disagreeNum,_that.createTime);case _:
  return null;

}
}

}

/// @nodoc


class _AppComment implements AppComment {
  const _AppComment({required this.id, required this.appId, this.version, required this.remark, this.agreeNum = 0, this.disagreeNum = 0, this.createTime});
  

/// 评论 ID
@override final  String id;
/// 应用 ID
@override final  String appId;
/// 关联版本号
@override final  String? version;
/// 评论内容
@override final  String remark;
/// 赞同数
@override@JsonKey() final  int agreeNum;
/// 反对数
@override@JsonKey() final  int disagreeNum;
/// 创建时间
@override final  String? createTime;

/// Create a copy of AppComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppCommentCopyWith<_AppComment> get copyWith => __$AppCommentCopyWithImpl<_AppComment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppComment&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.version, version) || other.version == version)&&(identical(other.remark, remark) || other.remark == remark)&&(identical(other.agreeNum, agreeNum) || other.agreeNum == agreeNum)&&(identical(other.disagreeNum, disagreeNum) || other.disagreeNum == disagreeNum)&&(identical(other.createTime, createTime) || other.createTime == createTime));
}


@override
int get hashCode => Object.hash(runtimeType,id,appId,version,remark,agreeNum,disagreeNum,createTime);

@override
String toString() {
  return 'AppComment(id: $id, appId: $appId, version: $version, remark: $remark, agreeNum: $agreeNum, disagreeNum: $disagreeNum, createTime: $createTime)';
}


}

/// @nodoc
abstract mixin class _$AppCommentCopyWith<$Res> implements $AppCommentCopyWith<$Res> {
  factory _$AppCommentCopyWith(_AppComment value, $Res Function(_AppComment) _then) = __$AppCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String appId, String? version, String remark, int agreeNum, int disagreeNum, String? createTime
});




}
/// @nodoc
class __$AppCommentCopyWithImpl<$Res>
    implements _$AppCommentCopyWith<$Res> {
  __$AppCommentCopyWithImpl(this._self, this._then);

  final _AppComment _self;
  final $Res Function(_AppComment) _then;

/// Create a copy of AppComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? version = freezed,Object? remark = null,Object? agreeNum = null,Object? disagreeNum = null,Object? createTime = freezed,}) {
  return _then(_AppComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,remark: null == remark ? _self.remark : remark // ignore: cast_nullable_to_non_nullable
as String,agreeNum: null == agreeNum ? _self.agreeNum : agreeNum // ignore: cast_nullable_to_non_nullable
as int,disagreeNum: null == disagreeNum ? _self.disagreeNum : disagreeNum // ignore: cast_nullable_to_non_nullable
as int,createTime: freezed == createTime ? _self.createTime : createTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
