// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_operation_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppOperationBatch {

/// 稳定批次 ID，同时作为通知替换 ID 的组成部分。
 String get id;/// 批次业务类型。
 AppOperationBatchKind get kind;/// 属于该批次的任务 ID，顺序与 [targets] 一致。
 List<String> get taskIds;/// 用户点击一键更新时冻结的目标列表。
 List<AppOperationTargetSnapshot> get targets;/// 批次创建时间戳。
 int get createdAt;/// 批次完成时间戳。
 int? get finishedAt;/// 当前批次状态。
 AppOperationBatchStatus get status;/// 系统通知投递状态。
 AppOperationNotificationState get notificationState;
/// Create a copy of AppOperationBatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppOperationBatchCopyWith<AppOperationBatch> get copyWith => _$AppOperationBatchCopyWithImpl<AppOperationBatch>(this as AppOperationBatch, _$identity);

  /// Serializes this AppOperationBatch to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppOperationBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.taskIds, taskIds)&&const DeepCollectionEquality().equals(other.targets, targets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.notificationState, notificationState) || other.notificationState == notificationState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,const DeepCollectionEquality().hash(taskIds),const DeepCollectionEquality().hash(targets),createdAt,finishedAt,status,notificationState);

@override
String toString() {
  return 'AppOperationBatch(id: $id, kind: $kind, taskIds: $taskIds, targets: $targets, createdAt: $createdAt, finishedAt: $finishedAt, status: $status, notificationState: $notificationState)';
}


}

/// @nodoc
abstract mixin class $AppOperationBatchCopyWith<$Res>  {
  factory $AppOperationBatchCopyWith(AppOperationBatch value, $Res Function(AppOperationBatch) _then) = _$AppOperationBatchCopyWithImpl;
@useResult
$Res call({
 String id, AppOperationBatchKind kind, List<String> taskIds, List<AppOperationTargetSnapshot> targets, int createdAt, int? finishedAt, AppOperationBatchStatus status, AppOperationNotificationState notificationState
});




}
/// @nodoc
class _$AppOperationBatchCopyWithImpl<$Res>
    implements $AppOperationBatchCopyWith<$Res> {
  _$AppOperationBatchCopyWithImpl(this._self, this._then);

  final AppOperationBatch _self;
  final $Res Function(AppOperationBatch) _then;

/// Create a copy of AppOperationBatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? taskIds = null,Object? targets = null,Object? createdAt = null,Object? finishedAt = freezed,Object? status = null,Object? notificationState = null,}) {
  return _then(AppOperationBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AppOperationBatchKind,taskIds: null == taskIds ? _self.taskIds : taskIds // ignore: cast_nullable_to_non_nullable
as List<String>,targets: null == targets ? _self.targets : targets // ignore: cast_nullable_to_non_nullable
as List<AppOperationTargetSnapshot>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppOperationBatchStatus,notificationState: null == notificationState ? _self.notificationState : notificationState // ignore: cast_nullable_to_non_nullable
as AppOperationNotificationState,
  ));
}

}


/// Adds pattern-matching-related methods to [AppOperationBatch].
extension AppOperationBatchPatterns on AppOperationBatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppOperationBatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppOperationBatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppOperationBatch value)  $default,){
final _that = this;
switch (_that) {
case _AppOperationBatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppOperationBatch value)?  $default,){
final _that = this;
switch (_that) {
case _AppOperationBatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AppOperationBatchKind kind,  List<String> taskIds,  List<AppOperationTargetSnapshot> targets,  int createdAt,  int? finishedAt,  AppOperationBatchStatus status,  AppOperationNotificationState notificationState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppOperationBatch() when $default != null:
return $default(_that.id,_that.kind,_that.taskIds,_that.targets,_that.createdAt,_that.finishedAt,_that.status,_that.notificationState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AppOperationBatchKind kind,  List<String> taskIds,  List<AppOperationTargetSnapshot> targets,  int createdAt,  int? finishedAt,  AppOperationBatchStatus status,  AppOperationNotificationState notificationState)  $default,) {final _that = this;
switch (_that) {
case _AppOperationBatch():
return $default(_that.id,_that.kind,_that.taskIds,_that.targets,_that.createdAt,_that.finishedAt,_that.status,_that.notificationState);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AppOperationBatchKind kind,  List<String> taskIds,  List<AppOperationTargetSnapshot> targets,  int createdAt,  int? finishedAt,  AppOperationBatchStatus status,  AppOperationNotificationState notificationState)?  $default,) {final _that = this;
switch (_that) {
case _AppOperationBatch() when $default != null:
return $default(_that.id,_that.kind,_that.taskIds,_that.targets,_that.createdAt,_that.finishedAt,_that.status,_that.notificationState);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppOperationBatch implements AppOperationBatch {
  const _AppOperationBatch({required this.id, this.kind = AppOperationBatchKind.updateAll, required  List<String> taskIds, required  List<AppOperationTargetSnapshot> targets, required this.createdAt, this.finishedAt, this.status = AppOperationBatchStatus.active, this.notificationState = AppOperationNotificationState.notRequested}): _taskIds = taskIds,_targets = targets;
  factory _AppOperationBatch.fromJson(Map<String, dynamic> json) => _$AppOperationBatchFromJson(json);

/// 稳定批次 ID，同时作为通知替换 ID 的组成部分。
@override final  String id;
/// 批次业务类型。
@override@JsonKey() final  AppOperationBatchKind kind;
/// 属于该批次的任务 ID，顺序与 [targets] 一致。
 final  List<String> _taskIds;
/// 属于该批次的任务 ID，顺序与 [targets] 一致。
@override List<String> get taskIds {
  if (_taskIds is EqualUnmodifiableListView) return _taskIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_taskIds);
}

/// 用户点击一键更新时冻结的目标列表。
 final  List<AppOperationTargetSnapshot> _targets;
/// 用户点击一键更新时冻结的目标列表。
@override List<AppOperationTargetSnapshot> get targets {
  if (_targets is EqualUnmodifiableListView) return _targets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targets);
}

/// 批次创建时间戳。
@override final  int createdAt;
/// 批次完成时间戳。
@override final  int? finishedAt;
/// 当前批次状态。
@override@JsonKey() final  AppOperationBatchStatus status;
/// 系统通知投递状态。
@override@JsonKey() final  AppOperationNotificationState notificationState;

/// Create a copy of AppOperationBatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppOperationBatchCopyWith<_AppOperationBatch> get copyWith => __$AppOperationBatchCopyWithImpl<_AppOperationBatch>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppOperationBatchToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppOperationBatch&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other._taskIds, _taskIds)&&const DeepCollectionEquality().equals(other._targets, _targets)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.notificationState, notificationState) || other.notificationState == notificationState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,const DeepCollectionEquality().hash(_taskIds),const DeepCollectionEquality().hash(_targets),createdAt,finishedAt,status,notificationState);

@override
String toString() {
  return 'AppOperationBatch(id: $id, kind: $kind, taskIds: $taskIds, targets: $targets, createdAt: $createdAt, finishedAt: $finishedAt, status: $status, notificationState: $notificationState)';
}


}

/// @nodoc
abstract mixin class _$AppOperationBatchCopyWith<$Res> implements $AppOperationBatchCopyWith<$Res> {
  factory _$AppOperationBatchCopyWith(_AppOperationBatch value, $Res Function(_AppOperationBatch) _then) = __$AppOperationBatchCopyWithImpl;
@override @useResult
$Res call({
 String id, AppOperationBatchKind kind, List<String> taskIds, List<AppOperationTargetSnapshot> targets, int createdAt, int? finishedAt, AppOperationBatchStatus status, AppOperationNotificationState notificationState
});




}
/// @nodoc
class __$AppOperationBatchCopyWithImpl<$Res>
    implements _$AppOperationBatchCopyWith<$Res> {
  __$AppOperationBatchCopyWithImpl(this._self, this._then);

  final _AppOperationBatch _self;
  final $Res Function(_AppOperationBatch) _then;

/// Create a copy of AppOperationBatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? taskIds = null,Object? targets = null,Object? createdAt = null,Object? finishedAt = freezed,Object? status = null,Object? notificationState = null,}) {
  return _then(_AppOperationBatch(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as AppOperationBatchKind,taskIds: null == taskIds ? _self._taskIds : taskIds // ignore: cast_nullable_to_non_nullable
as List<String>,targets: null == targets ? _self._targets : targets // ignore: cast_nullable_to_non_nullable
as List<AppOperationTargetSnapshot>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AppOperationBatchStatus,notificationState: null == notificationState ? _self.notificationState : notificationState // ignore: cast_nullable_to_non_nullable
as AppOperationNotificationState,
  ));
}


}


/// @nodoc
mixin _$AppOperationEffect {

/// 稳定事件 ID。
 String get id;/// 事件类型。
 AppOperationEffectType get type;/// 任务 ID 或批次 ID。
 String get aggregateId;/// 事件创建时间戳。
 int get createdAt;/// 已执行的投递次数。
 int get attemptCount;/// 最近一次尝试时间戳。
 int? get lastAttemptAt;
/// Create a copy of AppOperationEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppOperationEffectCopyWith<AppOperationEffect> get copyWith => _$AppOperationEffectCopyWithImpl<AppOperationEffect>(this as AppOperationEffect, _$identity);

  /// Serializes this AppOperationEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppOperationEffect&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.aggregateId, aggregateId) || other.aggregateId == aggregateId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptCount, attemptCount) || other.attemptCount == attemptCount)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,aggregateId,createdAt,attemptCount,lastAttemptAt);

@override
String toString() {
  return 'AppOperationEffect(id: $id, type: $type, aggregateId: $aggregateId, createdAt: $createdAt, attemptCount: $attemptCount, lastAttemptAt: $lastAttemptAt)';
}


}

/// @nodoc
abstract mixin class $AppOperationEffectCopyWith<$Res>  {
  factory $AppOperationEffectCopyWith(AppOperationEffect value, $Res Function(AppOperationEffect) _then) = _$AppOperationEffectCopyWithImpl;
@useResult
$Res call({
 String id, AppOperationEffectType type, String aggregateId, int createdAt, int attemptCount, int? lastAttemptAt
});




}
/// @nodoc
class _$AppOperationEffectCopyWithImpl<$Res>
    implements $AppOperationEffectCopyWith<$Res> {
  _$AppOperationEffectCopyWithImpl(this._self, this._then);

  final AppOperationEffect _self;
  final $Res Function(AppOperationEffect) _then;

/// Create a copy of AppOperationEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? aggregateId = null,Object? createdAt = null,Object? attemptCount = null,Object? lastAttemptAt = freezed,}) {
  return _then(AppOperationEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppOperationEffectType,aggregateId: null == aggregateId ? _self.aggregateId : aggregateId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppOperationEffect].
extension AppOperationEffectPatterns on AppOperationEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppOperationEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppOperationEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppOperationEffect value)  $default,){
final _that = this;
switch (_that) {
case _AppOperationEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppOperationEffect value)?  $default,){
final _that = this;
switch (_that) {
case _AppOperationEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  AppOperationEffectType type,  String aggregateId,  int createdAt,  int attemptCount,  int? lastAttemptAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppOperationEffect() when $default != null:
return $default(_that.id,_that.type,_that.aggregateId,_that.createdAt,_that.attemptCount,_that.lastAttemptAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  AppOperationEffectType type,  String aggregateId,  int createdAt,  int attemptCount,  int? lastAttemptAt)  $default,) {final _that = this;
switch (_that) {
case _AppOperationEffect():
return $default(_that.id,_that.type,_that.aggregateId,_that.createdAt,_that.attemptCount,_that.lastAttemptAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  AppOperationEffectType type,  String aggregateId,  int createdAt,  int attemptCount,  int? lastAttemptAt)?  $default,) {final _that = this;
switch (_that) {
case _AppOperationEffect() when $default != null:
return $default(_that.id,_that.type,_that.aggregateId,_that.createdAt,_that.attemptCount,_that.lastAttemptAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppOperationEffect implements AppOperationEffect {
  const _AppOperationEffect({required this.id, required this.type, required this.aggregateId, required this.createdAt, this.attemptCount = 0, this.lastAttemptAt});
  factory _AppOperationEffect.fromJson(Map<String, dynamic> json) => _$AppOperationEffectFromJson(json);

/// 稳定事件 ID。
@override final  String id;
/// 事件类型。
@override final  AppOperationEffectType type;
/// 任务 ID 或批次 ID。
@override final  String aggregateId;
/// 事件创建时间戳。
@override final  int createdAt;
/// 已执行的投递次数。
@override@JsonKey() final  int attemptCount;
/// 最近一次尝试时间戳。
@override final  int? lastAttemptAt;

/// Create a copy of AppOperationEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppOperationEffectCopyWith<_AppOperationEffect> get copyWith => __$AppOperationEffectCopyWithImpl<_AppOperationEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppOperationEffectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppOperationEffect&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.aggregateId, aggregateId) || other.aggregateId == aggregateId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.attemptCount, attemptCount) || other.attemptCount == attemptCount)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,aggregateId,createdAt,attemptCount,lastAttemptAt);

@override
String toString() {
  return 'AppOperationEffect(id: $id, type: $type, aggregateId: $aggregateId, createdAt: $createdAt, attemptCount: $attemptCount, lastAttemptAt: $lastAttemptAt)';
}


}

/// @nodoc
abstract mixin class _$AppOperationEffectCopyWith<$Res> implements $AppOperationEffectCopyWith<$Res> {
  factory _$AppOperationEffectCopyWith(_AppOperationEffect value, $Res Function(_AppOperationEffect) _then) = __$AppOperationEffectCopyWithImpl;
@override @useResult
$Res call({
 String id, AppOperationEffectType type, String aggregateId, int createdAt, int attemptCount, int? lastAttemptAt
});




}
/// @nodoc
class __$AppOperationEffectCopyWithImpl<$Res>
    implements _$AppOperationEffectCopyWith<$Res> {
  __$AppOperationEffectCopyWithImpl(this._self, this._then);

  final _AppOperationEffect _self;
  final $Res Function(_AppOperationEffect) _then;

/// Create a copy of AppOperationEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? aggregateId = null,Object? createdAt = null,Object? attemptCount = null,Object? lastAttemptAt = freezed,}) {
  return _then(_AppOperationEffect(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppOperationEffectType,aggregateId: null == aggregateId ? _self.aggregateId : aggregateId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,attemptCount: null == attemptCount ? _self.attemptCount : attemptCount // ignore: cast_nullable_to_non_nullable
as int,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
