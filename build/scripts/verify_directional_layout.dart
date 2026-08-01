/// 方向感知布局硬编码扫描门禁。
///
/// 阿拉伯语（RTL）支持落地后，项目约定新代码禁止使用物理方向
/// （left/right/topLeft 等）做布局对齐，必须使用 Directional 系列
/// （AlignmentDirectional / EdgeInsetsDirectional / TextAlign.start/end /
/// PositionedDirectional），防止未来新增界面把 RTL 布局改回硬编码。
///
/// 扫描范围仅限 lib/ 生产代码（UI 方向约束不适用于测试与构建脚本）。
/// 确属窗口物理几何等合理豁免时，在源码中使用
/// `// ignore: hardcoded_direction` 注释（本行或上一行）显式声明，
/// 保证豁免在源码里可见、可审查。
library;

import 'dart:io';

/// 违规模式：[正则, 说明]。
///
/// 注意 `alignment: Alignment.` 前缀限定，避免误报 LinearGradient 的
/// begin/end 渐变方向和 OverlayPortal 的 targetAnchor/followerAnchor
/// 锚点——这些是视觉/浮层几何，不属于文本流方向。
final _forbiddenPatterns = <(RegExp, String)>[
  (
    RegExp(r'alignment:\s*Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)'),
    '布局对齐应使用 AlignmentDirectional（如 centerStart/centerEnd）',
  ),
  (
    RegExp(r'TextAlign\.(left|right)'),
    '文本对齐应使用 TextAlign.start/end',
  ),
  (
    RegExp(r'EdgeInsets\.only\((left|right):'),
    '内边距应使用 EdgeInsetsDirectional.only(start/end)',
  ),
  (
    RegExp(r'Positioned\((left|right):'),
    '绝对定位应使用 PositionedDirectional(start/end)',
  ),
];

/// `// ignore: hardcoded_direction` 豁免标记。
const _ignoreMarker = 'ignore: hardcoded_direction';

/// 校验单行是否被豁免：本行，或上方紧邻的连续注释块中存在 ignore 标记。
bool _isIgnored(List<String> lines, int lineIndex) {
  if (lines[lineIndex].contains(_ignoreMarker)) return true;
  // 从上一行开始向上回溯连续注释行，注释块内任意位置出现标记即豁免
  for (var i = lineIndex - 1; i >= 0; i--) {
    final trimmed = lines[i].trimLeft();
    if (!trimmed.startsWith('//')) break;
    if (trimmed.contains(_ignoreMarker)) return true;
  }
  return false;
}

/// 扫描 lib/ 下全部 Dart 源文件，返回违规描述列表。
List<String> _scanLib() {
  final errors = <String>[];
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return errors;

  final files = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (file) =>
            file.path.endsWith('.dart') &&
            !file.path.endsWith('.g.dart') &&
            !file.path.endsWith('.freezed.dart'),
      )
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (_isIgnored(lines, index)) continue;
      for (final (pattern, message) in _forbiddenPatterns) {
        if (pattern.hasMatch(lines[index])) {
          errors.add('${file.path}:${index + 1} - $message');
        }
      }
    }
  }
  return errors;
}

void main() {
  try {
    final errors = _scanLib();
    if (errors.isNotEmpty) {
      stderr.writeln('方向感知布局校验失败（发现硬编码物理方向）：');
      for (final error in errors) {
        stderr.writeln('- $error');
      }
      stderr.writeln('');
      stderr.writeln(
        '请改用 AlignmentDirectional / EdgeInsetsDirectional / '
        'TextAlign.start/end / PositionedDirectional；确属窗口物理几何等'
        '合理豁免时，在源码加 // ignore: hardcoded_direction 注释。',
      );
      exitCode = 1;
      return;
    }

    stdout.writeln('directional layout verification passed');
  } on Object catch (error) {
    stderr.writeln('方向感知布局扫描失败：$error');
    exitCode = 1;
  }
}
