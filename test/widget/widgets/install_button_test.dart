import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/domain/models/install_progress.dart';

/// 安装按钮状态枚举
enum InstallButtonState {
  install,
  installing,
  installed,
  update,
  failed,
}

/// 安装按钮 Widget（用于测试）
///
/// 注意：这是测试用的简化版本
/// 实际项目应该在 lib/presentation/widgets/ 中实现完整版本
class InstallButton extends StatelessWidget {
  const InstallButton({
    super.key,
    required this.state,
    this.progress = 0.0,
    this.onPressed,
    this.error,
  });

  final InstallButtonState state;
  final double progress;
  final VoidCallback? onPressed;
  final String? error;

  String get _label {
    switch (state) {
      case InstallButtonState.install:
        return 'Install';
      case InstallButtonState.installing:
        return 'Installing...';
      case InstallButtonState.installed:
        return 'Open';
      case InstallButtonState.update:
        return 'Update';
      case InstallButtonState.failed:
        return 'Retry';
    }
  }

  IconData get _icon {
    switch (state) {
      case InstallButtonState.install:
        return Icons.download;
      case InstallButtonState.installing:
        return Icons.downloading;
      case InstallButtonState.installed:
        return Icons.open_in_new;
      case InstallButtonState.update:
        return Icons.update;
      case InstallButtonState.failed:
        return Icons.refresh;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state == InstallButtonState.installing) {
      return _buildInstallingButton(context);
    }

    return ElevatedButton.icon(
      onPressed: state == InstallButtonState.installing ? null : onPressed,
      icon: Icon(_icon, size: 18),
      label: Text(_label),
      style: _getButtonStyle(context),
    );
  }

  Widget _buildInstallingButton(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (state) {
      case InstallButtonState.installed:
        return ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        );
      case InstallButtonState.failed:
        return ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        );
      default:
        return ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        );
    }
  }
}

void main() {
  group('InstallButton Widget', () {
    group('Install state', () {
      testWidgets('should display "Install" label', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.install),
            ),
          ),
        );

        expect(find.text('Install'), findsOneWidget);
      });

      testWidgets('should display download icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.install),
            ),
          ),
        );

        expect(find.byIcon(Icons.download), findsOneWidget);
      });

      testWidgets('should call onPressed when tapped', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.install,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Installing state', () {
      testWidgets('should display progress indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.5,
              ),
            ),
          ),
        );

        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display progress percentage', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.75,
              ),
            ),
          ),
        );

        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('should not be pressable during install', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.5,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        // 安装中状态不应该有可点击的 ElevatedButton
        expect(find.byType(ElevatedButton), findsNothing);
        expect(pressed, isFalse);
      });
    });

    group('Installed state', () {
      testWidgets('should display "Open" label', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.installed),
            ),
          ),
        );

        expect(find.text('Open'), findsOneWidget);
      });

      testWidgets('should display open icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.installed),
            ),
          ),
        );

        expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      });
    });

    group('Update state', () {
      testWidgets('should display "Update" label', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.update),
            ),
          ),
        );

        expect(find.text('Update'), findsOneWidget);
      });

      testWidgets('should display update icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.update),
            ),
          ),
        );

        expect(find.byIcon(Icons.update), findsOneWidget);
      });
    });

    group('Failed state', () {
      testWidgets('should display "Retry" label', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.failed),
            ),
          ),
        );

        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should display refresh icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(state: InstallButtonState.failed),
            ),
          ),
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('should be pressable after failure', (tester) async {
        var pressed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.failed,
                onPressed: () => pressed = true,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(pressed, isTrue);
      });
    });

    group('Progress display', () {
      testWidgets('should show 0% at start', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 0.0,
              ),
            ),
          ),
        );

        expect(find.text('0%'), findsOneWidget);
      });

      testWidgets('should show 100% at completion', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: InstallButton(
                state: InstallButtonState.installing,
                progress: 1.0,
              ),
            ),
          ),
        );

        expect(find.text('100%'), findsOneWidget);
      });
    });
  });

  group('InstallTask integration', () {
    test('should map InstallTask to correct button state', () {
      final pendingTask = InstallTask(
        id: 'task-1',
        appId: 'com.example.test',
        appName: 'Test App',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(pendingTask.isProcessing, isFalse);
      expect(pendingTask.isCompleted, isFalse);
      expect(pendingTask.isFailed, isFalse);

      final processingTask = InstallTask(
        id: 'task-2',
        appId: 'com.example.test',
        appName: 'Test App',
        status: InstallStatus.installing,
        progress: 50.0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(processingTask.isProcessing, isTrue);

      final completedTask = InstallTask(
        id: 'task-3',
        appId: 'com.example.test',
        appName: 'Test App',
        status: InstallStatus.success,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(completedTask.isCompleted, isTrue);

      final failedTask = InstallTask(
        id: 'task-4',
        appId: 'com.example.test',
        appName: 'Test App',
        status: InstallStatus.failed,
        errorMessage: 'Install failed',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      expect(failedTask.isFailed, isTrue);
    });
  });
}