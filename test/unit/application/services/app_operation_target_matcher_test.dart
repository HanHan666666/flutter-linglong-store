/// 验证应用操作目标与已安装实例的共享匹配规则。
///
/// 该判定器同时服务启动恢复与更新后的收敛确认，因此这里覆盖两个关键边界：
/// 多实例歧义必须拒绝猜测、未冻结 expectedVersion 时不得判定成功。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_operation_target_matcher.dart';
import 'package:linglong_store/domain/models/app_operation_target_snapshot.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

void main() {
  const matcher = AppOperationTargetMatcher();

  group('AppOperationTargetMatcher.matchesInstalledApp', () {
    test('目标为空时只按 appId 匹配', () {
      const app = InstalledApp(
        appId: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
      );

      expect(
        matcher.matchesInstalledApp(app: app, appId: 'com.example.demo'),
        isTrue,
      );
      expect(
        matcher.matchesInstalledApp(app: app, appId: 'com.example.other'),
        isFalse,
      );
    });

    test('已冻结身份字段必须完全一致', () {
      const app = InstalledApp(
        appId: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
        arch: 'x86_64',
        channel: 'main',
        module: 'binary',
        repoName: 'stable',
      );
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        arch: 'x86_64',
        channel: 'main',
        module: 'binary',
        repoName: 'stable',
      );

      expect(
        matcher.matchesInstalledApp(
          app: app,
          appId: 'com.example.demo',
          target: target,
        ),
        isTrue,
      );
      expect(
        matcher.matchesInstalledApp(
          app: app,
          appId: 'com.example.demo',
          target: target.copyWith(arch: 'arm64'),
        ),
        isFalse,
      );
    });

    test('未冻结字段不参与约束', () {
      const app = InstalledApp(
        appId: 'com.example.demo',
        name: 'Demo',
        version: '1.0.0',
        arch: 'x86_64',
        channel: 'main',
      );
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
      );

      expect(
        matcher.matchesInstalledApp(
          app: app,
          appId: 'com.example.demo',
          target: target,
        ),
        isTrue,
      );
    });
  });

  group('AppOperationTargetMatcher.resolveUniqueInstalledTarget', () {
    test('存在多个同身份实例时拒绝猜测', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '1.0.0',
          arch: 'x86_64',
        ),
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '2.0.0',
          arch: 'x86_64',
        ),
      ];

      expect(
        matcher.resolveUniqueInstalledTarget(
          appId: 'com.example.demo',
          installedApps: apps,
        ),
        isNull,
      );
    });

    test('多版本并存时按已冻结版本相关身份仍能唯一定位', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '1.0.0',
          arch: 'x86_64',
          channel: 'main',
        ),
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '2.0.0',
          arch: 'x86_64',
          channel: 'beta',
        ),
      ];
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        arch: 'x86_64',
        channel: 'main',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      );

      final resolved = matcher.resolveUniqueInstalledTarget(
        appId: 'com.example.demo',
        installedApps: apps,
        target: target,
      );

      expect(resolved?.version, '1.0.0');
    });
  });

  group('AppOperationTargetMatcher.isUpdateSatisfiedInSnapshot', () {
    test('目标版本已出现时判定已收敛', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '2.0.0',
          arch: 'x86_64',
        ),
      ];
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        arch: 'x86_64',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      );

      expect(
        matcher.isUpdateSatisfiedInSnapshot(
          target: target,
          installedApps: apps,
        ),
        isTrue,
      );
    });

    test('快照仍是旧版本时判定未收敛', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '1.0.0',
          arch: 'x86_64',
        ),
      ];
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        arch: 'x86_64',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      );

      expect(
        matcher.isUpdateSatisfiedInSnapshot(
          target: target,
          installedApps: apps,
        ),
        isFalse,
      );
    });

    test('缺少 expectedVersion 时不得判定成功', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '2.0.0',
        ),
      ];
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        installedVersion: '1.0.0',
      );

      expect(
        matcher.isUpdateSatisfiedInSnapshot(
          target: target,
          installedApps: apps,
        ),
        isFalse,
      );
    });

    test('身份歧义时不得判定成功', () {
      const apps = [
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '1.0.0',
        ),
        InstalledApp(
          appId: 'com.example.demo',
          name: 'Demo',
          version: '2.0.0',
        ),
      ];
      const target = AppOperationTargetSnapshot(
        appId: 'com.example.demo',
        displayName: 'Demo',
        installedVersion: '1.0.0',
        expectedVersion: '2.0.0',
      );

      expect(
        matcher.isUpdateSatisfiedInSnapshot(
          target: target,
          installedApps: apps,
        ),
        isFalse,
      );
    });
  });
}
