import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/repositories/file_app_operation_journal_repository.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/domain/models/app_operation_batch.dart';
import 'package:linglong_store/domain/models/app_operation_journal_snapshot.dart';

void main() {
  setUpAll(AppLogger.init);

  group('FileAppOperationJournalRepository', () {
    late Directory temporaryDirectory;
    late File journalFile;

    setUp(() {
      temporaryDirectory = Directory.systemTemp.createTempSync(
        'linglong-operation-journal-test-',
      );
      journalFile = File('${temporaryDirectory.path}/operations/queue-v2.json');
    });

    tearDown(() {
      if (temporaryDirectory.existsSync()) {
        temporaryDirectory.deleteSync(recursive: true);
      }
    });

    test('原子保存并恢复版本化操作快照', () async {
      final repository = FileAppOperationJournalRepository(journalFile);
      const snapshot = AppOperationJournalSnapshot(
        batches: [
          AppOperationBatch(
            id: 'batch-1',
            taskIds: [],
            targets: [],
            createdAt: 100,
          ),
        ],
      );

      await repository.save(snapshot);

      final restored = repository.load();
      expect(restored, isNotNull);
      expect(restored!.schemaVersion, 2);
      expect(restored.batches.single.id, 'batch-1');
      expect(
        journalFile.parent
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.tmp'))
            .toList(),
        isEmpty,
      );
    });

    test('损坏快照会保留诊断副本并返回空状态', () {
      journalFile.parent.createSync(recursive: true);
      journalFile.writeAsStringSync('{invalid json');
      final repository = FileAppOperationJournalRepository(journalFile);

      final restored = repository.load();

      expect(restored, const AppOperationJournalSnapshot());
      expect(journalFile.existsSync(), isFalse);
      expect(
        journalFile.parent
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('.corrupt-'))
            .length,
        1,
      );
    });
  });
}
