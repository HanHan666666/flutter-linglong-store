import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/linglong_environment_management_provider.dart';
import 'package:linglong_store/application/services/linglong_environment_management_service.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_queue_state.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/linglong_env_check_result.dart';
import 'package:linglong_store/domain/models/linglong_environment_management.dart';
import 'package:linglong_store/domain/models/linglong_repository_config.dart';
import 'package:linglong_store/domain/repositories/linglong_repository_management_repository.dart';

void main() {
  group('LinglongEnvironmentManagement provider', () {
    test('load reads analysis and repository config', () async {
      final service = _FakeManagementService();
      final repository = _FakeRepositoryManagementRepository();
      final container = _createContainer(service, repository);
      addTearDown(container.dispose);

      await container
          .read(linglongEnvironmentManagementProvider.notifier)
          .load();

      final state = container.read(linglongEnvironmentManagementProvider);
      expect(state.status, LinglongEnvironmentManagementStatus.ready);
      expect(state.analysis?.runningAppCount, 0);
      expect(state.repositoryConfig?.defaultRepo, 'stable');
      expect(service.analyzeCallCount, 1);
      expect(repository.getCallCount, 1);
    });

    test(
      'repairOstreeRepository stores result and refreshes analysis',
      () async {
        final service = _FakeManagementService();
        final repository = _FakeRepositoryManagementRepository();
        final container = _createContainer(service, repository);
        addTearDown(container.dispose);

        final result = await container
            .read(linglongEnvironmentManagementProvider.notifier)
            .repairOstreeRepository();

        final state = container.read(linglongEnvironmentManagementProvider);
        expect(result.success, isTrue);
        expect(state.status, LinglongEnvironmentManagementStatus.ready);
        expect(
          state.repairResult?.action,
          LinglongEnvironmentRepairAction.ostreeFsckDelete,
        );
        expect(service.repairOstreeCallCount, 1);
        expect(service.analyzeCallCount, 1);
      },
    );

    test(
      'repairLinglongDataPermissions stores result and refreshes analysis',
      () async {
        final service = _FakeManagementService();
        final repository = _FakeRepositoryManagementRepository();
        final container = _createContainer(service, repository);
        addTearDown(container.dispose);

        final result = await container
            .read(linglongEnvironmentManagementProvider.notifier)
            .repairLinglongDataPermissions();

        final state = container.read(linglongEnvironmentManagementProvider);
        expect(result.success, isTrue);
        expect(state.status, LinglongEnvironmentManagementStatus.ready);
        expect(
          state.repairResult?.action,
          LinglongEnvironmentRepairAction.fixDataPermissions,
        );
        expect(service.repairDataPermissionCallCount, 1);
        expect(service.analyzeCallCount, 1);
      },
    );

    test(
      'moveLinglongStorage is blocked when install queue has active tasks',
      () async {
        final service = _FakeManagementService();
        final repository = _FakeRepositoryManagementRepository();
        final container = _createContainer(
          service,
          repository,
          installQueueState: InstallQueueState(
            currentTask: _installTask(
              id: 'task-1',
              appId: 'org.example.demo',
              appName: 'Demo',
              status: InstallStatus.installing,
            ),
            isProcessing: true,
          ),
        );
        addTearDown(container.dispose);

        final result = await container
            .read(linglongEnvironmentManagementProvider.notifier)
            .moveLinglongStorage('/data/linglong');

        final state = container.read(linglongEnvironmentManagementProvider);
        expect(result.success, isFalse);
        expect(result.message, contains('Demo'));
        expect(state.status, LinglongEnvironmentManagementStatus.failed);
        expect(state.repairResult?.success, isFalse);
        expect(service.moveStorageCallCount, 0);
      },
    );

    test(
      'addRepository delegates to repository and refreshes config',
      () async {
        final service = _FakeManagementService();
        final repository = _FakeRepositoryManagementRepository();
        final container = _createContainer(service, repository);
        addTearDown(container.dispose);

        await container
            .read(linglongEnvironmentManagementProvider.notifier)
            .addRepository(
              name: 'test',
              url: 'https://repo.example.com',
              alias: 'test-alias',
            );

        final state = container.read(linglongEnvironmentManagementProvider);
        expect(state.status, LinglongEnvironmentManagementStatus.ready);
        expect(repository.addCalls.single, {
          'name': 'test',
          'url': 'https://repo.example.com',
          'alias': 'test-alias',
        });
        expect(repository.getCallCount, 1);
        expect(state.repositoryConfig?.repos.single.name, 'stable');
      },
    );
  });
}

ProviderContainer _createContainer(
  _FakeManagementService service,
  _FakeRepositoryManagementRepository repository, {
  InstallQueueState installQueueState = const InstallQueueState(),
}) {
  return ProviderContainer(
    overrides: [
      linglongEnvironmentManagementServiceProvider.overrideWithValue(service),
      linglongRepositoryManagementRepositoryProvider.overrideWithValue(
        repository,
      ),
      installQueueProvider.overrideWith(
        () => _TestInstallQueue(initialState: installQueueState),
      ),
    ],
  );
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

  int analyzeCallCount = 0;
  int repairOstreeCallCount = 0;
  int repairDataPermissionCallCount = 0;
  int moveStorageCallCount = 0;

  @override
  Future<LinglongEnvironmentAnalysis> analyzeEnvironment() async {
    analyzeCallCount += 1;
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
        isOk: true,
      ),
      ostree: const LinglongOstreeCheckResult(isAvailable: true, isOk: true),
      issues: const [],
      runningAppCount: 0,
      analyzedAt: DateTime.fromMillisecondsSinceEpoch(1),
    );
  }

  @override
  Future<LinglongEnvironmentRepairResult> repairOstreeRepository({
    String? logFilePath,
  }) async {
    repairOstreeCallCount += 1;
    return const LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.ostreeFsckDelete,
      success: true,
      message: 'ok',
      logFilePath: '/tmp/repair.log',
    );
  }

  @override
  Future<LinglongEnvironmentRepairResult> repairLinglongDataPermissions({
    String? logFilePath,
  }) async {
    repairDataPermissionCallCount += 1;
    return const LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.fixDataPermissions,
      success: true,
      message: 'fixed',
      logFilePath: '/tmp/permission.log',
    );
  }

  @override
  Future<LinglongEnvironmentRepairResult> moveLinglongStorage(
    String targetPath, {
    String? logFilePath,
  }) async {
    moveStorageCallCount += 1;
    return const LinglongEnvironmentRepairResult(
      action: LinglongEnvironmentRepairAction.moveStorageRoot,
      success: true,
      message: 'moved',
      logFilePath: '/tmp/move.log',
    );
  }
}

class _FakeRepositoryManagementRepository
    implements LinglongRepositoryManagementRepository {
  int getCallCount = 0;
  final addCalls = <Map<String, String?>>[];

  @override
  Future<LinglongRepositoryConfig> getRepositoryConfig() async {
    getCallCount += 1;
    return const LinglongRepositoryConfig(
      defaultRepo: 'stable',
      repos: [
        LinglongRepoInfo(
          name: 'stable',
          url: 'https://repo.example.com',
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
  }) async {
    addCalls.add({'name': name, 'url': url, 'alias': alias});
    return 'ok';
  }

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

InstallTask _installTask({
  required String id,
  required String appId,
  required String appName,
  required InstallStatus status,
}) {
  return InstallTask(
    id: id,
    appId: appId,
    appName: appName,
    status: status,
    createdAt: 1,
  );
}

class _TestInstallQueue extends InstallQueue {
  _TestInstallQueue({required InstallQueueState initialState})
    : _initialState = initialState;

  final InstallQueueState _initialState;

  @override
  InstallQueueState build() => _initialState;

  @override
  Future<void> startProcessing() async {}
}
