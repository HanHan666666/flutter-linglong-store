# 错误诊断 + 引导式修复模块 设计方案

> 文档版本：1.0
> 更新日期：2026-07-25
> 适用范围：下载中心安装失败错误的「诊断 → 推荐解决方案 → 一键修复（带脚本审计）」能力，作为独立的、数据驱动的、与业务解耦的通用模块。

## 一、需求与定位

下载中心安装失败时，错误红字（`download_manager_dialog.dart:628` 的 `_buildErrorText`）旁加一个 **⚠️ 帮助按钮**，点击弹窗显示「推荐解决方案 + 社区来源链接」；若可自动修复则提供 **「一键修复」**——执行前先让用户**审计即将执行的 Shell 脚本全文**，确认后 `pkexec` 执行、记日志、反馈结果。

定位为**通用诊断框架**（数据驱动），`RequestInteraction`（OBS 换源）作为第一条规则；以后新增错误只需加规则，不动业务代码。

### 设计目标

- **解耦**：模块自成一体，业务侧只有最小侵入点。
- **数据驱动**：加新错误 = 在规则注册表加一条规则，零业务代码改动。
- **可维护**：复用项目已有的执行器、日志、展示组件，不重复造轮子。
- **安全**：所有特权操作必须经用户审计确认，不静默执行。
- **i18n 全覆盖**：所有 UI 文案走 l10n（比参照的 docs/21 模块做得更好）。

## 二、关键事实（已调研确认）

| 项 | 结论 |
|---|---|
| 红框真身 | `_buildErrorText`（`download_manager_dialog.dart:628`），`Padding>Text` 红字（非真红框，靠文字颜色 `AppColors.error` 实现），两张卡片（当前任务+历史记录）都走它 |
| 错误数据来源 | `InstallTask.errorMessage/errorCode/errorDetail`（`install_task.dart`），Data 层把 ll-cli JSON 的 `code/message` 原样透传 |
| 最佳模板 | `LinglongEnvironmentManagementService` —— 已把"脚本生成(纯函数) → 写临时文件 → `pkexec bash` 执行+日志 → 截断输出 → finally 清理"跑通 3 遍 |
| 可复用执行器 | `ShellCommandExecutor`（注入式，带流式日志、超时、可测）+ `shellCommandExecutorProvider` |
| 可复用展示组件 | `CopyableCommandBlock`（等宽+复制）、`SelectableText`、`ConfirmDialog`、`showAppSuccess/Error`、`LocalPathOpener` |
| 日志/XDG | `AppXdgPaths.resolveLogsDirectoryPath()`，application-id = `com.dongpl.linglong-store.v2` |
| **缺口** | 项目目前**没有任何"展示脚本全文供审计"的 UI**，需新建（`ScriptReviewDialog`） |
| i18n | `lib/core/i18n/l10n/app_zh.arb`（中文模板先行）+ `app_en.arb`，`flutter gen-l10n` |
| 代码生成 | Freezed + Riverpod，`dart run build_runner build --delete-conflicting-outputs` |
| 测试 SDK | `/home/hao/Flutter/flutter-stable/bin/flutter test`（非默认 PATH） |
| 分层依赖方向 | Presentation → Application → Domain ← Data ← Platform |

### 错误数据流（ll-cli JSON → UI）

```
ll-cli install --json  (stdout 流出 JSON line)
  {"code":-1,"message":"Failed to connect signal: RequestInteraction"}
    ↓ Data: linglong_cli_repository_impl.dart  (_buildFailureMessage 行 109-126, InstallProgress 行 229-248)
  InstallProgress { error, errorCode, errorDetail, status: failed }
    ↓ Application: install_queue_provider.dart  (_handleProgress 行 521-577, _markFailed 行 678-740)
  InstallTask { errorMessage, errorCode, errorDetail }
    ↓ Presentation: download_manager_dialog.dart  (_buildErrorText 行 628)
  红字 Text
```

`RequestInteraction` 字符串在项目代码中**没有字面量命中**，它是 ll-cli 运行时输出，以 JSON `message` 字段流出。`code=-1` 在 `install_messages.dart` 的 `getErrorMessageFromCode` 映射为 `installErrorGeneric`。

## 三、模块结构（照抄 docs/21 分层契约，独立目录解耦）

```
docs/24-error-diagnostics-and-guided-repair.md               ← 本文档

lib/domain/models/
  error_diagnosis.dart                                        ← 纯模型：Signature/Solution/Rule/Result/RepairResult

lib/core/error_diagnostics/                                   ← 模块独立目录（解耦核心）
  diagnosis_rule.dart                                         ← DiagnosisRule 抽象
  diagnosis_rule_registry.dart                                ← 规则注册表（数据驱动核心）
  rules/
    request_interaction_rule.dart                             ← 第一条规则：RequestInteraction → OBS 换源

lib/core/platform/
  shell_script_runner.dart                                    ← 【小重构】从环境管理 Service 提取脚本执行三件套(public)，新老共用

lib/application/services/
  error_diagnostics_service.dart                              ← diagnose() + buildScript() + runRepair()，注入 ShellCommandExecutor

lib/application/providers/
  error_diagnostics_provider.dart                             ← @riverpod Notifier，UI 唯一状态入口

lib/presentation/widgets/
  error_help_button.dart                                      ← ⚠️ 按钮（插到红字旁）
  solution_dialog.dart                                        ← 解决方案弹窗（描述 + 社区链接 + 一键修复入口）
  script_review_dialog.dart                                   ← 【新能力】脚本审计弹窗（填补项目缺口）

lib/core/i18n/l10n/app_zh.arb / app_en.arb                    ← 文案 key（i18n 全覆盖）

下载中心改动（唯一业务侵入点，最小）：
  lib/presentation/widgets/download_manager_dialog.dart:628   ← _buildErrorText 外层 Padding → Row([Expanded(Text), ErrorHelpButton(task)])
```

## 四、核心数据模型（`domain/models/error_diagnosis.dart`，Freezed）

```dart
/// 错误特征：用来判断一个 InstallTask 是否命中规则
@freezed
class ErrorSignature with _$ErrorSignature {
  const factory ErrorSignature({
    int? errorCode,                  // 如 -1
    String? messageContains,         // 子串匹配
    String? errorDetailContains,     // 如 'RequestInteraction'
  }) = _ErrorSignature;

  /// 各条件为 AND：设置了几个就都得满足
  bool matches(InstallTask task) {
    if (errorCode != null && task.errorCode != errorCode) return false;
    if (messageContains != null &&
        !(task.errorMessage?.toLowerCase().contains(messageContains!.toLowerCase()) ?? false)) {
      return false;
    }
    if (errorDetailContains != null &&
        !(task.errorDetail?.toLowerCase().contains(errorDetailContains!.toLowerCase()) ?? false)) {
      return false;
    }
    return true;
  }
}

/// 修复方式：script=可一键修复，manualOnly=只展示方案
enum RepairKind { script, manualOnly }

@freezed
class DiagnosisSolution with _$DiagnosisSolution {
  const factory DiagnosisSolution({
    required String title,
    required String description,      // 多行纯文本/markdown，描述怎么修
    String? referenceUrl,             // 社区链接（如 bbs.deepin.org.cn/post/289061）
    @Default(RepairKind.manualOnly) RepairKind kind,
    String? scriptKey,                // 指向 registry 的脚本生成器（kind==script 时）
  }) = _DiagnosisSolution;
}

/// 诊断规则（数据驱动，加新错误就加一条）
@freezed
class DiagnosisRule with _$DiagnosisRule {
  const factory DiagnosisRule({
    required String id,               // 'request-interaction-obs-source'
    required ErrorSignature signature,
    required DiagnosisSolution solution,
    @Default(0) int priority,         // 数字大的优先（多规则同时命中时）
  }) = _DiagnosisRule;
}

/// 一次匹配的输出
@freezed
class DiagnosisResult with _$DiagnosisResult {
  const DiagnosisResult._();
  const factory DiagnosisResult({
    required String ruleId,
    required DiagnosisSolution solution,
  }) = _DiagnosisResult;

  bool get isRepairable => solution.kind == RepairKind.script;
}

/// 修复执行结果（参照 LinglongEnvironmentRepairResult）
@freezed
class GuidedRepairResult with _$GuidedRepairResult {
  const factory GuidedRepairResult({
    required bool success,
    required String message,
    String? logFilePath,              // XDG logs 目录
    String? output,                   // 截断 ≤4000
  }) = _GuidedRepairResult;
}
```

## 五、规则注册表（`core/error_diagnostics/diagnosis_rule_registry.dart`）—— 解耦核心

```dart
/// 诊断规则注册表：数据驱动，加新错误就加一条规则。
/// 不依赖任何业务 Provider，只依赖 InstallTask 纯模型。
class DiagnosisRuleRegistry {
  DiagnosisRuleRegistry()
      : _rules = [
          RequestInteractionRule.rule,
          // ← 以后加新错误在这里加一行
        ];

  final List<DiagnosisRule> _rules;
  final Map<String, String Function()> _scriptBuilders = {
    RequestInteractionRule.scriptKey: RequestInteractionRule.buildUbuntu2404Script,
    // ← 可一键修复的规则，把脚本生成器注册进来
  };

  /// 遍历规则（按 priority 降序），返回首个命中的结果；都不命中返回 null
  DiagnosisResult? diagnose(InstallTask task) {
    final sorted = [..._rules]..sort((a, b) => b.priority.compareTo(a.priority));
    for (final rule in sorted) {
      if (rule.signature.matches(task)) {
        return DiagnosisResult(ruleId: rule.id, solution: rule.solution);
      }
    }
    return null;
  }

  /// 取脚本全文供审计（纯函数，无副作用）
  String buildScript(String key) {
    final builder = _scriptBuilders[key];
    if (builder == null) {
      throw StateError('未注册的脚本 key: $key');
    }
    return builder();
  }
}
```

### 第一条规则（`rules/request_interaction_rule.dart`）

- `signature`: `errorCode == -1 && errorDetailContains == 'RequestInteraction'`
- `solution.title`: 「玲珑运行时不匹配，需换装社区 OBS 源版本」
- `solution.description`: 引用 `docs/cross-distro-linglong-install-from-obs-source.md` 浓缩的根因 + 解决步骤
- `solution.referenceUrl`: `https://bbs.deepin.org.cn/zh/post/289061`
- `solution.kind`: `RepairKind.script`
- `solution.scriptKey`: `'obs-source-ubuntu-2404'`

对应脚本生成器产出 Ubuntu 24.04 的 OBS 换源脚本：加源 → 导入 GPG key → `apt install linglong-bin linglong-box`。

**脚本内部首行自检发行版**（`/etc/os-release`），不匹配则友好退出——尊重"程序不做发行版守卫、发行版适配由脚本自己处理"的决策。这是脚本设计最佳实践，写进文档约定。

## 六、共享 helper 小重构（`core/platform/shell_script_runner.dart`）

把 `LinglongEnvironmentManagementService` 的 5 个私有方法提成 public 共享类，新老模块共用，避免复制：

| 方法 | 来源（环境管理 Service 行号） | 作用 |
|---|---|---|
| `writeTemporaryScript(String, {prefix})` → `Future<File>` | 904-916 | 写 `Directory.systemTemp/<prefix>-<ts>.sh` |
| `deleteFileIfExists(File)` → `Future<void>` | 918-926 | finally 清理 |
| `createLogFilePath(String prefix)` → `Future<String>` | 1132-1148 | 走 `AppXdgPaths`，`<prefix>-yyyyMMdd-HHmmss.log` |
| `truncateOutput(String, {maxLength=4000})` → `String` | 1177 | 超长追加截断提示 |
| `shellSingleQuote(String)` → `String` | 1184 | 防注入单引号转义 |

环境管理 Service 改为依赖这个 helper（行为不变，仅提取），其现有测试照常通过。

## 七、Service（`application/services/error_diagnostics_service.dart`）

注入 `ShellCommandExecutor` + `DiagnosisRuleRegistry` + `ShellScriptRunner` + `Clock`。

```dart
class ErrorDiagnosticsService {
  ErrorDiagnosticsService({
    required ShellCommandExecutor executor,
    required DiagnosisRuleRegistry registry,
    required ShellScriptRunner scriptRunner,
    required DateTime Function() clock,
  });

  /// 诊断一个失败任务，返回匹配的解决方案；都不命中返回 null
  DiagnosisResult? diagnose(InstallTask task) => _registry.diagnose(task);

  /// 取脚本全文（纯委托，供 UI 审计）
  String buildRepairScript(String scriptKey) => _registry.buildScript(scriptKey);

  /// 执行一键修复
  /// 复用环境管理模块的脚本执行范式：生成 → 写临时文件 → pkexec bash 执行+日志 → 截断 → finally 清理
  Future<GuidedRepairResult> runRepair(String scriptKey, {String? logFilePath}) async {
    final script = _registry.buildScript(scriptKey);
    final resolvedLogFilePath = logFilePath ?? await _scriptRunner.createLogFilePath('error-repair');
    File? scriptFile;
    try {
      scriptFile = await _scriptRunner.writeTemporaryScript(script, prefix: 'error-repair');
      final result = await _executor.run(
        ['pkexec', 'bash', scriptFile.path],
        timeout: const Duration(minutes: 10),
        environment: _englishLocaleEnv,  // 固定 LC_ALL=C.UTF-8，避免中文 locale 干扰
        logOptions: ShellCommandLogOptions(filePath: resolvedLogFilePath, overwrite: true),
      );
      return GuidedRepairResult(
        success: result.success,
        message: result.success ? '修复完成' : result.primaryMessage,
        logFilePath: resolvedLogFilePath,
        output: _scriptRunner.truncateOutput('${result.stdout}\n${result.stderr}'),
      );
    } catch (e) {
      return GuidedRepairResult(success: false, message: '修复执行失败：$e', logFilePath: resolvedLogFilePath);
    } finally {
      if (scriptFile != null) await _scriptRunner.deleteFileIfExists(scriptFile);
    }
  }

  static const _englishLocaleEnv = {'LC_ALL': 'C.UTF-8', 'LANG': 'C.UTF-8'};
}
```

Provider 注入（`application/providers/error_diagnostics_provider.dart`）：

```dart
final errorDiagnosticsServiceProvider = Provider<ErrorDiagnosticsService>((ref) {
  return ErrorDiagnosticsService(
    executor: ref.watch(shellCommandExecutorProvider),
    registry: DiagnosisRuleRegistry(),
    scriptRunner: ShellScriptRunner(),
    clock: DateTime.now,
  );
});
```

## 八、Provider 状态编排（`application/providers/error_diagnostics_provider.dart`，@riverpod）

```dart
enum ErrorDiagnosticsStatus {
  idle, diagnosing, diagnosed, noMatch,
  scriptPrepared, repairing, repaired, failed,
}

@freezed
class ErrorDiagnosticsState with _$ErrorDiagnosticsState {
  const factory ErrorDiagnosticsState({
    @Default(ErrorDiagnosticsStatus.idle) ErrorDiagnosticsStatus status,
    DiagnosisResult? result,        // 命中的解决方案
    String? pendingScript,          // 待审计的脚本全文
    GuidedRepairResult? repairResult,
    String? errorMessage,
  }) = _ErrorDiagnosticsState;
}

@riverpod
class ErrorDiagnostics extends _$ErrorDiagnostics {
  ErrorDiagnosticsService get _service => ref.read(errorDiagnosticsServiceProvider);

  @override
  ErrorDiagnosticsState build() => const ErrorDiagnosticsState();

  Future<void> diagnose(InstallTask task) async { /* ... */ }

  /// 取 result.solution.scriptKey → service.buildRepairScript → state.pendingScript
  Future<void> prepareScript() async { /* ... */ }

  /// service.runRepair → state.repairResult；修复后可触发下载中心相关刷新
  Future<void> confirmAndRun() async { /* ... */ }
}
```

## 九、UI 组件与交互流程

### 9.1 插入点（唯一业务改动）

`download_manager_dialog.dart:628` 的 `_buildErrorText`：

```dart
// 改造前：
Widget _buildErrorText(BuildContext context) {
  if (!widget.task.isFailed || widget.task.errorMessage == null) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text(widget.task.errorMessage!, style: ....copyWith(color: AppColors.error), softWrap: true),
  );
}

// 改造后：
Widget _buildErrorText(BuildContext context) {
  if (!widget.task.isFailed || widget.task.errorMessage == null) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(widget.task.errorMessage!, style: ....copyWith(color: AppColors.error), softWrap: true),
        ),
        ErrorHelpButton(task: widget.task),   // ← 新增；按钮内部先 diagnose，命中才显示
      ],
    ),
  );
}
```

### 9.2 ErrorHelpButton（`presentation/widgets/error_help_button.dart`）

`ConsumerWidget`，`IconButton(icon: Icons.help_outline, iconSize: 18, visualDensity: compact)`，复用现有 `_buildIconActionButton`（行 887-903）的样式语言。

行为：

1. `build` 时 `ref.read(provider.notifier).diagnose(task)`（或在点击时惰性触发）
2. 命中 → `showDialog(SolutionDialog(result: result))`
3. 未命中 → 不显示按钮（构建期判断，避免空点击）

### 9.3 SolutionDialog（`presentation/widgets/solution_dialog.dart`）

布局：

- `title`: `solution.title`
- `content`: `Column` → `SelectableText(solution.description)` 多行 + `InkWell`（`solution.referenceUrl`，点击调系统浏览器）
- `actions`:
  - `TextButton(关闭)`
  - `FilledButton(一键修复)` —— **仅 `result.isRepairable` 时显示**，点击 → `ref.read(provider.notifier).prepareScript()` → `showDialog(ScriptReviewDialog(script: state.pendingScript))`

### 9.4 ScriptReviewDialog（`presentation/widgets/script_review_dialog.dart`，新能力）

**填补项目缺口**：项目目前没有任何"展示脚本全文供审计"的 UI。

```dart
class ScriptReviewDialog extends ConsumerWidget {
  const ScriptReviewDialog({required this.script, required this.ruleId, super.key});
  final String script;
  final String ruleId;

  static Future<bool> show(BuildContext context, {required String script, required String ruleId}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ScriptReviewDialog(script: script, ruleId: ruleId),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(l10n.errorDiagnosticsScriptReviewTitle),
      content: SizedBox(
        width: 600, height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.errorDiagnosticsScriptReviewRiskWarning),   // 风险说明
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: CopyableCommandBlock(command: script, semanticLabel: l10n.errorDiagnosticsScriptA11y),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(
          style: ConfirmButtonStyle.warning,  // 复用现有按钮样式
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.errorDiagnosticsConfirmRun),
        ),
      ],
    );
  }
}
```

### 9.5 完整交互流程

```
红字旁 ⚠️ 按钮
   → diagnose(task)
       → 命中 → SolutionDialog(方案描述 + 社区链接)
                  → 点「一键修复」
                      → prepareScript() → state.pendingScript
                          → ScriptReviewDialog(脚本全文 + 风险说明)
                              → 点「确认执行」
                                  → confirmAndRun() → pkexec bash 执行 + 记日志
                                      → 结果：成功/失败 + 截断输出 + 「打开日志目录」按钮
       → 不命中 → 不显示按钮（或在按钮上提示"暂无推荐方案"）
```

修复结果展示：复用 `showAppSuccess` / `showAppError`（`core/utils/app_notification_helpers.dart`）+ 「打开日志目录」按钮（`LocalPathOpener.openDirectory(path.dirname(logFilePath))`）。

## 十、解耦体现（满足"可维护性好"的要求）

1. **数据驱动**：加新错误 = 在 registry 加一条 `DiagnosisRule` + scriptBuilder，零业务代码改动。
2. **模块自治**：`lib/core/error_diagnostics/` 自成一体，不依赖下载中心/安装队列的业务逻辑（只依赖 `InstallTask` 这个纯模型）。
3. **单一侵入点**：业务侧只改 `_buildErrorText` 一行结构，加一个按钮。
4. **复用不重复造轮子**：`ShellCommandExecutor` / `AppXdgPaths` / `CopyableCommandBlock` / `LocalPathOpener` 全复用；提取共享 helper 让新老模块共用脚本执行范式。
5. **i18n 全覆盖**：所有 UI 文案走 l10n（比参照的 docs/21 模块做得更好，符合 CLAUDE.md 无障碍要求）。

## 十一、参考依据

1. 远程 Deepin 25 主机项目实读：`download_manager_dialog.dart:628`（红字）、`install_queue_provider.dart:521-740`（错误数据流）、`linglong_environment_management_service.dart:161-191/329-491/904-926/1132-1148/1177-1184`（脚本执行范式）、`shell_command_executor.dart`（执行器）、`copyable_command_block.dart`（脚本展示）、`app_xdg_paths.dart:169`（日志目录）、`install_messages.dart:38-78`（错误码映射）。
2. `docs/21-linglong-environment-management.md`：模块分层契约与脚本执行范式参照。
3. `docs/cross-distro-linglong-install-from-obs-source.md`：`RequestInteraction` 错误的根因与 OBS 换源解决方案。
4. 社区来源：[玲珑商店无法下载](https://bbs.deepin.org.cn/post/300089) / [玲珑 1.12.2 各发行版更新](https://bbs.deepin.org.cn/zh/post/289061)。

## 十二、实现边界（不做什么）

- 不动 `install_queue_provider` 状态机、不改 `InstallTask` 模型（解决方案是 UI 层从现有字段派生）。
- 不在 UI/Provider 里拼 shell 命令（全部收敛到 Service）。
- **不做发行版守卫**（尊重决策，发行版适配由脚本内部 `/etc/os-release` 检测处理；这是脚本设计最佳实践）。
- 不静默执行任何特权操作（脚本审计确认是硬流程）。
- 不修改 `CliExecutor`（ll-cli 专用，与本模块无关）。
- `RequestInteraction` 字符串不硬编码进业务代码（仅出现在规则定义里）。

## 十三、测试（三层，照抄 docs/21 模式）

| 层 | 文件 | 测什么 |
|---|---|---|
| domain | `test/unit/core/error_diagnostics/diagnosis_rule_registry_test.dart` | signature 匹配（命中/不命中/多字段 AND）、规则优先级（priority 降序） |
| service | `test/unit/application/services/error_diagnostics_service_test.dart` | `_FakeShellCommandRunner.fromCommands({...})` 断言 `['pkexec','bash',...]` 命令、脚本内容 `contains('apt install linglong-bin')`、日志路径落在 XDG logs、截断逻辑 |
| provider | `test/unit/application/providers/error_diagnostics_provider_test.dart` | 状态流转（idle→diagnosing→diagnosed/noMatch→scriptPrepared→repairing→repaired/failed）、override service |
| widget | `test/widget/presentation/widgets/{error_help_button,solution_dialog,script_review_dialog}_test.dart` | 按钮命中/未命中的显隐、弹窗渲染、referenceUrl 点击、审计确认交互、确认执行回调 |
| 回归 | `test/widget/presentation/widgets/download_manager_dialog_test.dart` | 改造后红字仍正常显示、帮助按钮存在且命中失败任务时可点开弹窗 |

### Service 单测惯用法（照抄）

```dart
class _FakeShellCommandRunner implements ShellCommandRunner {
  _FakeShellCommandRunner.fromCommands(this._results, {this._dynamicResult});
  final Map<String, ShellCommandResult> _results;     // key = command.join(' ')
  final List<List<String>> commands = [];             // 记录所有调用，便于断言
  final List<ShellCommandLogOptions?> logOptions = [];
  Future<ShellCommandResult> run(List<String> command, {...}) async {
    commands.add(List<String>.from(command));
    final key = command.join(' ');
    final result = _results[key] ?? _dynamicResult?.call(command);
    if (result == null) throw StateError('Unexpected command: $key');
    return result;
  }
}
```

断言样例：

```dart
expect(runner.commands.single.take(2).toList(), ['pkexec', 'bash']);
expect(runner.commands.single.last, startsWith('/tmp/error-repair-'));
// 读取临时脚本文件内容，校验脚本正确
final scriptContent = await File(runner.commands.single.last).readAsString();
expect(scriptContent, contains('apt install linglong-bin linglong-box'));
expect(scriptContent, contains('/etc/os-release'));  // 脚本自带发行版检测
```

运行：`/home/hao/Flutter/flutter-stable/bin/flutter test <file>`

## 十四、落地步骤（Conventional Commits，每步一提交）

1. `docs: 新增错误诊断+引导式修复模块设计文档` —— 本文档落地
2. `refactor: 提取 ShellScriptRunner 共享 helper` —— `lib/core/platform/shell_script_runner.dart`，环境管理 Service 改用它（行为不变）+ 跑回归测试
3. `feat(domain): 错误诊断领域模型` —— `lib/domain/models/error_diagnosis.dart` + `build_runner`
4. `feat(core): 错误诊断规则注册表与首条规则` —— `lib/core/error_diagnostics/` + `rules/request_interaction_rule.dart`
5. `feat(app): 错误诊断 Service` —— `lib/application/services/error_diagnostics_service.dart`
6. `feat(app): 错误诊断 Provider` —— `lib/application/providers/error_diagnostics_provider.dart`
7. `feat(ui): 脚本审计对话框` —— `lib/presentation/widgets/script_review_dialog.dart`（先做，它是缺口）
8. `feat(ui): 解决方案弹窗与帮助按钮` —— `solution_dialog.dart` + `error_help_button.dart`
9. `feat(ui): 下载中心接入帮助按钮` —— 改 `download_manager_dialog.dart:628`（最小侵入接入）
10. `feat(i18n): 错误诊断模块文案` —— zh/en arb + `flutter gen-l10n`
11. `test: 错误诊断模块三层测试` —— domain/service/provider/widget + 全量 `flutter analyze`

## 十五、i18n 文案 key 清单（`app_zh.arb` 中文模板先行）

| key | 中文文案 |
|---|---|
| `errorDiagnosticsButtonTooltip` | 查看推荐解决方案 |
| `errorDiagnosticsButtonA11y` | 查看此错误的推荐解决方案 |
| `errorDiagnosticsNoSolution` | 暂无推荐解决方案 |
| `errorDiagnosticsSolutionTitle` | 推荐解决方案 |
| `errorDiagnosticsReferenceLabel` | 查看方案来源 |
| `errorDiagnosticsRepairButton` | 一键修复 |
| `errorDiagnosticsRepairButtonA11y` | 使用推荐脚本一键修复此问题 |
| `errorDiagnosticsScriptReviewTitle` | 即将执行的修复脚本 |
| `errorDiagnosticsScriptReviewRiskWarning` | 以下脚本将以管理员权限执行，请仔细阅读确认后再继续。 |
| `errorDiagnosticsScriptA11y` | 修复脚本内容 |
| `errorDiagnosticsConfirmRun` | 确认执行 |
| `errorDiagnosticsRunning` | 正在执行修复… |
| `errorDiagnosticsRepairSuccess` | 修复完成 |
| `errorDiagnosticsRepairFailed` | 修复失败 |
| `errorDiagnosticsOpenLog` | 打开日志目录 |

### RequestInteraction 规则专属文案

| key | 中文文案 |
|---|---|
| `errorDiagnosticsRequestInteractionTitle` | 玲珑运行时不匹配，需换装社区 OBS 源版本 |
| `errorDiagnosticsRequestInteractionDescription` | 当前系统自带的玲珑运行时在非 Deepin/UOS 发行版上不稳定，导致安装交互信号无法连接。推荐换装社区维护的玲珑 1.12.2 稳定版（来自 OBS 社区源）。一键修复将自动添加 Ubuntu 24.04 的 OBS 软件源、导入 GPG 签名并安装 linglong-bin 与 linglong-box。详见方案来源中的安装教程。 |
