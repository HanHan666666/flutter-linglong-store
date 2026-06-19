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
    expect(find.text('OSTree 仓库完整性异常'), findsOneWidget);
    expect(find.text('修复'), findsOneWidget);

    // 警示横幅：提示功能尚不稳定，三个 Tab 共享，位于标题与 TabBar 之间
    final l10n = await AppLocalizations.delegate.load(const Locale('zh'));
    expect(find.text(l10n.envManagementWarning), findsOneWidget);
    expect(
      find.byIcon(Icons.warning_amber_rounded),
      findsWidgets,
    );

    await tester.tap(find.text('仓库管理'));
    await tester.pumpAndSettle();
    expect(find.text('默认仓库：stable'), findsOneWidget);
    expect(find.text('stable'), findsWidgets);
    expect(find.text('添加仓库'), findsOneWidget);

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
  });
}

class _FakeManagementService extends LinglongEnvironmentManagementService {
  _FakeManagementService()
    : super(
        executor: ShellCommandExecutor(
          runner: const _FixedShellCommandRunner(),
        ),
        environmentService: LinglongEnvironmentService(
          executor: ShellCommandExecutor(
            runner: const _FixedShellCommandRunner(),
          ),
        ),
      );

  @override
  Future<LinglongEnvironmentAnalysis> analyzeEnvironment() async {
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
      ostree: const LinglongOstreeCheckResult(
        isAvailable: true,
        isOk: false,
        detail: 'Corrupted file object found',
      ),
      issues: const [
        LinglongEnvironmentIssue(
          code: LinglongEnvironmentIssueCode.ostreeRepositoryCorrupted,
          severity: LinglongEnvironmentIssueSeverity.error,
          title: 'OSTree 仓库完整性异常',
          description: '检测到玲珑本地 OSTree 仓库可能存在损坏对象。',
          repairAction: LinglongEnvironmentRepairAction.ostreeFsckDelete,
          rawDetail: 'Corrupted file object found',
        ),
      ],
      runningAppCount: 0,
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(1),
    );
  }
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
