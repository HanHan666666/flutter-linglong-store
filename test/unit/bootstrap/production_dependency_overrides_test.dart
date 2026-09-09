/// 生产组合根装配 smoke 测试。
///
/// 组合根只在 `main.dart` 使用，普通单测不会触达；这里只验证本功能新增的两个
/// 覆盖（免密规则 Gateway 与只读模式读取器）能被正确解析，避免漏配 override
/// 直到应用启动才暴露。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/polkit_rule_provider.dart';
import 'package:linglong_store/bootstrap/production_dependency_overrides.dart';
import 'package:linglong_store/core/platform/polkit_rule_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('组合根注入免密规则 Gateway 与只读模式读取器', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: createProductionDependencyOverrides(
        sharedPreferences: prefs,
      ),
    );
    addTearDown(container.dispose);

    expect(
      container.read(polkitRuleGatewayProvider),
      isA<PolkitRuleScriptGateway>(),
    );

    // 只读读取器接到控制器内存状态：没有缓存时返回 false（走 helper 路径），
    // 且读取过程不触发任何特权调用或受限目录访问。
    final reader = container.read(passwordFreeInstallModeReaderProvider);
    expect(reader(), isFalse);
    expect(container.read(polkitRuleProvider).usesPasswordFreeCli, isFalse);
  });
}
