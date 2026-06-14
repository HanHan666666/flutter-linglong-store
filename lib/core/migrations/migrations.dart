import 'package:app_data_migrations/app_data_migrations.dart';

import 'scripts/v001_migrate_legacy_data_directory.dart';

/// 玲珑应用商店的迁移注册表。
///
/// **新增 V 脚本流程**：
/// 1. 在 `scripts/` 目录创建 `v00X_xxx.dart`
/// 2. 在下方列表末尾追加一行
/// 3. commit
///
/// **铁律**：
/// - id 一旦发布永不复用、永不修改、永不删除
/// - V 脚本必须幂等（详见 `app_data_migrations` 仓库的
///   `doc/03-迁移脚本编写指南.md#v-脚本-review-checklist`）
final List<Migration> appMigrations = <Migration>[
  // v001：把旧 application-id 数据目录迁移到当前目录。
  // 必须排在所有依赖应用数据目录的服务初始化之前执行。
  V001MigrateLegacyDataDirectory(),
];
