/// 方向感知布局的 Dart AST 校验器。
///
/// 该文件承载可复用的扫描逻辑，供 CI 命令与单元测试共同调用。使用 AST 而不是
/// 行级正则，是为了可靠识别多行参数，同时只约束布局语义，避免误伤渐变和浮层锚点。
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

/// `// ignore: hardcoded_direction` 物理方向豁免标记。
const String directionalLayoutIgnoreMarker = 'ignore: hardcoded_direction';

/// 已确认由 Flutter Material 自动按 [TextDirection] 镜像的方向图标。
///
/// 对这些图标再手写 RTL 条件分支会产生双重反转，因此门禁只检查“条件切换两个图标”
/// 的写法；直接使用其中任一图标是正确做法。
const Set<String> _autoMirroredDirectionalIcons = {
  'arrow_back',
  'arrow_back_sharp',
  'arrow_back_rounded',
  'arrow_back_outlined',
  'arrow_back_ios',
  'arrow_back_ios_sharp',
  'arrow_back_ios_rounded',
  'arrow_back_ios_outlined',
  'arrow_back_ios_new',
  'arrow_back_ios_new_sharp',
  'arrow_back_ios_new_rounded',
  'arrow_back_ios_new_outlined',
  'arrow_forward',
  'arrow_forward_sharp',
  'arrow_forward_rounded',
  'arrow_forward_outlined',
  'arrow_forward_ios',
  'arrow_forward_ios_sharp',
  'arrow_forward_ios_rounded',
  'arrow_forward_ios_outlined',
  'chevron_left',
  'chevron_left_sharp',
  'chevron_left_rounded',
  'chevron_left_outlined',
  'chevron_right',
  'chevron_right_sharp',
  'chevron_right_rounded',
  'chevron_right_outlined',
};

/// 单个方向感知布局违规。
class DirectionalLayoutViolation {
  /// 创建带源码位置的违规记录。
  const DirectionalLayoutViolation({
    required this.path,
    required this.line,
    required this.message,
  });

  /// 违规源文件路径。
  final String path;

  /// 一基源码行号。
  final int line;

  /// 面向开发者的修复建议。
  final String message;

  @override
  String toString() => '$path:$line - $message';
}

/// 校验单份 Dart 源码并返回全部方向违规。
///
/// [path] 仅用于诊断展示；未解析符号不会影响语法树扫描，但语法错误会直接抛出，
/// 避免 CI 在输入不完整时错误报告“校验通过”。
List<DirectionalLayoutViolation> verifyDirectionalLayoutSource(
  String source, {
  required String path,
}) {
  final parseResult = parseString(
    content: source,
    path: path,
    throwIfDiagnostics: false,
  );
  if (parseResult.errors.isNotEmpty) {
    final firstError = parseResult.errors.first;
    throw FormatException('$path: ${firstError.message}');
  }

  final violations = <DirectionalLayoutViolation>[];
  parseResult.unit.accept(
    _DirectionalLayoutVisitor(
      path: path,
      source: source,
      lineInfo: parseResult.lineInfo,
      violations: violations,
    ),
  );
  return violations;
}

/// 扫描指定目录下的生产 Dart 源码。
///
/// 代码生成文件由模板决定且不可手工修复，因此默认跳过 `.g.dart` 与
/// `.freezed.dart`。返回值按文件路径和行号稳定排序，便于 CI 日志审阅。
List<DirectionalLayoutViolation> scanDirectionalLayoutDirectory(
  Directory directory,
) {
  if (!directory.existsSync()) return const [];

  final files =
      directory
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

  final violations = <DirectionalLayoutViolation>[];
  for (final file in files) {
    violations.addAll(
      verifyDirectionalLayoutSource(file.readAsStringSync(), path: file.path),
    );
  }
  violations.sort((a, b) {
    final pathOrder = a.path.compareTo(b.path);
    return pathOrder != 0 ? pathOrder : a.line.compareTo(b.line);
  });
  return violations;
}

/// 遍历 AST 并将物理方向 API 收敛成统一诊断。
class _DirectionalLayoutVisitor extends RecursiveAstVisitor<void> {
  /// 创建单文件扫描器。
  _DirectionalLayoutVisitor({
    required this.path,
    required String source,
    required this.lineInfo,
    required this.violations,
  }) : _lines = source.split('\n');

  /// 当前文件路径。
  final String path;

  /// 源码行号映射。
  final LineInfo lineInfo;

  /// 当前扫描累计的违规集合。
  final List<DirectionalLayoutViolation> violations;

  /// 按行拆分的源码，用于识别显式豁免注释。
  final List<String> _lines;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // 使用源码片段兼容 analyzer 对 `const EdgeInsets.only` 等命名构造的
    // 不同 AST 字段形态；取末两段也能兼容带 import prefix 的调用。
    final nameParts = node.constructorName.toSource().split('.');
    final typeName = nameParts.length > 1
        ? nameParts[nameParts.length - 2]
        : nameParts.single;
    final constructorName = nameParts.length > 1 ? nameParts.last : null;

    _verifyConstructorLikeInvocation(
      typeName: typeName,
      constructorName: constructorName,
      arguments: node.argumentList.arguments,
      invocationNode: node,
    );

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // parseString 不做符号解析，无 const 的构造调用在语法树中表现为 MethodInvocation。
    // 因此这里与 InstanceCreationExpression 共用同一套参数校验。
    final targetName = node.target?.toSource();
    final methodName = node.methodName.name;
    _verifyConstructorLikeInvocation(
      typeName: targetName ?? methodName,
      constructorName: targetName == null ? null : methodName,
      arguments: node.argumentList.arguments,
      invocationNode: node,
    );
    super.visitMethodInvocation(node);
  }

  /// 校验构造调用的方向参数，同时兼容已识别和未解析的 AST 节点形态。
  void _verifyConstructorLikeInvocation({
    required String typeName,
    required String? constructorName,
    required NodeList<Expression> arguments,
    required AstNode invocationNode,
  }) {
    final invocationIgnored = _isIgnored(invocationNode);
    if (typeName == 'EdgeInsets' && constructorName == 'only') {
      for (final argument in arguments.whereType<NamedExpression>()) {
        final name = argument.name.label.name;
        if ((name == 'left' || name == 'right') &&
            !invocationIgnored &&
            !_isIgnored(argument)) {
          _addViolation(
            argument,
            '内边距应使用 EdgeInsetsDirectional.only(start/end)',
          );
        }
      }
    }

    if (typeName == 'EdgeInsets' && constructorName == 'fromLTRB') {
      if (arguments.length == 4 &&
          arguments.first.toSource() != arguments[2].toSource() &&
          !invocationIgnored) {
        _addViolation(
          invocationNode,
          '左右不对称内边距应使用 EdgeInsetsDirectional.fromSTEB(start/end)',
        );
      }
    }

    if (typeName == 'Positioned') {
      for (final argument in arguments.whereType<NamedExpression>()) {
        final name = argument.name.label.name;
        if ((name == 'left' || name == 'right') &&
            !invocationIgnored &&
            !_isIgnored(argument)) {
          _addViolation(argument, '绝对定位应使用 PositionedDirectional(start/end)');
        }
      }
    }
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    if (node.name.label.name == 'alignment' &&
        _isPhysicalAlignment(node.expression) &&
        !_isIgnored(node)) {
      _addViolation(
        node,
        '布局对齐应使用 AlignmentDirectional（如 centerStart/centerEnd）',
      );
    }
    super.visitNamedExpression(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'TextAlign' &&
        (node.identifier.name == 'left' || node.identifier.name == 'right') &&
        !_isIgnored(node)) {
      _addViolation(node, '文本对齐应使用 TextAlign.start/end');
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    final condition = node.condition.toSource();
    final thenIcon = _materialIconName(node.thenExpression);
    final elseIcon = _materialIconName(node.elseExpression);
    if (condition.contains('TextDirection.rtl') &&
        thenIcon != null &&
        elseIcon != null &&
        thenIcon != elseIcon &&
        _autoMirroredDirectionalIcons.contains(thenIcon) &&
        _autoMirroredDirectionalIcons.contains(elseIcon) &&
        !_isIgnored(node)) {
      _addViolation(node, '该 Material 方向图标已支持自动镜像，请保留单一图标以避免 RTL 双重反转');
    }
    super.visitConditionalExpression(node);
  }

  /// 判断表达式是否为禁止用于布局的物理 [Alignment] 枚举。
  bool _isPhysicalAlignment(Expression expression) {
    if (expression is! PrefixedIdentifier ||
        expression.prefix.name != 'Alignment') {
      return false;
    }
    return const {
      'centerLeft',
      'centerRight',
      'topLeft',
      'topRight',
      'bottomLeft',
      'bottomRight',
    }.contains(expression.identifier.name);
  }

  /// 提取直接作为条件分支结果的 Material 图标名称。
  String? _materialIconName(Expression expression) {
    final match = RegExp(
      r'^Icons\.([A-Za-z0-9_]+)$',
    ).firstMatch(expression.toSource());
    return match?.group(1);
  }

  /// 判断违规节点是否由本行或上方紧邻注释块显式豁免。
  bool _isIgnored(AstNode node) {
    final lineIndex = lineInfo.getLocation(node.offset).lineNumber - 1;
    if (_lines[lineIndex].contains(directionalLayoutIgnoreMarker)) return true;

    for (var index = lineIndex - 1; index >= 0; index--) {
      final line = _lines[index].trimLeft();
      if (!line.startsWith('//')) break;
      if (line.contains(directionalLayoutIgnoreMarker)) return true;
    }
    return false;
  }

  /// 以节点起始位置记录诊断，确保多行调用仍能跳转到实际违规参数。
  void _addViolation(AstNode node, String message) {
    violations.add(
      DirectionalLayoutViolation(
        path: path,
        line: lineInfo.getLocation(node.offset).lineNumber,
        message: message,
      ),
    );
  }
}
