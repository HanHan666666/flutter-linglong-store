/// 免密安装规则领域模型测试（docs/50 §4.1、§6.3）。
///
/// 覆盖缓存版本化格式、损坏缓存回退、执行路径判据，以及“成功必须同时满足
/// 回读状态等于目标”的契约。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/domain/models/polkit_rule_state.dart';

void main() {
  group('PasswordFreeInstallCache', () {
    test('缺失缓存使用默认关闭且不标记待同步', () {
      expect(PasswordFreeInstallCache.tryParse(null), isNull);
      expect(PasswordFreeInstallCache.defaults.enabled, isFalse);
      expect(PasswordFreeInstallCache.defaults.needsSync, isFalse);
    });

    test('解析版本化 JSON 并保留两个字段', () {
      final cache = PasswordFreeInstallCache.tryParse(
        '{"version":1,"enabled":true,"needsSync":true}',
      );

      expect(cache, isNotNull);
      expect(cache!.enabled, isTrue);
      expect(cache.needsSync, isTrue);
    });

    test('版本不支持或结构损坏时解析失败', () {
      expect(
        PasswordFreeInstallCache.tryParse('{"version":2,"enabled":true,"needsSync":false}'),
        isNull,
      );
      expect(
        PasswordFreeInstallCache.tryParse('{"enabled":true,"needsSync":false}'),
        isNull,
      );
      expect(
        PasswordFreeInstallCache.tryParse('{"version":1,"enabled":"yes"}'),
        isNull,
      );
      expect(PasswordFreeInstallCache.tryParse('not json'), isNull);
      expect(PasswordFreeInstallCache.tryParse('[]'), isNull);
      expect(PasswordFreeInstallCache.tryParse('   '), isNull);
    });

    test('序列化结果可被自身解析', () {
      const cache = PasswordFreeInstallCache(enabled: true, needsSync: false);
      final parsed = PasswordFreeInstallCache.tryParse(
        jsonEncode(cache.toJson()),
      );

      expect(parsed!.enabled, isTrue);
      expect(parsed.needsSync, isFalse);
      expect(cache.toJson()['version'], PasswordFreeInstallCache.formatVersion);
    });

    test('只有已确认开启且无待同步时才走普通 CLI', () {
      expect(
        const PasswordFreeInstallCache(enabled: true, needsSync: false)
            .usesPasswordFreeCli,
        isTrue,
      );
      expect(
        const PasswordFreeInstallCache(enabled: true, needsSync: true)
            .usesPasswordFreeCli,
        isFalse,
      );
      expect(
        const PasswordFreeInstallCache(enabled: false, needsSync: false)
            .usesPasswordFreeCli,
        isFalse,
      );
    });
  });

  group('PolkitRuleTransactionResult.matchesRequestedTarget', () {
    PolkitRuleTransactionResult build({
      required bool requested,
      required PolkitRuleSystemState after,
      required PolkitRuleOutcome outcome,
    }) {
      return PolkitRuleTransactionResult(
        requestedEnabled: requested,
        before: PolkitRuleSystemState.disabled,
        after: after,
        outcome: outcome,
      );
    }

    test('applied 且回读等于目标才算成功', () {
      expect(
        build(
          requested: true,
          after: PolkitRuleSystemState.enabled,
          outcome: PolkitRuleOutcome.applied,
        ).matchesRequestedTarget,
        isTrue,
      );
      expect(
        build(
          requested: false,
          after: PolkitRuleSystemState.disabled,
          outcome: PolkitRuleOutcome.unchanged,
        ).matchesRequestedTarget,
        isTrue,
      );
    });

    test('回读状态与目标不一致时不算成功', () {
      expect(
        build(
          requested: true,
          after: PolkitRuleSystemState.disabled,
          outcome: PolkitRuleOutcome.applied,
        ).matchesRequestedTarget,
        isFalse,
      );
      expect(
        build(
          requested: true,
          after: PolkitRuleSystemState.unknown,
          outcome: PolkitRuleOutcome.unchanged,
        ).matchesRequestedTarget,
        isFalse,
      );
    });

    test('conflict 与 failed 结论永不算成功', () {
      expect(
        build(
          requested: true,
          after: PolkitRuleSystemState.conflict,
          outcome: PolkitRuleOutcome.conflict,
        ).matchesRequestedTarget,
        isFalse,
      );
      expect(
        build(
          requested: true,
          after: PolkitRuleSystemState.enabled,
          outcome: PolkitRuleOutcome.failed,
        ).matchesRequestedTarget,
        isFalse,
      );
    });
  });
}
