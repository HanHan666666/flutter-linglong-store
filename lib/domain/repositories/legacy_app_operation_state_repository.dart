/// 定义旧版应用操作状态的迁移读取端口。
///
/// 该端口只服务从 SharedPreferences 队列迁移到 XDG Journal；新业务不得继续
/// 写入旧存储，迁移完成后应清除旧事实。
library;

import '../models/install_queue_state.dart';

/// 旧版应用操作状态仓储。
abstract class LegacyAppOperationStateRepository {
  /// 读取旧队列；不存在任何旧事实时返回空状态。
  InstallQueueState load();

  /// 在新 Journal 已可靠落盘后清除旧事实。
  Future<void> clear();
}
