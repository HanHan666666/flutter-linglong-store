import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/providers/application_card_state_provider.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/presentation/widgets/install_button.dart';

void main() {
  group('ApplicationCardStateIndex', () {
    test('returns open for highest installed version without updates', () {
      const index = ApplicationCardStateIndex(
        installedVersionByAppId: {'org.example.app': '2.0.0'},
        updateAppIds: {},
        activeTasksByAppId: {},
      );

      final state = index.resolve(
        appId: 'org.example.app',
        latestVersion: '2.0.0',
      );

      expect(state.buttonState, InstallButtonState.open);
      expect(state.isInstalled, isTrue);
      expect(state.hasUpdate, isFalse);
      expect(state.isInstalling, isFalse);
    });

    test('returns update when app id exists in update set', () {
      const index = ApplicationCardStateIndex(
        installedVersionByAppId: {'org.example.app': '1.0.0'},
        updateAppIds: {'org.example.app'},
        activeTasksByAppId: {},
      );

      final state = index.resolve(
        appId: 'org.example.app',
        latestVersion: '1.0.0',
      );

      expect(state.buttonState, InstallButtonState.update);
      expect(state.isInstalled, isTrue);
      expect(state.hasUpdate, isTrue);
    });

    test(
      'falls back to remote version comparison when update set is empty',
      () {
        const index = ApplicationCardStateIndex(
          installedVersionByAppId: {'org.example.app': '1.0.0'},
          updateAppIds: {},
          activeTasksByAppId: {},
        );

        final state = index.resolve(
          appId: 'org.example.app',
          latestVersion: '1.2.0',
        );

        expect(state.buttonState, InstallButtonState.update);
        expect(state.hasUpdate, isTrue);
      },
    );

    test(
      'keeps tri-state and exposes installing progress from active task',
      () {
        final installingTask = InstallTask(
          id: 'task-1',
          appId: 'org.example.app',
          appName: 'Example App',
          status: InstallStatus.pending,
          progress: 0.35,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        final index = ApplicationCardStateIndex(
          installedVersionByAppId: const {},
          updateAppIds: const {},
          activeTasksByAppId: {'org.example.app': installingTask},
        );

        final state = index.resolve(
          appId: 'org.example.app',
          latestVersion: '1.0.0',
        );

        expect(state.buttonState, InstallButtonState.notInstalled);
        expect(state.isInstalling, isTrue);
        expect(state.progress, closeTo(0.35, 0.001));
      },
    );
  });
}
