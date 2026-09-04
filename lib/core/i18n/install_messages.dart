import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/models/app_operation_failure.dart';
import '../../domain/models/install_progress.dart';
import '../../domain/models/install_task.dart';
import '../../domain/models/linux_distribution.dart';
import 'l10n/app_localizations.dart';

/// 安装相关消息的国际化辅助类
///
/// 用于在 widget 树外（如 Repository 层）访问国际化字符串。
/// 通过 [Locale] 获取对应的翻译。
class InstallMessages {
  InstallMessages._(this._l10n);

  final AppLocalizations _l10n;

  /// 从 Locale 创建
  factory InstallMessages.fromLocale(Locale locale) {
    return InstallMessages._(lookupAppLocalizations(locale));
  }

  /// 从 AppLocalizations 创建（用于 widget 树内）
  factory InstallMessages.fromL10n(AppLocalizations l10n) {
    return InstallMessages._(l10n);
  }

  /// 操作标签
  String get installLabel => _l10n.operationInstall;
  String get updateLabel => _l10n.operationUpdate;

  // ==================== 错误码消息 ====================

  /// 根据错误码获取用户友好的错误消息
  String getErrorMessageFromCode(int code) {
    switch (code) {
      case -1:
        return _l10n.installErrorGeneric;
      case -2:
        return _l10n.installErrorTimeout;
      case 1:
        return _l10n.installCancelled;
      case 1000:
        return _l10n.installErrorUnknown;
      case 1001:
        return _l10n.installErrorAppNotFoundRemote;
      case 1002:
        return _l10n.installErrorAppNotFoundLocal;
      case 2001:
        return _l10n.installFailed;
      case 2002:
        return _l10n.installErrorAppNotInRemote;
      case 2003:
        return _l10n.installErrorSameVersion;
      case 2004:
        return _l10n.installErrorDowngrade;
      case 2005:
        return _l10n.installErrorModuleVersionNotAllowed;
      case 2006:
        return _l10n.installErrorModuleRequiresApp;
      case 2007:
        return _l10n.installErrorModuleExists;
      case 2008:
        return _l10n.installErrorArchMismatch;
      case 2009:
        return _l10n.installErrorModuleNotInRemote;
      case 2010:
        return _l10n.installErrorMissingErofs;
      case 2011:
        return _l10n.installErrorUnsupportedFormat;
      case 3001:
        return _l10n.installErrorNetwork;
      case 4001:
        return _l10n.installErrorInvalidRef;
      case 4002:
        return _l10n.installErrorUnknownArch;
      default:
        return _l10n.installErrorCode(code);
    }
  }

  // ==================== 状态消息 ====================

  /// 从 ll-cli 原始行或旧持久化 JSON 文本中提取纯 message 内容。
  String extractMessageText(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final rawMessage = decoded['message']?.toString().trim();
        if (rawMessage != null && rawMessage.isNotEmpty) {
          return rawMessage;
        }
      }
    } catch (_) {
      // 非 JSON 行按普通文本处理。
    }

    return trimmed;
  }

  /// 根据消息内容生成用户友好的状态描述
  String getStatusFromMessage(String message) {
    final plainMessage = extractMessageText(message);
    final lower = plainMessage.toLowerCase();

    if (lower.contains('beginning to install')) {
      return _l10n.installStatusStarting;
    } else if (lower.contains('installing application')) {
      return _l10n.installStatusInstallingApp;
    } else if (lower.contains('installing runtime')) {
      return _l10n.installStatusInstallingRuntime;
    } else if (lower.contains('installing base')) {
      return _l10n.installStatusInstallingBase;
    } else if (lower.contains('downloading metadata')) {
      return _l10n.installStatusDownloadingMeta;
    } else if (lower.contains('downloading files') ||
        lower.contains('downloading')) {
      return _l10n.installStatusDownloadingFiles;
    } else if (lower.contains('processing after install')) {
      return _l10n.installStatusPostProcessing;
    } else if (lower.contains('success') || lower.contains('completed')) {
      return _l10n.installStatusCompleted;
    } else if (plainMessage.isNotEmpty) {
      // 保留完整文案给 Tooltip、复制和无障碍语义使用；视觉截断只允许在 UI 层处理。
      return plainMessage;
    }
    return _l10n.installStatusProcessing;
  }

  // ==================== 操作消息 ====================

  /// 等待操作
  String waitingFor(String operation) => _l10n.waitingForOperation(operation);

  /// 准备操作
  String preparing(String operation, String appId) =>
      _l10n.operationPreparing(operation, appId);

  /// 操作已取消
  String cancelled(String operation) => _l10n.operationCancelled(operation);

  /// 操作完成
  String completed(String operation) => _l10n.operationCompleted(operation);

  /// 操作状态未知
  String unknownStatus(String operation) => _l10n.operationUnknown(operation);

  /// 无法确认操作结果
  String confirmFailed(String operation) =>
      _l10n.operationConfirmFailed(operation);

  /// 操作超时
  String timeout(String operation) => _l10n.operationTimeout(operation);

  /// 操作失败
  String failed(String operation) => _l10n.operationFailed(operation);

  /// 按当前语言格式化一个持久化任务的状态文案。
  ///
  /// 结构化字段优先；旧字符串字段只用于兼容升级前的 Journal。该方法必须在
  /// Presentation 构建时调用，禁止把返回值重新写回任务状态。
  String messageForTask(
    InstallTask task, {
    LinuxDistribution distribution = LinuxDistribution.unknown,
  }) {
    if (task.status == InstallStatus.failed) {
      return errorMessageForTask(task, distribution: distribution);
    }

    final operation = _operationForTask(task);
    return switch (task.status) {
      InstallStatus.pending => waitingFor(operation),
      InstallStatus.downloading || InstallStatus.installing =>
        (task.messageCode == AppOperationMessageCode.preparing
                ? preparing(operation, task.appId)
                : _messageForCode(task.messageCode)) ??
            task.displayMessage ??
            _l10n.installStatusProcessing,
      InstallStatus.success => completed(operation),
      InstallStatus.cancelled => cancelled(operation),
      InstallStatus.interrupted => taskCrashInterrupted,
      InstallStatus.failed => failed(operation),
    };
  }

  /// 按当前语言格式化任务失败摘要，同时保留原始诊断的排障价值。
  ///
  /// [AppOperationFailure.diagnostic] 不会被修改；只有最终显示文本会按既有规则
  /// 追加诊断和发行版提示。
  String errorMessageForTask(
    InstallTask task, {
    LinuxDistribution distribution = LinuxDistribution.unknown,
  }) {
    final failure = task.failure;
    if (failure == null) {
      final legacyMessage =
          task.errorMessage ??
          task.displayMessage ??
          failed(_operationForTask(task));
      return appendDistributionGuidance(
        distribution: distribution,
        scenario: task.isUpdateTask
            ? LinuxDistributionGuidanceScenario.appUpdateFailure
            : LinuxDistributionGuidanceScenario.appInstallFailure,
        message: legacyMessage,
      );
    }

    final operation = _operationForTask(task);
    final summary = switch (failure.kind) {
      AppOperationFailureKind.cli =>
        failure.cliCode == null
            ? failed(operation)
            : getErrorMessageFromCode(failure.cliCode!),
      AppOperationFailureKind.timeout => timeout(operation),
      AppOperationFailureKind.resultUnconfirmed ||
      AppOperationFailureKind.streamEndedWithoutTerminal => confirmFailed(
        operation,
      ),
      AppOperationFailureKind.execution => failed(operation),
      AppOperationFailureKind.interrupted => taskCrashRetryHint,
      // 特权 helper 授权链路失败（docs/47 §10.2/§10.3）：给出明确的授权语义
      // 文案，而不是泛化的“操作失败”。
      AppOperationFailureKind.authorizationCancelled =>
        _l10n.installErrorAuthorizationCancelled,
      AppOperationFailureKind.helperUnavailable =>
        _l10n.installErrorHelperUnavailable,
    };
    final detail = failure.diagnostic?.trim();
    final message =
        detail == null ||
            detail.isEmpty ||
            detail == summary ||
            summary.contains(detail)
        ? summary
        : '$summary: $detail';
    final scenario =
        failure.guidanceScenario ??
        (task.isUpdateTask
            ? LinuxDistributionGuidanceScenario.appUpdateFailure
            : LinuxDistributionGuidanceScenario.appInstallFailure);
    return appendDistributionGuidance(
      distribution: distribution,
      scenario: scenario,
      message: message,
    );
  }

  /// 把稳定阶段代码映射到当前 locale。
  String? _messageForCode(AppOperationMessageCode? code) {
    return switch (code) {
      AppOperationMessageCode.preparing => null,
      AppOperationMessageCode.starting => _l10n.installStatusStarting,
      AppOperationMessageCode.installingApplication =>
        _l10n.installStatusInstallingApp,
      AppOperationMessageCode.installingRuntime =>
        _l10n.installStatusInstallingRuntime,
      AppOperationMessageCode.installingBase =>
        _l10n.installStatusInstallingBase,
      AppOperationMessageCode.downloadingMetadata =>
        _l10n.installStatusDownloadingMeta,
      AppOperationMessageCode.downloadingFiles =>
        _l10n.installStatusDownloadingFiles,
      AppOperationMessageCode.postProcessing =>
        _l10n.installStatusPostProcessing,
      AppOperationMessageCode.processing => _l10n.installStatusProcessing,
      AppOperationMessageCode.completed => _l10n.installStatusCompleted,
      null => null,
    };
  }

  /// 获取任务类型对应的当前语言操作名。
  String _operationForTask(InstallTask task) {
    return task.isUpdateTask ? updateLabel : installLabel;
  }

  // ==================== 其他消息 ====================

  /// 卸载失败
  String uninstallFailed(String error) => _l10n.uninstallFailedWithError(error);

  /// 卸载异常
  String uninstallException(String error) => _l10n.uninstallException(error);

  /// 终止失败
  String stopFailed(String error) => _l10n.stopFailedWithError(error);

  /// 终止异常
  String stopException(String error) => _l10n.stopException(error);

  /// 快捷方式已创建
  String get shortcutCreated => _l10n.shortcutCreated;

  /// 快捷方式已创建（带路径）
  String shortcutCreatedWithPath(String path) =>
      _l10n.shortcutCreatedWithPath(path);

  /// 创建失败
  String shortcutCreateFailed(String error) =>
      _l10n.shortcutCreateFailedWithError(error);

  /// 清理失败
  String pruneFailed(String error) => _l10n.pruneFailedWithError(error);

  /// 清理异常
  String pruneException(String error) => _l10n.pruneException(error);

  /// 获取版本失败
  String get versionFailed => _l10n.getVersionFailed;

  /// 任务崩溃中断
  String get taskCrashInterrupted => _l10n.taskCrashInterrupted;

  /// 任务崩溃重试提示
  String get taskCrashRetryHint => _l10n.taskCrashRetryHint;

  /// ll-cli 未安装
  String get llCliNotInstalled => _l10n.llCliNotInstalled;

  /// 无法获取应用信息
  String get appInfoUnavailable => _l10n.appInfoUnavailable;

  /// 创建快捷方式失败
  String shortcutCreateException(String error) =>
      _l10n.shortcutCreateException(error);

  /// 安装超时
  String get installTimeout => _l10n.installTimeout;

  /// 获取发行版在指定场景下的特殊提示。
  ///
  /// 当前只有 UOS 实现了特殊提示，但调用侧无需再关心 `isUos` 这种发行版细节。
  ///
  /// 这里是“发行版能力 -> 业务场景提示文案”的唯一映射点：
  /// - 模型层只声明 capability / scenario；
  /// - 文案层只在这里决定最终展示哪条 l10n 文案；
  /// - 页面和 Provider 不允许再各自 switch 发行版名称。
  ///
  /// 后续新增发行版时，优先在这里补映射，而不是在页面里插入新的条件分支。
  String? guidanceForDistribution({
    required LinuxDistribution distribution,
    required LinuxDistributionGuidanceScenario scenario,
  }) {
    if (!distribution.supportsGuidanceScenario(scenario)) {
      return null;
    }

    return switch ((distribution.id, scenario)) {
      (
        LinuxDistributionId.uos,
        LinuxDistributionGuidanceScenario.envInstallDialog,
      ) =>
        _l10n.uosEnvInstallHint,
      (
        LinuxDistributionId.uos,
        LinuxDistributionGuidanceScenario.appInstallFailure,
      ) =>
        _l10n.uosAppInstallFailureHint,
      _ => null,
    };
  }

  /// 在原始失败文案后追加发行版特殊提示。
  ///
  /// 这里会自动处理空字符串和重复追加，
  /// 这样队列层/UI 层只需要把“原始失败文案 + distribution + scenario”交进来即可。
  String appendDistributionGuidance({
    required LinuxDistribution distribution,
    required LinuxDistributionGuidanceScenario scenario,
    required String message,
  }) {
    final hint = guidanceForDistribution(
      distribution: distribution,
      scenario: scenario,
    );
    if (hint == null) {
      return message.trim();
    }

    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return hint;
    }
    if (trimmed.contains(hint)) {
      return trimmed;
    }
    return '$trimmed $hint';
  }
}

/// 安装阶段判断（纯逻辑，不依赖 i18n）
class InstallPhaseDetector {
  InstallPhaseDetector._();

  /// 根据消息内容判断是否处于下载阶段
  static bool isDownloading(String message) {
    final lower = message.toLowerCase();
    return lower.contains('download') || lower.contains('downloading');
  }

  /// 根据消息内容判断是否处于安装阶段
  static bool isInstalling(String message) {
    final lower = message.toLowerCase();
    return lower.contains('installing') ||
        lower.contains('unpacking') ||
        lower.contains('extracting') ||
        lower.contains('processing');
  }
}
