import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:linglong_store/core/utils/format_utils.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';

void main() {
  group('FormatUtils', () {
    group('formatFileSize', () {
      test('should return bytes when size is less than 1KB', () {
        expect(FormatUtils.formatFileSize(0), equals('0 B'));
        expect(FormatUtils.formatFileSize(512), equals('512 B'));
        expect(FormatUtils.formatFileSize(1023), equals('1023 B'));
      });

      test('should return KB when size is between 1KB and 1MB', () {
        expect(FormatUtils.formatFileSize(1024), equals('1.0 KB'));
        expect(FormatUtils.formatFileSize(1536), equals('1.5 KB'));
        expect(FormatUtils.formatFileSize(1024 * 512), equals('512.0 KB'));
        expect(FormatUtils.formatFileSize(1024 * 1023), equals('1023.0 KB'));
      });

      test('should return MB when size is between 1MB and 1GB', () {
        expect(FormatUtils.formatFileSize(1024 * 1024), equals('1.0 MB'));
        expect(
          FormatUtils.formatFileSize((1024 * 1024 * 1.5).toInt()),
          equals('1.5 MB'),
        );
        expect(
          FormatUtils.formatFileSize(1024 * 1024 * 512),
          equals('512.0 MB'),
        );
        expect(
          FormatUtils.formatFileSize(1024 * 1024 * 1023),
          equals('1023.0 MB'),
        );
      });

      test('should return GB when size is greater than 1GB', () {
        expect(
          FormatUtils.formatFileSize(1024 * 1024 * 1024),
          equals('1.0 GB'),
        );
        expect(
          FormatUtils.formatFileSize((1024 * 1024 * 1024 * 2.5).toInt()),
          equals('2.5 GB'),
        );
        expect(
          FormatUtils.formatFileSize(1024 * 1024 * 1024 * 100),
          equals('100.0 GB'),
        );
      });

      test('should handle edge cases correctly', () {
        // 边界值测试
        expect(FormatUtils.formatFileSize(1023), equals('1023 B'));
        expect(FormatUtils.formatFileSize(1024), equals('1.0 KB'));
        expect(
          FormatUtils.formatFileSize(1024 * 1024 - 1),
          equals('1024.0 KB'),
        );
        expect(FormatUtils.formatFileSize(1024 * 1024), equals('1.0 MB'));
      });
    });

    group('formatFileSizeValue', () {
      test('should format string byte values with human readable units', () {
        expect(
          FormatUtils.formatFileSizeValue('759577252'),
          equals('724.39 MB'),
        );
        expect(
          FormatUtils.formatFileSizeValue('1073741824'),
          equals('1.00 GB'),
        );
      });

      test(
        'should return KB for values smaller than 1MB to match Rust app',
        () {
          expect(FormatUtils.formatFileSizeValue(512), equals('0.50 KB'));
          expect(FormatUtils.formatFileSizeValue('1023'), equals('1.00 KB'));
        },
      );

      test('should return placeholder for null empty or invalid values', () {
        expect(FormatUtils.formatFileSizeValue(null), equals('--'));
        expect(FormatUtils.formatFileSizeValue(''), equals('--'));
        expect(FormatUtils.formatFileSizeValue('  '), equals('--'));
        expect(FormatUtils.formatFileSizeValue('invalid'), equals('--'));
      });

      test('should accept numeric inputs directly', () {
        expect(FormatUtils.formatFileSizeValue(1024 * 1024), equals('1.00 MB'));
        expect(
          FormatUtils.formatFileSizeValue(2.5 * 1024 * 1024 * 1024),
          equals('2.50 GB'),
        );
      });
    });

    group('formatDownloadCount', () {
      test('should return original number when count is less than 1000', () {
        expect(FormatUtils.formatDownloadCount(0), equals('0'));
        expect(FormatUtils.formatDownloadCount(999), equals('999'));
      });

      test('should return k format when count is between 1000 and 9999', () {
        expect(FormatUtils.formatDownloadCount(1000), equals('1.0k'));
        expect(FormatUtils.formatDownloadCount(1500), equals('1.5k'));
        expect(FormatUtils.formatDownloadCount(9999), equals('10.0k'));
      });

      test(
        'should return Chinese wan format when count is between 10000 and 99999999',
        () {
          expect(FormatUtils.formatDownloadCount(10000), equals('1.0万'));
          expect(FormatUtils.formatDownloadCount(50000), equals('5.0万'));
          expect(FormatUtils.formatDownloadCount(100000), equals('10.0万'));
          expect(FormatUtils.formatDownloadCount(99999999), equals('10000.0万'));
        },
      );

      test(
        'should return Chinese yi format when count is greater than 100000000',
        () {
          expect(FormatUtils.formatDownloadCount(100000000), equals('1.0亿'));
          expect(FormatUtils.formatDownloadCount(500000000), equals('5.0亿'));
          expect(FormatUtils.formatDownloadCount(1000000000), equals('10.0亿'));
        },
      );

      test('should handle typical app download counts', () {
        expect(FormatUtils.formatDownloadCount(500), equals('500'));
        expect(FormatUtils.formatDownloadCount(5000), equals('5.0k'));
        expect(FormatUtils.formatDownloadCount(50000), equals('5.0万'));
        expect(FormatUtils.formatDownloadCount(500000), equals('50.0万'));
        expect(FormatUtils.formatDownloadCount(5000000), equals('500.0万'));
        expect(FormatUtils.formatDownloadCount(50000000), equals('5000.0万'));
        expect(FormatUtils.formatDownloadCount(500000000), equals('5.0亿'));
      });
    });

    group('formatSpeed', () {
      test('should return B/s when speed is less than 1KB/s', () {
        expect(FormatUtils.formatSpeed(0), equals('0 B/s'));
        expect(FormatUtils.formatSpeed(512), equals('512 B/s'));
        expect(FormatUtils.formatSpeed(1023), equals('1023 B/s'));
      });

      test('should return KB/s when speed is between 1KB/s and 1MB/s', () {
        expect(FormatUtils.formatSpeed(1024), equals('1.0 KB/s'));
        expect(FormatUtils.formatSpeed(1024 * 100), equals('100.0 KB/s'));
        expect(FormatUtils.formatSpeed(1024 * 512), equals('512.0 KB/s'));
      });

      test('should return MB/s when speed is between 1MB/s and 1GB/s', () {
        expect(FormatUtils.formatSpeed(1024 * 1024), equals('1.0 MB/s'));
        expect(FormatUtils.formatSpeed(1024 * 1024 * 10), equals('10.0 MB/s'));
        expect(
          FormatUtils.formatSpeed(1024 * 1024 * 100),
          equals('100.0 MB/s'),
        );
      });

      test('should return GB/s when speed is greater than 1GB/s', () {
        expect(FormatUtils.formatSpeed(1024 * 1024 * 1024), equals('1.0 GB/s'));
        expect(
          FormatUtils.formatSpeed(1024 * 1024 * 1024 * 10),
          equals('10.0 GB/s'),
        );
      });

      test('should format typical network speeds correctly', () {
        // 模拟常见下载速度
        expect(
          FormatUtils.formatSpeed(1024 * 50),
          equals('50.0 KB/s'),
        ); // 50KB/s
        expect(
          FormatUtils.formatSpeed(1024 * 500),
          equals('500.0 KB/s'),
        ); // 500KB/s
        expect(
          FormatUtils.formatSpeed(1024 * 1024 * 1),
          equals('1.0 MB/s'),
        ); // 1MB/s
        expect(
          FormatUtils.formatSpeed(1024 * 1024 * 5),
          equals('5.0 MB/s'),
        ); // 5MB/s
      });
    });
  });

  group('formatRelativeTime', () {
    testWidgets('小于24小时显示小时数', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final now = DateTime.now();
            final createTime = now.subtract(const Duration(hours: 5)).toIso8601String();
            final result = formatRelativeTime(createTime, l10n);
            expect(result, contains('5小时前上架'));
            return const SizedBox();
          },
        ),
      ));
    });

    testWidgets('小于7天显示天数', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final now = DateTime.now();
            final createTime = now.subtract(const Duration(days: 3)).toIso8601String();
            final result = formatRelativeTime(createTime, l10n);
            expect(result, contains('3天前上架'));
            return const SizedBox();
          },
        ),
      ));
    });

    testWidgets('超过7天显示完整日期', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final createTime = DateTime(2026, 4, 1, 10, 30).toIso8601String();
            final result = formatRelativeTime(createTime, l10n);
            expect(result, contains('2026-04-01上架'));
            return const SizedBox();
          },
        ),
      ));
    });

    testWidgets('null返回空字符串', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final result = formatRelativeTime(null, l10n);
            expect(result, '');
            return const SizedBox();
          },
        ),
      ));
    });
  });

  group('formatDownloadCountText', () {
    testWidgets('正常数值显示千位分隔符', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final result = formatDownloadCountText(12345, l10n);
            expect(result, '下载 12,345次');
            return const SizedBox();
          },
        ),
      ));
    });

    testWidgets('null或0返回空字符串', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            expect(formatDownloadCountText(null, l10n), '');
            expect(formatDownloadCountText(0, l10n), '');
            return const SizedBox();
          },
        ),
      ));
    });
  });
}
