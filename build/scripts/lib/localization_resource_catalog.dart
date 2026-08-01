/// 本地化资源目录的共享读取与校验模型。
///
/// Flutter 代码生成、Linux 元数据渲染和发布门禁必须观察同一批 ARB；该模型集中
/// 处理文件发现、locale 身份、消息键与占位符一致性，避免不同脚本各自实现一套
/// 不完整规则。
library;

import 'dart:convert';
import 'dart:io';

/// 正式发布本地化资源所在目录。
const String localizationResourceDirectoryPath = 'lib/core/i18n/l10n';

/// Flutter gen-l10n 使用的中文模板资源。
const String localizationTemplateFileName = 'app_zh.arb';

/// Linux 平台元数据依赖的全部可翻译消息键。
///
/// Stable 名称复用 `appTitle`；其余字段在 ARB 中保持独立语义，禁止模板或 Shell
/// 根据某个界面文案猜测平台展示内容。
const Set<String> linuxMetadataMessageKeys = <String>{
  'appTitle',
  'linuxDesktopNameNightly',
  'linuxDesktopGenericName',
  'linuxDesktopComment',
  'linuxDesktopCommentNightly',
  'linuxDesktopKeywords',
  'linuxAppStreamDescription',
};

/// ARB 文件名与 Flutter locale 身份遵循的格式。
final RegExp _arbFileNamePattern = RegExp(
  r'^app_([A-Za-z]{2,3}(?:_[A-Za-z0-9]{2,8})*)\.arb$',
);

/// Desktop Entry 使用的 POSIX locale 格式。
final RegExp _desktopLocalePattern = RegExp(
  r'^[a-z]{2,3}(?:_[A-Z]{2})?(?:@[A-Za-z0-9_-]+)?$',
);

/// AppStream `xml:lang` 使用的 BCP 47 基础格式。
///
/// 完整 BCP 47 语法非常宽；这里覆盖 Flutter 发布 locale 会使用的 language、script、
/// region 和 variant 子标签，同时把复杂映射留在 ARB 显式配置中，禁止自动猜测。
final RegExp _appStreamLocalePattern = RegExp(
  r'^[a-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$',
);

/// 提取普通占位符和 ICU plural/select 的入口变量。
final RegExp _placeholderPattern = RegExp(r'\{([A-Za-z][A-Za-z0-9_]*)(?:[,}])');

/// 单个正式发布语言的 ARB 资源。
class LocalizationResource {
  /// 创建已经完成 JSON 解码的资源。
  const LocalizationResource({
    required this.file,
    required this.locale,
    required this.desktopLocale,
    required this.appStreamLocale,
    required this.isLinuxMetadataFallback,
    required this.values,
  });

  /// 资源文件。
  final File file;

  /// Flutter 与 ARB 使用的 locale。
  final String locale;

  /// XDG Desktop Entry 使用的显式 POSIX locale。
  final String desktopLocale;

  /// AppStream `xml:lang` 使用的显式 BCP 47 locale。
  final String appStreamLocale;

  /// 是否为 Linux 元数据的无 locale 默认回退资源。
  final bool isLinuxMetadataFallback;

  /// ARB 顶层内容。
  final Map<String, dynamic> values;

  /// 文件名，用于稳定且简洁的错误信息。
  String get fileName => file.uri.pathSegments.last;

  /// 返回不包含 ARB 元数据的业务消息键。
  Set<String> get messageKeys {
    return values.keys.where((key) => !key.startsWith('@')).toSet();
  }

  /// 读取一个已经通过目录校验的字符串消息。
  String message(String key) {
    final value = values[key];
    if (value is! String) {
      throw StateError('$fileName: $key 不是字符串消息');
    }
    return value;
  }
}

/// 正式发布 ARB 的完整目录快照。
class LocalizationResourceCatalog {
  /// 创建确定顺序的资源目录。
  const LocalizationResourceCatalog({
    required this.resources,
    required this.template,
  });

  /// 从工作区默认目录加载全部 ARB。
  factory LocalizationResourceCatalog.load({
    String directoryPath = localizationResourceDirectoryPath,
  }) {
    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      throw FileSystemException('本地化资源目录不存在', directory.path);
    }

    final files =
        directory
            .listSync()
            .whereType<File>()
            .where(
              (file) =>
                  _arbFileNamePattern.hasMatch(file.uri.pathSegments.last),
            )
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    if (files.isEmpty) {
      throw StateError('$directoryPath 中没有正式 app_*.arb 资源');
    }

    final resources = files.map(_readResource).toList(growable: false);
    final templateMatches = resources
        .where((resource) => resource.fileName == localizationTemplateFileName)
        .toList(growable: false);
    if (templateMatches.length != 1) {
      throw StateError('必须且只能存在一个 $localizationTemplateFileName');
    }

    return LocalizationResourceCatalog(
      resources: resources,
      template: templateMatches.single,
    );
  }

  /// 按文件名排序的全部正式发布语言。
  final List<LocalizationResource> resources;

  /// 消息键集合的基准模板。
  final LocalizationResource template;

  /// Linux 元数据无 locale 默认值使用的唯一资源。
  LocalizationResource get linuxMetadataFallback {
    return resources.singleWhere(
      (resource) => resource.isLinuxMetadataFallback,
    );
  }

  /// 校验目录完整性并返回全部问题。
  ///
  /// 调用方应一次性展示全部错误，避免翻译维护者反复运行命令逐个修复。
  List<String> validate() {
    final errors = <String>[];
    final templateKeys = template.messageKeys;
    final seenLocales = <String>{};
    final seenDesktopLocales = <String>{};
    final seenAppStreamLocales = <String>{};
    var fallbackCount = 0;

    for (final resource in resources) {
      if (!seenLocales.add(resource.locale)) {
        errors.add(
          '${resource.fileName}: Flutter locale ${resource.locale} 重复',
        );
      }
      if (!_desktopLocalePattern.hasMatch(resource.desktopLocale)) {
        errors.add(
          '${resource.fileName}: @@linuxDesktopLocale '
          '不是合法 POSIX locale: ${resource.desktopLocale}',
        );
      } else if (!seenDesktopLocales.add(resource.desktopLocale)) {
        errors.add(
          '${resource.fileName}: Desktop locale ${resource.desktopLocale} 重复',
        );
      }
      if (!_appStreamLocalePattern.hasMatch(resource.appStreamLocale)) {
        errors.add(
          '${resource.fileName}: @@appStreamLocale '
          '不是合法 BCP 47 locale: ${resource.appStreamLocale}',
        );
      } else if (!seenAppStreamLocales.add(resource.appStreamLocale)) {
        errors.add(
          '${resource.fileName}: AppStream locale '
          '${resource.appStreamLocale} 重复',
        );
      }
      if (resource.isLinuxMetadataFallback) {
        fallbackCount += 1;
      }

      final resourceKeys = resource.messageKeys;
      final missingKeys = templateKeys.difference(resourceKeys).toList()
        ..sort();
      final extraKeys = resourceKeys.difference(templateKeys).toList()..sort();
      if (missingKeys.isNotEmpty) {
        errors.add('${resource.fileName}: 缺少消息键 ${missingKeys.join(', ')}');
      }
      if (extraKeys.isNotEmpty) {
        errors.add('${resource.fileName}: 存在模板之外的消息键 ${extraKeys.join(', ')}');
      }

      for (final key in templateKeys.intersection(resourceKeys)) {
        final templateValue = template.values[key];
        final resourceValue = resource.values[key];
        if (templateValue is! String || resourceValue is! String) {
          errors.add('${resource.fileName}: $key 必须是字符串消息');
          continue;
        }
        final expectedPlaceholders = _placeholders(templateValue);
        final actualPlaceholders = _placeholders(resourceValue);
        if (!_sameSet(expectedPlaceholders, actualPlaceholders)) {
          errors.add(
            '${resource.fileName}: $key 占位符应为 '
            '${expectedPlaceholders.toList()..sort()}，实际为 '
            '${actualPlaceholders.toList()..sort()}',
          );
        }
      }

      _validateLinuxMetadataMessages(resource, errors);
    }

    if (fallbackCount != 1) {
      errors.add(
        '全部正式 ARB 必须恰好有一个 '
        '@@linuxMetadataFallback=true，实际为 $fallbackCount 个',
      );
    }
    return errors;
  }
}

/// 解码单个 ARB 并读取平台身份元数据。
LocalizationResource _readResource(File file) {
  final fileName = file.uri.pathSegments.last;
  final fileMatch = _arbFileNamePattern.firstMatch(fileName)!;
  final fileLocale = fileMatch.group(1)!;
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('${file.path} 顶层必须是 JSON 对象');
  }

  final declaredLocale = decoded['@@locale'];
  if (declaredLocale != fileLocale) {
    throw FormatException(
      '$fileName: @@locale 应为 "$fileLocale"，实际为 '
      '${jsonEncode(declaredLocale)}',
    );
  }
  final desktopLocale = decoded['@@linuxDesktopLocale'];
  final appStreamLocale = decoded['@@appStreamLocale'];
  final fallbackValue = decoded['@@linuxMetadataFallback'];
  if (desktopLocale is! String || desktopLocale.isEmpty) {
    throw FormatException('$fileName: 缺少 @@linuxDesktopLocale');
  }
  if (appStreamLocale is! String || appStreamLocale.isEmpty) {
    throw FormatException('$fileName: 缺少 @@appStreamLocale');
  }
  if (fallbackValue != null && fallbackValue is! bool) {
    throw FormatException('$fileName: @@linuxMetadataFallback 必须是布尔值');
  }

  return LocalizationResource(
    file: file,
    locale: fileLocale,
    desktopLocale: desktopLocale,
    appStreamLocale: appStreamLocale,
    isLinuxMetadataFallback: fallbackValue == true,
    values: decoded,
  );
}

/// 校验平台元数据文案的单行、非空和关键词列表约束。
void _validateLinuxMetadataMessages(
  LocalizationResource resource,
  List<String> errors,
) {
  for (final key in linuxMetadataMessageKeys) {
    final value = resource.values[key];
    if (value is! String) {
      errors.add('${resource.fileName}: 缺少 Linux 元数据字符串 $key');
      continue;
    }
    if (value.isEmpty || value.trim() != value) {
      errors.add('${resource.fileName}: $key 不能为空或包含首尾空白');
    }
    if (value.contains('\n') || value.contains('\r')) {
      errors.add('${resource.fileName}: $key 必须是单行文本');
    }
  }

  _validateNightlyMetadataDiffers(resource, errors);

  final keywords = resource.values['linuxDesktopKeywords'];
  if (keywords is! String || !keywords.endsWith(';')) {
    errors.add('${resource.fileName}: linuxDesktopKeywords 必须以分号结尾');
    return;
  }
  final parts = keywords.split(';');
  if (parts.length < 2 ||
      parts.last.isNotEmpty ||
      parts.take(parts.length - 1).any((part) => part.trim().isEmpty)) {
    errors.add('${resource.fileName}: linuxDesktopKeywords 必须是非空分号列表');
  }
}

/// 校验每种语言的 Nightly 名称和摘要与 Stable 确实不同。
///
/// 渠道语义应由 ARB 内容表达，不能通过测试搜索英文 `Nightly`
/// 推断；这样新增语言可以使用完全本地化的渠道文案。
void _validateNightlyMetadataDiffers(
  LocalizationResource resource,
  List<String> errors,
) {
  const channelMessagePairs = <({String stableKey, String nightlyKey})>[
    (stableKey: 'appTitle', nightlyKey: 'linuxDesktopNameNightly'),
    (
      stableKey: 'linuxDesktopComment',
      nightlyKey: 'linuxDesktopCommentNightly',
    ),
  ];

  for (final pair in channelMessagePairs) {
    final stableValue = resource.values[pair.stableKey];
    final nightlyValue = resource.values[pair.nightlyKey];
    if (stableValue is String &&
        nightlyValue is String &&
        stableValue == nightlyValue) {
      errors.add(
        '${resource.fileName}: ${pair.nightlyKey} '
        '必须与 ${pair.stableKey} 保持渠道差异',
      );
    }
  }
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
