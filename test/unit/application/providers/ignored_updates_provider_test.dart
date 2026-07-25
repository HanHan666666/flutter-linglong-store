import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/ignored_updates_provider.dart';
import 'package:linglong_store/core/storage/ignored_update_storage.dart';
import 'package:linglong_store/domain/models/ignored_update.dart';

void main() {
  group('IgnoredUpdates', () {
    test('restores persisted records synchronously on first read', () {
      final storage = _MemoryIgnoredUpdateStorage(
        initialRecords: const [
          IgnoredUpdate(
            appId: 'org.example.demo',
            appName: 'Demo',
            ignoredVersion: '1.0.0',
            ignoredAt: 100,
          ),
        ],
      );
      final container = _createContainer(storage);
      addTearDown(container.dispose);

      final state = container.read(ignoredUpdatesProvider);

      expect(state.count, 1);
      expect(state.contains('org.example.demo'), isTrue);
      expect(container.read(ignoredUpdatesCountProvider), 1);
    });

    test('keeps state unchanged when persistence fails', () async {
      final storage = _MemoryIgnoredUpdateStorage(shouldSave: false);
      final container = _createContainer(storage);
      addTearDown(container.dispose);

      final saved = await container
          .read(ignoredUpdatesProvider.notifier)
          .ignore(_demoRecord);

      expect(saved, isFalse);
      expect(container.read(ignoredUpdatesProvider).records, isEmpty);
    });

    test('serializes rapid restores without losing either change', () async {
      final storage = _MemoryIgnoredUpdateStorage(
        initialRecords: const [_demoRecord, _otherRecord],
        saveDelay: const Duration(milliseconds: 10),
      );
      final container = _createContainer(storage);
      addTearDown(container.dispose);

      final notifier = container.read(ignoredUpdatesProvider.notifier);
      final results = await Future.wait([
        notifier.restore(_demoRecord.appId),
        notifier.restore(_otherRecord.appId),
      ]);

      expect(results, everyElement(isTrue));
      expect(container.read(ignoredUpdatesProvider).records, isEmpty);
      expect(
        storage.savedSnapshots
            .map((snapshot) => snapshot.map((record) => record.appId).toList())
            .toList(),
        [
          [_otherRecord.appId],
          <String>[],
        ],
      );
    });

    test('persists across provider container recreation', () async {
      final storage = _MemoryIgnoredUpdateStorage();
      final firstContainer = _createContainer(storage);

      expect(
        await firstContainer
            .read(ignoredUpdatesProvider.notifier)
            .ignore(_demoRecord),
        isTrue,
      );
      firstContainer.dispose();

      final secondContainer = _createContainer(storage);
      addTearDown(secondContainer.dispose);

      expect(
        secondContainer
            .read(ignoredUpdatesProvider)
            .contains(_demoRecord.appId),
        isTrue,
      );
    });

    test('keeps repeated ignore and restore operations idempotent', () async {
      final storage = _MemoryIgnoredUpdateStorage();
      final container = _createContainer(storage);
      addTearDown(container.dispose);
      final notifier = container.read(ignoredUpdatesProvider.notifier);

      expect(await notifier.ignore(_demoRecord), isTrue);
      expect(await notifier.ignore(_demoRecord), isTrue);
      expect(container.read(ignoredUpdatesProvider).count, 1);

      expect(await notifier.restore(_demoRecord.appId), isTrue);
      expect(await notifier.restore(_demoRecord.appId), isTrue);
      expect(container.read(ignoredUpdatesProvider).records, isEmpty);
      expect(storage.savedSnapshots, hasLength(2));
    });
  });
}

const IgnoredUpdate _demoRecord = IgnoredUpdate(
  appId: 'org.example.demo',
  appName: 'Demo',
  ignoredVersion: '1.0.0',
  ignoredAt: 200,
);

const IgnoredUpdate _otherRecord = IgnoredUpdate(
  appId: 'org.example.other',
  appName: 'Other',
  ignoredVersion: '2.0.0',
  ignoredAt: 100,
);

ProviderContainer _createContainer(IgnoredUpdateStorage storage) {
  return ProviderContainer(
    overrides: [ignoredUpdateStorageProvider.overrideWithValue(storage)],
  );
}

/// 模拟可配置写入结果和延迟的测试存储。
class _MemoryIgnoredUpdateStorage implements IgnoredUpdateStorage {
  /// 创建带可选初始快照、写入结果和延迟的内存存储。
  _MemoryIgnoredUpdateStorage({
    List<IgnoredUpdate> initialRecords = const <IgnoredUpdate>[],
    this.shouldSave = true,
    this.saveDelay = Duration.zero,
  }) : _records = List<IgnoredUpdate>.from(initialRecords);

  /// 当前已经成功保存的记录。
  List<IgnoredUpdate> _records;

  /// 是否允许本次测试中的持久化操作成功。
  final bool shouldSave;

  /// 用于复现并发写入竞态的模拟延迟。
  final Duration saveDelay;

  /// 每次成功写入的完整快照，用于验证串行化顺序。
  final List<List<IgnoredUpdate>> savedSnapshots = <List<IgnoredUpdate>>[];

  @override
  List<IgnoredUpdate> load() => List<IgnoredUpdate>.from(_records);

  @override
  Future<bool> save(List<IgnoredUpdate> records) async {
    if (saveDelay > Duration.zero) {
      await Future<void>.delayed(saveDelay);
    }
    if (!shouldSave) {
      return false;
    }
    final snapshot = List<IgnoredUpdate>.from(records);
    savedSnapshots.add(snapshot);
    _records = snapshot;
    return true;
  }
}
