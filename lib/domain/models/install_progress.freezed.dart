// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'install_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InstallProgress {

 String get appId; InstallProgressEventType get eventType; InstallStatus get status; double get progress;/// 旧调用方使用的展示文案；新 Data 事件保持为空。
 String? get message;/// 可在当前语言下重新格式化的稳定阶段代码。
 AppOperationMessageCode? get messageCode;/// ll-cli 返回的原始 message 文本。
 String? get rawMessage;/// ll-cli 输出流中的原始单行内容，用于下载中心按任务保存诊断日志。
 String? get outputLine;/// 旧调用方使用的错误摘要；新 Data 事件保持为空。
 String? get error; int? get errorCode;/// 后端返回的原始错误详情。
 String? get errorDetail;/// 与 locale 无关的结构化失败事实。
 AppOperationFailure? get failure;
/// Create a copy of InstallProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstallProgressCopyWith<InstallProgress> get copyWith => _$InstallProgressCopyWithImpl<InstallProgress>(this as InstallProgress, _$identity);

  /// Serializes this InstallProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstallProgress&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.messageCode, messageCode) || other.messageCode == messageCode)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&(identical(other.outputLine, outputLine) || other.outputLine == outputLine)&&(identical(other.error, error) || other.error == error)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.failure, failure) || other.failure == failure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,eventType,status,progress,message,messageCode,rawMessage,outputLine,error,errorCode,errorDetail,failure);

@override
String toString() {
  return 'InstallProgress(appId: $appId, eventType: $eventType, status: $status, progress: $progress, message: $message, messageCode: $messageCode, rawMessage: $rawMessage, outputLine: $outputLine, error: $error, errorCode: $errorCode, errorDetail: $errorDetail, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InstallProgressCopyWith<$Res>  {
  factory $InstallProgressCopyWith(InstallProgress value, $Res Function(InstallProgress) _then) = _$InstallProgressCopyWithImpl;
@useResult
$Res call({
 String appId, InstallProgressEventType eventType, InstallStatus status, double progress, String? message, AppOperationMessageCode? messageCode, String? rawMessage, String? outputLine, String? error, int? errorCode, String? errorDetail, AppOperationFailure? failure
});


$AppOperationFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$InstallProgressCopyWithImpl<$Res>
    implements $InstallProgressCopyWith<$Res> {
  _$InstallProgressCopyWithImpl(this._self, this._then);

  final InstallProgress _self;
  final $Res Function(InstallProgress) _then;

/// Create a copy of InstallProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? appId = null,Object? eventType = null,Object? status = null,Object? progress = null,Object? message = freezed,Object? messageCode = freezed,Object? rawMessage = freezed,Object? outputLine = freezed,Object? error = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as InstallProgressEventType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,messageCode: freezed == messageCode ? _self.messageCode : messageCode // ignore: cast_nullable_to_non_nullable
as AppOperationMessageCode?,rawMessage: freezed == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String?,outputLine: freezed == outputLine ? _self.outputLine : outputLine // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as int?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppOperationFailure?,
  ));
}
/// Create a copy of InstallProgress
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


/// Adds pattern-matching-related methods to [InstallProgress].
extension InstallProgressPatterns on InstallProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstallProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstallProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstallProgress value)  $default,){
final _that = this;
switch (_that) {
case _InstallProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstallProgress value)?  $default,){
final _that = this;
switch (_that) {
case _InstallProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String appId,  InstallProgressEventType eventType,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String? outputLine,  String? error,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstallProgress() when $default != null:
return $default(_that.appId,_that.eventType,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.outputLine,_that.error,_that.errorCode,_that.errorDetail,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String appId,  InstallProgressEventType eventType,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String? outputLine,  String? error,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure)  $default,) {final _that = this;
switch (_that) {
case _InstallProgress():
return $default(_that.appId,_that.eventType,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.outputLine,_that.error,_that.errorCode,_that.errorDetail,_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String appId,  InstallProgressEventType eventType,  InstallStatus status,  double progress,  String? message,  AppOperationMessageCode? messageCode,  String? rawMessage,  String? outputLine,  String? error,  int? errorCode,  String? errorDetail,  AppOperationFailure? failure)?  $default,) {final _that = this;
switch (_that) {
case _InstallProgress() when $default != null:
return $default(_that.appId,_that.eventType,_that.status,_that.progress,_that.message,_that.messageCode,_that.rawMessage,_that.outputLine,_that.error,_that.errorCode,_that.errorDetail,_that.failure);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstallProgress implements InstallProgress {
  const _InstallProgress({required this.appId, this.eventType = InstallProgressEventType.message, required this.status, this.progress = 0.0, this.message, this.messageCode, this.rawMessage, this.outputLine, this.error, this.errorCode, this.errorDetail, this.failure});
  factory _InstallProgress.fromJson(Map<String, dynamic> json) => _$InstallProgressFromJson(json);

@override final  String appId;
@override@JsonKey() final  InstallProgressEventType eventType;
@override final  InstallStatus status;
@override@JsonKey() final  double progress;
/// 旧调用方使用的展示文案；新 Data 事件保持为空。
@override final  String? message;
/// 可在当前语言下重新格式化的稳定阶段代码。
@override final  AppOperationMessageCode? messageCode;
/// ll-cli 返回的原始 message 文本。
@override final  String? rawMessage;
/// ll-cli 输出流中的原始单行内容，用于下载中心按任务保存诊断日志。
@override final  String? outputLine;
/// 旧调用方使用的错误摘要；新 Data 事件保持为空。
@override final  String? error;
@override final  int? errorCode;
/// 后端返回的原始错误详情。
@override final  String? errorDetail;
/// 与 locale 无关的结构化失败事实。
@override final  AppOperationFailure? failure;

/// Create a copy of InstallProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstallProgressCopyWith<_InstallProgress> get copyWith => __$InstallProgressCopyWithImpl<_InstallProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstallProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstallProgress&&(identical(other.appId, appId) || other.appId == appId)&&(identical(other.eventType, eventType) || other.eventType == eventType)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.message, message) || other.message == message)&&(identical(other.messageCode, messageCode) || other.messageCode == messageCode)&&(identical(other.rawMessage, rawMessage) || other.rawMessage == rawMessage)&&(identical(other.outputLine, outputLine) || other.outputLine == outputLine)&&(identical(other.error, error) || other.error == error)&&(identical(other.errorCode, errorCode) || other.errorCode == errorCode)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.failure, failure) || other.failure == failure));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,appId,eventType,status,progress,message,messageCode,rawMessage,outputLine,error,errorCode,errorDetail,failure);

@override
String toString() {
  return 'InstallProgress(appId: $appId, eventType: $eventType, status: $status, progress: $progress, message: $message, messageCode: $messageCode, rawMessage: $rawMessage, outputLine: $outputLine, error: $error, errorCode: $errorCode, errorDetail: $errorDetail, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$InstallProgressCopyWith<$Res> implements $InstallProgressCopyWith<$Res> {
  factory _$InstallProgressCopyWith(_InstallProgress value, $Res Function(_InstallProgress) _then) = __$InstallProgressCopyWithImpl;
@override @useResult
$Res call({
 String appId, InstallProgressEventType eventType, InstallStatus status, double progress, String? message, AppOperationMessageCode? messageCode, String? rawMessage, String? outputLine, String? error, int? errorCode, String? errorDetail, AppOperationFailure? failure
});


@override $AppOperationFailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$InstallProgressCopyWithImpl<$Res>
    implements _$InstallProgressCopyWith<$Res> {
  __$InstallProgressCopyWithImpl(this._self, this._then);

  final _InstallProgress _self;
  final $Res Function(_InstallProgress) _then;

/// Create a copy of InstallProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? appId = null,Object? eventType = null,Object? status = null,Object? progress = null,Object? message = freezed,Object? messageCode = freezed,Object? rawMessage = freezed,Object? outputLine = freezed,Object? error = freezed,Object? errorCode = freezed,Object? errorDetail = freezed,Object? failure = freezed,}) {
  return _then(_InstallProgress(
appId: null == appId ? _self.appId : appId // ignore: cast_nullable_to_non_nullable
as String,eventType: null == eventType ? _self.eventType : eventType // ignore: cast_nullable_to_non_nullable
as InstallProgressEventType,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InstallStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,messageCode: freezed == messageCode ? _self.messageCode : messageCode // ignore: cast_nullable_to_non_nullable
as AppOperationMessageCode?,rawMessage: freezed == rawMessage ? _self.rawMessage : rawMessage // ignore: cast_nullable_to_non_nullable
as String?,outputLine: freezed == outputLine ? _self.outputLine : outputLine // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,errorCode: freezed == errorCode ? _self.errorCode : errorCode // ignore: cast_nullable_to_non_nullable
as int?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as AppOperationFailure?,
  ));
}

/// Create a copy of InstallProgress
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
