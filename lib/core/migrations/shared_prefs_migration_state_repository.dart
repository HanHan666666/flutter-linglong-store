import 'package:app_data_migrations/app_data_migrations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 基于 [SharedPreferences] 实现的迁移状态仓库。
///
/// 持久化 key：`linglong-store.migration.applied`，
/// 值为 List<String>，记录所有已应用的迁移 id。
class SharedPrefsMigrationStateRepository
    implements MigrationStateRepository {
  SharedPrefsMigrationStateRepository(this._prefs);

  final SharedPreferences _prefs;

  /// 持久化 key，带应用前缀避免与其他配置冲突。
  static const _key = 'linglong-store.migration.applied';

  @override
  Future<List<String>> loadApplied() async {
    return _prefs.getStringList(_key) ?? const <String>[];
  }

  @override
  Future<void> markApplied(String id) async {
    final current = _prefs.getStringList(_key) ?? const <String>[];
    if (current.contains(id)) return;
    await _prefs.setStringList(_key, <String>[...current, id]);
  }
}
