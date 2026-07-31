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
    final errors = <String>[
      ...catalog.validate(),
      ..._validateLocalizationUsage(),
    ];
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

/// 拒绝界面层把完整 ARB 契约重新降级为可空访问。
///
/// 所有正式 ARB 已由资源目录校验保证键集合一致，因此运行时再用 `?.` 回退只会
/// 掩盖接线错误，并把某一种语言硬编码进其他语言界面。原始诊断和业务可空字段不
/// 属于此规则，扫描范围只覆盖手写 Dart 源码中的本地化对象访问。
List<String> _validateLocalizationUsage() {
  final errors = <String>[];
  final sourceRoot = Directory('lib');
  if (!sourceRoot.existsSync()) {
    return const ['未找到 lib 目录，无法校验界面本地化接线'];
  }

  final forbiddenPatterns = <({RegExp pattern, String reason})>[
    (
      pattern: RegExp(r'AppLocalizations\.of\([^)]*\)\s*\?\.'),
      reason: 'AppLocalizations.of(...) 必须使用非空本地化契约',
    ),
    (pattern: RegExp(r'\bl10n\s*\?\.'), reason: 'l10n 不得使用可空访问并回退到单一语言'),
    (
      pattern: RegExp(r'\bAppLocalizations\s*\?\s+[A-Za-z_]'),
      reason: '展示组件不得接收可空 AppLocalizations',
    ),
  ];

  final files = sourceRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where(
        (file) => !file.path.contains('/core/i18n/l10n/app_localizations'),
      );

  for (final file in files) {
    final source = file.readAsStringSync();
    for (final rule in forbiddenPatterns) {
      for (final match in rule.pattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        errors.add('${file.path}:$line: ${rule.reason}');
      }
    }
  }
  return errors;
}
