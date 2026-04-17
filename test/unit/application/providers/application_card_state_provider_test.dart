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
      );

      expect(state.buttonState, InstallButtonState.update);
      expect(state.isInstalled, isTrue);
      expect(state.hasUpdate, isTrue);
    });

    test(
      'returns update when app is in update set',
      () {
        const index = ApplicationCardStateIndex(
          installedVersionByAppId: {'org.example.app': '1.0.0'},
          updateAppIds: {'org.example.app'},
          activeTasksByAppId: {},
        );

        final state = index.resolve(
          appId: 'org.example.app',
        );

        expect(state.buttonState, InstallButtonState.update);
        expect(state.hasUpdate, isTrue);
      },
    );

    test('returns pending button state for queued task', () {
      const index = ApplicationCardStateIndex(
        installedVersionByAppId: {},
        updateAppIds: {},
        activeTasksByAppId: {
          'org.example.app': InstallTask(
            id: 'task-pending',
            appId: 'org.example.app',
            appName: 'Example',
            status: InstallStatus.pending,
            createdAt: 1,
          ),
        },
      );

      final resolved = index.resolve(appId: 'org.example.app');

      expect(resolved.buttonState, InstallButtonState.pending);
      expect(resolved.isInstalling, isTrue);
    });

    test('returns installing button state for active download', () {
      const index = ApplicationCardStateIndex(
        installedVersionByAppId: {},
        updateAppIds: {},
        activeTasksByAppId: {
          'org.example.app': InstallTask(
            id: 'task-installing',
            appId: 'org.example.app',
            appName: 'Example',
            status: InstallStatus.installing,
            createdAt: 1,
          ),
        },
      );

      final resolved = index.resolve(appId: 'org.example.app');

      expect(resolved.buttonState, InstallButtonState.installing);
      expect(resolved.isInstalling, isTrue);
    });
  });
}
