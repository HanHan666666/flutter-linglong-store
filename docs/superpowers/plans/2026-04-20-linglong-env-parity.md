# Linglong Environment Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align Flutter Linglong environment detection and auto-install behavior with Rust semantics while keeping Flutter-only skip support and adding regression coverage.

**Architecture:** Move environment detection and auto-install side effects out of `LinglongEnvProvider` into focused services. Add a general shell executor for non-`ll-cli` commands, restore install script sourcing through `/app/findShellString`, and update the launch/dialog flow to treat low-version results as warning-only instead of blocking failures.

**Tech Stack:** Flutter, Riverpod, Freezed, Retrofit/Dio, Flutter test, widget test, build_runner

---

> User explicitly waived the repository worktree rule for this task. Execute in the current workspace.

## File Map

- Create: `lib/application/services/linglong_environment_service.dart`
- Create: `lib/application/services/linglong_install_script_service.dart`
- Create: `lib/core/platform/shell_command_executor.dart`
- Modify: `lib/domain/models/linglong_env_check_result.dart`
- Modify: `lib/data/datasources/remote/app_api_service.dart`
- Modify: `lib/data/models/api_dto.dart`
- Modify: `lib/application/providers/linglong_env_provider.dart`
- Modify: `lib/application/providers/launch_provider.dart`
- Modify: `lib/presentation/pages/launch/launch_page.dart`
- Modify: `lib/presentation/widgets/linglong_env_dialog.dart`
- Modify: generated files affected by Freezed/Retrofit/Riverpod
- Test: `test/unit/application/services/linglong_environment_service_test.dart`
- Test: `test/unit/application/services/linglong_install_script_service_test.dart`
- Test: `test/unit/core/platform/shell_command_executor_test.dart`
- Test: `test/unit/application/providers/linglong_env_provider_test.dart`
- Test: `test/unit/application/providers/launch_provider_test.dart`
- Test: `test/widget/presentation/pages/launch_page_test.dart`

### Task 1: Add the Failing Service and Executor Tests

**Files:**
- Create: `test/unit/application/services/linglong_environment_service_test.dart`
- Create: `test/unit/application/services/linglong_install_script_service_test.dart`
- Create: `test/unit/core/platform/shell_command_executor_test.dart`
- Create: `test/unit/application/providers/linglong_env_provider_test.dart`
- Modify: `test/unit/application/providers/launch_provider_test.dart`
- Modify: `test/widget/presentation/pages/launch_page_test.dart`

- [ ] **Step 1: Write the failing environment-service tests**

```dart
test('returns failure when ll-cli help cannot run', () async {
  final service = LinglongEnvironmentService(
    processRunner: FakeProcessRunner.fromCommands({
      'll-cli --help': const ProcessRunResult(exitCode: 127, stderr: 'not found'),
    }),
  );

  final result = await service.checkEnvironment();

  expect(result.isOk, isFalse);
  expect(result.llCliVersion, isNull);
  expect(result.repoStatus, RepoStatus.unavailable);
});

test('returns warning-only success when ll-cli version is lower than 1.9.0', () async {
  final service = LinglongEnvironmentService(
    processRunner: FakeProcessRunner.fromCommands({
      'll-cli --help': const ProcessRunResult(exitCode: 0, stdout: 'usage'),
      'll-cli --json repo show': const ProcessRunResult(
        exitCode: 0,
        stdout: '{"defaultRepo":"stable","repos":[{"name":"stable","url":"https://repo"}]}',
      ),
      'll-cli --json --version': const ProcessRunResult(
        exitCode: 0,
        stdout: '{"version":"1.8.2"}',
      ),
    }),
  );

  final result = await service.checkEnvironment();

  expect(result.isOk, isTrue);
  expect(result.warningMessage, isNotNull);
  expect(result.repoStatus, RepoStatus.ok);
});

test('returns failure when repo list is empty', () async {
  final service = LinglongEnvironmentService(
    processRunner: FakeProcessRunner.fromCommands({
      'll-cli --help': const ProcessRunResult(exitCode: 0, stdout: 'usage'),
      'll-cli --json repo show': const ProcessRunResult(
        exitCode: 0,
        stdout: '{"defaultRepo":"stable","repos":[]}',
      ),
      'll-cli --json --version': const ProcessRunResult(
        exitCode: 0,
        stdout: '{"version":"1.9.1"}',
      ),
    }),
  );

  final result = await service.checkEnvironment();

  expect(result.isOk, isFalse);
  expect(result.repoStatus, RepoStatus.notConfigured);
});
```

- [ ] **Step 2: Write the failing install-script and shell-executor tests**

```dart
test('throws when backend returns an empty shell script', () async {
  final service = LinglongInstallScriptService(
    loadScript: () async => '',
  );

  expect(service.fetchInstallScript, throwsA(isA<StateError>()));
});

test('returns stderr first when shell command exits non-zero', () async {
  final runner = FakeShellCommandRunner.single(
    const ProcessRunResult(exitCode: 1, stdout: 'out', stderr: 'boom'),
  );
  final executor = ShellCommandExecutor(runner: runner);

  final result = await executor.run(['pkexec', 'bash', '/tmp/test.sh']);

  expect(result.exitCode, 1);
  expect(result.primaryMessage, 'boom');
});
```

- [ ] **Step 3: Write the failing provider and launch-flow tests**

```dart
test('performAutoInstall returns false when pkexec bash exits non-zero', () async {
  final container = ProviderContainer(
    overrides: [
      linglongEnvironmentServiceProvider.overrideWithValue(FakeEnvService.success()),
      linglongInstallScriptServiceProvider.overrideWithValue(
        FakeInstallScriptService(script: '#!/bin/bash\necho test'),
      ),
      shellCommandExecutorProvider.overrideWithValue(
        FakeShellCommandExecutor.failure(stderr: 'pkexec denied'),
      ),
    ],
  );

  final success = await container.read(linglongEnvProvider.notifier).performAutoInstall();

  expect(success, isFalse);
});

test('launch sequence does not stop on warning-only environment result', () async {
  final notifier = TestLaunchSequence(
    envResult: LinglongEnvCheckResult(
      isOk: true,
      warningMessage: 'version too low',
      llCliVersion: '1.8.2',
      repoStatus: RepoStatus.ok,
      checkedAt: 1,
    ),
  );

  await notifier.runSequence();

  expect(notifier.state.currentStep, isNot(LaunchStep.environmentCheck));
});

testWidgets('warning-only environment state does not show the env dialog', (tester) async {
  await tester.pumpWidget(buildLaunchPage(
    envState: warningEnvState,
    launchState: const LaunchState(),
  ));

  await tester.pump();

  expect(find.text('环境检测'), findsNothing);
});
```

- [ ] **Step 4: Run the new tests to verify they fail for the right reason**

Run:

```bash
flutter test test/unit/application/services/linglong_environment_service_test.dart
flutter test test/unit/application/services/linglong_install_script_service_test.dart
flutter test test/unit/core/platform/shell_command_executor_test.dart
flutter test test/unit/application/providers/linglong_env_provider_test.dart
flutter test test/unit/application/providers/launch_provider_test.dart
flutter test test/widget/presentation/pages/launch_page_test.dart
```

Expected:
- Service and provider tests fail because the new services/providers/fields do not exist yet.
- Launch tests fail because warning-only results still follow the blocking path.

- [ ] **Step 5: Commit the tests**

```bash
git add test/unit/application/services/linglong_environment_service_test.dart \
        test/unit/application/services/linglong_install_script_service_test.dart \
        test/unit/core/platform/shell_command_executor_test.dart \
        test/unit/application/providers/linglong_env_provider_test.dart \
        test/unit/application/providers/launch_provider_test.dart \
        test/widget/presentation/pages/launch_page_test.dart
git commit -m "test: 补充玲珑环境对齐回归用例"
```

### Task 2: Implement the Environment and Install Services

**Files:**
- Create: `lib/application/services/linglong_environment_service.dart`
- Create: `lib/application/services/linglong_install_script_service.dart`
- Create: `lib/core/platform/shell_command_executor.dart`
- Modify: `lib/domain/models/linglong_env_check_result.dart`
- Modify: `lib/data/datasources/remote/app_api_service.dart`
- Modify: `lib/data/models/api_dto.dart`

- [ ] **Step 1: Implement the new result fields and API DTO needed by the tests**

```dart
const factory LinglongEnvCheckResult({
  required bool isOk,
  String? warningMessage,
  String? errorMessage,
  String? errorDetail,
  String? arch,
  String? osVersion,
  String? glibcVersion,
  String? kernelInfo,
  String? detailMsg,
  String? llCliVersion,
  String? llBinVersion,
  String? repoName,
  @Default(<LinglongRepoInfo>[]) List<LinglongRepoInfo> repos,
  @Default(false) bool isContainer,
  @Default(RepoStatus.unknown) RepoStatus repoStatus,
  required int checkedAt,
}) = _LinglongEnvCheckResult;

@freezed
sealed class StringResponse with _$StringResponse {
  const factory StringResponse({
    required int code,
    String? message,
    String? data,
  }) = _StringResponse;
}
```

- [ ] **Step 2: Implement the failing shell-command executor minimally**

```dart
class ShellCommandExecutor {
  ShellCommandExecutor({ShellCommandRunner? runner}) : _runner = runner ?? const ProcessShellCommandRunner();

  final ShellCommandRunner _runner;

  Future<ShellCommandResult> run(
    List<String> command, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    return _runner.run(command, timeout: timeout);
  }
}
```

- [ ] **Step 3: Implement the environment service minimally to satisfy the red tests**

```dart
final help = await _runner.run(['ll-cli', '--help']);
if (help.exitCode != 0) {
  return LinglongEnvCheckResult(
    isOk: false,
    errorMessage: 'll-cli 未安装或不可用',
    repoStatus: RepoStatus.unavailable,
    checkedAt: _clock(),
  );
}

final repoResult = await _loadRepoInfo();
if (repoResult.repos.isEmpty) {
  return LinglongEnvCheckResult(
    isOk: false,
    errorMessage: '未检测到玲珑仓库配置，请检查环境',
    repoStatus: RepoStatus.notConfigured,
    checkedAt: _clock(),
  );
}

final version = await _loadVersion();
if (VersionCompare.lessThan(version, _minimumVersion)) {
  return LinglongEnvCheckResult(
    isOk: true,
    warningMessage: '当前玲珑基础环境版本($version)过低，建议升级至 >= $_minimumVersion',
    llCliVersion: version,
    repoStatus: RepoStatus.ok,
    repos: repoResult.repos,
    checkedAt: _clock(),
  );
}
```

- [ ] **Step 4: Implement the backend install-script loader**

```dart
class LinglongInstallScriptService {
  LinglongInstallScriptService({required Future<String> Function() loadScript})
      : _loadScript = loadScript;

  final Future<String> Function() _loadScript;

  Future<String> fetchInstallScript() async {
    final script = (await _loadScript()).trim();
    if (script.isEmpty) {
      throw StateError('获取安装脚本失败，请稍后重试');
    }
    return script;
  }
}
```

- [ ] **Step 5: Run the service and executor tests to verify they pass**

Run:

```bash
flutter test test/unit/application/services/linglong_environment_service_test.dart
flutter test test/unit/application/services/linglong_install_script_service_test.dart
flutter test test/unit/core/platform/shell_command_executor_test.dart
```

Expected:
- All three test files pass.

- [ ] **Step 6: Commit the services**

```bash
git add lib/application/services/linglong_environment_service.dart \
        lib/application/services/linglong_install_script_service.dart \
        lib/core/platform/shell_command_executor.dart \
        lib/domain/models/linglong_env_check_result.dart \
        lib/data/datasources/remote/app_api_service.dart \
        lib/data/models/api_dto.dart \
        test/unit/application/services/linglong_environment_service_test.dart \
        test/unit/application/services/linglong_install_script_service_test.dart \
        test/unit/core/platform/shell_command_executor_test.dart
git commit -m "feat: 对齐玲珑环境检测与脚本获取服务"
```

### Task 3: Rewire Provider, Launch Flow, and Dialog

**Files:**
- Modify: `lib/application/providers/linglong_env_provider.dart`
- Modify: `lib/application/providers/launch_provider.dart`
- Modify: `lib/presentation/pages/launch/launch_page.dart`
- Modify: `lib/presentation/widgets/linglong_env_dialog.dart`
- Modify: generated files affected by Riverpod/Freezed
- Test: `test/unit/application/providers/linglong_env_provider_test.dart`
- Test: `test/unit/application/providers/launch_provider_test.dart`
- Test: `test/widget/presentation/pages/launch_page_test.dart`

- [ ] **Step 1: Inject the new services into the provider and remove the old direct process logic**

```dart
final environmentService = ref.read(linglongEnvironmentServiceProvider);
final result = await environmentService.checkEnvironment();

state = state.copyWith(
  checkState: LinglongEnvCheckState.success,
  result: result,
);
```

- [ ] **Step 2: Reimplement auto-install to use backend script + pkexec bash**

```dart
final script = await ref.read(linglongInstallScriptServiceProvider).fetchInstallScript();
final tempFile = await _writeInstallScript(script);
final output = await ref.read(shellCommandExecutorProvider).run([
  'pkexec',
  'bash',
  tempFile.path,
]);

if (output.exitCode != 0) {
  state = state.copyWith(
    isInstalling: false,
    installMessage: output.primaryMessage,
  );
  return false;
}
```

- [ ] **Step 3: Update launch blocking behavior to allow warning-only success**

```dart
if (!envResult.isOk) {
  state = state.copyWith(
    hasError: true,
    errorMessage: envResult.errorMessage,
  );
  return false;
}

if (envResult.warningMessage != null) {
  AppLogger.warning('Linglong environment warning: ${envResult.warningMessage}');
}
```

- [ ] **Step 4: Update the dialog and page behavior**

```dart
final canSkip = result?.canSkip ?? false;

if (envState.result?.isOk ?? false) {
  Navigator.of(context).pop();
}

if ((next.result?.isOk ?? false) || next.shouldShowDialog) {
  // warning-only success must not enter this branch
}
```

- [ ] **Step 5: Regenerate code after model/provider/API signature changes**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `*.g.dart` and `*.freezed.dart` update with no stale signatures left behind.

- [ ] **Step 6: Run provider and widget tests to verify they pass**

Run:

```bash
flutter test test/unit/application/providers/linglong_env_provider_test.dart
flutter test test/unit/application/providers/launch_provider_test.dart
flutter test test/widget/presentation/pages/launch_page_test.dart
```

Expected:
- Warning-only env results no longer block launch.
- Failed env results still trigger the dialog.
- Auto-install failure surfaces real stderr.

- [ ] **Step 7: Commit the flow rewiring**

```bash
git add lib/application/providers/linglong_env_provider.dart \
        lib/application/providers/launch_provider.dart \
        lib/presentation/pages/launch/launch_page.dart \
        lib/presentation/widgets/linglong_env_dialog.dart \
        lib/application/providers/linglong_env_provider.g.dart \
        lib/application/providers/launch_provider.g.dart \
        lib/domain/models/linglong_env_check_result.freezed.dart \
        lib/domain/models/linglong_env_check_result.g.dart \
        lib/data/datasources/remote/app_api_service.g.dart \
        test/unit/application/providers/linglong_env_provider_test.dart \
        test/unit/application/providers/launch_provider_test.dart \
        test/widget/presentation/pages/launch_page_test.dart
git commit -m "feat: 对齐启动链路的玲珑环境门禁语义"
```

### Task 4: Run the Full Verification Sweep and Sync Docs

**Files:**
- Modify: `AGENTS.md`
- Modify: any docs updated during implementation if needed

- [ ] **Step 1: Record the new maintenance rule in `AGENTS.md`**

```md
- 2026-04-20：玲珑环境检测必须与 Rust 语义对齐：`ll-cli` 缺失或 repo 缺失时阻断启动，`ll-cli < 1.9.0` 仅 warning 不阻断；自动安装脚本统一来自 `/app/findShellString`，执行链路必须是真正的 `pkexec bash <temp-script>`；Flutter 可保留 `skip`，但仅限非致命失败场景。
```

- [ ] **Step 2: Run targeted analysis and tests**

Run:

```bash
flutter analyze lib/application/services/linglong_environment_service.dart \
                lib/application/services/linglong_install_script_service.dart \
                lib/core/platform/shell_command_executor.dart \
                lib/application/providers/linglong_env_provider.dart \
                lib/application/providers/launch_provider.dart \
                lib/presentation/pages/launch/launch_page.dart \
                lib/presentation/widgets/linglong_env_dialog.dart \
                test/unit/application/services/linglong_environment_service_test.dart \
                test/unit/application/services/linglong_install_script_service_test.dart \
                test/unit/core/platform/shell_command_executor_test.dart \
                test/unit/application/providers/linglong_env_provider_test.dart \
                test/unit/application/providers/launch_provider_test.dart \
                test/widget/presentation/pages/launch_page_test.dart

flutter test test/unit/application/services/linglong_environment_service_test.dart \
             test/unit/application/services/linglong_install_script_service_test.dart \
             test/unit/core/platform/shell_command_executor_test.dart \
             test/unit/application/providers/linglong_env_provider_test.dart \
             test/unit/application/providers/launch_provider_test.dart \
             test/widget/presentation/pages/launch_page_test.dart
```

Expected:
- `flutter analyze` returns 0 issues for the touched files.
- All targeted tests pass.

- [ ] **Step 3: Commit the documentation sync**

```bash
git add AGENTS.md
git commit -m "docs: 同步玲珑环境对齐约束"
```
