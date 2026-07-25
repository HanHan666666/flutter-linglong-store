/// 应用持续忽略更新的内存状态与持久化协调。
///
/// Provider 是忽略记录的单一事实来源：同步恢复本地快照、串行执行写入，
/// 并向更新检查和管理弹窗提供不可变列表及 O(1) appId 索引。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import '../../core/storage/ignored_update_storage.dart';
import '../../domain/models/ignored_update.dart';
import 'install_queue_provider.dart' show sharedPreferencesProvider;

/// 忽略更新本地存储 Provider。
///
/// 正式运行时使用应用入口注入的 SharedPreferences；未注入的轻量 Widget
/// 测试使用不可写空存储，避免无关测试因基础设施缺失而失败。
final ignoredUpdateStorageProvider = Provider<IgnoredUpdateStorage>((ref) {
  try {
    return SharedPreferencesIgnoredUpdateStorage(
      ref.watch(sharedPreferencesProvider),
    );
  } catch (_) {
    // Riverpod 会包装未注入 Provider 抛出的异常；该兜底仅兼容轻量 Widget
    // 测试，正式应用由 main 在 runApp 前完成 SharedPreferences 注入。
    return const _UnavailableIgnoredUpdateStorage();
  }
});

/// 忽略更新状态 Provider，跨页面和启动流程保持常驻。
final ignoredUpdatesProvider =
    NotifierProvider<IgnoredUpdates, IgnoredUpdatesState>(IgnoredUpdates.new);

/// 已忽略应用数量，只在数量变化时通知头部入口重建。
final ignoredUpdatesCountProvider = Provider<int>((ref) {
  return ref.watch(ignoredUpdatesProvider.select((state) => state.count));
});

/// 忽略更新不可变状态。
class IgnoredUpdatesState {
  /// 创建空状态。
  const IgnoredUpdatesState.empty()
    : records = const <IgnoredUpdate>[],
      appIds = const <String>{};

  /// 从已经校验和去重的记录创建状态。
  IgnoredUpdatesState.fromRecords(List<IgnoredUpdate> sourceRecords)
    : records = List<IgnoredUpdate>.unmodifiable(_sortRecords(sourceRecords)),
      appIds = Set<String>.unmodifiable(
        sourceRecords.map((record) => record.appId),
      );

  /// 按忽略时间倒序排列的只读记录。
  final List<IgnoredUpdate> records;

  /// 用于更新检查快速过滤的只读 appId 集合。
  final Set<String> appIds;

  /// 已忽略应用数量。
  int get count => records.length;

  /// 判断指定应用是否处于持续忽略状态。
  bool contains(String appId) => appIds.contains(appId);

  /// 使用领域模型的统一比较规则创建排序副本，避免修改调用方列表。
  static List<IgnoredUpdate> _sortRecords(List<IgnoredUpdate> records) {
    return List<IgnoredUpdate>.from(records)
      ..sort(IgnoredUpdate.compareForDisplay);
  }
}

/// 忽略更新状态控制器。
class IgnoredUpdates extends Notifier<IgnoredUpdatesState> {
  /// 串行写入尾部，防止多个完整快照并行写入后互相覆盖。
  Future<void> _mutationTail = Future<void>.value();

  /// 当前使用的本地存储，由 Provider 统一注入。
  late IgnoredUpdateStorage _storage;

  @override
  IgnoredUpdatesState build() {
    _storage = ref.read(ignoredUpdateStorageProvider);
    final records = _storage.load();
    return records.isEmpty
        ? const IgnoredUpdatesState.empty()
        : IgnoredUpdatesState.fromRecords(records);
  }

  /// 持续忽略指定应用。
  ///
  /// 重复忽略按 appId 幂等处理；只有完整快照写入成功后才发布新状态。
  Future<bool> ignore(IgnoredUpdate record) {
    return _enqueueMutation('ignore', () async {
      // 无有效身份的记录无法稳定过滤或恢复，禁止进入持久化状态。
      if (record.appId.trim().isEmpty) {
        return false;
      }
      if (state.contains(record.appId)) {
        return true;
      }

      final nextRecords = <IgnoredUpdate>[record, ...state.records];
      final saved = await _storage.save(nextRecords);
      if (!saved) {
        return false;
      }

      state = IgnoredUpdatesState.fromRecords(nextRecords);
      return true;
    });
  }

  /// 恢复指定应用的更新提醒。
  ///
  /// 记录不存在时按幂等成功处理；写入失败时保留原状态。
  Future<bool> restore(String appId) {
    return _enqueueMutation('restore', () async {
      if (!state.contains(appId)) {
        return true;
      }

      final nextRecords = state.records
          .where((record) => record.appId != appId)
          .toList();
      final saved = await _storage.save(nextRecords);
      if (!saved) {
        return false;
      }

      state = nextRecords.isEmpty
          ? const IgnoredUpdatesState.empty()
          : IgnoredUpdatesState.fromRecords(nextRecords);
      return true;
    });
  }

  /// 把状态变更排入单一写入队列，并统一收敛异常为失败结果。
  Future<bool> _enqueueMutation(
    String operation,
    Future<bool> Function() mutation,
  ) {
    final completer = Completer<bool>();
    _mutationTail = _mutationTail.then((_) async {
      try {
        completer.complete(await mutation());
      } catch (error, stackTrace) {
        AppLogger.error(
          'Ignored update $operation mutation failed',
          error,
          stackTrace,
        );
        completer.complete(false);
      }
    });
    return completer.future;
  }
}

/// SharedPreferences 未注入时使用的只读空存储。
///
/// 该兜底只服务轻量测试和异常启动环境；正式应用始终由 main 注入真实实例。
class _UnavailableIgnoredUpdateStorage implements IgnoredUpdateStorage {
  /// 创建不可写空存储。
  const _UnavailableIgnoredUpdateStorage();

  @override
  List<IgnoredUpdate> load() => const <IgnoredUpdate>[];

  @override
  Future<bool> save(List<IgnoredUpdate> records) async => false;
}
