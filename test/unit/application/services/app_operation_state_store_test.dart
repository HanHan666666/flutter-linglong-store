import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/app_operation_state_store.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/repositories/shared_preferences_legacy_app_operation_state_repository.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/memory_app_operation_journal_repository.dart';

void main() {
  setUpAll(AppLogger.init);

  test('旧队列落入 Journal 后才删除 SharedPreferences 事实', () async {
    final task = InstallTask(
      id: 'legacy-task',
      appId: 'org.example.legacy',
      appName: 'Legacy App',
      createdAt: DateTime(2026).millisecondsSinceEpoch,
    );
    SharedPreferences.setMockInitialValues({
      legacyCurrentInstallTaskPreferenceKey: jsonEncode(task.toJson()),
      legacyInstallQueuePreferenceKey: jsonEncode(const <Object>[]),
    });
    final preferences = await SharedPreferences.getInstance();
    final journal = MemoryAppOperationJournalRepository();
    final store = AppOperationStateStore(
      journal: journal,
      legacyRepository: SharedPreferencesLegacyAppOperationStateRepository(
        preferences,
      ),
    );

    final result = store.restore();

    expect(result.state.currentTask?.id, task.id);
    expect(result.migrationPersistence, isNotNull);
    await result.migrationPersistence;
    expect(journal.snapshot?.currentTask?.id, task.id);
    expect(
      preferences.containsKey(legacyCurrentInstallTaskPreferenceKey),
      isFalse,
    );
    expect(preferences.containsKey(legacyInstallQueuePreferenceKey), isFalse);
  });
}
