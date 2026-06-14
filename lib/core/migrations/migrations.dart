import 'package:app_data_migrations/app_data_migrations.dart';

/// 玲珑应用商店的迁移注册表。
///
/// **新增 V 脚本流程**：
/// 1. 在 `scripts/` 目录创建 `v00X_xxx.dart`
/// 2. 在下方列表末尾追加一行
/// 3. commit
///
/// **铁律**：
/// - id 一旦发布永不复用、永不修改、永不删除
/// - V 脚本要保证幂等
const List<Migration> appMigrations = <Migration>[
  // 首版暂无迁移，保持空列表
];
