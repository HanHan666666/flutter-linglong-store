/// ARB 本地化资源结构校验入口。
///
/// 该命令复用 Linux 元数据生成器的资源目录模型，在代码生成前一次性拒绝漏译、
/// locale 身份漂移、占位符错误和平台元数据不完整，确保所有消费者观察同一契约。
library;

import 'dart:io';

import 'lib/localization_resource_catalog.dart';

/// 校验全部正式发布 ARB，并以非零退出码报告问题。
void main() {
  try {
    final catalog = LocalizationResourceCatalog.load();
    final errors = catalog.validate();
    if (errors.isNotEmpty) {
      stderr.writeln('本地化资源校验失败：');
      for (final error in errors) {
        stderr.writeln('- $error');
      }
      exitCode = 1;
      return;
    }

    stdout.writeln(
      'localization resource verification passed '
      '(${catalog.resources.length} locales, '
      '${catalog.template.messageKeys.length} messages)',
    );
  } on Object catch (error) {
    stderr.writeln('本地化资源读取失败：$error');
    exitCode = 1;
  }
}
