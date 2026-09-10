/// 生产组合根装配 smoke 测试。
///
/// 组合根只在 `main.dart` 使用，普通单测不会触达；这里验证本功能新增的覆盖
/// （免密规则 Gateway、只读模式读取器、helper 信任解析器）能被正确解析，
/// 避免漏配 override 直到应用启动才暴露。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/polkit_rule_provider.dart';
import 'package:linglong_store/bootstrap/production_dependency_overrides.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/polkit_rule_gateway.dart';
import 'package:linglong_store/data/repositories/linglong_cli_repository_impl.dart';
import 'package:linglong_store/domain/models/app_self_update.dart';
import 'package:linglong_store/domain/models/privileged_helper_trust.dart';
import 'package:linglong_store/domain/repositories/app_self_update_gateways.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(AppLogger.init);

  Future<ProviderContainer> buildProductionContainer() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: createProductionDependencyOverrides(sharedPreferences: prefs),
    );
    addTearDown(container.dispose);
    return container;
  }

  test('组合根注入免密规则 Gateway 与只读模式读取器', () async {
    final container = await buildProductionContainer();

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

  test('组合根注入 helper 信任解析器与安装 Repository（docs/51）', () async {
    final container = await buildProductionContainer();

    // 端口必须被覆盖（漏配时读取会抛 StateError）；读取只构造闭包，
    // 不会触发任何探测命令。
    final resolver = container.read(privilegedHelperTrustResolverProvider);
    expect(resolver, isA<PrivilegedHelperTrustResolver>());

    // 安装传输的 Repository 可正常构建（信任解析器在构造时注入）。
    expect(
      container.read(linglongCliRepositoryProvider),
      isA<LinglongCliRepositoryImpl>(),
    );
  });

  test('信任解析器单次解析并缓存，探测异常保守为不可信（fail closed）', () async {
    final counting = _CountingProbe(result: true);
    final resolver = buildMemoizedHelperTrustResolver(counting);

    expect(await resolver(), isTrue);
    expect(await resolver(), isTrue);
    expect(counting.calls, 1, reason: '同一会话只应探测一次');

    final failing = buildMemoizedHelperTrustResolver(_ThrowingProbe());
    expect(await failing(), isFalse);
  });
}

/// 固定结果并统计调用次数的探测替身。
class _CountingProbe implements AppInstallationProbe {
  _CountingProbe({required this.result});

  final bool result;
  int calls = 0;

  @override
  Future<AppInstallation> detect() => throw UnimplementedError();

  @override
  Future<bool> isManagedBySystemPackageManager() async {
    calls += 1;
    return result;
  }
}

/// 探测抛异常的替身。
class _ThrowingProbe implements AppInstallationProbe {
  @override
  Future<AppInstallation> detect() => throw UnimplementedError();

  @override
  Future<bool> isManagedBySystemPackageManager() async {
    throw StateError('probe failure');
  }
}
