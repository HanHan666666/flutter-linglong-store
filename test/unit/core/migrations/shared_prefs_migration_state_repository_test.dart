import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_data_migrations/app_data_migrations.dart';

import 'package:linglong_store/core/migrations/shared_prefs_migration_state_repository.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('初始无 applied', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsMigrationStateRepository(prefs);
    expect(await repo.loadApplied(), isEmpty);
  });

  test('markApplied 后能读到', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsMigrationStateRepository(prefs);
    await repo.markApplied('v001');
    await repo.markApplied('v002');
    final applied = await repo.loadApplied();
    expect(applied, containsAll(['v001', 'v002']));
    expect(applied.length, 2);
  });

  test('markApplied 幂等', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = SharedPrefsMigrationStateRepository(prefs);
    await repo.markApplied('v001');
    await repo.markApplied('v001');
    expect((await repo.loadApplied()).length, 1);
  });

  test('实现接口 MigrationStateRepository', () async {
    final prefs = await SharedPreferences.getInstance();
    expect(
      SharedPrefsMigrationStateRepository(prefs),
      isA<MigrationStateRepository>(),
    );
  });
}
