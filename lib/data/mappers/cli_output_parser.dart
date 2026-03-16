import 'dart:convert';

import '../../domain/models/installed_app.dart';
import '../../domain/models/running_app.dart';

/// CLI 输出解析器
class CliOutputParser {
  CliOutputParser._();

  /// 解析已安装应用列表
  ///
  /// ll-cli list 输出格式示例：
  /// ```
  /// AppID                     Version    Arch    Channel    Size
  /// com.tencent.wechat        4.0.0      x86_64  stable     256M
  /// cn.wps.wps-office         11.1.0     x86_64  stable     512M
  /// ```
  static List<InstalledApp> parseInstalledApps(String output) {
    final sanitizedOutput = _stripAnsi(output).trim();
    if (sanitizedOutput.isEmpty) {
      return const [];
    }

    // 优先解析 ll-cli 的 JSON 输出；这是当前仓库对齐旧版 Rust 商店的首选路径。
    final jsonApps = _parseInstalledAppsFromJson(sanitizedOutput);
    if (jsonApps != null) {
      return jsonApps;
    }

    final List<InstalledApp> apps = [];
    final lines = sanitizedOutput.split('\n');

    bool headerFound = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 跳过表头
      if (!headerFound) {
        final lowerTrimmed = trimmed.toLowerCase();
        if (lowerTrimmed.contains('appid') ||
            (lowerTrimmed.contains('id') && lowerTrimmed.contains('version'))) {
          headerFound = true;
        }
        continue;
      }

      // 解析行数据
      // 尝试多种格式
      final app = _parseInstalledAppLine(trimmed);
      if (app != null) {
        apps.add(app);
      }
    }

    return apps;
  }

  /// 解析单行已安装应用数据
  static InstalledApp? _parseInstalledAppLine(String line) {
    final normalizedLine = _stripAnsi(line).trim();
    if (normalizedLine.isEmpty) return null;

    // 当前 ll-cli 的表格输出使用 2 个及以上空格分隔列；
    // 这样既能兼容名字/描述中包含空格的情况，也能兼容旧表头格式。
    final parts = normalizedLine
        .split(RegExp(r'\s{2,}'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length < 2) return null;

    final appId = parts[0];
    final hasCurrentTableLayout =
        parts.length >= 5 && !_looksLikeVersion(parts[1]);

    final name = hasCurrentTableLayout
        ? parts[1]
        : _extractNameFromAppId(appId);
    final version = parts.length > (hasCurrentTableLayout ? 2 : 1)
        ? parts[hasCurrentTableLayout ? 2 : 1]
        : '';
    final arch = hasCurrentTableLayout
        ? ''
        : (parts.length > 2 ? parts[2] : '');
    final channel = hasCurrentTableLayout
        ? (parts.length > 3 ? parts[3] : '')
        : (parts.length > 3 ? parts[3] : '');
    final module = hasCurrentTableLayout
        ? (parts.length > 4 ? parts[4] : '')
        : null;
    final description = hasCurrentTableLayout && parts.length > 5
        ? parts[5]
        : null;
    final size = hasCurrentTableLayout
        ? null
        : (parts.length > 4 ? parts[4] : '');

    if (appId.isEmpty) return null;

    return InstalledApp(
      appId: appId,
      name: name,
      version: version,
      arch: arch,
      channel: channel,
      size: size,
      module: module,
      description: description,
    );
  }

  /// 解析 ll-cli list --json 输出。
  ///
  /// 字段结构与旧版 Rust 商店保持一致：`arch`/`size` 可能是字符串、数字或数组，
  /// 因此这里做宽松解析，避免因为字段类型变化导致安装列表富化链路中断。
  static List<InstalledApp>? _parseInstalledAppsFromJson(String output) {
    try {
      final decoded = jsonDecode(output);
      if (decoded is! List<dynamic>) {
        return null;
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_mapInstalledAppFromJson)
          .whereType<InstalledApp>()
          .toList();
    } catch (_) {
      return null;
    }
  }

  static InstalledApp? _mapInstalledAppFromJson(Map<String, dynamic> json) {
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
      repoName: json['repoName']?.toString() ?? json['repo_name']?.toString(),
    );
  }

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

  static String _stripAnsi(String input) {
    return input.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
  }

  static bool _looksLikeVersion(String value) {
    return RegExp(r'^\d+(?:\.\d+)*(?:[-+._][A-Za-z0-9]+)*$').hasMatch(value);
  }

  /// 从 AppID 提取应用名称
  static String _extractNameFromAppId(String appId) {
    // 格式: com.vendor.appname -> appname
    final parts = appId.split('.');
    if (parts.length >= 3) {
      return parts.sublist(2).join('.');
    }
    return appId;
  }

  /// 解析运行中进程列表
  ///
  /// ll-cli ps 输出格式示例：
  /// ```
  /// NAME                      PID     APPID
  /// wechat                    12345   com.tencent.wechat
  /// wps-office                12346   cn.wps.wps-office
  /// ```
  static List<RunningApp> parseRunningApps(String output) {
    final List<RunningApp> apps = [];
    final lines = output.split('\n');

    bool headerFound = false;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // 跳过表头
      if (!headerFound) {
        if (trimmed.contains('NAME') || trimmed.contains('PID')) {
          headerFound = true;
        }
        continue;
      }

      // 解析行数据
      final match = RegExp(r'^(\S+)\s+(\d+)\s+(\S+)').firstMatch(trimmed);

      if (match != null) {
        final name = match.group(1)!;
        final pid = int.tryParse(match.group(2)!) ?? 0;
        final appId = match.group(3)!;

        if (pid > 0 && appId.isNotEmpty) {
          apps.add(RunningApp(appId: appId, name: name, pid: pid));
        }
      }
    }

    return apps;
  }

  /// 解析搜索结果
  ///
  /// ll-cli search 输出格式与 list 类似
  static List<InstalledApp> parseSearchResults(String output) {
    return parseInstalledApps(output);
  }

  /// 解析应用信息
  ///
  /// ll-cli query 输出格式：
  /// ```
  /// AppID: com.tencent.wechat
  /// Name: WeChat
  /// Version: 4.0.0
  /// ...
  /// ```
  static Map<String, String> parseAppInfo(String output) {
    final info = <String, String>{};
    final lines = output.split('\n');

    for (final line in lines) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim();
        final value = line.substring(colonIndex + 1).trim();
        info[key.toLowerCase()] = value;
      }
    }

    return info;
  }

  /// 解析安装进度输出
  ///
  /// 支持格式：
  /// - "downloading... 50%"
  /// - "installing... 80%"
  /// - "Downloading xx%"
  /// - "Installing..."
  /// - "Downloaded xx/yy MB"
  /// - "complete"
  /// - "success"
  static InstallProgressInfo parseInstallProgress(String line) {
    final info = InstallProgressInfo(rawLine: line);
    final lowerLine = line.toLowerCase();

    // 检测下载进度
    if (lowerLine.contains('download')) {
      info.phase = InstallPhase.downloading;

      // 尝试解析百分比
      final percentMatch = RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(line);
      if (percentMatch != null) {
        info.progress = double.tryParse(percentMatch.group(1)!) ?? 0.0;
      }

      // 尝试解析已下载/总大小
      final sizeMatch = RegExp(
        r'(\d+(?:\.\d+)?)\s*/\s*(\d+(?:\.\d+)?)',
      ).firstMatch(line);
      if (sizeMatch != null) {
        final downloaded = double.tryParse(sizeMatch.group(1)!) ?? 0;
        final total = double.tryParse(sizeMatch.group(2)!) ?? 1;
        if (total > 0) {
          info.progress = (downloaded / total) * 100;
        }
      }

      // 尝试解析 "downloading... xx%" 格式
      final downloadingMatch = RegExp(
        r'downloading[\.…\s]*(\d+(?:\.\d+)?)\s*%',
        caseSensitive: false,
      ).firstMatch(line);
      if (downloadingMatch != null) {
        info.progress = double.tryParse(downloadingMatch.group(1)!) ?? 0.0;
      }
    }

    // 检测安装阶段
    if (lowerLine.contains('installing') ||
        lowerLine.contains('unpacking') ||
        lowerLine.contains('extracting')) {
      info.phase = InstallPhase.installing;

      // 尝试解析 "installing... xx%" 格式
      final installingMatch = RegExp(
        r'installing[\.…\s]*(\d+(?:\.\d+)?)\s*%',
        caseSensitive: false,
      ).firstMatch(line);
      if (installingMatch != null) {
        info.progress = double.tryParse(installingMatch.group(1)!) ?? 0.0;
      }
    }

    // 检测完成
    if (lowerLine.contains('success') ||
        lowerLine.contains('completed') ||
        lowerLine.contains('finished') ||
        lowerLine.contains('complete') ||
        lowerLine == 'done' ||
        lowerLine == 'ok') {
      info.phase = InstallPhase.completed;
      info.progress = 100;
    }

    // 检测错误
    if (lowerLine.contains('error') ||
        lowerLine.contains('failed') ||
        lowerLine.contains('failure')) {
      info.phase = InstallPhase.failed;
      info.errorMessage = line;
    }

    return info;
  }

  /// 检测输出是否表示安装完成
  static bool isInstallComplete(String output) {
    final lower = output.toLowerCase();
    return lower.contains('success') ||
        lower.contains('completed') ||
        lower.contains('finished') ||
        lower.contains('installed');
  }

  /// 检测输出是否表示安装失败
  static bool isInstallFailed(String output) {
    final lower = output.toLowerCase();
    return lower.contains('error') ||
        lower.contains('failed') ||
        lower.contains('unable');
  }

  /// 从错误输出提取错误码
  static int? extractErrorCode(String output) {
    // 尝试匹配错误码格式
    // 例如: "Error code: 123" 或 "E123" 或 "(123)"
    final patterns = [
      RegExp(r'error\s*(?:code)?\s*[:\s]*(\d+)', caseSensitive: false),
      RegExp(r'E(\d{3,})'),
      RegExp(r'\((\d{3,})\)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(output);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }

    return null;
  }

  /// 解析 ll-cli --json 输出的单行 JSON
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

    // 尝试解析为 JSON
    Map<String, dynamic>? json;
    try {
      json = jsonDecode(trimmed) as Map<String, dynamic>?;
    } catch (e) {
      // 非 JSON 行，返回 null
      return null;
    }

    if (json == null) return null;

    final message = json['message'] as String? ?? '';
    final percentage = json['percentage'] as num?;
    final code = json['code'] as int?;

    // 根据字段判断事件类型
    if (code != null) {
      // Error: 包含 code 字段
      return ParsedJsonEvent(
        eventType: JsonEventType.error,
        message: message,
        code: code,
      );
    } else if (percentage != null) {
      // Progress: 包含 percentage 字段
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

  /// 综合解析安装进度（支持 JSON 和纯文本两种格式）
  ///
  /// 优先尝试 JSON 解析，失败则回退到纯文本解析
  static InstallProgressInfo parseInstallProgressEx(String line) {
    // 首先尝试 JSON 解析
    final jsonEvent = parseJsonLine(line);
    if (jsonEvent != null) {
      return _convertJsonEventToProgressInfo(jsonEvent, line);
    }

    // 回退到纯文本解析
    return parseInstallProgress(line);
  }

  /// 将 JSON 事件转换为进度信息
  static InstallProgressInfo _convertJsonEventToProgressInfo(
    ParsedJsonEvent event,
    String rawLine,
  ) {
    final info = InstallProgressInfo(rawLine: rawLine);

    switch (event.eventType) {
      case JsonEventType.progress:
        // 进度事件
        info.progress = event.percentage ?? 0.0;
        if (InstallErrorCode.isDownloading(event.message)) {
          info.phase = InstallPhase.downloading;
        } else if (InstallErrorCode.isInstalling(event.message)) {
          info.phase = InstallPhase.installing;
        } else if (event.percentage != null && event.percentage! >= 100) {
          info.phase = InstallPhase.completed;
        } else {
          // 根据进度百分比推断阶段
          // 0-70% 通常为下载阶段
          // 70-100% 通常为安装阶段
          if (info.progress < 70) {
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
          info.progress = 100;
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
      // 通用错误
      case -1:
        return '安装失败: 通用错误';
      case -2:
        return '安装失败: 进度超时';

      // 用户操作
      case 1:
        return '安装已取消';

      // 1000 系列：通用错误
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
      // 截取前50个字符作为状态
      if (message.length > 50) {
        return '${message.substring(0, 50)}...';
      }
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
