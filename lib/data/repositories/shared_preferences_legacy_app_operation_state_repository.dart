/// 读取并清理旧版 SharedPreferences 应用操作队列。
///
/// 该适配器仅为一次性迁移保留；当前队列的唯一持久化位置是 XDG State Journal，
/// 禁止通过本类新增写入旧 key 的行为。
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/install_queue_state.dart';
import '../../domain/models/install_task.dart';
import '../../domain/repositories/legacy_app_operation_state_repository.dart';

/// 旧版 SharedPreferences 中保存当前任务的 key。
const String legacyCurrentInstallTaskPreferenceKey =
    'linglong-store-current-install-task';

/// 旧版 SharedPreferences 中保存等待队列的 key。
const String legacyInstallQueuePreferenceKey = 'linglong-store-install-queue';

/// SharedPreferences 旧队列读取适配器。
class SharedPreferencesLegacyAppOperationStateRepository
    implements LegacyAppOperationStateRepository {
  /// 创建只读迁移适配器。
  const SharedPreferencesLegacyAppOperationStateRepository(
    SharedPreferences preferences,
  ) : _preferences = preferences;

  /// 仅用于读取和清理历史 key 的偏好存储。
  final SharedPreferences _preferences;

  @override
  InstallQueueState load() {
    final currentTaskJson = _preferences.getString(
      legacyCurrentInstallTaskPreferenceKey,
    );
    final queueJson = _preferences.getString(legacyInstallQueuePreferenceKey);
    return InstallQueueState(
      currentTask: currentTaskJson == null
          ? null
          : InstallTask.fromJson(
              jsonDecode(currentTaskJson) as Map<String, dynamic>,
            ),
      queue: queueJson == null
          ? const <InstallTask>[]
          : (jsonDecode(queueJson) as List<dynamic>)
                .map(
                  (item) => InstallTask.fromJson(item as Map<String, dynamic>),
                )
                .toList(),
    );
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(legacyCurrentInstallTaskPreferenceKey);
    await _preferences.remove(legacyInstallQueuePreferenceKey);
  }
}
