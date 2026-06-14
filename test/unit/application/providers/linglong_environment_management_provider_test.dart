import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linglong_store/application/providers/linglong_environment_management_provider.dart';
import 'package:linglong_store/application/services/linglong_environment_management_service.dart';
import 'package:linglong_store/application/services/linglong_environment_service.dart';
import 'package:linglong_store/core/platform/shell_command_executor.dart';
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
  _FakeRepositoryManagementRepository repository,
) {
  return ProviderContainer(
    overrides: [
      linglongEnvironmentManagementServiceProvider.overrideWithValue(service),
      linglongRepositoryManagementRepositoryProvider.overrideWithValue(
        repository,
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
