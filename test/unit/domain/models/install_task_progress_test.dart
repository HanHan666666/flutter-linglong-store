import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';

void main() {
  group('InstallTask progress presentation helpers', () {
    InstallTask buildTask(double progress) {
      return InstallTask(
        id: 'task-1',
        appId: 'org.example.demo',
        appName: 'Demo',
        status: InstallStatus.installing,
        progress: progress,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    test('normalizes ratio progress into percent label', () {
      final task = buildTask(0.74);

      expect(task.progressPercentLabel, '74%');
      expect(task.progressValue, closeTo(0.74, 0.0001));
    });

    test('normalizes legacy percent progress into ratio', () {
      final task = buildTask(74.0);

      expect(task.progressPercentLabel, '74%');
      expect(task.progressValue, closeTo(0.74, 0.0001));
    });
  });
}
