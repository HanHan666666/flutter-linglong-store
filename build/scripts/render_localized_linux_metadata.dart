/// 从正式 ARB 生成完整的 XDG Desktop Entry 与 AppStream 本地化字段。
///
/// Shell 仍负责版本、架构、应用身份和包格式变量；本工具只负责自然语言字段，按
/// Stable/Nightly 渠道选择内容并严格验证每个字段覆盖全部发布语言。新增语言时只需
/// 添加 ARB，禁止在模板或 Shell 中增加语言分支。
library;

import 'dart:convert';
import 'dart:io';

import 'lib/localization_resource_catalog.dart';

/// 模板中 canonical Desktop Entry 名称字段的生成标记。
const String _desktopNameMarker = '@LOCALIZED_DESKTOP_NAME@';

/// 模板中 canonical Desktop Entry 通用名称字段的生成标记。
const String _desktopGenericNameMarker = '@LOCALIZED_DESKTOP_GENERIC_NAME@';

/// 模板中 Desktop Entry 说明字段的生成标记。
const String _desktopCommentMarker = '@LOCALIZED_DESKTOP_COMMENT@';

/// 模板中 canonical Desktop Entry 搜索关键词字段的生成标记。
const String _desktopKeywordsMarker = '@LOCALIZED_DESKTOP_KEYWORDS@';

/// 模板中 AppStream 名称元素的生成标记。
const String _appStreamNameMarker = '@LOCALIZED_APPSTREAM_NAME@';

/// 模板中 AppStream 摘要元素的生成标记。
const String _appStreamSummaryMarker = '@LOCALIZED_APPSTREAM_SUMMARY@';

/// 模板中 AppStream 描述段落的生成标记。
const String _appStreamDescriptionMarker = '@LOCALIZED_APPSTREAM_DESCRIPTION@';

/// 仍残留在已渲染平台文件中的模板标记。
final RegExp _unresolvedMarkerPattern = RegExp(r'@[A-Z][A-Z0-9_]+@');

/// Stable 与 Nightly 共享的渠道模型。
enum _ReleaseChannel {
  /// 正式稳定版。
  stable,

  /// 每日构建版。
  nightly;

  /// 解析 Shell 传入的稳定渠道值。
  static _ReleaseChannel parse(String value) {
    return switch (value) {
      'stable' => _ReleaseChannel.stable,
      'nightly' => _ReleaseChannel.nightly,
      _ => throw FormatException('不支持的元数据渠道: $value'),
    };
  }
}

/// 命令行渲染参数。
class _RenderArguments {
  /// 创建已经完成路径校验前解析的参数。
  const _RenderArguments({
    required this.channel,
    required this.desktopFile,
    required this.compatibilityDirectory,
    required this.appStreamFile,
  });

  /// 从成对的长选项解析渲染参数。
  factory _RenderArguments.parse(List<String> arguments) {
    final values = <String, String>{};
    for (var index = 0; index < arguments.length; index += 2) {
      if (index + 1 >= arguments.length || !arguments[index].startsWith('--')) {
        throw const FormatException(_usage);
      }
      values[arguments[index]] = arguments[index + 1];
    }

    final channel = values['--channel'];
    final desktopPath = values['--desktop-file'];
    final compatibilityPath = values['--compat-directory'];
    final appStreamPath = values['--appstream-file'];
    if (values.length != 4 ||
        channel == null ||
        desktopPath == null ||
        compatibilityPath == null ||
        appStreamPath == null) {
      throw const FormatException(_usage);
    }

    return _RenderArguments(
      channel: _ReleaseChannel.parse(channel),
      desktopFile: File(desktopPath),
      compatibilityDirectory: Directory(compatibilityPath),
      appStreamFile: File(appStreamPath),
    );
  }

  /// 当前发布渠道。
  final _ReleaseChannel channel;

  /// canonical Desktop Entry 输出文件。
  final File desktopFile;

  /// 当前渠道全部 compatibility Desktop Entry 的目录。
  final Directory compatibilityDirectory;

  /// AppStream 输出文件。
  final File appStreamFile;

  /// 命令行用法。
  static const String _usage =
      'Usage: render_localized_linux_metadata.dart '
      '--channel <stable|nightly> --desktop-file <path> '
      '--compat-directory <path> --appstream-file <path>';
}

/// 加载 ARB、渲染全部平台文件并验证语言集合。
void main(List<String> arguments) {
  try {
    final options = _RenderArguments.parse(arguments);
    final catalog = LocalizationResourceCatalog.load();
    final catalogErrors = catalog.validate();
    if (catalogErrors.isNotEmpty) {
      throw StateError(catalogErrors.join('\n'));
    }

    _requireFile(options.desktopFile);
    _requireFile(options.appStreamFile);
    if (!options.compatibilityDirectory.existsSync()) {
      throw FileSystemException(
        '兼容 Desktop Entry 目录不存在',
        options.compatibilityDirectory.path,
      );
    }
    final compatibilityFiles =
        options.compatibilityDirectory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.desktop'))
            .toList()
          ..sort((left, right) => left.path.compareTo(right.path));
    if (compatibilityFiles.isEmpty) {
      throw StateError('当前渠道没有 compatibility Desktop Entry');
    }

    _renderCanonicalDesktop(
      file: options.desktopFile,
      catalog: catalog,
      channel: options.channel,
    );
    for (final file in compatibilityFiles) {
      _renderCompatibilityDesktop(
        file: file,
        catalog: catalog,
        channel: options.channel,
      );
    }
    _renderAppStream(
      file: options.appStreamFile,
      catalog: catalog,
      channel: options.channel,
    );

    stdout.writeln(
      'localized Linux metadata rendered '
      '(${catalog.resources.length} locales, '
      '${compatibilityFiles.length} compatibility entries)',
    );
  } on Object catch (error) {
    stderr.writeln('Linux 本地化元数据生成失败：$error');
    exitCode = 1;
  }
}

/// 渲染 canonical Desktop Entry 的四组可本地化字段。
void _renderCanonicalDesktop({
  required File file,
  required LocalizationResourceCatalog catalog,
  required _ReleaseChannel channel,
}) {
  var content = file.readAsStringSync();
  content = _replaceMarker(
    content,
    _desktopNameMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'Name',
      messageKey: _nameKey(channel),
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _desktopGenericNameMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'GenericName',
      messageKey: 'linuxDesktopGenericName',
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _desktopCommentMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'Comment',
      messageKey: _commentKey(channel),
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _desktopKeywordsMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'Keywords',
      messageKey: 'linuxDesktopKeywords',
    ),
    file,
  );
  _verifyNoMarkers(content, file);
  _verifyDesktopFieldSets(
    content: content,
    file: file,
    catalog: catalog,
    expectedFields: const <String>{
      'Name',
      'GenericName',
      'Comment',
      'Keywords',
    },
  );
  file.writeAsStringSync(content);
}

/// 渲染隐藏兼容入口；未启用的字段必须对所有语言同时不存在。
void _renderCompatibilityDesktop({
  required File file,
  required LocalizationResourceCatalog catalog,
  required _ReleaseChannel channel,
}) {
  var content = file.readAsStringSync();
  content = _replaceMarker(
    content,
    _desktopNameMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'Name',
      messageKey: _nameKey(channel),
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _desktopCommentMarker,
    _desktopFieldBlock(
      catalog: catalog,
      field: 'Comment',
      messageKey: _commentKey(channel),
    ),
    file,
  );
  _verifyNoMarkers(content, file);
  _verifyDesktopFieldSets(
    content: content,
    file: file,
    catalog: catalog,
    expectedFields: const <String>{'Name', 'Comment'},
    forbiddenFields: const <String>{'GenericName', 'Keywords'},
  );
  file.writeAsStringSync(content);
}

/// 渲染 AppStream 名称、摘要和描述的完整语言集合。
void _renderAppStream({
  required File file,
  required LocalizationResourceCatalog catalog,
  required _ReleaseChannel channel,
}) {
  var content = file.readAsStringSync();
  content = _replaceMarker(
    content,
    _appStreamNameMarker,
    _appStreamElementBlock(
      catalog: catalog,
      element: 'name',
      messageKey: _nameKey(channel),
      indent: '  ',
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _appStreamSummaryMarker,
    _appStreamElementBlock(
      catalog: catalog,
      element: 'summary',
      messageKey: _commentKey(channel),
      indent: '  ',
    ),
    file,
  );
  content = _replaceMarker(
    content,
    _appStreamDescriptionMarker,
    _appStreamElementBlock(
      catalog: catalog,
      element: 'p',
      messageKey: 'linuxAppStreamDescription',
      indent: '    ',
    ),
    file,
  );
  _verifyNoMarkers(content, file);
  _verifyAppStreamFieldSets(content: content, file: file, catalog: catalog);
  file.writeAsStringSync(content);
}

/// 返回当前渠道使用的应用名称消息键。
String _nameKey(_ReleaseChannel channel) {
  return switch (channel) {
    _ReleaseChannel.stable => 'appTitle',
    _ReleaseChannel.nightly => 'linuxDesktopNameNightly',
  };
}

/// 返回当前渠道使用的摘要消息键。
String _commentKey(_ReleaseChannel channel) {
  return switch (channel) {
    _ReleaseChannel.stable => 'linuxDesktopComment',
    _ReleaseChannel.nightly => 'linuxDesktopCommentNightly',
  };
}

/// 构建一个 Desktop Entry 字段的默认值和全部显式 locale 行。
String _desktopFieldBlock({
  required LocalizationResourceCatalog catalog,
  required String field,
  required String messageKey,
}) {
  final lines = <String>[
    '$field=${_escapeDesktopValue(catalog.linuxMetadataFallback.message(messageKey))}',
    for (final resource in catalog.resources)
      '$field[${resource.desktopLocale}]='
          '${_escapeDesktopValue(resource.message(messageKey))}',
  ];
  return lines.join('\n');
}

/// 构建一个 AppStream 元素的默认值和全部显式 locale 元素。
String _appStreamElementBlock({
  required LocalizationResourceCatalog catalog,
  required String element,
  required String messageKey,
  required String indent,
}) {
  final escape = const HtmlEscape(HtmlEscapeMode.element).convert;
  final lines = <String>[
    '$indent<$element>'
        '${escape(catalog.linuxMetadataFallback.message(messageKey))}'
        '</$element>',
    for (final resource in catalog.resources)
      '$indent<$element xml:lang="${resource.appStreamLocale}">'
          '${escape(resource.message(messageKey))}'
          '</$element>',
  ];
  return lines.join('\n');
}

/// 转义 Desktop Entry 单行 localestring。
String _escapeDesktopValue(String value) {
  return value
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}

/// 精确替换一个必须出现一次的字段级模板标记。
String _replaceMarker(
  String content,
  String marker,
  String replacement,
  File file,
) {
  final count = marker.allMatches(content).length;
  if (count != 1) {
    throw FormatException('${file.path}: $marker 应出现一次，实际为 $count 次');
  }
  return content.replaceFirst(marker, replacement);
}

/// 确认平台输出没有任何未解析的构建标记。
void _verifyNoMarkers(String content, File file) {
  final markers =
      _unresolvedMarkerPattern
          .allMatches(content)
          .map((match) => match.group(0)!)
          .toSet()
          .toList()
        ..sort();
  if (markers.isNotEmpty) {
    throw FormatException('${file.path}: 存在未解析标记 ${markers.join(', ')}');
  }
}

/// 验证 Desktop Entry 每个已启用字段拥有相同且完整的语言集合。
void _verifyDesktopFieldSets({
  required String content,
  required File file,
  required LocalizationResourceCatalog catalog,
  required Set<String> expectedFields,
  Set<String> forbiddenFields = const <String>{},
}) {
  final expectedLocales = catalog.resources
      .map((resource) => resource.desktopLocale)
      .toSet();
  for (final field in expectedFields) {
    final matches = RegExp(
      '^${RegExp.escape(field)}(?:\\[([A-Za-z0-9_@-]+)\\])?=',
      multiLine: true,
    ).allMatches(content).toList(growable: false);
    final defaults = matches.where((match) => match.group(1) == null).length;
    final locales = matches
        .map((match) => match.group(1))
        .whereType<String>()
        .toSet();
    if (defaults != 1 || !_sameSet(locales, expectedLocales)) {
      throw FormatException(
        '${file.path}: $field 语言集合不完整，默认值 $defaults 个，'
        '期望 ${_sorted(expectedLocales)}，实际 ${_sorted(locales)}',
      );
    }
  }
  for (final field in forbiddenFields) {
    final fieldPattern = RegExp(
      '^${RegExp.escape(field)}(?:\\[[A-Za-z0-9_@-]+\\])?=',
      multiLine: true,
    );
    if (fieldPattern.hasMatch(content)) {
      throw FormatException('${file.path}: 禁止生成 $field 字段');
    }
  }
}

/// 验证 AppStream 三组元素拥有相同且完整的语言集合。
void _verifyAppStreamFieldSets({
  required String content,
  required File file,
  required LocalizationResourceCatalog catalog,
}) {
  final expectedLocales = catalog.resources
      .map((resource) => resource.appStreamLocale)
      .toSet();
  for (final element in const <String>['name', 'summary', 'p']) {
    final matches = RegExp(
      '<$element(?: xml:lang="([^"]+)")?>',
    ).allMatches(content).toList(growable: false);
    final defaults = matches.where((match) => match.group(1) == null).length;
    final locales = matches
        .map((match) => match.group(1))
        .whereType<String>()
        .toSet();
    if (defaults != 1 || !_sameSet(locales, expectedLocales)) {
      throw FormatException(
        '${file.path}: <$element> 语言集合不完整，默认值 $defaults 个，'
        '期望 ${_sorted(expectedLocales)}，实际 ${_sorted(locales)}',
      );
    }
  }
}

/// 检查输入文件存在且为普通文件。
void _requireFile(File file) {
  if (!file.existsSync()) {
    throw FileSystemException('待渲染平台文件不存在', file.path);
  }
}

/// 比较两个集合内容是否完全一致。
bool _sameSet(Set<String> left, Set<String> right) {
  return left.length == right.length && left.containsAll(right);
}

/// 返回用于稳定错误信息的有序集合。
List<String> _sorted(Set<String> values) => values.toList()..sort();
