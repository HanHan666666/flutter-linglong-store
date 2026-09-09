/// 设置页免密安装开关 Widget 测试（docs/50 §5、§10.1 Widget 行）。
///
/// 覆盖：开关与副标题展示、待同步提示、开启风险确认、取消不调用系统命令、
/// 关闭直接同步、处理中禁用并显示 loading、失败详情可复制、无障碍语义。
library;

import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/linglong_env_provider.dart';
import 'package:linglong_store/application/providers/polkit_rule_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';
import 'package:linglong_store/domain/repositories/polkit_rule_gateway.dart';
import 'package:linglong_store/presentation/pages/setting/widgets/password_free_install_tile.dart';
import 'package:linglong_store/presentation/widgets/copyable_command_block.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

/// 可编程的 Gateway 替身。
class _FakePolkitRuleGateway implements PolkitRuleGateway {
  _FakePolkitRuleGateway({this.result, this.error});

  PolkitRuleTransactionResult? result;
  Object? error;
  final List<bool> requests = <bool>[];
  Completer<void>? hold;

  @override
  Future<PolkitRuleTransactionResult> apply({required bool enabled}) async {
    requests.add(enabled);
    final gate = hold;
    if (gate != null) {
      await gate.future;
    }
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result!;
  }
}

/// 测试期间固定中文环境。
class _FixedGlobalApp extends GlobalApp {
  @override
  GlobalAppState build() {
    return const GlobalAppState(locale: Locale('zh'), isInitialized: true);
  }
}

PolkitRuleTransactionResult _appliedResult({required bool requested}) {
  return PolkitRuleTransactionResult(
    requestedEnabled: requested,
    before: requested
        ? PolkitRuleSystemState.disabled
        : PolkitRuleSystemState.enabled,
    after: requested
        ? PolkitRuleSystemState.enabled
        : PolkitRuleSystemState.disabled,
    outcome: PolkitRuleOutcome.applied,
  );
}

Future<ProviderContainer> _pumpTile(
  WidgetTester tester, {
  required _FakePolkitRuleGateway gateway,
  Map<String, Object> initialPreferences = const <String, Object>{},
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues(initialPreferences);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      polkitRuleGatewayProvider.overrideWithValue(gateway),
      appOperationJournalRepositoryProvider.overrideWithValue(
        MemoryAppOperationJournalRepository(),
      ),
      linglongEnvProvider.overrideWithValue(
        const LinglongEnvState(
          checkState: LinglongEnvCheckState.success,
          result: LinglongEnvCheckResult(
            isOk: true,
            distribution: LinuxDistribution.uos,
            checkedAt: 1,
          ),
        ),
      ),
      globalAppProvider.overrideWith(_FixedGlobalApp.new),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: PasswordFreeInstallTile()),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  testWidgets('默认关闭：展示标题、副标题与关闭状态的开关', (tester) async {
    await _pumpTile(tester, gateway: _FakePolkitRuleGateway());

    expect(find.text('安装时免密码确认'), findsOneWidget);
    expect(
      find.text('安装和更新应用时免输密码；卸载等操作沿用系统授权设置。'),
      findsOneWidget,
    );
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
    expect(tile.onChanged, isNotNull);
  });

  testWidgets('待同步时补充提示行且开关可交互', (tester) async {
    await _pumpTile(
      tester,
      gateway: _FakePolkitRuleGateway(),
      initialPreferences: <String, Object>{
        PasswordFreeInstallCache.preferencesKey: '{"version":1}',
      },
    );

    expect(
      find.text('显示的是上次保存的状态，修改时将同步系统设置。'),
      findsOneWidget,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNotNull,
    );
  });

  testWidgets('开启：先风险确认，确认后只提权一次并提示成功', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: true),
    );
    await _pumpTile(tester, gateway: gateway);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('开启免密码确认？'), findsOneWidget);
    expect(find.text('我已了解风险，开启'), findsOneWidget);
    expect(find.text('保持原设置'), findsOneWidget);
    expect(gateway.requests, isEmpty, reason: '确认前不得调用系统命令');

    await tester.tap(find.text('我已了解风险，开启'));
    await tester.pumpAndSettle();

    expect(gateway.requests, <bool>[true]);
    expect(find.text('已开启安装免密'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('取消确认：不调用系统命令，开关保持关闭且可再次点击', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: true),
    );
    await _pumpTile(tester, gateway: gateway);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保持原设置'));
    await tester.pumpAndSettle();

    expect(gateway.requests, isEmpty);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    // 单飞锁已释放：再次点击仍能弹出确认框。
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.text('开启免密码确认？'), findsOneWidget);
  });

  testWidgets('关闭：无需风险确认，直接同步系统设置', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: false),
    );
    await _pumpTile(
      tester,
      gateway: gateway,
      initialPreferences: <String, Object>{
        PasswordFreeInstallCache.preferencesKey:
            '{"version":1,"enabled":true,"needsSync":false}',
      },
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('开启免密码确认？'), findsNothing);
    expect(gateway.requests, <bool>[false]);
    expect(find.text('已关闭本功能的免密设置'), findsOneWidget);
  });

  testWidgets('处理中禁用开关并显示本地化 loading', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: true),
    )..hold = Completer<void>();
    await _pumpTile(tester, gateway: gateway);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我已了解风险，开启'));
    await tester.pump();

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.onChanged, isNull, reason: '非 ready 状态必须禁用开关');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gateway.hold!.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
      isNotNull,
    );
  });

  testWidgets('失败时提供可复制的诊断详情', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.unexpected,
        '事务脚本输出不符合版本化契约: boom',
      ),
    );
    await _pumpTile(tester, gateway: gateway);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我已了解风险，开启'));
    await tester.pumpAndSettle();

    expect(find.byType(CopyableCommandBlock), findsOneWidget);
    expect(
      find.text('事务脚本输出不符合版本化契约: boom'),
      findsOneWidget,
    );
    expect(find.text('安装时免密码确认'), findsWidgets);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(CopyableCommandBlock), findsNothing);
  });

  testWidgets('开关具备可切换语义且交互高度不低于 48px', (tester) async {
    await _pumpTile(tester, gateway: _FakePolkitRuleGateway());

    final data = tester
        .getSemantics(find.byType(SwitchListTile))
        .getSemanticsData();
    // 开关语义：具备“可切换”状态且当前为关闭；控件可聚焦、可点击。
    expect(data.flagsCollection.isToggled, Tristate.isFalse);
    expect(data.flagsCollection.isFocused, isNot(Tristate.none));
    expect(data.hasAction(SemanticsAction.tap), isTrue);

    final size = tester.getSize(find.byType(SwitchListTile));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('离开设置页后事务仍正确收尾并更新缓存', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: true),
    )..hold = Completer<void>();
    final container = await _pumpTile(tester, gateway: gateway);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('我已了解风险，开启'));
    await tester.pump();

    // 离开设置页（组件被移除）后再完成提权：控制器不依赖页面可见性。
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
    );
    gateway.hold!.complete();
    await tester.pumpAndSettle();

    final state = container.read(polkitRuleProvider);
    expect(state.enabled, isTrue);
    expect(state.needsSync, isFalse);
    expect(state.phase, PasswordFreeInstallPhase.ready);
  });

  testWidgets('键盘可达：Tab 聚焦后按空格可触发开启确认', (tester) async {
    final gateway = _FakePolkitRuleGateway(
      result: _appliedResult(requested: true),
    );
    await _pumpTile(tester, gateway: gateway);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();

    expect(find.text('开启免密码确认？'), findsOneWidget);
    expect(gateway.requests, isEmpty);
  });
}
