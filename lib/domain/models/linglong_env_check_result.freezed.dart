// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linglong_env_check_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinglongEnvCheckResult {

/// 是否通过检测
 bool get isOk;/// 非阻断警告信息
 String? get warningMessage;/// ll-cli 版本
 String? get llCliVersion;/// linglong-bin 版本
 String? get llBinVersion;/// 系统架构
 String? get arch;/// 操作系统版本
 String? get osVersion;/// glibc 版本
 String? get glibcVersion;/// 内核信息
 String? get kernelInfo;/// 额外诊断信息
 String? get detailMsg;/// 默认仓库名
 String? get repoName;/// 仓库列表
 List<LinglongRepoInfo> get repos;/// 是否在容器环境中
 bool get isContainer;/// 当前 Linux 发行版画像。
///
/// 这是环境检测链路向下游透传“发行版特殊适配”信息的统一出口。
/// 后续如果新增发行版特殊提示，应继续复用这个字段，
/// 不要重新在结果模型里增加 `isUos` / `isDeepin` 之类一次性布尔值。
 LinuxDistribution get distribution;/// repo 状态
 RepoStatus get repoStatus;/// 导致环境检测失败的用户可读命令。
///
/// 该字段用于把“命令执行失败”和“业务数据为空”区分开；
/// 启动期仓库读取失败时会记录为 `ll-cli --json repo show`，
/// UI 可据此向用户说明失败的是仓库读取命令，而不是仓库一定没有配置。
 String? get failedCommand;/// 失败命令退出码。
///
/// 退出码本身不直接决定 UI 文案，但保留它能帮助日志、测试和后续诊断
/// 精确还原底层命令状态，避免只依赖模糊错误文案。
 int? get failedCommandExitCode;/// 推荐的环境恢复动作。
///
/// 该字段只表达“当前诊断建议用户执行什么动作”，不携带命令文本；
/// 具体命令仍由 Application/Service 层受控封装。
 LinglongEnvRecoveryAction? get recoveryAction;/// 错误消息
 String? get errorMessage;/// 错误详情
 String? get errorDetail;/// 检测时间戳
 int get checkedAt;
/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinglongEnvCheckResultCopyWith<LinglongEnvCheckResult> get copyWith => _$LinglongEnvCheckResultCopyWithImpl<LinglongEnvCheckResult>(this as LinglongEnvCheckResult, _$identity);

  /// Serializes this LinglongEnvCheckResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinglongEnvCheckResult&&(identical(other.isOk, isOk) || other.isOk == isOk)&&(identical(other.warningMessage, warningMessage) || other.warningMessage == warningMessage)&&(identical(other.llCliVersion, llCliVersion) || other.llCliVersion == llCliVersion)&&(identical(other.llBinVersion, llBinVersion) || other.llBinVersion == llBinVersion)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.glibcVersion, glibcVersion) || other.glibcVersion == glibcVersion)&&(identical(other.kernelInfo, kernelInfo) || other.kernelInfo == kernelInfo)&&(identical(other.detailMsg, detailMsg) || other.detailMsg == detailMsg)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&const DeepCollectionEquality().equals(other.repos, repos)&&(identical(other.isContainer, isContainer) || other.isContainer == isContainer)&&(identical(other.distribution, distribution) || other.distribution == distribution)&&(identical(other.repoStatus, repoStatus) || other.repoStatus == repoStatus)&&(identical(other.failedCommand, failedCommand) || other.failedCommand == failedCommand)&&(identical(other.failedCommandExitCode, failedCommandExitCode) || other.failedCommandExitCode == failedCommandExitCode)&&(identical(other.recoveryAction, recoveryAction) || other.recoveryAction == recoveryAction)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,isOk,warningMessage,llCliVersion,llBinVersion,arch,osVersion,glibcVersion,kernelInfo,detailMsg,repoName,const DeepCollectionEquality().hash(repos),isContainer,distribution,repoStatus,failedCommand,failedCommandExitCode,recoveryAction,errorMessage,errorDetail,checkedAt]);

@override
String toString() {
  return 'LinglongEnvCheckResult(isOk: $isOk, warningMessage: $warningMessage, llCliVersion: $llCliVersion, llBinVersion: $llBinVersion, arch: $arch, osVersion: $osVersion, glibcVersion: $glibcVersion, kernelInfo: $kernelInfo, detailMsg: $detailMsg, repoName: $repoName, repos: $repos, isContainer: $isContainer, distribution: $distribution, repoStatus: $repoStatus, failedCommand: $failedCommand, failedCommandExitCode: $failedCommandExitCode, recoveryAction: $recoveryAction, errorMessage: $errorMessage, errorDetail: $errorDetail, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class $LinglongEnvCheckResultCopyWith<$Res>  {
  factory $LinglongEnvCheckResultCopyWith(LinglongEnvCheckResult value, $Res Function(LinglongEnvCheckResult) _then) = _$LinglongEnvCheckResultCopyWithImpl;
@useResult
$Res call({
 bool isOk, String? warningMessage, String? llCliVersion, String? llBinVersion, String? arch, String? osVersion, String? glibcVersion, String? kernelInfo, String? detailMsg, String? repoName, List<LinglongRepoInfo> repos, bool isContainer, LinuxDistribution distribution, RepoStatus repoStatus, String? failedCommand, int? failedCommandExitCode, LinglongEnvRecoveryAction? recoveryAction, String? errorMessage, String? errorDetail, int checkedAt
});


$LinuxDistributionCopyWith<$Res> get distribution;

}
/// @nodoc
class _$LinglongEnvCheckResultCopyWithImpl<$Res>
    implements $LinglongEnvCheckResultCopyWith<$Res> {
  _$LinglongEnvCheckResultCopyWithImpl(this._self, this._then);

  final LinglongEnvCheckResult _self;
  final $Res Function(LinglongEnvCheckResult) _then;

/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOk = null,Object? warningMessage = freezed,Object? llCliVersion = freezed,Object? llBinVersion = freezed,Object? arch = freezed,Object? osVersion = freezed,Object? glibcVersion = freezed,Object? kernelInfo = freezed,Object? detailMsg = freezed,Object? repoName = freezed,Object? repos = null,Object? isContainer = null,Object? distribution = null,Object? repoStatus = null,Object? failedCommand = freezed,Object? failedCommandExitCode = freezed,Object? recoveryAction = freezed,Object? errorMessage = freezed,Object? errorDetail = freezed,Object? checkedAt = null,}) {
  return _then(LinglongEnvCheckResult(
isOk: null == isOk ? _self.isOk : isOk // ignore: cast_nullable_to_non_nullable
as bool,warningMessage: freezed == warningMessage ? _self.warningMessage : warningMessage // ignore: cast_nullable_to_non_nullable
as String?,llCliVersion: freezed == llCliVersion ? _self.llCliVersion : llCliVersion // ignore: cast_nullable_to_non_nullable
as String?,llBinVersion: freezed == llBinVersion ? _self.llBinVersion : llBinVersion // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,glibcVersion: freezed == glibcVersion ? _self.glibcVersion : glibcVersion // ignore: cast_nullable_to_non_nullable
as String?,kernelInfo: freezed == kernelInfo ? _self.kernelInfo : kernelInfo // ignore: cast_nullable_to_non_nullable
as String?,detailMsg: freezed == detailMsg ? _self.detailMsg : detailMsg // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repos: null == repos ? _self.repos : repos // ignore: cast_nullable_to_non_nullable
as List<LinglongRepoInfo>,isContainer: null == isContainer ? _self.isContainer : isContainer // ignore: cast_nullable_to_non_nullable
as bool,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as LinuxDistribution,repoStatus: null == repoStatus ? _self.repoStatus : repoStatus // ignore: cast_nullable_to_non_nullable
as RepoStatus,failedCommand: freezed == failedCommand ? _self.failedCommand : failedCommand // ignore: cast_nullable_to_non_nullable
as String?,failedCommandExitCode: freezed == failedCommandExitCode ? _self.failedCommandExitCode : failedCommandExitCode // ignore: cast_nullable_to_non_nullable
as int?,recoveryAction: freezed == recoveryAction ? _self.recoveryAction : recoveryAction // ignore: cast_nullable_to_non_nullable
as LinglongEnvRecoveryAction?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinuxDistributionCopyWith<$Res> get distribution {
  
  return $LinuxDistributionCopyWith<$Res>(_self.distribution, (value) {
    return _then(_self.copyWith(distribution: value));
  });
}
}


/// Adds pattern-matching-related methods to [LinglongEnvCheckResult].
extension LinglongEnvCheckResultPatterns on LinglongEnvCheckResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinglongEnvCheckResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinglongEnvCheckResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinglongEnvCheckResult value)  $default,){
final _that = this;
switch (_that) {
case _LinglongEnvCheckResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinglongEnvCheckResult value)?  $default,){
final _that = this;
switch (_that) {
case _LinglongEnvCheckResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOk,  String? warningMessage,  String? llCliVersion,  String? llBinVersion,  String? arch,  String? osVersion,  String? glibcVersion,  String? kernelInfo,  String? detailMsg,  String? repoName,  List<LinglongRepoInfo> repos,  bool isContainer,  LinuxDistribution distribution,  RepoStatus repoStatus,  String? failedCommand,  int? failedCommandExitCode,  LinglongEnvRecoveryAction? recoveryAction,  String? errorMessage,  String? errorDetail,  int checkedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinglongEnvCheckResult() when $default != null:
return $default(_that.isOk,_that.warningMessage,_that.llCliVersion,_that.llBinVersion,_that.arch,_that.osVersion,_that.glibcVersion,_that.kernelInfo,_that.detailMsg,_that.repoName,_that.repos,_that.isContainer,_that.distribution,_that.repoStatus,_that.failedCommand,_that.failedCommandExitCode,_that.recoveryAction,_that.errorMessage,_that.errorDetail,_that.checkedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOk,  String? warningMessage,  String? llCliVersion,  String? llBinVersion,  String? arch,  String? osVersion,  String? glibcVersion,  String? kernelInfo,  String? detailMsg,  String? repoName,  List<LinglongRepoInfo> repos,  bool isContainer,  LinuxDistribution distribution,  RepoStatus repoStatus,  String? failedCommand,  int? failedCommandExitCode,  LinglongEnvRecoveryAction? recoveryAction,  String? errorMessage,  String? errorDetail,  int checkedAt)  $default,) {final _that = this;
switch (_that) {
case _LinglongEnvCheckResult():
return $default(_that.isOk,_that.warningMessage,_that.llCliVersion,_that.llBinVersion,_that.arch,_that.osVersion,_that.glibcVersion,_that.kernelInfo,_that.detailMsg,_that.repoName,_that.repos,_that.isContainer,_that.distribution,_that.repoStatus,_that.failedCommand,_that.failedCommandExitCode,_that.recoveryAction,_that.errorMessage,_that.errorDetail,_that.checkedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOk,  String? warningMessage,  String? llCliVersion,  String? llBinVersion,  String? arch,  String? osVersion,  String? glibcVersion,  String? kernelInfo,  String? detailMsg,  String? repoName,  List<LinglongRepoInfo> repos,  bool isContainer,  LinuxDistribution distribution,  RepoStatus repoStatus,  String? failedCommand,  int? failedCommandExitCode,  LinglongEnvRecoveryAction? recoveryAction,  String? errorMessage,  String? errorDetail,  int checkedAt)?  $default,) {final _that = this;
switch (_that) {
case _LinglongEnvCheckResult() when $default != null:
return $default(_that.isOk,_that.warningMessage,_that.llCliVersion,_that.llBinVersion,_that.arch,_that.osVersion,_that.glibcVersion,_that.kernelInfo,_that.detailMsg,_that.repoName,_that.repos,_that.isContainer,_that.distribution,_that.repoStatus,_that.failedCommand,_that.failedCommandExitCode,_that.recoveryAction,_that.errorMessage,_that.errorDetail,_that.checkedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinglongEnvCheckResult implements LinglongEnvCheckResult {
  const _LinglongEnvCheckResult({required this.isOk, this.warningMessage, this.llCliVersion, this.llBinVersion, this.arch, this.osVersion, this.glibcVersion, this.kernelInfo, this.detailMsg, this.repoName,  List<LinglongRepoInfo> repos = const <LinglongRepoInfo>[], this.isContainer = false, this.distribution = const LinuxDistribution(), this.repoStatus = RepoStatus.unknown, this.failedCommand, this.failedCommandExitCode, this.recoveryAction, this.errorMessage, this.errorDetail, required this.checkedAt}): _repos = repos;
  factory _LinglongEnvCheckResult.fromJson(Map<String, dynamic> json) => _$LinglongEnvCheckResultFromJson(json);

/// 是否通过检测
@override final  bool isOk;
/// 非阻断警告信息
@override final  String? warningMessage;
/// ll-cli 版本
@override final  String? llCliVersion;
/// linglong-bin 版本
@override final  String? llBinVersion;
/// 系统架构
@override final  String? arch;
/// 操作系统版本
@override final  String? osVersion;
/// glibc 版本
@override final  String? glibcVersion;
/// 内核信息
@override final  String? kernelInfo;
/// 额外诊断信息
@override final  String? detailMsg;
/// 默认仓库名
@override final  String? repoName;
/// 仓库列表
 final  List<LinglongRepoInfo> _repos;
/// 仓库列表
@override@JsonKey() List<LinglongRepoInfo> get repos {
  if (_repos is EqualUnmodifiableListView) return _repos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_repos);
}

/// 是否在容器环境中
@override@JsonKey() final  bool isContainer;
/// 当前 Linux 发行版画像。
///
/// 这是环境检测链路向下游透传“发行版特殊适配”信息的统一出口。
/// 后续如果新增发行版特殊提示，应继续复用这个字段，
/// 不要重新在结果模型里增加 `isUos` / `isDeepin` 之类一次性布尔值。
@override@JsonKey() final  LinuxDistribution distribution;
/// repo 状态
@override@JsonKey() final  RepoStatus repoStatus;
/// 导致环境检测失败的用户可读命令。
///
/// 该字段用于把“命令执行失败”和“业务数据为空”区分开；
/// 启动期仓库读取失败时会记录为 `ll-cli --json repo show`，
/// UI 可据此向用户说明失败的是仓库读取命令，而不是仓库一定没有配置。
@override final  String? failedCommand;
/// 失败命令退出码。
///
/// 退出码本身不直接决定 UI 文案，但保留它能帮助日志、测试和后续诊断
/// 精确还原底层命令状态，避免只依赖模糊错误文案。
@override final  int? failedCommandExitCode;
/// 推荐的环境恢复动作。
///
/// 该字段只表达“当前诊断建议用户执行什么动作”，不携带命令文本；
/// 具体命令仍由 Application/Service 层受控封装。
@override final  LinglongEnvRecoveryAction? recoveryAction;
/// 错误消息
@override final  String? errorMessage;
/// 错误详情
@override final  String? errorDetail;
/// 检测时间戳
@override final  int checkedAt;

/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinglongEnvCheckResultCopyWith<_LinglongEnvCheckResult> get copyWith => __$LinglongEnvCheckResultCopyWithImpl<_LinglongEnvCheckResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinglongEnvCheckResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinglongEnvCheckResult&&(identical(other.isOk, isOk) || other.isOk == isOk)&&(identical(other.warningMessage, warningMessage) || other.warningMessage == warningMessage)&&(identical(other.llCliVersion, llCliVersion) || other.llCliVersion == llCliVersion)&&(identical(other.llBinVersion, llBinVersion) || other.llBinVersion == llBinVersion)&&(identical(other.arch, arch) || other.arch == arch)&&(identical(other.osVersion, osVersion) || other.osVersion == osVersion)&&(identical(other.glibcVersion, glibcVersion) || other.glibcVersion == glibcVersion)&&(identical(other.kernelInfo, kernelInfo) || other.kernelInfo == kernelInfo)&&(identical(other.detailMsg, detailMsg) || other.detailMsg == detailMsg)&&(identical(other.repoName, repoName) || other.repoName == repoName)&&const DeepCollectionEquality().equals(other._repos, _repos)&&(identical(other.isContainer, isContainer) || other.isContainer == isContainer)&&(identical(other.distribution, distribution) || other.distribution == distribution)&&(identical(other.repoStatus, repoStatus) || other.repoStatus == repoStatus)&&(identical(other.failedCommand, failedCommand) || other.failedCommand == failedCommand)&&(identical(other.failedCommandExitCode, failedCommandExitCode) || other.failedCommandExitCode == failedCommandExitCode)&&(identical(other.recoveryAction, recoveryAction) || other.recoveryAction == recoveryAction)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.errorDetail, errorDetail) || other.errorDetail == errorDetail)&&(identical(other.checkedAt, checkedAt) || other.checkedAt == checkedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,isOk,warningMessage,llCliVersion,llBinVersion,arch,osVersion,glibcVersion,kernelInfo,detailMsg,repoName,const DeepCollectionEquality().hash(_repos),isContainer,distribution,repoStatus,failedCommand,failedCommandExitCode,recoveryAction,errorMessage,errorDetail,checkedAt]);

@override
String toString() {
  return 'LinglongEnvCheckResult(isOk: $isOk, warningMessage: $warningMessage, llCliVersion: $llCliVersion, llBinVersion: $llBinVersion, arch: $arch, osVersion: $osVersion, glibcVersion: $glibcVersion, kernelInfo: $kernelInfo, detailMsg: $detailMsg, repoName: $repoName, repos: $repos, isContainer: $isContainer, distribution: $distribution, repoStatus: $repoStatus, failedCommand: $failedCommand, failedCommandExitCode: $failedCommandExitCode, recoveryAction: $recoveryAction, errorMessage: $errorMessage, errorDetail: $errorDetail, checkedAt: $checkedAt)';
}


}

/// @nodoc
abstract mixin class _$LinglongEnvCheckResultCopyWith<$Res> implements $LinglongEnvCheckResultCopyWith<$Res> {
  factory _$LinglongEnvCheckResultCopyWith(_LinglongEnvCheckResult value, $Res Function(_LinglongEnvCheckResult) _then) = __$LinglongEnvCheckResultCopyWithImpl;
@override @useResult
$Res call({
 bool isOk, String? warningMessage, String? llCliVersion, String? llBinVersion, String? arch, String? osVersion, String? glibcVersion, String? kernelInfo, String? detailMsg, String? repoName, List<LinglongRepoInfo> repos, bool isContainer, LinuxDistribution distribution, RepoStatus repoStatus, String? failedCommand, int? failedCommandExitCode, LinglongEnvRecoveryAction? recoveryAction, String? errorMessage, String? errorDetail, int checkedAt
});


@override $LinuxDistributionCopyWith<$Res> get distribution;

}
/// @nodoc
class __$LinglongEnvCheckResultCopyWithImpl<$Res>
    implements _$LinglongEnvCheckResultCopyWith<$Res> {
  __$LinglongEnvCheckResultCopyWithImpl(this._self, this._then);

  final _LinglongEnvCheckResult _self;
  final $Res Function(_LinglongEnvCheckResult) _then;

/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOk = null,Object? warningMessage = freezed,Object? llCliVersion = freezed,Object? llBinVersion = freezed,Object? arch = freezed,Object? osVersion = freezed,Object? glibcVersion = freezed,Object? kernelInfo = freezed,Object? detailMsg = freezed,Object? repoName = freezed,Object? repos = null,Object? isContainer = null,Object? distribution = null,Object? repoStatus = null,Object? failedCommand = freezed,Object? failedCommandExitCode = freezed,Object? recoveryAction = freezed,Object? errorMessage = freezed,Object? errorDetail = freezed,Object? checkedAt = null,}) {
  return _then(_LinglongEnvCheckResult(
isOk: null == isOk ? _self.isOk : isOk // ignore: cast_nullable_to_non_nullable
as bool,warningMessage: freezed == warningMessage ? _self.warningMessage : warningMessage // ignore: cast_nullable_to_non_nullable
as String?,llCliVersion: freezed == llCliVersion ? _self.llCliVersion : llCliVersion // ignore: cast_nullable_to_non_nullable
as String?,llBinVersion: freezed == llBinVersion ? _self.llBinVersion : llBinVersion // ignore: cast_nullable_to_non_nullable
as String?,arch: freezed == arch ? _self.arch : arch // ignore: cast_nullable_to_non_nullable
as String?,osVersion: freezed == osVersion ? _self.osVersion : osVersion // ignore: cast_nullable_to_non_nullable
as String?,glibcVersion: freezed == glibcVersion ? _self.glibcVersion : glibcVersion // ignore: cast_nullable_to_non_nullable
as String?,kernelInfo: freezed == kernelInfo ? _self.kernelInfo : kernelInfo // ignore: cast_nullable_to_non_nullable
as String?,detailMsg: freezed == detailMsg ? _self.detailMsg : detailMsg // ignore: cast_nullable_to_non_nullable
as String?,repoName: freezed == repoName ? _self.repoName : repoName // ignore: cast_nullable_to_non_nullable
as String?,repos: null == repos ? _self._repos : repos // ignore: cast_nullable_to_non_nullable
as List<LinglongRepoInfo>,isContainer: null == isContainer ? _self.isContainer : isContainer // ignore: cast_nullable_to_non_nullable
as bool,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as LinuxDistribution,repoStatus: null == repoStatus ? _self.repoStatus : repoStatus // ignore: cast_nullable_to_non_nullable
as RepoStatus,failedCommand: freezed == failedCommand ? _self.failedCommand : failedCommand // ignore: cast_nullable_to_non_nullable
as String?,failedCommandExitCode: freezed == failedCommandExitCode ? _self.failedCommandExitCode : failedCommandExitCode // ignore: cast_nullable_to_non_nullable
as int?,recoveryAction: freezed == recoveryAction ? _self.recoveryAction : recoveryAction // ignore: cast_nullable_to_non_nullable
as LinglongEnvRecoveryAction?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,errorDetail: freezed == errorDetail ? _self.errorDetail : errorDetail // ignore: cast_nullable_to_non_nullable
as String?,checkedAt: null == checkedAt ? _self.checkedAt : checkedAt // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of LinglongEnvCheckResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LinuxDistributionCopyWith<$Res> get distribution {
  
  return $LinuxDistributionCopyWith<$Res>(_self.distribution, (value) {
    return _then(_self.copyWith(distribution: value));
  });
}
}


/// @nodoc
mixin _$LinglongRepoInfo {

 String get name; String get url; String? get alias; String? get priority;
/// Create a copy of LinglongRepoInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinglongRepoInfoCopyWith<LinglongRepoInfo> get copyWith => _$LinglongRepoInfoCopyWithImpl<LinglongRepoInfo>(this as LinglongRepoInfo, _$identity);

  /// Serializes this LinglongRepoInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinglongRepoInfo&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.alias, alias) || other.alias == alias)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,url,alias,priority);

@override
String toString() {
  return 'LinglongRepoInfo(name: $name, url: $url, alias: $alias, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $LinglongRepoInfoCopyWith<$Res>  {
  factory $LinglongRepoInfoCopyWith(LinglongRepoInfo value, $Res Function(LinglongRepoInfo) _then) = _$LinglongRepoInfoCopyWithImpl;
@useResult
$Res call({
 String name, String url, String? alias, String? priority
});




}
/// @nodoc
class _$LinglongRepoInfoCopyWithImpl<$Res>
    implements $LinglongRepoInfoCopyWith<$Res> {
  _$LinglongRepoInfoCopyWithImpl(this._self, this._then);

  final LinglongRepoInfo _self;
  final $Res Function(LinglongRepoInfo) _then;

/// Create a copy of LinglongRepoInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? url = null,Object? alias = freezed,Object? priority = freezed,}) {
  return _then(LinglongRepoInfo(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinglongRepoInfo].
extension LinglongRepoInfoPatterns on LinglongRepoInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinglongRepoInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinglongRepoInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinglongRepoInfo value)  $default,){
final _that = this;
switch (_that) {
case _LinglongRepoInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinglongRepoInfo value)?  $default,){
final _that = this;
switch (_that) {
case _LinglongRepoInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String url,  String? alias,  String? priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinglongRepoInfo() when $default != null:
return $default(_that.name,_that.url,_that.alias,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String url,  String? alias,  String? priority)  $default,) {final _that = this;
switch (_that) {
case _LinglongRepoInfo():
return $default(_that.name,_that.url,_that.alias,_that.priority);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String url,  String? alias,  String? priority)?  $default,) {final _that = this;
switch (_that) {
case _LinglongRepoInfo() when $default != null:
return $default(_that.name,_that.url,_that.alias,_that.priority);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinglongRepoInfo implements LinglongRepoInfo {
  const _LinglongRepoInfo({required this.name, required this.url, this.alias, this.priority});
  factory _LinglongRepoInfo.fromJson(Map<String, dynamic> json) => _$LinglongRepoInfoFromJson(json);

@override final  String name;
@override final  String url;
@override final  String? alias;
@override final  String? priority;

/// Create a copy of LinglongRepoInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinglongRepoInfoCopyWith<_LinglongRepoInfo> get copyWith => __$LinglongRepoInfoCopyWithImpl<_LinglongRepoInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinglongRepoInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinglongRepoInfo&&(identical(other.name, name) || other.name == name)&&(identical(other.url, url) || other.url == url)&&(identical(other.alias, alias) || other.alias == alias)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,url,alias,priority);

@override
String toString() {
  return 'LinglongRepoInfo(name: $name, url: $url, alias: $alias, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$LinglongRepoInfoCopyWith<$Res> implements $LinglongRepoInfoCopyWith<$Res> {
  factory _$LinglongRepoInfoCopyWith(_LinglongRepoInfo value, $Res Function(_LinglongRepoInfo) _then) = __$LinglongRepoInfoCopyWithImpl;
@override @useResult
$Res call({
 String name, String url, String? alias, String? priority
});




}
/// @nodoc
class __$LinglongRepoInfoCopyWithImpl<$Res>
    implements _$LinglongRepoInfoCopyWith<$Res> {
  __$LinglongRepoInfoCopyWithImpl(this._self, this._then);

  final _LinglongRepoInfo _self;
  final $Res Function(_LinglongRepoInfo) _then;

/// Create a copy of LinglongRepoInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? url = null,Object? alias = freezed,Object? priority = freezed,}) {
  return _then(_LinglongRepoInfo(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,alias: freezed == alias ? _self.alias : alias // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
