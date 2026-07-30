// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'install_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstallTask {

/// 唯一任务ID
 String get id;/// 应用ID
 String get appId;/// 应用名称
 String get appName;/// 应用图标URL
 String? get icon;/// 队列任务类型
 InstallTaskKind get kind;/// 所属批次 ID；单任务和人工重试不属于批次。
 String? get batchId;/// 入队时冻结的完整目标身份。
///
/// 旧版持久化任务可能为空，恢复时必须按中断处理，禁止仅凭 appId
/// 乐观判断更新已经成功。
 AppOperationTargetSnapshot? get target;/// 目标版本
 String? get version;/// 是否强制安装
 bool get force;/// 当前状态
 InstallStatus get status;/// 安装进度（`0.0..1.0` 比例值，由 [progressValue] 归一化后供 UI 消费）。
 double get progress;/// 旧快照中的状态文案；新任务不得写入本地化字符串。
 String? get message;/// 可在当前语言下重新格式化的稳定阶段代码。
 AppOperationMessageCode? get messageCode;/// 安装链路中保留的原始 message 文本，用于诊断。
 String? get rawMessage;/// 当前任务累计的 ll-cli 命令与原始输出，随下载中心 item 生命周期保存。
 String get commandOutput;/// 旧快照中的错误文案；新任务不得写入本地化字符串。
 String? get errorMessage;/// 错误代码
 int? get errorCode;/// 错误详情
 String? get errorDetail;/// 与 locale 无关的结构化失败事实。
 AppOperationFailure? get failure;/// 任务创建时间戳
 int get createdAt;/// 任务开始时间戳
 int? get startedAt;/// 任务完成时间戳
 int? get finishedAt;
/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallTaskCopyWith<InstallTask> get copyWith => _$InstallTaskCopyWithImpl<InstallTask>(this as InstallTask, _$identity);

  /// Serializes this InstallTask to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallTask&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.target, target) || other.target == target)&&(identical(other.version, version) || other.version == version)&&(identical(other.force, force) || other.force == force)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.messageCode, messageCode) || other.messageCode == messageCode)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&(identical(other.commandOutput, commandOutput) || other.commandOutput == commandOutput)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,appId,appName,icon,kind,batchId,target,version,force,status,progress,message,messageCode,rawMessage,commandOutput,errorMessage,errorCode,errorDetail,failure,createdAt,startedAt,finishedAt]);

@override
String toString() {
  return 'InstallTask(id: $id, appId: $appId, appName: $appName, icon: $icon, kind: $kind, batchId: $batchId, target: $target, version: $version, force: $force, status: $status, progress: $progress, message: $message, messageCode: $messageCode, rawMessage: $rawMessage, commandOutput: $commandOutput, errorMessage: $errorMessage, errorCode: $errorCode, errorDetail: $errorDetail, failure: $failure, createdAt: $createdAt, startedAt: $startedAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class $InstallTaskCopyWith<$Res>  {
  factory $InstallTaskCopyWith(InstallTask value, $Res Function(InstallTask) _then) = _$InstallTaskCopyWithImpl;
@useResult
$Res call({
 String id, String appId, String appName, String? icon, InstallTaskKind kind, String? batchId, AppOperationTargetSnapshot? target, String? version, bool force, InstallStatus status, double progress, String? message, AppOperationMessageCode? messageCode, String? rawMessage, String commandOutput, String? errorMessage, int? errorCode, String? errorDetail, AppOperationFailure? failure, int createdAt, int? startedAt, int? finishedAt
});


$AppOperationTargetSnapshotCopyWith<$Res>? get target;$AppOperationFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$InstallTaskCopyWithImpl<$Res>
    implements $InstallTaskCopyWith<$Res> {
  _$InstallTaskCopyWithImpl(this._self, this._then);

  final InstallTask _self;
  final $Res Function(InstallTask) _then;

/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? appId = null,Object? appName = null,Object? icon = freezed,Object? kind = null,Object? batchId = freezed,Object? target = freezed,Object? version = freezed,Object? force = null,Object? status = null,Object? progress = null,Object? message = freezed,Object? messageCode = freezed,Object? rawMessage = freezed,Object? commandOutput = null,Object? errorMessage = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? failure = freezed,Object? createdAt = null,Object? startedAt = freezed,Object? finishedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InstallTaskKind,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as AppOperationTargetSnapshot?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,force: null == force ? _self.force : force // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,messageCode: freezed == messageCode ? _self.messageCode : messageCode // ignore: cast_nullable_to_non_nullable
as AppOperationMessageCode?,rawMessage: freezed == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String?,commandOutput: null == commandOutput ? _self.commandOutput : commandOutput // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as int?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppOperationFailure?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppOperationTargetSnapshotCopyWith<$Res>? get target {
    if (_self.target == null) {
    return null;
  }

  return $AppOperationTargetSnapshotCopyWith<$Res>(_self.target!, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppOperationFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppOperationFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [InstallTask].
extension InstallTaskPatterns on InstallTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallTask value)  $default,){
final _that = this;
switch (_that) {
case _InstallTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallTask value)?  $default,){
final _that = this;
switch (_that) {
case _InstallTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String appId,  String appName,  String? icon,  InstallTaskKind kind,  String? batchId,  AppOperationTargetSnapshot? target,  String? version,  bool force,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String commandOutput,  String? errorMessage,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure,  int createdAt,  int? startedAt,  int? finishedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallTask() when $default != null:
return $default(_that.id,_that.appId,_that.appName,_that.icon,_that.kind,_that.batchId,_that.target,_that.version,_that.force,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.commandOutput,_that.errorMessage,_that.errorCode,_that.errorDetail,_that.failure,_that.createdAt,_that.startedAt,_that.finishedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String appId,  String appName,  String? icon,  InstallTaskKind kind,  String? batchId,  AppOperationTargetSnapshot? target,  String? version,  bool force,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String commandOutput,  String? errorMessage,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure,  int createdAt,  int? startedAt,  int? finishedAt)  $default,) {final _that = this;
switch (_that) {
case _InstallTask():
return $default(_that.id,_that.appId,_that.appName,_that.icon,_that.kind,_that.batchId,_that.target,_that.version,_that.force,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.commandOutput,_that.errorMessage,_that.errorCode,_that.errorDetail,_that.failure,_that.createdAt,_that.startedAt,_that.finishedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String appId,  String appName,  String? icon,  InstallTaskKind kind,  String? batchId,  AppOperationTargetSnapshot? target,  String? version,  bool force,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String commandOutput,  String? errorMessage,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure,  int createdAt,  int? startedAt,  int? finishedAt)?  $default,) {final _that = this;
switch (_that) {
case _InstallTask() when $default != null:
return $default(_that.id,_that.appId,_that.appName,_that.icon,_that.kind,_that.batchId,_that.target,_that.version,_that.force,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.commandOutput,_that.errorMessage,_that.errorCode,_that.errorDetail,_that.failure,_that.createdAt,_that.startedAt,_that.finishedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstallTask implements InstallTask {
  const _InstallTask({required this.id, required this.appId, required this.appName, this.icon, this.kind = InstallTaskKind.install, this.batchId, this.target, this.version, this.force = false, this.status = InstallStatus.pending, this.progress = 0.0, this.message, this.messageCode, this.rawMessage, this.commandOutput = '', this.errorMessage, this.errorCode, this.errorDetail, this.failure, required this.createdAt, this.startedAt, this.finishedAt});
  factory _InstallTask.fromJson(Map<String, dynamic> json) => _$InstallTaskFromJson(json);

/// 唯一任务ID
@override final  String id;
/// 应用ID
@override final  String appId;
/// 应用名称
@override final  String appName;
/// 应用图标URL
@override final  String? icon;
/// 队列任务类型
@override@JsonKey() final  InstallTaskKind kind;
/// 所属批次 ID；单任务和人工重试不属于批次。
@override final  String? batchId;
/// 入队时冻结的完整目标身份。
///
/// 旧版持久化任务可能为空，恢复时必须按中断处理，禁止仅凭 appId
/// 乐观判断更新已经成功。
@override final  AppOperationTargetSnapshot? target;
/// 目标版本
@override final  String? version;
/// 是否强制安装
@override@JsonKey() final  bool force;
/// 当前状态
@override@JsonKey() final  InstallStatus status;
/// 安装进度（`0.0..1.0` 比例值，由 [progressValue] 归一化后供 UI 消费）。
@override@JsonKey() final  double progress;
/// 旧快照中的状态文案；新任务不得写入本地化字符串。
@override final  String? message;
/// 可在当前语言下重新格式化的稳定阶段代码。
@override final  AppOperationMessageCode? messageCode;
/// 安装链路中保留的原始 message 文本，用于诊断。
@override final  String? rawMessage;
/// 当前任务累计的 ll-cli 命令与原始输出，随下载中心 item 生命周期保存。
@override@JsonKey() final  String commandOutput;
/// 旧快照中的错误文案；新任务不得写入本地化字符串。
@override final  String? errorMessage;
/// 错误代码
@override final  int? errorCode;
/// 错误详情
@override final  String? errorDetail;
/// 与 locale 无关的结构化失败事实。
@override final  AppOperationFailure? failure;
/// 任务创建时间戳
@override final  int createdAt;
/// 任务开始时间戳
@override final  int? startedAt;
/// 任务完成时间戳
@override final  int? finishedAt;

/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallTaskCopyWith<_InstallTask> get copyWith => __$InstallTaskCopyWithImpl<_InstallTask>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstallTaskToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallTask&&(identical(other.id, id) || other.id == id)&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.appName, appName) || other.appName == appName)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.batchId, batchId) || other.batchId == batchId)&&(identical(other.target, target) || other.target == target)&&(identical(other.version, version) || other.version == version)&&(identical(other.force, force) || other.force == force)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.messageCode, messageCode) || other.messageCode == messageCode)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&(identical(other.commandOutput, commandOutput) || other.commandOutput == commandOutput)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,appId,appName,icon,kind,batchId,target,version,force,status,progress,message,messageCode,rawMessage,commandOutput,errorMessage,errorCode,errorDetail,failure,createdAt,startedAt,finishedAt]);

@override
String toString() {
  return 'InstallTask(id: $id, appId: $appId, appName: $appName, icon: $icon, kind: $kind, batchId: $batchId, target: $target, version: $version, force: $force, status: $status, progress: $progress, message: $message, messageCode: $messageCode, rawMessage: $rawMessage, commandOutput: $commandOutput, errorMessage: $errorMessage, errorCode: $errorCode, errorDetail: $errorDetail, failure: $failure, createdAt: $createdAt, startedAt: $startedAt, finishedAt: $finishedAt)';
}


}

/// @nodoc
abstract mixin class _$InstallTaskCopyWith<$Res> implements $InstallTaskCopyWith<$Res> {
  factory _$InstallTaskCopyWith(_InstallTask value, $Res Function(_InstallTask) _then) = __$InstallTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String appId, String appName, String? icon, InstallTaskKind kind, String? batchId, AppOperationTargetSnapshot? target, String? version, bool force, InstallStatus status, double progress, String? message, AppOperationMessageCode? messageCode, String? rawMessage, String commandOutput, String? errorMessage, int? errorCode, String? errorDetail, AppOperationFailure? failure, int createdAt, int? startedAt, int? finishedAt
});


@override $AppOperationTargetSnapshotCopyWith<$Res>? get target;@override $AppOperationFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$InstallTaskCopyWithImpl<$Res>
    implements _$InstallTaskCopyWith<$Res> {
  __$InstallTaskCopyWithImpl(this._self, this._then);

  final _InstallTask _self;
  final $Res Function(_InstallTask) _then;

/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? appId = null,Object? appName = null,Object? icon = freezed,Object? kind = null,Object? batchId = freezed,Object? target = freezed,Object? version = freezed,Object? force = null,Object? status = null,Object? progress = null,Object? message = freezed,Object? messageCode = freezed,Object? rawMessage = freezed,Object? commandOutput = null,Object? errorMessage = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? failure = freezed,Object? createdAt = null,Object? startedAt = freezed,Object? finishedAt = freezed,}) {
  return _then(_InstallTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,appName: null == appName ? _self.appName : appName // ignore: cast_nullable_to_non_nullable
as String,icon: freezed == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String?,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InstallTaskKind,batchId: freezed == batchId ? _self.batchId : batchId // ignore: cast_nullable_to_non_nullable
as String?,target: freezed == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as AppOperationTargetSnapshot?,version: freezed == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String?,force: null == force ? _self.force : force // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,messageCode: freezed == messageCode ? _self.messageCode : messageCode // ignore: cast_nullable_to_non_nullable
as AppOperationMessageCode?,rawMessage: freezed == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String?,commandOutput: null == commandOutput ? _self.commandOutput : commandOutput // ignore: cast_nullable_to_non_nullable
as String,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as int?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppOperationFailure?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int?,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppOperationTargetSnapshotCopyWith<$Res>? get target {
    if (_self.target == null) {
    return null;
  }

  return $AppOperationTargetSnapshotCopyWith<$Res>(_self.target!, (value) {
    return _then(_self.copyWith(target: value));
  });
}/// Create a copy of InstallTask
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppOperationFailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $AppOperationFailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
