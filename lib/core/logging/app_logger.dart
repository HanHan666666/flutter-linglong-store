import 'dart:io';

import 'package:logger/logger.dart';

/// 日志文件相对路径（相对于 $HOME），与反馈对话框上传路径保持一致
const _kLogFileRelative =
    '.local/share/com.dongpl.linglong-store.v2/logs/linglong-store.log';

/// 日志文件最大容量 10 MB，超出后滚动轮转
const _kMaxFileSize = 10 * 1024 * 1024;

/// 保留的历史日志文件数量（.1, .2, .3），最多占用约 40MB
const _kMaxHistoryFiles = 3;

/// 应用日志服务
///
/// 同时输出到控制台和文件，文件达到 10MB 时自动滚动轮转。
class AppLogger {
  AppLogger._();

  static late final Logger _logger;

  /// 初始化日志
  static Future<void> init() async {
    final home = Platform.environment['HOME'] ?? '';

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: _MultiOutput([
        ConsoleOutput(),
        if (home.isNotEmpty)
          _RollingFileOutput(
            filePath: '$home/$_kLogFileRelative',
            maxFileSize: _kMaxFileSize,
            maxHistoryFiles: _kMaxHistoryFiles,
          ),
      ]),
    );
  }

  /// 调试日志
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 信息日志
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 警告日志
  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 错误日志
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 致命错误日志
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 多目标输出：将日志同时分发到多个 [LogOutput]
class _MultiOutput extends LogOutput {
  final List<LogOutput> _outputs;

  _MultiOutput(this._outputs);

  @override
  Future<void> init() async {
    await Future.wait(_outputs.map((o) => o.init()));
  }

  @override
  void output(OutputEvent event) {
    for (final output in _outputs) {
      // 单个输出失败不影响其他输出
      try {
        output.output(event);
      } catch (_) {}
    }
  }

  @override
  Future<void> destroy() async {
    await Future.wait(_outputs.map((o) => o.destroy()));
  }
}

/// 滚动文件输出：日志写入文件，达到 [maxFileSize] 时自动轮转。
///
/// 轮转策略：当前日志文件达到大小上限后，
/// 删除最老的历史文件，依次重命名 .log.2 → .log.3, .log.1 → .log.2,
/// 当前文件 → .log.1，然后创建新的空日志文件继续写入。
class _RollingFileOutput extends LogOutput {
  final String filePath;
  final int maxFileSize;
  final int maxHistoryFiles;

  IOSink? _sink;

  _RollingFileOutput({
    required this.filePath,
    required this.maxFileSize,
    required this.maxHistoryFiles,
  });

  @override
  Future<void> init() async {
    // 确保日志目录存在
    final dir = Directory(File(filePath).parent.path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _openSink();
  }

  @override
  void output(OutputEvent event) {
    final sink = _sink;
    if (sink == null) return;

    for (final line in event.lines) {
      sink.writeln(line);
    }

    // 写入后检查文件大小，超限则滚动
    _checkRotation();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
  }

  /// 打开文件追加写入流
  void _openSink() {
    _sink = File(filePath).openWrite(mode: FileMode.append);
  }

  /// 检查当前日志文件大小，超限时执行滚动轮转
  void _checkRotation() {
    final file = File(filePath);
    if (!file.existsSync()) return;
    if (file.lengthSync() < maxFileSize) return;

    // 先关闭当前写入流
    _sink?.close();

    // 删除最老的历史文件
    final oldest = File('$filePath.${maxHistoryFiles}');
    if (oldest.existsSync()) {
      oldest.deleteSync();
    }

    // 依次重命名历史文件：.log.(n-1) → .log.n
    for (var i = maxHistoryFiles - 1; i >= 1; i--) {
      final src = File('$filePath.$i');
      if (src.existsSync()) {
        src.renameSync('$filePath.${i + 1}');
      }
    }

    // 当前日志文件重命名为 .log.1
    file.renameSync('$filePath.1');

    // 创建新的空日志文件并打开写入流
    _openSink();
  }
}
