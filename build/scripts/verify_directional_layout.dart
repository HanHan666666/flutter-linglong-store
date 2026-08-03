/// 方向感知布局硬编码扫描门禁。
///
/// 扫描 `lib/` 生产代码并通过 AST 识别物理方向布局。确属窗口物理几何等合理
/// 豁免时，在违规参数本行或上方紧邻注释块中声明
/// `// ignore: hardcoded_direction`，使例外保持可见、可审查。
library;

import 'dart:io';

import 'lib/directional_layout_verifier.dart';

/// 执行方向感知布局校验并通过进程退出码反馈给 CI。
void main() {
  try {
    final violations = scanDirectionalLayoutDirectory(Directory('lib'));
    if (violations.isNotEmpty) {
      stderr.writeln('方向感知布局校验失败（发现硬编码物理方向）：');
      for (final violation in violations) {
        stderr.writeln('- $violation');
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
