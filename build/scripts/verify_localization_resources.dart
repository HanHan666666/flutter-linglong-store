/// ARB 本地化资源结构校验入口。
///
/// 该脚本在代码生成前比较所有语言与中文模板的消息键及占位符，避免新增语言时
/// 因漏译、拼错占位符或 locale 声明错误而生成不完整的运行时资源。
library;

import 'dart:convert';
import 'dart:io';

/// ARB 文件名和 locale 标识遵循的固定格式。
final RegExp _arbFileNamePattern = RegExp(r'^app_([A-Za-z0-9_]+)\.arb$');

/// 提取普通占位符和 ICU plural/select 的入口变量。
final RegExp _placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)(?:[,}])');

/// 校验所有 ARB 文件并以非零退出码报告结构漂移。
void main() {
  final localizationDirectory = Directory('lib/core/i18n/l10n');
  final templateFile = File('${localizationDirectory.path}/app_zh.arb');
  final template = _readArb(templateFile);
  final templateKeys = _messageKeys(template);
  final errors = <String>[];

  final arbFiles =
      localizationDirectory
          .listSync()
          .whereType<File>()
          .where((file) => _arbFileNamePattern.hasMatch(_baseName(file.path)))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));

  for (final file in arbFiles) {
    final fileName = _baseName(file.path);
    final locale = _arbFileNamePattern.firstMatch(fileName)!.group(1)!;
    final resource = _readArb(file);
    if (resource['@@locale'] != locale) {
      errors.add(
        '$fileName: @@locale 应为 "$locale"，实际为 '
        '${jsonEncode(resource['@@locale'])}',
      );
    }

    final resourceKeys = _messageKeys(resource);
    final missingKeys = templateKeys.difference(resourceKeys).toList()..sort();
    final extraKeys = resourceKeys.difference(templateKeys).toList()..sort();
    if (missingKeys.isNotEmpty) {
      errors.add('$fileName: 缺少消息键 ${missingKeys.join(', ')}');
    }
    if (extraKeys.isNotEmpty) {
      errors.add('$fileName: 存在模板之外的消息键 ${extraKeys.join(', ')}');
    }

    for (final key in templateKeys.intersection(resourceKeys)) {
      final templateValue = template[key];
      final resourceValue = resource[key];
      if (templateValue is! String || resourceValue is! String) {
        errors.add('$fileName: $key 必须是字符串消息');
        continue;
      }
      final expectedPlaceholders = _placeholders(templateValue);
      final actualPlaceholders = _placeholders(resourceValue);
      if (!_sameSet(expectedPlaceholders, actualPlaceholders)) {
        errors.add(
          '$fileName: $key 占位符应为 '
          '${expectedPlaceholders.toList()..sort()}，实际为 '
          '${actualPlaceholders.toList()..sort()}',
        );
      }
    }
  }

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
    '(${arbFiles.length} locales, ${templateKeys.length} messages)',
  );
}

/// 读取并确认 ARB 顶层为 JSON 对象。
Map<String, dynamic> _readArb(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('${file.path} 顶层必须是 JSON 对象');
  }
  return decoded;
}

/// 返回不包含 ARB 元数据的业务消息键。
Set<String> _messageKeys(Map<String, dynamic> resource) {
  return resource.keys.where((key) => !key.startsWith('@')).toSet();
}

/// 从消息文本提取去重后的占位符名称。
Set<String> _placeholders(String message) {
  return _placeholderPattern
      .allMatches(message)
      .map((match) => match.group(1)!)
      .toSet();
}

/// 比较两个集合内容是否完全一致。
bool _sameSet(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

/// 获取路径末尾文件名，避免为一个简单操作引入额外依赖。
String _baseName(String path) => path.split(Platform.pathSeparator).last;
