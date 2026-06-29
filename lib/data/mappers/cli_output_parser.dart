import 'dart:convert';

import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';

/// ll-cli JSON 输出解析器
///
/// 本文件只负责把 `ll-cli --json` 的结构化输出转换为领域模型。
/// 文本表格输出不再作为业务输入，避免不同 linyaps 版本的列宽、表头和本地化文案
/// 影响列表、搜索、进程和安装状态判断的稳定性。
class CliOutputParser {
  CliOutputParser._();

  /// 解析已安装应用列表。
  ///
  /// 仅接受 `ll-cli list --json` 返回的顶层数组；解析失败时返回空列表，
  /// 由调用方根据命令退出码决定是否展示环境异常。
  static List<InstalledApp> parseInstalledApps(String output) {
    final sanitizedOutput = output.trim();
    if (sanitizedOutput.isEmpty) {
      return const [];
    }

    return _parseInstalledAppsFromJson(sanitizedOutput);
  }

  /// 解析 `ll-cli list --json` 输出。
  ///
  /// 字段结构与旧版 Rust 商店保持一致：`arch`/`size` 可能是字符串、数字或数组，
  /// 因此这里做宽松解析，避免因为字段类型变化导致安装列表富化链路中断。
  static List<InstalledApp> _parseInstalledAppsFromJson(String output) {
    try {
      final decoded = jsonDecode(output);
      if (decoded is! List<dynamic>) {
        return const [];
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapInstalledAppFromJson)
          .whereType<InstalledApp>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// 将单个应用 JSON 对象转换为已安装应用模型。
  ///
  /// `repoName` 在 `search --json` 分组对象里可能只体现在父级仓库名上，
  /// 因此允许调用方传入 `fallbackRepoName` 作为缺省仓库来源。
  static InstalledApp? _mapInstalledAppFromJson(
    Map<String, dynamic> json, {
    String? fallbackRepoName,
  }) {
    final appId = (json['appId'] ?? json['appid'] ?? json['id'])?.toString();
    final name = json['name']?.toString();
    final version = json['version']?.toString();

    if (appId == null || appId.isEmpty || name == null || version == null) {
      return null;
    }

    return InstalledApp(
      appId: appId,
      name: name,
      version: version,
      arch: _normalizeArch(json['arch']),
      channel: json['channel']?.toString(),
      description: json['description']?.toString(),
      kind: json['kind']?.toString(),
      module: json['module']?.toString(),
      runtime: json['runtime']?.toString(),
      size: _normalizeValue(json['size']),
      repoName:
          json['repoName']?.toString() ??
          json['repo_name']?.toString() ??
          fallbackRepoName,
    );
  }

  /// 归一化架构字段。
  ///
  /// linyaps JSON 中 `arch` 可为字符串或数组；领域层当前保存为字符串，
  /// 因此这里保留所有非空架构并用逗号连接，避免丢失多架构信息。
  static String? _normalizeArch(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      final archList = value
          .map((item) => item?.toString())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      return archList.isEmpty ? null : archList.join(', ');
    }
    return value.toString();
  }

  /// 归一化 JSON 标量或数组值。
  ///
  /// `size` 等字段在不同版本里可能是数字、字符串或数组，统一转换为
  /// 可展示和可缓存的字符串形式。
  static String? _normalizeValue(Object? value) {
    if (value == null) return null;
    if (value is List) {
      final values = value
          .map((item) => item?.toString())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
      return values.isEmpty ? null : values.join(', ');
    }
    return value.toString();
  }

  /// 解析运行中进程列表。
  ///
  /// 仅接受 `ll-cli --json ps` 的结构化输出。不同 linyaps 版本可能返回
  /// 顶层数组，也可能包在 `apps`/`processes`/`data` 字段中。
  static List<RunningApp> parseRunningApps(String output) {
    final trimmed = output.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(trimmed);
      final entries = switch (decoded) {
        List<dynamic>() => decoded,
        Map<String, dynamic>() =>
          decoded['apps'] ?? decoded['processes'] ?? decoded['data'],
        _ => null,
      };

      if (entries is! List<dynamic>) {
        return const [];
      }

      return entries
          .whereType<Map<String, dynamic>>()
          .map(_mapRunningAppFromJson)
          .whereType<RunningApp>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// 将单个进程 JSON 对象转换为运行中应用模型。
  ///
  /// `ll-cli --json ps` 的字段名在现有用例中存在大小写差异，
  /// 这里只兼容明确的 JSON 字段别名，不再解析任何文本列。
  static RunningApp? _mapRunningAppFromJson(Map<String, dynamic> json) {
    final explicitAppId =
        json['app']?.toString() ??
        json['appId']?.toString() ??
        json['appid']?.toString();
    final packageRef = json['package']?.toString();
    final explicitContainerId =
        json['containerId']?.toString() ??
        json['containerID']?.toString() ??
        json['container_id']?.toString() ??
        json['container']?.toString();
    final id = json['id']?.toString();
    final appId =
        explicitAppId ??
        _extractAppIdFromPackage(packageRef) ??
        (explicitContainerId != null ? id : null);
    final containerId =
        explicitContainerId ??
        ((explicitAppId != null || packageRef != null) ? id : null);
    final pid = _parseInt(json['pid']);

    if (appId == null ||
        appId.isEmpty ||
        containerId == null ||
        containerId.isEmpty ||
        pid == null ||
        pid <= 0) {
      return null;
    }

    return RunningApp(
      id: containerId,
      appId: appId,
      name: appId,
      version: '',
      arch: '',
      channel: '',
      source: '',
      pid: pid,
      containerId: containerId,
    );
  }

  /// 从 `ll-cli --json ps` 的 package 引用提取应用 ID。
  ///
  /// linyaps 1.12.2 返回形如 `main:com.qq.wemeet/3.26.10.404/x86_64`
  /// 的 package 字段，其中冒号前是仓库或 channel，斜杠后是版本和架构。
  static String? _extractAppIdFromPackage(String? packageRef) {
    if (packageRef == null || packageRef.isEmpty) {
      return null;
    }
    final withoutChannel = packageRef.contains(':')
        ? packageRef.substring(packageRef.indexOf(':') + 1)
        : packageRef;
    final slashIndex = withoutChannel.indexOf('/');
    final appId = slashIndex >= 0
        ? withoutChannel.substring(0, slashIndex)
        : withoutChannel;
    return appId.isEmpty ? null : appId;
  }

  /// 解析整数 JSON 字段。
  ///
  /// `pid` 可能由测试桩或不同 CLI 版本以数字或字符串形式返回，
  /// 这里统一转换并拒绝无法解析的值。
  static int? _parseInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  /// 解析搜索结果。
  ///
  /// `ll-cli search <appId> --json` 在 linyaps 1.12.2 中返回按仓库名分组的
  /// JSON 对象，如 `{"stable":[...]}`。解析时将父级仓库名写入 `repoName`，
  /// 供版本列表继续保持精确身份。
  static List<InstalledApp> parseSearchResults(String output) {
    final trimmed = output.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List<dynamic>) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(_mapInstalledAppFromJson)
            .whereType<InstalledApp>()
            .toList();
      }

      if (decoded is Map<String, dynamic>) {
        final results = <InstalledApp>[];
        for (final entry in decoded.entries) {
          final apps = entry.value;
          if (apps is! List<dynamic>) {
            continue;
          }
          for (final appJson in apps.whereType<Map<String, dynamic>>()) {
            final app = _mapInstalledAppFromJson(
              appJson,
              fallbackRepoName: entry.key,
            );
            if (app != null) {
              results.add(app);
            }
          }
        }
        return results;
      }
    } catch (_) {
      return const [];
    }

    return const [];
  }

  /// 解析 `ll-cli --json` 安装/更新输出的单行 JSON。
  ///
  /// JSON 格式示例：
  /// - Progress: `{"message":"Downloading files","percentage":38.4}`
  /// - Error: `{"message":"Network failed","code":3001}`
  /// - Message: `{"message":"Install success"}`
  ///
  /// 返回 null 表示非 JSON 行或空行
  static ParsedJsonEvent? parseJsonLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    Map<String, dynamic>? json;
    try {
      json = jsonDecode(trimmed) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }

    if (json == null) return null;

    final message = json['message'] as String? ?? '';
    final percentage = json['percentage'] as num?;
    final code = json['code'] as int?;

    if (code != null) {
      return ParsedJsonEvent(
        eventType: JsonEventType.error,
        message: message,
        code: code,
      );
    } else if (percentage != null) {
      return ParsedJsonEvent(
        eventType: JsonEventType.progress,
        message: message,
        percentage: percentage.toDouble(),
      );
    } else {
      // Message: 仅包含 message
      return ParsedJsonEvent(
        eventType: JsonEventType.message,
        message: message,
      );
    }
  }

  /// 综合解析安装进度。
  ///
  /// 仅使用 JSON 事件驱动状态机；非 JSON 输出作为原始日志保留，但不会再
  /// 推断下载、安装、完成或失败状态，避免普通日志误触发业务状态迁移。
  static InstallProgressInfo parseInstallProgressEx(String line) {
    final jsonEvent = parseJsonLine(line);
    if (jsonEvent != null) {
      return _convertJsonEventToProgressInfo(jsonEvent, line);
    }

    return InstallProgressInfo(rawLine: line);
  }

  /// 将 JSON 事件转换为进度信息
  static InstallProgressInfo _convertJsonEventToProgressInfo(
    ParsedJsonEvent event,
    String rawLine,
  ) {
    final info = InstallProgressInfo(rawLine: rawLine);

    switch (event.eventType) {
      case JsonEventType.progress:
        // 进度事件 (CLI 输出 percentage 0-100，归一化为 0.0-1.0)
        info.progress = (event.percentage ?? 0.0) / 100;
        if (InstallErrorCode.isDownloading(event.message)) {
          info.phase = InstallPhase.downloading;
        } else if (InstallErrorCode.isInstalling(event.message)) {
          info.phase = InstallPhase.installing;
        } else if (event.percentage != null && event.percentage! >= 100) {
          info.phase = InstallPhase.completed;
        } else {
          // 根据进度百分比推断阶段 (0.7 = 70%)
          // 0-70% 通常为下载阶段，70-100% 通常为安装阶段
          if (info.progress < 0.7) {
            info.phase = InstallPhase.downloading;
          } else {
            info.phase = InstallPhase.installing;
          }
        }
        break;

      case JsonEventType.error:
        // 错误事件
        info.phase = InstallPhase.failed;
        info.errorMessage = InstallErrorCode.getStatusFromCode(
          event.code ?? -1,
        );
        break;

      case JsonEventType.message:
        // 消息事件
        final lowerMsg = event.message.toLowerCase();
        if (lowerMsg.contains('success') ||
            lowerMsg.contains('completed') ||
            lowerMsg.contains('finished')) {
          info.phase = InstallPhase.completed;
          info.progress = 1.0;
        } else if (lowerMsg.contains('error') ||
            lowerMsg.contains('failed') ||
            lowerMsg.contains('failure')) {
          info.phase = InstallPhase.failed;
          info.errorMessage = event.message;
        } else if (InstallErrorCode.isDownloading(event.message)) {
          info.phase = InstallPhase.downloading;
        } else if (InstallErrorCode.isInstalling(event.message)) {
          info.phase = InstallPhase.installing;
        }
        break;
    }

    return info;
  }
}

/// 安装进度阶段
enum InstallPhase { pending, downloading, installing, completed, failed }

/// JSON 事件类型（对应 ll-cli --json 输出）
enum JsonEventType {
  /// 进度事件（包含 percentage）
  progress,

  /// 错误事件（包含 code）
  error,

  /// 消息事件（仅包含 message）
  message,
}

/// JSON 解析结果
class ParsedJsonEvent {
  ParsedJsonEvent({
    required this.eventType,
    required this.message,
    this.percentage,
    this.code,
  });

  /// 事件类型
  final JsonEventType eventType;

  /// 消息内容
  final String message;

  /// 进度百分比 (0-100)
  final double? percentage;

  /// 错误码
  final int? code;
}

/// 安装进度信息
class InstallProgressInfo {
  InstallProgressInfo({
    required this.rawLine,
    this.phase = InstallPhase.pending,
    this.progress = 0.0,
    this.errorMessage,
  });

  /// 原始输出行
  final String rawLine;

  /// 当前阶段
  InstallPhase phase;

  /// 进度百分比 (0-100)
  double progress;

  /// 错误信息
  String? errorMessage;
}

/// 安装错误码映射
///
/// 错误码来源：linglong::utils::error::ErrorCode
class InstallErrorCode {
  InstallErrorCode._();

  /// 根据错误码获取用户友好的错误消息
  static String getStatusFromCode(int code) {
    switch (code) {
      // 基础错误
      case -1:
        return '安装失败';
      case -2:
        return '安装失败: 进度超时';

      // 用户操作
      case 1:
        return '安装已取消';

      // 1000 系列：基础错误
      case 1000:
        return '安装失败: 未知错误';
      case 1001:
        return '安装失败: 远程仓库找不到应用';
      case 1002:
        return '安装失败: 本地找不到应用';

      // 2000 系列：安装相关错误
      case 2001:
        return '安装失败';
      case 2002:
        return '安装失败: 远程无该应用';
      case 2003:
        return '安装失败: 已安装同版本';
      case 2004:
        return '安装失败: 需要降级安装';
      case 2005:
        return '安装失败: 安装模块时不允许指定版本';
      case 2006:
        return '安装失败: 安装模块需先安装应用';
      case 2007:
        return '安装失败: 模块已存在';
      case 2008:
        return '安装失败: 架构不匹配';
      case 2009:
        return '安装失败: 远程无该模块';
      case 2010:
        return '安装失败: 缺少 erofs 解压命令';
      case 2011:
        return '安装失败: 不支持的文件格式';

      // 3000 系列：网络错误
      case 3001:
        return '安装失败: 网络错误';

      // 4000 系列：参数错误
      case 4001:
        return '安装失败: 无效引用';
      case 4002:
        return '安装失败: 未知架构';

      // 未知错误码
      default:
        return '安装失败: 错误码 $code';
    }
  }

  /// 根据消息内容生成用户友好的状态描述
  static String getStatusFromMessage(String message) {
    final lower = message.toLowerCase();

    if (lower.contains('beginning to install')) {
      return '开始安装';
    } else if (lower.contains('installing application')) {
      return '正在安装应用';
    } else if (lower.contains('installing runtime')) {
      return '正在安装运行时';
    } else if (lower.contains('installing base')) {
      return '正在安装基础包';
    } else if (lower.contains('downloading metadata')) {
      return '正在下载元数据';
    } else if (lower.contains('downloading files') ||
        lower.contains('downloading')) {
      return '正在下载文件';
    } else if (lower.contains('processing after install')) {
      return '安装后处理';
    } else if (lower.contains('success') || lower.contains('completed')) {
      return '安装完成';
    } else if (message.isNotEmpty) {
      // 保留完整文案给 Tooltip、复制和无障碍语义使用；视觉截断只允许在 UI 层处理。
      return message;
    }
    return '正在处理';
  }

  /// 根据进度消息判断是否处于下载阶段
  static bool isDownloading(String message) {
    final lower = message.toLowerCase();
    return lower.contains('download') || lower.contains('downloading');
  }

  /// 根据进度消息判断是否处于安装阶段
  static bool isInstalling(String message) {
    final lower = message.toLowerCase();
    return lower.contains('installing') ||
        lower.contains('unpacking') ||
        lower.contains('extracting') ||
        lower.contains('processing');
  }
}
