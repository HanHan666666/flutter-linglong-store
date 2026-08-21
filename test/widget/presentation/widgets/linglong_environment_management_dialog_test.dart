import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_dependency_providers.dart';
import 'package:linglong_store/application/providers/linglong_environment_management_provider.dart';
import 'package:linglong_store/application/services/linglong_environment_management_service.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/linglong_environment_management.dart';
import 'package:linglong_store/domain/models/linglong_repository_config.dart';
import 'package:linglong_store/domain/repositories/linglong_repository_management_repository.dart';
import 'package:linglong_store/presentation/widgets/linglong_environment_management_dialog.dart';

void main() {
  testWidgets('dialog renders analysis, repository and storage tabs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linglongEnvironmentManagementServiceProvider.overrideWithValue(
            _FakeManagementService(),
          ),
          linglongRepositoryManagementRepositoryProvider.overrideWithValue(
            _FakeRepositoryManagementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: LinglongEnvironmentManagementDialog()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('玲珑环境管理'), findsOneWidget);
    expect(find.text('环境分析'), findsOneWidget);
    expect(find.text('本地数据'), findsOneWidget);
    expect(find.text('正常'), findsWidgets);
    expect(find.text('OSTree'), findsNothing);
    expect(find.text('OSTree 对象完整性风险'), findsNothing);

    // 警示横幅已随功能稳定移除，不再有全局红色警告。
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));

    // 分段式 TabBar：默认选中第一个 Tab「环境分析」，其文字应为白色（主题色填充态）
    final analysisTabStyle = tester.widget<Text>(find.text('环境分析')).style!;
    expect(analysisTabStyle.color, Colors.white);

    await tester.tap(find.text('仓库管理'));
    await tester.pumpAndSettle();
    expect(find.text('默认仓库：stable'), findsOneWidget);
    // 切换后「仓库管理」应高亮（白字），「环境分析」恢复为次级灰字
    expect(tester.widget<Text>(find.text('仓库管理')).style!.color, Colors.white);
    expect(
      tester.widget<Text>(find.text('环境分析')).style!.color,
      AppTheme.lightTheme.colorScheme.onSurfaceVariant,
    );
    expect(find.text('stable'), findsWidgets);
    expect(find.text('添加仓库'), findsOneWidget);
    // 仓库管理说明提示：标题 + 正文，提示仅限官方 stable 仓库数据、勿删 stable
    expect(find.text(l10n.repoManagementHintTitle), findsOneWidget);
    expect(find.text(l10n.repoManagementHintMessage), findsOneWidget);

    await tester.tap(find.text('保存位置'));
    await tester.pumpAndSettle();
    expect(find.text('当前保存位置'), findsOneWidget);
    expect(find.text('新的保存位置'), findsOneWidget);
    expect(find.text('移动保存位置'), findsOneWidget);
  });

  // 仓库管理区域文案需随 locale 切换为英文，验证 l10n key 正确接入
  testWidgets('dialog renders localized repository hints in English', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linglongEnvironmentManagementServiceProvider.overrideWithValue(
            _FakeManagementService(),
          ),
          linglongRepositoryManagementRepositoryProvider.overrideWithValue(
            _FakeRepositoryManagementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: LinglongEnvironmentManagementDialog()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    // 使用本地化标签切换页面，防止测试绕过实际语言资源契约。
    await tester.tap(find.text(l10n.envManagementRepositoryTab));
    await tester.pumpAndSettle();
    expect(find.text(l10n.repoManagementHintTitle), findsOneWidget);
    expect(find.text(l10n.repoManagementHintMessage), findsOneWidget);
  });

  testWidgets('dialog confirms linglong data permission repair', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final service = _FakeManagementService(
      analysis: _permissionIssueAnalysis(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          linglongEnvironmentManagementServiceProvider.overrideWithValue(
            service,
          ),
          linglongRepositoryManagementRepositoryProvider.overrideWithValue(
            _FakeRepositoryManagementRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Center(child: LinglongEnvironmentManagementDialog()),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('玲珑数据目录权限异常'), findsOneWidget);

    await tester.tap(find.text('修复'));
    await tester.pumpAndSettle();
    expect(find.text('修复玲珑数据目录权限'), findsOneWidget);

    await tester.tap(find.text('修复权限'));
    await tester.pumpAndSettle();
    expect(service.repairDataPermissionCallCount, 1);
  });
}

class _FakeManagementService extends LinglongEnvironmentManagementService {
  _FakeManagementService({LinglongEnvironmentAnalysis? analysis})
    : _analysis = analysis,
      super(
        executor: ShellCommandExecutor(
          runner: const _FixedShellCommandRunner(),
        ),
        environmentService: LinglongEnvironmentService(
          executor: ShellCommandExecutor(
            runner: const _FixedShellCommandRunner(),
          ),
        ),
      );

  final LinglongEnvironmentAnalysis? _analysis;
  int repairDataPermissionCallCount = 0;

  @override
  Future<LinglongEnvironmentAnalysis> analyzeEnvironment() async {
    return _analysis ?? _defaultAnalysis();
  }

  @override
  Future<LinglongEnvironmentRepairResult> repairLinglongDataPermissions({
    String? logFilePath,
  }) async {
    repairDataPermissionCallCount += 1;
    return const LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.fixDataPermissions,
      success: true,
      code: LinglongEnvironmentRepairResultCode.dataPermissionRepairCompleted,
      logFilePath: '/tmp/permission.log',
    );
  }
}

LinglongEnvironmentAnalysis _defaultAnalysis() {
  return LinglongEnvironmentAnalysis(
    envResult: const LinglongEnvCheckResult(
      isOk: true,
      llCliVersion: '1.12.2',
      repoStatus: RepoStatus.ok,
      checkedAt: 1,
    ),
    storage: const LinglongStorageInfo(
      rootPath: '/var/lib/linglong',
      usagePercent: 94,
    ),
    dataPermission: const LinglongDataPermissionCheckResult(
      isAvailable: true,
      isOk: true,
    ),
    ostree: const LinglongOstreeCheckResult(isAvailable: true, isOk: true),
    issues: const [],
    runningAppCount: 0,
    analyzedAt: DateTime.fromMillisecondsSinceEpoch(1),
  );
}

LinglongEnvironmentAnalysis _permissionIssueAnalysis() {
  return LinglongEnvironmentAnalysis(
    envResult: const LinglongEnvCheckResult(
      isOk: true,
      llCliVersion: '1.12.2',
      repoStatus: RepoStatus.ok,
      checkedAt: 1,
    ),
    storage: const LinglongStorageInfo(rootPath: '/var/lib/linglong'),
    dataPermission: const LinglongDataPermissionCheckResult(
      isAvailable: true,
      isOk: false,
      detail: '/var/lib/linglong/repo 当前 root:root mode=775',
    ),
    ostree: const LinglongOstreeCheckResult(isAvailable: true, isOk: true),
    issues: const [
      LinglongEnvironmentIssue(
        code: LinglongEnvironmentIssueCode.linglongDataPermissionAbnormal,
        severity: LinglongEnvironmentIssueSeverity.error,
        repairAction: LinglongEnvironmentRepairAction.fixDataPermissions,
        rawDetail: '/var/lib/linglong/repo 当前 root:root mode=775',
        subject: 'deepin-linglong',
      ),
    ],
    runningAppCount: 0,
    analyzedAt: DateTime.fromMillisecondsSinceEpoch(1),
  );
}

class _FakeRepositoryManagementRepository
    implements LinglongRepositoryManagementRepository {
  @override
  Future<LinglongRepositoryConfig> getRepositoryConfig() async {
    return const LinglongRepositoryConfig(
      defaultRepo: 'stable',
      repos: [
        LinglongRepoInfo(
          name: 'stable',
          url: 'https://repo.example.com',
          alias: 'stable',
          priority: '0',
        ),
      ],
    );
  }

  @override
  Future<String> addRepository({
    required String name,
    required String url,
    String? alias,
  }) async => 'ok';

  @override
  Future<String> removeRepository(String aliasOrName) async => 'ok';

  @override
  Future<String> setDefaultRepository(String aliasOrName) async => 'ok';

  @override
  Future<String> setRepositoryMirror(
    String aliasOrName, {
    required bool enabled,
  }) async => 'ok';

  @override
  Future<String> setRepositoryPriority(
    String aliasOrName,
    int priority,
  ) async => 'ok';

  @override
  Future<String> updateRepository({
    required String aliasOrName,
    required String url,
  }) async => 'ok';
}

class _FixedShellCommandRunner implements ShellCommandRunner {
  const _FixedShellCommandRunner();

  @override
  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
    Map<String, String>? environment,
    ShellCommandLogOptions? logOptions,
  }) async {
    return const ShellCommandResult(stdout: '', stderr: '', exitCode: 0);
  }
}
