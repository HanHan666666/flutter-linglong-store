/// 方向感知布局 AST 门禁的单元测试。
///
/// 覆盖多行调用、方向安全写法、显式豁免和自动镜像图标的双重处理，
/// 防止门禁退化成只能识别单行文本的正则扫描。
library;

import 'package:flutter_test/flutter_test.dart';

// ignore: avoid_relative_lib_imports - 构建门禁不属于应用运行库，测试需直接复用脚本实现。
import '../../../../build/scripts/lib/directional_layout_verifier.dart';

void main() {
  group('verifyDirectionalLayoutSource', () {
    test('识别多行 EdgeInsets.only 和 Positioned 的物理方向参数', () {
      const source = '''
Widget build() {
  return Stack(
    children: [
      Padding(
        padding: const EdgeInsets.only(
          top: 8,
          left: 12,
        ),
      ),
      Positioned(
        top: 0,
        right: 4,
        child: child,
      ),
    ],
  );
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, hasLength(2));
      expect(
        violations.map((violation) => violation.message),
        containsAll([
          contains('EdgeInsetsDirectional.only'),
          contains('PositionedDirectional'),
        ]),
      );
    });

    test('仅拦截左右不对称的 EdgeInsets.fromLTRB', () {
      const source = '''
Widget build() {
  final safe = EdgeInsets.fromLTRB(16, 8, 16, 4);
  final unsafe = EdgeInsets.fromLTRB(16, 8, 4, 4);
  final directional = EdgeInsetsDirectional.fromSTEB(16, 8, 4, 4);
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, hasLength(1));
      expect(violations.single.line, 3);
      expect(violations.single.message, contains('fromSTEB'));
    });

    test('识别布局 Alignment 和 TextAlign 的物理方向枚举', () {
      const source = '''
Widget build() {
  return Container(
    alignment: Alignment.centerRight,
    child: Text('x', textAlign: TextAlign.left),
  );
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, hasLength(2));
    });

    test('保留紧邻注释和参数行上的物理几何豁免', () {
      const source = '''
Widget build() {
  // ignore: hardcoded_direction - 窗口物理边缘不随语言变化
  final windowPadding = EdgeInsets.only(right: 8);
  // ignore: hardcoded_direction - 原生窗口矩形
  final windowChild = Positioned(
    left: 8,
    child: child,
  );
  return Positioned(
    top: 0,
    // ignore: hardcoded_direction - 原生窗口坐标
    left: 4,
    child: child,
  );
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, isEmpty);
    });

    test('识别会与 Flutter 自动镜像叠加的方向图标分支', () {
      const source = '''
Widget build(BuildContext context) {
  return Icon(
    Directionality.of(context) == TextDirection.rtl
        ? Icons.arrow_back_ios
        : Icons.arrow_forward_ios,
  );
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, hasLength(1));
      expect(violations.single.message, contains('自动镜像'));
    });

    test('方向感知 API 和单一自动镜像图标不会误报', () {
      const source = '''
Widget build() {
  return PositionedDirectional(
    start: 8,
    child: Padding(
      padding: EdgeInsetsDirectional.only(end: 4),
      child: const Icon(Icons.arrow_forward_ios),
    ),
  );
}
''';

      final violations = verifyDirectionalLayoutSource(
        source,
        path: 'lib/example.dart',
      );

      expect(violations, isEmpty);
    });
  });
}
