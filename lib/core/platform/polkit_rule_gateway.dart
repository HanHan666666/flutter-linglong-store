/// 免密安装 polkit 规则的平台 Gateway（docs/50 §6）。
///
/// 本文件是本功能唯一的特权配置入口：只有它可以把固定模板写入用户私有工作区、
/// 通过 `pkexec --disable-internal-agent /bin/bash <脚本> <enable|disable>` 提权
/// 执行，并严格解析结构化结果。禁止在别处新增第二条 pkexec 调用路径，也禁止
/// 复用安装传输用的特权 helper 静默修改系统策略（§6.1）。
///
/// 根脚本只接受两个固定动作、只操作固定规则路径，正文来自随应用分发的固定
/// 模板；用户工作区使用随机私有目录与私有脚本，命令退出后在 finally 清理。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../domain/models/polkit_rule_state.dart';
import '../../domain/repositories/polkit_rule_gateway.dart';
import '../logging/app_logger.dart';
import 'shell_command_executor.dart';

/// 本功能固定规则文件路径（docs/50 §3.1）。
const String kPolkitRuleFilePath =
    '/etc/polkit-1/rules.d/60-linglong-store.rules';

/// 固定规则目录；只读取与校验，不修改其权限，也不要求用户加入 polkitd 组。
const String kPolkitRuleDirectoryPath = '/etc/polkit-1/rules.d';

/// 当前受支持的规则模板版本。
///
/// 将来升级模板时必须显式列出可迁移的历史模板，不能仅凭一行“由商店生成”的
/// 注释覆盖用户文件（docs/50 §4.2）。
const int kPolkitRuleTemplateVersion = 1;

/// 授权与执行的总等待上限（docs/50 §6.3）。
const Duration kPolkitRuleTransactionTimeout = Duration(seconds: 120);

/// 规则正文模板（版本 1）。
///
/// 这是唯一事实来源：脚本正文、回读比对与测试都使用它。必须使用大写
/// `polkit.Result.YES`——小写 `.yes` 是 `undefined`，不会产生免密授权。
const String kPasswordFreeInstallRuleTemplate = '''
/**
 * 玲珑商店安装免密规则，模板版本 1。
 * 仅为本机活动会话放行安装类操作；其他操作继续由系统策略决定。
 * 此标记用于识别用途，文件归属判断仍须校验完整模板及文件元数据。
 */
polkit.addRule(function(action, subject) {
    // 会话限制用于缩小授权范围，不将远程或非活动会话纳入本规则。
    if (!subject.local || !subject.active) {
        return;
    }

    // 精确枚举 action，防止上游新增敏感操作后被前缀规则意外放行。
    if (action.id === "org.deepin.linglong.PackageManager1.install" ||
        action.id === "org.deepin.linglong.PackageManager1.update" ||
        action.id === "org.deepin.linglong.PackageManager1.install-from-file") {
        return polkit.Result.YES;
    }
});
''';

/// 脚本模板中规则正文的替换占位符。
const String _kRuleTemplatePlaceholder = '@@RULE_TEMPLATE@@';

/// root 事务脚本模板。
///
/// 说明（与 docs/50 §6.2 一一对应）：
/// - 只接受 `enable` / `disable`，其余参数以自身定义的退出码失败；
/// - 打开规则目录文件描述符并用 `flock` 排他锁串行化本功能各实例，最多等待
///   10 秒，不创建普通用户可预占的锁文件；
/// - 锁内先读取真实状态，冲突或无法读取时不做任何修改；
/// - 开启时在规则目录内用 `mktemp` 创建不以 `.rules` 结尾的随机临时文件，
///   写入完整模板、设置预期属主与 0644、比对内容，再以同目录 `mv -T` 原子发布；
///   替换前再次确认目标仍处于允许操作的状态；
/// - 关闭时只删除通过归属校验的固定文件，不存在则幂等成功；
/// - 回读 `after` 后输出固定结构结果，诊断写 stderr；
/// - 脚本内部错误使用 64~68 自有退出码，不直接透传子命令的 126/127。
///
/// 隔离测试模式：**仅当调用者不是 root** 时允许用环境变量
/// `LL_STORE_POLKIT_RULES_DIR` 指定隔离目录，并把预期属主放宽为当前用户。
/// root（pkexec 生产路径）下该变量一律忽略，固定路径与 root:root 校验不可
/// 绕过；pkexec 本身也会重置环境，生产链路根本收不到该变量。
const String _kTransactionScriptTemplate = r'''
#!/bin/bash
# 玲珑商店免密安装规则事务脚本（模板版本 1）。
#
# 由商店 GUI 通过 `pkexec --disable-internal-agent /bin/bash <脚本> <enable|disable>`
# 以 root 执行。只接受两个固定动作，正文来自随应用分发的固定模板，不接受任何
# 来自普通用户的路径或内容参数。
#
# root 下只操作固定规则路径；非 root 时仅允许在 LL_STORE_POLKIT_RULES_DIR 指定的
# 隔离目录中执行（供自动化测试），并且该目录不得等于系统规则目录——普通用户
# 因此永远无法让本脚本触碰系统策略目录。
set -u

readonly RULE_DIR_FIXED='/etc/polkit-1/rules.d'
readonly RULE_FILE_NAME='60-linglong-store.rules'
readonly LOCK_WAIT_SECONDS=10
readonly TMP_PREFIX='.ll-store-polkit-rule.'

# 脚本内部错误使用自身定义的退出码，不直接透传子命令的 126/127，
# 避免 GUI 把执行错误误识别为 pkexec 授权取消。
readonly EXIT_USAGE=64
readonly EXIT_UNSUPPORTED=65
readonly EXIT_NOT_ROOT=66
readonly EXIT_LOCK_TIMEOUT=67
readonly EXIT_INTERNAL=68

# 规则正文：由 GUI 在生成脚本时注入，写入与回读比对共用这一份。
RULE_TEMPLATE=$(cat <<'RULE_TEMPLATE_EOF'
@@RULE_TEMPLATE@@
RULE_TEMPLATE_EOF
)

log() {
  printf '[linglong-store-polkit-rule] %s\n' "$*" >&2
}

# 输出固定结构结果：stdout 只承载机器可读结果，诊断一律走 stderr。
emit_result() {
  printf '{"version":1,"requestedEnabled":%s,"before":"%s","after":"%s","outcome":"%s","reason":"%s"}\n' \
    "$1" "$2" "$3" "$4" "$5"
}

# 读取固定路径的系统状态：enabled / disabled / conflict / unknown。
#
# enabled 必须同时满足：普通文件、预期属主与属组、0644、正文与模板逐字节一致。
read_state() {
  local mode owner group
  if [[ -L "$rules_path" ]]; then
    printf 'conflict'
    return
  fi
  if [[ ! -e "$rules_path" ]]; then
    printf 'disabled'
    return
  fi
  if [[ ! -f "$rules_path" ]]; then
    printf 'conflict'
    return
  fi
  mode=$(stat -c '%a' -- "$rules_path" 2>/dev/null) || { printf 'unknown'; return; }
  owner=$(stat -c '%u' -- "$rules_path" 2>/dev/null) || { printf 'unknown'; return; }
  group=$(stat -c '%g' -- "$rules_path" 2>/dev/null) || { printf 'unknown'; return; }
  if [[ "$mode" != '644' || "$owner" != "$expected_uid" || "$group" != "$expected_gid" ]]; then
    printf 'conflict'
    return
  fi
  if cmp -s -- "$rules_path" <(printf '%s\n' "$RULE_TEMPLATE"); then
    printf 'enabled'
  else
    printf 'conflict'
  fi
}

# 清理上次异常退出遗留的临时文件：只删本功能命名、预期属主所有的普通文件。
cleanup_stale_temp_files() {
  local candidate owner
  shopt -s nullglob
  for candidate in "$rules_dir/$TMP_PREFIX"*; do
    [[ -f "$candidate" && ! -L "$candidate" ]] || continue
    owner=$(stat -c '%u' -- "$candidate" 2>/dev/null) || continue
    [[ "$owner" == "$expected_uid" ]] || continue
    rm -f -- "$candidate" || true
    log "removed stale temp file: $candidate"
  done
  shopt -u nullglob
}

action="${1:-}"
if [[ "$action" != 'enable' && "$action" != 'disable' ]]; then
  log "unsupported action: ${action}"
  exit "$EXIT_USAGE"
fi

requested='false'
target_state='disabled'
if [[ "$action" == 'enable' ]]; then
  requested='true'
  target_state='enabled'
fi

# 生产路径（root）只操作固定路径；隔离测试模式仅在非 root 时生效。
rules_dir="$RULE_DIR_FIXED"
expected_uid=0
expected_gid=0
if [[ "$EUID" -ne 0 ]]; then
  if [[ -n "${LL_STORE_POLKIT_RULES_DIR:-}" ]]; then
    # 隔离测试模式不得指向系统目录，避免非 root 调用产生第二目标路径；
    # 先去掉尾部斜杠，防止 `/etc/polkit-1/rules.d/` 绕过字面比较。
    isolated_dir="${LL_STORE_POLKIT_RULES_DIR%/}"
    if [[ "$isolated_dir" == "$RULE_DIR_FIXED" ]]; then
      log 'isolated rules directory must not be the system directory'
      exit "$EXIT_NOT_ROOT"
    fi
    rules_dir="$isolated_dir"
    expected_uid="$EUID"
    expected_gid="$(id -g)"
  else
    log 'refusing to run without root privileges'
    exit "$EXIT_NOT_ROOT"
  fi
fi
rules_path="$rules_dir/$RULE_FILE_NAME"

# 目录缺失或不是目录：明确失败，不修改目录权限、不自动部署 polkit。
if [[ ! -d "$rules_dir" ]]; then
  log "rules directory is unavailable: $rules_dir"
  exit "$EXIT_UNSUPPORTED"
fi

# 缺少 flock 说明环境无法保证本功能各实例串行，按环境不支持处理。
if ! command -v flock >/dev/null 2>&1; then
  log 'flock is unavailable; cannot serialize rule transactions'
  exit "$EXIT_UNSUPPORTED"
fi

# 跨实例锁：打开目录文件描述符后 flock 排他，不创建可预占的锁文件。
if ! exec 9< "$rules_dir"; then
  log "cannot open rules directory: $rules_dir"
  exit "$EXIT_INTERNAL"
fi
if ! flock -x -w "$LOCK_WAIT_SECONDS" 9; then
  log "lock timeout after ${LOCK_WAIT_SECONDS}s"
  exit "$EXIT_LOCK_TIMEOUT"
fi

cleanup_stale_temp_files

before=$(read_state)
log "before=$before"

if [[ "$before" == 'unknown' ]]; then
  log 'cannot read current rule state'
  exit "$EXIT_INTERNAL"
fi

# 同名文件内容不同、符号链接、目录、属主或权限异常：不覆盖、不删除。
if [[ "$before" == 'conflict' ]]; then
  emit_result "$requested" "$before" "$before" 'conflict' 'conflict'
  exit 0
fi

# 真实状态已经等于目标：不重复写入或删除，按幂等成功结束。
if [[ "$before" == "$target_state" ]]; then
  emit_result "$requested" "$before" "$before" 'unchanged' 'none'
  exit 0
fi

if [[ "$action" == 'enable' ]]; then
  # 临时文件名不以 .rules 结尾，polkit 不会提前加载半成品。
  if ! staging=$(mktemp -- "$rules_dir/$TMP_PREFIX"XXXXXX); then
    log 'cannot create staging file'
    exit "$EXIT_INTERNAL"
  fi
  # 所有正常/异常退出路径都删除本次临时文件。
  trap 'rm -f -- "$staging"' EXIT

  if ! printf '%s\n' "$RULE_TEMPLATE" > "$staging"; then
    log 'cannot write staging file'
    exit "$EXIT_INTERNAL"
  fi
  if [[ "$EUID" -eq 0 ]]; then
    if ! chown root:root -- "$staging"; then
      log 'cannot set staging owner'
      exit "$EXIT_INTERNAL"
    fi
  fi
  if ! chmod 644 -- "$staging"; then
    log 'cannot set staging mode'
    exit "$EXIT_INTERNAL"
  fi
  # 写入结果自校验：内容不符时绝不发布。
  if ! cmp -s -- "$staging" <(printf '%s\n' "$RULE_TEMPLATE"); then
    log 'staged content mismatch'
    exit "$EXIT_INTERNAL"
  fi

  # 替换前再次确认目标仍处于允许操作的状态，避免误覆盖管理员更改。
  current=$(read_state)
  if [[ "$current" == 'conflict' ]]; then
    emit_result "$requested" "$before" 'conflict' 'conflict' 'conflict'
    exit 0
  fi
  if [[ "$current" == 'enabled' ]]; then
    emit_result "$requested" "$before" "$current" 'unchanged' 'none'
    exit 0
  fi
  if [[ "$current" == 'unknown' ]]; then
    log 'cannot re-read current rule state before publish'
    exit "$EXIT_INTERNAL"
  fi

  if ! mv -T -- "$staging" "$rules_path"; then
    after=$(read_state)
    log 'publish failed'
    emit_result "$requested" "$before" "$after" 'failed' 'writeFailed'
    exit 0
  fi
  trap - EXIT

  after=$(read_state)
  if [[ "$after" == 'enabled' ]]; then
    emit_result "$requested" "$before" "$after" 'applied' 'none'
  else
    log "post-write verification failed: after=$after"
    emit_result "$requested" "$before" "$after" 'failed' 'verifyFailed'
  fi
  exit 0
fi

# 关闭：before 已确认是本功能规则文件（普通文件、预期属主、0644、模板一致）。
if ! rm -f -- "$rules_path"; then
  after=$(read_state)
  log 'delete failed'
  emit_result "$requested" "$before" "$after" 'failed' 'deleteFailed'
  exit 0
fi

after=$(read_state)
if [[ "$after" == 'disabled' ]]; then
  emit_result "$requested" "$before" "$after" 'applied' 'none'
else
  log "post-delete verification failed: after=$after"
  emit_result "$requested" "$before" "$after" 'failed' 'verifyFailed'
fi
exit 0
''';

/// 用固定模板生成可执行的 root 事务脚本。
///
/// 单独导出便于测试断言脚本与模板的一致性（模板正文只维护一份常量）。
String buildPolkitRuleTransactionScript() {
  const template = kPasswordFreeInstallRuleTemplate;
  // heredoc 正文由 printf 统一补一个换行，因此注入时去掉模板自带的末尾换行，
  // 保证正式文件正文与常量逐字节一致。
  final body = template.endsWith('\n')
      ? template.substring(0, template.length - 1)
      : template;
  return _kTransactionScriptTemplate.replaceFirst(
    _kRuleTemplatePlaceholder,
    body,
  );
}

/// 基于 pkexec 与固定脚本的 [PolkitRuleGateway] 实现。
class PolkitRuleScriptGateway implements PolkitRuleGateway {
  /// 创建 Gateway。
  ///
  /// [executor] 复用项目既有 Shell 执行器；[workspaceRoot] 与 [pkexecPath] 是
  /// 测试注入缝，生产不传。脚本一律在随机私有目录中重新生成，不复用共享
  /// `/tmp` 根目录下可预测的文件名。
  PolkitRuleScriptGateway({
    ShellCommandExecutor? executor,
    Directory? workspaceRoot,
    String pkexecPath = 'pkexec',
    String bashPath = '/bin/bash',
    this.timeout = kPolkitRuleTransactionTimeout,
  }) : _executor = executor ?? ShellCommandExecutor(),
       _workspaceRoot = workspaceRoot,
       _pkexecPath = pkexecPath,
       _bashPath = bashPath;

  final ShellCommandExecutor _executor;
  final Directory? _workspaceRoot;
  final String _pkexecPath;
  final String _bashPath;

  /// 授权与执行的总等待上限。
  final Duration timeout;

  @override
  Future<PolkitRuleTransactionResult> apply({required bool enabled}) async {
    final Directory workspace;
    try {
      workspace = await (_workspaceRoot ?? Directory.systemTemp).createTemp(
        'll-store-polkit-rule-',
      );
    } catch (error) {
      throw PolkitRuleException(
        PolkitRuleFailureKind.unexpected,
        '无法创建私有工作区: $error',
      );
    }

    try {
      // 0700 目录 + 0700 脚本：工作区对同机其他用户不可遍历。
      await _setMode(workspace.path, '700');
      final script = File('${workspace.path}/transaction.sh');
      // 先落一个空文件并收紧到 0700，再写入正文：writeAsString 会沿用已有
      // 文件的权限，避免正文在默认 umask 权限下短暂可读（§6.1 要求脚本 0700）。
      await script.create();
      await _setMode(script.path, '700');
      // 异步完整写入后再执行，避免执行到半截脚本。
      await script.writeAsString(
        buildPolkitRuleTransactionScript(),
        flush: true,
      );

      final ShellCommandResult result;
      try {
        result = await _executor.runStreaming(
          <String>[
            _pkexecPath,
            // 无桌面代理时明确失败，不使用终端认证代理。
            '--disable-internal-agent',
            _bashPath,
            script.path,
            enabled ? 'enable' : 'disable',
          ],
          // 空回调只为启用流式逐行日志（完整日志写入既有 XDG 日志）；
          // 结果解析只读 stdout 尾部，不从自由文本推断成功。
          onOutput: (ShellOutputLine _) {},
          timeout: timeout,
        );
      } on TimeoutException catch (error) {
        throw PolkitRuleException(
          PolkitRuleFailureKind.timeout,
          '提权同步超时: $error',
        );
      } on ProcessException catch (error) {
        throw PolkitRuleException(
          PolkitRuleFailureKind.authorizationUnavailable,
          'pkexec 启动失败: ${error.message}',
          exitCode: error.errorCode,
        );
      } on FileSystemException catch (error) {
        throw PolkitRuleException(
          PolkitRuleFailureKind.unexpected,
          '临时工作区 IO 失败: ${error.message}',
        );
      }
      return _interpret(result, requestedEnabled: enabled);
    } finally {
      // 命令退出后才清理工作区；授权仍等待时不会删除脚本。
      await _deleteWorkspace(workspace);
    }
  }

  /// 把执行结果映射为结构化事务结果或稳定异常。
  PolkitRuleTransactionResult _interpret(
    ShellCommandResult result, {
    required bool requestedEnabled,
  }) {
    final exitCode = result.exitCode;
    if (exitCode != 0) {
      throw PolkitRuleException(
        _mapExitCode(exitCode),
        _diagnosticOf(result),
        exitCode: exitCode,
      );
    }

    final parsed = _parseStdout(
      result.stdout,
      requestedEnabled: requestedEnabled,
    );
    if (parsed == null) {
      throw PolkitRuleException(
        PolkitRuleFailureKind.invalidResult,
        '事务脚本输出不符合版本化契约: ${_diagnosticOf(result)}',
        exitCode: exitCode,
      );
    }
    return parsed;
  }

  /// 脚本自有退出码到稳定失败类型的映射。
  ///
  /// 126/127 由 pkexec 产生，与脚本的 64~68 不重叠；脚本从不透传子命令退出码。
  PolkitRuleFailureKind _mapExitCode(int exitCode) {
    return switch (exitCode) {
      126 => PolkitRuleFailureKind.authorizationCancelled,
      127 => PolkitRuleFailureKind.authorizationUnavailable,
      64 || 65 || 66 => PolkitRuleFailureKind.unsupportedEnvironment,
      67 => PolkitRuleFailureKind.timeout,
      _ => PolkitRuleFailureKind.unexpected,
    };
  }

  String _diagnosticOf(ShellCommandResult result) {
    final stderr = result.stderr.trim();
    if (stderr.isNotEmpty) {
      return stderr;
    }
    final stdout = result.stdout.trim();
    return stdout.isEmpty ? '事务脚本未输出任何内容' : stdout;
  }

  /// 严格解析 stdout 中最后一条非空结果行。
  ///
  /// 版本、枚举和字段必须全部合法；任何缺失或越界都返回 null，由调用方按
  /// “无可靠结果”处理，避免把半截输出误判成成功。
  PolkitRuleTransactionResult? _parseStdout(
    String stdout, {
    required bool requestedEnabled,
  }) {
    String? candidate;
    for (final line in const LineSplitter().convert(stdout)) {
      if (line.trim().isNotEmpty) {
        candidate = line.trim();
      }
    }
    if (candidate == null) {
      return null;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(candidate);
    } catch (_) {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    if (decoded['version'] != PolkitRuleTransactionResult.contractVersion) {
      return null;
    }

    final requested = decoded['requestedEnabled'];
    final before = _parseSystemState(decoded['before']);
    final after = _parseSystemState(decoded['after']);
    final outcome = _parseOutcome(decoded['outcome']);
    final reason = _parseReason(decoded['reason']);
    if (requested is! bool ||
        before == null ||
        after == null ||
        outcome == null ||
        reason == null) {
      return null;
    }
    if (requested != requestedEnabled) {
      return null;
    }

    return PolkitRuleTransactionResult(
      requestedEnabled: requested,
      before: before,
      after: after,
      outcome: outcome,
      reason: reason,
    );
  }

  PolkitRuleSystemState? _parseSystemState(Object? value) {
    for (final state in PolkitRuleSystemState.values) {
      if (value == state.name) {
        return state;
      }
    }
    return null;
  }

  PolkitRuleOutcome? _parseOutcome(Object? value) {
    for (final outcome in PolkitRuleOutcome.values) {
      if (value == outcome.name) {
        return outcome;
      }
    }
    return null;
  }

  PolkitRuleFailureReason? _parseReason(Object? value) {
    for (final reason in PolkitRuleFailureReason.values) {
      if (value == reason.name) {
        return reason;
      }
    }
    return null;
  }

  Future<void> _setMode(String path, String mode) async {
    final result = await Process.run('chmod', <String>[mode, path]);
    if (result.exitCode != 0) {
      throw PolkitRuleException(
        PolkitRuleFailureKind.unexpected,
        '无法设置工作区权限($mode): ${result.stderr.toString().trim()}',
      );
    }
  }

  Future<void> _deleteWorkspace(Directory workspace) async {
    try {
      await workspace.delete(recursive: true);
    } catch (error) {
      // 清理失败不影响事务结论；残留物只是普通用户的私有目录。
      AppLogger.warning('清理免密规则临时工作区失败: ${workspace.path}', error);
    }
  }
}
