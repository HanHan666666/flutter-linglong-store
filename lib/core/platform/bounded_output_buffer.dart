import 'dart:collection';
import 'dart:convert';

/// 可选上限的输出行缓冲。
///
/// 普通场景（`maxBytes == null`）保留完整输出；设置上限后只保留固定字节数的
/// 尾部内容，每次按完整行淘汰，不会在 UTF-8 字符中间截断。
///
/// 用途：子进程 stderr 等"只需尾部诊断信息"的输出流，防止异常场景下
/// （如 ll-cli 刷屏）无界累积拖高内存；完整内容仍应写入专用日志。
class BoundedOutputBuffer {
  /// 创建可选上限的输出缓冲。
  ///
  /// [maxBytes] 为 null 表示保留完整输出。
  BoundedOutputBuffer({this.maxBytes});

  /// 输出保留的 UTF-8 字节上限；null 表示不设限。
  final int? maxBytes;

  final StringBuffer _unbounded = StringBuffer();
  final ListQueue<_CapturedOutputLine> _bounded =
      ListQueue<_CapturedOutputLine>();
  int _boundedBytes = 0;

  /// 追加一行输出。
  void addLine(String line) {
    final limit = maxBytes;
    if (limit == null) {
      _unbounded.writeln(line);
      return;
    }

    final byteLength = utf8.encode(line).length + 1;
    if (byteLength > limit) {
      // 单行超过上限时不保留该行，完整内容仍然存在专用日志中。
      _bounded.clear();
      _boundedBytes = 0;
      return;
    }

    _bounded.add(_CapturedOutputLine(line: line, byteLength: byteLength));
    _boundedBytes += byteLength;
    while (_boundedBytes > limit && _bounded.isNotEmpty) {
      _boundedBytes -= _bounded.removeFirst().byteLength;
    }
  }

  /// 当前保留的文本。
  String get text {
    if (maxBytes == null) {
      return _unbounded.toString();
    }
    return _bounded.map((item) => item.line).join('\n') +
        (_bounded.isEmpty ? '' : '\n');
  }
}

/// 有界输出缓冲中的单行及其 UTF-8 占用。
class _CapturedOutputLine {
  const _CapturedOutputLine({required this.line, required this.byteLength});

  final String line;
  final int byteLength;
}
