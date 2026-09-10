// 特权 helper 定位入口单测（docs/51：仅 bundle 内固定路径解析）。
//
// 覆盖：bundle 内 helper 存在时返回该路径；缺失时按"授权组件不可用"失败；
// 未注入覆盖时按解析后可执行文件推导 `libexec/` 路径。
// 原 FUSE 检测/暂存/清扫用例随信任边界收敛删除，不再保留。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_binary.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_exception.dart';

void main() {
  late Directory tempDir;
  late File bundleHelper;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ll-helper-test');
    final bundleDir = Directory('${tempDir.path}/bundle')
      ..createSync(recursive: true);
    bundleHelper = File('${bundleDir.path}/linglong_store_helper');
    bundleHelper.writeAsStringSync('#!/bin/sh\nexit 0\n');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('PrivilegedHelperBinary.prepare', () {
    test('helper 存在时返回 bundle 内绝对路径', () {
      final binary = PrivilegedHelperBinary(
        bundleHelperPathOverride: bundleHelper.path,
      );

      expect(binary.prepare(), bundleHelper.path);
    });

    test('helper 缺失时按授权组件不可用失败', () {
      final binary = PrivilegedHelperBinary(
        bundleHelperPathOverride: '${tempDir.path}/bundle/missing_helper',
      );

      expect(
        () => binary.prepare(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
    });

    test('未注入覆盖时按解析后可执行文件推导 bundle 内路径', () {
      // 真实布局：<bundle>/linglong_store 与 <bundle>/libexec/linglong_store_helper。
      final derived =
          File('${tempDir.path}/bundle/libexec/linglong_store_helper')
            ..createSync(recursive: true)
            ..writeAsStringSync('#!/bin/sh\nexit 0\n');

      final binary = PrivilegedHelperBinary(
        resolvedExecutableOverride: '${tempDir.path}/bundle/linglong_store',
      );

      expect(binary.prepare(), derived.path);
    });

    test('推导路径不存在时按授权组件不可用失败', () {
      final binary = PrivilegedHelperBinary(
        resolvedExecutableOverride: '${tempDir.path}/bundle/linglong_store',
      );

      expect(
        () => binary.prepare(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
    });
  });
}
