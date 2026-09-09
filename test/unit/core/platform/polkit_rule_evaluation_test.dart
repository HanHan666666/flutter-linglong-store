/// polkit 规则求值测试（docs/50 §3.2、§10.1「规则求值」行）。
///
/// 用与 polkit API 一致的求值环境（node + `polkit.addRule` / `polkit.Result` 桩）
/// 验证模板的**实际授权结果**，而不是只比较模板字符串是否变化。
///
/// 桩里只定义大写 `Result.YES/NO/AUTH_ADMIN`，故意不定义小写 `yes`：一旦模板
/// 回退成 `polkit.Result.yes`（其值为 `undefined`），白名单断言会立即失败，
/// 不会因为测试替身补了合法常量而被掩盖。
///
/// 需要 node（CI 的 ubuntu-latest 自带）；缺少 node 时测试直接失败并给出提示，
/// 不静默跳过。
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/polkit_rule_gateway.dart';

/// 求值桩前缀：只提供 polkit 真实存在的大写结果常量。
const String _harnessPrologue = r'''
const rules = [];
const polkit = {
  addRule(fn) { rules.push(fn); },
  Result: { YES: 'YES', NO: 'NO', AUTH_ADMIN: 'AUTH_ADMIN' },
};
''';

/// 求值桩后缀：枚举 action 与会话属性，按 polkit「首个有效结果决定授权」求值。
const String _harnessEpilogue = r'''
const actions = [
  'org.deepin.linglong.PackageManager1.install',
  'org.deepin.linglong.PackageManager1.update',
  'org.deepin.linglong.PackageManager1.install-from-file',
  'org.deepin.linglong.PackageManager1.uninstall',
  'org.deepin.linglong.PackageManager1.prune',
  'org.deepin.linglong.PackageManager1.set-configuration',
  'org.freedesktop.policykit.exec',
  'com.example.unknown',
];
const subjects = {
  'local-active': { local: true, active: true },
  'remote-active': { local: false, active: true },
  'local-inactive': { local: true, active: false },
};
const results = {};
for (const [subjectName, subject] of Object.entries(subjects)) {
  for (const actionId of actions) {
    const decided = rules
      .map((rule) => rule({ id: actionId }, subject))
      .find((value) => value !== undefined);
    results[actionId + '|' + subjectName] =
      decided === undefined ? null : decided;
  }
}
console.log(JSON.stringify(results));
''';

/// 白名单：本规则只放行这三个安装类 action。
const List<String> _whitelistedActions = <String>[
  'org.deepin.linglong.PackageManager1.install',
  'org.deepin.linglong.PackageManager1.update',
  'org.deepin.linglong.PackageManager1.install-from-file',
];

/// 明确不处理的操作：独立卸载、手动清理、修改配置与通用 pkexec 提权。
const List<String> _unhandledActions = <String>[
  'org.deepin.linglong.PackageManager1.uninstall',
  'org.deepin.linglong.PackageManager1.prune',
  'org.deepin.linglong.PackageManager1.set-configuration',
  'org.freedesktop.policykit.exec',
  'com.example.unknown',
];

const List<String> _subjects = <String>[
  'local-active',
  'remote-active',
  'local-inactive',
];

void main() {
  late Directory workspace;
  late Map<String, dynamic> results;

  setUpAll(() async {
    try {
      await Process.run('node', <String>['--version']);
    } on ProcessException {
      fail('规则求值测试需要 node 环境，请安装 node 后重试');
    }
    workspace = await Directory.systemTemp.createTemp('polkit-rule-eval-');
    final harness = File('${workspace.path}/rule_eval.js');
    await harness.writeAsString(
      _harnessPrologue + kPasswordFreeInstallRuleTemplate + _harnessEpilogue,
    );
    final run = await Process.run('node', <String>[harness.path]);
    expect(run.exitCode, 0, reason: run.stderr.toString());
    results = Map<String, dynamic>.from(
      jsonDecode(run.stdout.toString().trim()) as Map<String, dynamic>,
    );
  });

  tearDownAll(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  test('三个安装 action 在本机活动会话返回 YES', () {
    for (final action in _whitelistedActions) {
      expect(
        results['$action|local-active'],
        'YES',
        reason: '$action 应在 local-active 会话返回 polkit.Result.YES',
      );
    }
  });

  test('远程与非活动会话不被放行', () {
    for (final action in _whitelistedActions) {
      expect(results['$action|remote-active'], isNull, reason: action);
      expect(results['$action|local-inactive'], isNull, reason: action);
    }
  });

  test('卸载、清理、修改配置与通用提权一律不处理', () {
    for (final action in _unhandledActions) {
      for (final subject in _subjects) {
        expect(
          results['$action|$subject'],
          isNull,
          reason: '$action / $subject 不应被本规则返回任何授权结果',
        );
      }
    }
  });

  test('求值桩按 polkit 顺序语义工作：更早的拒绝规则优先', () async {
    // 单独验证一次桩本身：在模板之前注册一条返回 NO 的规则后，安装类 action
    // 的结果必须由更早的规则决定，说明白名单断言使用的顺序语义与 polkit 一致。
    final harness = File('${workspace.path}/rule_order.js');
    await harness.writeAsString(
      '$_harnessPrologue'
      'polkit.addRule(function(action, subject) { return polkit.Result.NO; });\n'
      '$kPasswordFreeInstallRuleTemplate'
      '$_harnessEpilogue',
    );
    final run = await Process.run('node', <String>[harness.path]);
    expect(run.exitCode, 0, reason: run.stderr.toString());
    final ordered = Map<String, dynamic>.from(
      jsonDecode(run.stdout.toString().trim()) as Map<String, dynamic>,
    );

    for (final action in _whitelistedActions) {
      expect(ordered['$action|local-active'], 'NO');
    }
  });
}
