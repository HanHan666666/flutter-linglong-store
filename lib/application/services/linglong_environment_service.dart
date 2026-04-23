import 'dart:convert';
import 'dart:io';

import '../../core/platform/shell_command_executor.dart';
import '../../domain/models/linglong_env_check_result.dart';

typedef OsReleaseReader = Future<String?> Function();
typedef EnvVarReader = String? Function(String name);
typedef TimestampReader = int Function();

class LinglongEnvironmentService {
  LinglongEnvironmentService({
    required ShellCommandExecutor executor,
    OsReleaseReader? osReleaseReader,
    EnvVarReader? environmentReader,
    TimestampReader? clock,
    String minimumVersion = '1.9.0',
  }) : _executor = executor,
       _osReleaseReader = osReleaseReader ?? _defaultOsReleaseReader,
       _environmentReader = environmentReader ?? _defaultEnvironmentReader,
       _clock = clock ?? _defaultClock,
       _minimumVersion = minimumVersion;

  final ShellCommandExecutor _executor;
  final OsReleaseReader _osReleaseReader;
  final EnvVarReader _environmentReader;
  final TimestampReader _clock;
  final String _minimumVersion;

  static const Map<String, String> _englishLocaleEnv = {
    'LC_ALL': 'C.UTF-8',
    'LANG': 'C.UTF-8',
    'LANGUAGE': 'C.UTF-8',
    'LC_MESSAGES': 'C.UTF-8',
  };

  Future<LinglongEnvCheckResult> checkEnvironment() async {
    final checkedAt = _clock();

    final arch = await _runAndTrim(['uname', '-m']);
    final rawOsVersion = await _loadOsVersion();
    final glibcVersion = await _loadGlibcVersion();
    final kernelInfo = await _runAndTrim(['uname', '-a']);
    final detailMsg = await _loadDetailMessage();
    final osVersion = _buildReportedOsVersion(
      osVersion: rawOsVersion,
      glibcVersion: glibcVersion,
      kernelInfo: kernelInfo,
    );

    final help = await _runLlCli(['--help']);
    if (help == null || !help.success) {
      return LinglongEnvCheckResult(
        isOk: false,
        arch: arch,
        osVersion: osVersion,
        glibcVersion: glibcVersion,
        kernelInfo: kernelInfo,
        detailMsg: detailMsg,
        errorMessage: 'll-cli 未安装或不可用',
        errorDetail: help?.primaryMessage,
        repoStatus: RepoStatus.unavailable,
        checkedAt: checkedAt,
      );
    }

    final repoInfo = await _loadRepoInfo();
    if (repoInfo.repos.isEmpty) {
      return LinglongEnvCheckResult(
        isOk: false,
        arch: arch,
        osVersion: osVersion,
        glibcVersion: glibcVersion,
        kernelInfo: kernelInfo,
        detailMsg: detailMsg,
        errorMessage: '未检测到玲珑仓库配置，请检查环境',
        repoStatus: repoInfo.status,
        checkedAt: checkedAt,
      );
    }

    final version = await _loadLlCliVersion();
    if (version == null) {
      return LinglongEnvCheckResult(
        isOk: false,
        arch: arch,
        osVersion: osVersion,
        glibcVersion: glibcVersion,
        kernelInfo: kernelInfo,
        detailMsg: detailMsg,
        errorMessage: '无法检测到玲珑环境版本，请确认已安装',
        repoStatus: RepoStatus.ok,
        repoName: repoInfo.defaultRepo,
        repos: repoInfo.repos,
        checkedAt: checkedAt,
      );
    }

    final llBinVersion = await _loadLinglongBinVersion();
    final isContainer = _environmentReader('LINYAPS_CONTAINER') == 'yes';
    final warningMessage = _compareVersions(version, _minimumVersion) < 0
        ? '当前玲珑基础环境版本($version)过低，建议升级至 >= $_minimumVersion'
        : null;

    return LinglongEnvCheckResult(
      isOk: true,
      warningMessage: warningMessage,
      arch: arch,
      osVersion: osVersion,
      glibcVersion: glibcVersion,
      kernelInfo: kernelInfo,
      detailMsg: detailMsg,
      llCliVersion: version,
      llBinVersion: llBinVersion,
      repoName: repoInfo.defaultRepo,
      repos: repoInfo.repos,
      isContainer: isContainer,
      repoStatus: RepoStatus.ok,
      checkedAt: checkedAt,
    );
  }

  Future<String?> _loadOsVersion() async {
    final osRelease = await _osReleaseReader();
    if (osRelease != null) {
      for (final line in const LineSplitter().convert(osRelease)) {
        if (!line.startsWith('PRETTY_NAME=')) {
          continue;
        }
        return line.split('=').skip(1).join('=').replaceAll('"', '').trim();
      }
    }
    return _runAndTrim(['uname', '-a']);
  }

  String? _buildReportedOsVersion({
    required String? osVersion,
    required String? glibcVersion,
    required String? kernelInfo,
  }) {
    final parts = <String>[];
    if (osVersion != null && osVersion.trim().isNotEmpty) {
      parts.add('OS: ${osVersion.trim()}');
    }
    if (glibcVersion != null && glibcVersion.trim().isNotEmpty) {
      parts.add('glibc: ${glibcVersion.trim()}');
    }
    if (kernelInfo != null && kernelInfo.trim().isNotEmpty) {
      parts.add('kernel: ${kernelInfo.trim()}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' | ');
  }

  Future<String?> _loadGlibcVersion() async {
    final result = await _run(['ldd', '--version']);
    if (result == null) {
      return null;
    }
    final lines = const LineSplitter().convert(
      '${result.stdout}\n${result.stderr}',
    );
    for (final line in lines) {
      final match = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  Future<String?> _loadDetailMessage() async {
    final result = await _run(['bash', '-c', 'dpkg -l | grep linglong']);
    if (result == null || !result.success) {
      return null;
    }
    final trimmed = result.stdout.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<_RepoInfo> _loadRepoInfo() async {
    final jsonResult = await _runLlCli(['--json', 'repo', 'show']);
    if (jsonResult != null && jsonResult.success) {
      final parsed = _parseRepoJson(jsonResult.stdout);
      if (parsed != null) {
        return parsed.repos.isEmpty
            ? parsed.copyWith(status: RepoStatus.notConfigured)
            : parsed.copyWith(status: RepoStatus.ok);
      }

      final textFallback = _parseRepoText(jsonResult.stdout);
      if (textFallback.repos.isNotEmpty) {
        return textFallback.copyWith(status: RepoStatus.ok);
      }
    }

    final textResult = await _runLlCli(['repo', 'show']);
    if (textResult != null && textResult.success) {
      final parsed = _parseRepoText(textResult.stdout);
      if (parsed.repos.isNotEmpty) {
        return parsed.copyWith(status: RepoStatus.ok);
      }
      return parsed.copyWith(status: RepoStatus.notConfigured);
    }

    return const _RepoInfo(status: RepoStatus.unavailable);
  }

  _RepoInfo? _parseRepoJson(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return null;
      }
      final reposJson = json['repos'];
      final repos = <LinglongRepoInfo>[];
      if (reposJson is List) {
        for (final item in reposJson) {
          if (item is! Map<String, dynamic>) {
            continue;
          }
          repos.add(
            LinglongRepoInfo(
              name: item['name']?.toString() ?? '',
              url: item['url']?.toString() ?? '',
              alias: item['alias']?.toString(),
              priority: item['priority']?.toString(),
            ),
          );
        }
      }

      return _RepoInfo(
        defaultRepo: json['defaultRepo']?.toString(),
        repos: repos.where((repo) => repo.name.isNotEmpty).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  _RepoInfo _parseRepoText(String raw) {
    final lines = const LineSplitter()
        .convert(raw)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const _RepoInfo(status: RepoStatus.notConfigured);
    }

    final defaultRepo = lines.first.contains(':')
        ? lines.first.split(':').skip(1).join(':').trim()
        : null;
    final repos = <LinglongRepoInfo>[];
    for (final line in lines.skip(2)) {
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty) {
        continue;
      }
      repos.add(
        LinglongRepoInfo(
          name: parts.isNotEmpty ? parts[0] : '',
          url: parts.length > 1 ? parts[1] : '',
          alias: parts.length > 2 ? parts[2] : null,
          priority: parts.length > 3 ? parts[3] : null,
        ),
      );
    }

    return _RepoInfo(defaultRepo: defaultRepo, repos: repos);
  }

  Future<String?> _loadLlCliVersion() async {
    final result = await _runLlCli(['--json', '--version']);
    if (result == null || !result.success) {
      return null;
    }

    try {
      final json = jsonDecode(result.stdout);
      if (json is Map<String, dynamic>) {
        final version = json['version']?.toString().trim();
        if (version != null && version.isNotEmpty) {
          return version;
        }
      }
    } catch (_) {
      // Fall back to regex parsing below.
    }

    final match = RegExp(r'(\d+\.\d+\.\d+)').firstMatch(result.stdout);
    return match?.group(1);
  }

  Future<String?> _loadLinglongBinVersion() async {
    final result = await _run(['apt-cache', 'policy', 'linglong-bin']);
    if (result == null || !result.success) {
      return null;
    }

    for (final line in const LineSplitter().convert(result.stdout)) {
      if (!line.contains('Installed:') && !line.contains('已安装：')) {
        continue;
      }
      final parts = line.split(':');
      if (parts.length < 2) {
        continue;
      }
      final version = parts.sublist(1).join(':').trim();
      if (version.isNotEmpty) {
        return version;
      }
    }
    return null;
  }

  Future<ShellCommandResult?> _runLlCli(List<String> arguments) {
    return _run(['ll-cli', ...arguments], environment: _englishLocaleEnv);
  }

  Future<ShellCommandResult?> _run(
    List<String> command, {
    Map<String, String>? environment,
  }) async {
    try {
      return await _executor.run(command, environment: environment);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _runAndTrim(List<String> command) async {
    final result = await _run(command);
    if (result == null || !result.success) {
      return null;
    }
    final trimmed = result.stdout.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Future<String?> _defaultOsReleaseReader() async {
    try {
      final file = File('/etc/os-release');
      if (!await file.exists()) {
        return null;
      }
      return file.readAsString();
    } catch (_) {
      return null;
    }
  }

  static String? _defaultEnvironmentReader(String name) =>
      Platform.environment[name];

  static int _defaultClock() => DateTime.now().millisecondsSinceEpoch;

  int _compareVersions(String left, String right) {
    final leftParts = left
        .split(RegExp(r'[._-]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final rightParts = right
        .split(RegExp(r'[._-]'))
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final length = leftParts.length > rightParts.length
        ? leftParts.length
        : rightParts.length;
    for (var index = 0; index < length; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }
}

class _RepoInfo {
  const _RepoInfo({
    this.defaultRepo,
    this.repos = const [],
    this.status = RepoStatus.unknown,
  });

  final String? defaultRepo;
  final List<LinglongRepoInfo> repos;
  final RepoStatus status;

  _RepoInfo copyWith({
    String? defaultRepo,
    List<LinglongRepoInfo>? repos,
    RepoStatus? status,
  }) {
    return _RepoInfo(
      defaultRepo: defaultRepo ?? this.defaultRepo,
      repos: repos ?? this.repos,
      status: status ?? this.status,
    );
  }
}
