/// 免密安装规则同步服务测试（docs/50 §8）。
///
/// 验证服务只做“调用 Gateway + 归约事实”：把结构化结果原样上抛，
/// 把异常映射为稳定失败类型，不吞掉诊断。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/polkit_rule_service.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';
import 'package:linglong_store/domain/repositories/polkit_rule_gateway.dart';

/// 可编程的 Gateway 替身。
class _FakePolkitRuleGateway implements PolkitRuleGateway {
  _FakePolkitRuleGateway({this.result, this.error});

  PolkitRuleTransactionResult? result;
  Object? error;
  final List<bool> requests = <bool>[];

  @override
  Future<PolkitRuleTransactionResult> apply({required bool enabled}) async {
    requests.add(enabled);
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result!;
  }
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  test('结构化结果原样归约为完成事实', () async {
    final gateway = _FakePolkitRuleGateway(
      result: const PolkitRuleTransactionResult(
        requestedEnabled: true,
        before: PolkitRuleSystemState.disabled,
        after: PolkitRuleSystemState.enabled,
        outcome: PolkitRuleOutcome.applied,
      ),
    );
    final service = PolkitRuleService(gateway: gateway);

    final fact = await service.synchronize(enabled: true);

    expect(fact, isA<PolkitRuleSyncCompleted>());
    final completed = fact as PolkitRuleSyncCompleted;
    expect(completed.matchesRequestedTarget, isTrue);
    expect(completed.result.after, PolkitRuleSystemState.enabled);
    expect(gateway.requests, <bool>[true]);
  });

  test('PolkitRuleException 映射为稳定失败类型并保留诊断', () async {
    final gateway = _FakePolkitRuleGateway(
      error: const PolkitRuleException(
        PolkitRuleFailureKind.authorizationCancelled,
        'pkexec authorization dismissed by user',
        exitCode: 126,
      ),
    );

    final fact = await PolkitRuleService(gateway: gateway).synchronize(
      enabled: true,
    );

    expect(fact, isA<PolkitRuleSyncFailed>());
    final failed = fact as PolkitRuleSyncFailed;
    expect(failed.kind, PolkitRuleFailureKind.authorizationCancelled);
    expect(failed.diagnostic, contains('dismissed'));
  });

  test('未预期异常归约为 unexpected 而不是向上抛出', () async {
    final gateway = _FakePolkitRuleGateway(error: StateError('boom'));

    final fact = await PolkitRuleService(gateway: gateway).synchronize(
      enabled: false,
    );

    expect(fact, isA<PolkitRuleSyncFailed>());
    expect(
      (fact as PolkitRuleSyncFailed).kind,
      PolkitRuleFailureKind.unexpected,
    );
  });
}
