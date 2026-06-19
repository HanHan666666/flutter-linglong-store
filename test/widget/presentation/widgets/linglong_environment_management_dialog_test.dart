import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(find.text('可用，有风险'), findsOneWidget);
    expect(find.text('OSTree 对象完整性风险'), findsOneWidget);
    expect(find.text('修复'), findsOneWidget);

    // 警示横幅：提示功能尚不稳定，三个 Tab 共享，位于标题与 TabBar 之间。
    // 采用红色强烈警告（AppColors.error），图标为 error_outline。
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(l10n.envManagementWarning), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsWidgets);

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

  // 警示横幅文案需随 locale 切换为英文，验证 l10n key 正确接入
  testWidgets('dialog renders localized warning banner in English', (
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
    expect(find.text(l10n.envManagementWarning), findsOneWidget);

    // 验证仓库管理说明提示在英文 locale 下也正确渲染。
    // 注意：Tab 标签当前为硬编码中文，不随 locale 变化，故仍按 '仓库管理' 定位。
    await tester.tap(find.text('仓库管理'));
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
      message: '玲珑数据目录权限已修复',
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
    ostree: const LinglongOstreeCheckResult(
      isAvailable: true,
      isOk: true,
      hasIntegrityWarning: true,
      detail: 'Corrupted file object found',
    ),
    issues: const [
      LinglongEnvironmentIssue(
        code: LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
        severity: LinglongEnvironmentIssueSeverity.warning,
        title: 'OSTree 对象完整性风险',
        description: '深度校验发现对象损坏，但当前玲珑仓库仍可读取。',
        repairAction: LinglongEnvironmentRepairAction.ostreeFsckDelete,
        rawDetail: 'Corrupted file object found',
      ),
    ],
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
        title: '玲珑数据目录权限异常',
        description: '关键目录属主异常，可能导致仓库迁移、下载对象或创建 layer 失败。',
        repairAction: LinglongEnvironmentRepairAction.fixDataPermissions,
        rawDetail: '/var/lib/linglong/repo 当前 root:root mode=775',
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
