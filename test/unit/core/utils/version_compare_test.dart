import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/utils/version_compare.dart';

void main() {
  group('VersionCompare', () {
    group('compare', () {
      test('should return 0 for equal versions', () {
        expect(VersionCompare.compare('1.0.0', '1.0.0'), equals(0));
        expect(VersionCompare.compare('2.5.3', '2.5.3'), equals(0));
        expect(VersionCompare.compare('0.0.1', '0.0.1'), equals(0));
      });

      test('should return negative when first version is smaller', () {
        expect(VersionCompare.compare('1.0.0', '1.0.1'), lessThan(0));
        expect(VersionCompare.compare('1.0.0', '1.1.0'), lessThan(0));
        expect(VersionCompare.compare('1.0.0', '2.0.0'), lessThan(0));
        expect(VersionCompare.compare('1.2.3', '1.2.4'), lessThan(0));
      });

      test('should return positive when first version is larger', () {
        expect(VersionCompare.compare('1.0.1', '1.0.0'), greaterThan(0));
        expect(VersionCompare.compare('1.1.0', '1.0.0'), greaterThan(0));
        expect(VersionCompare.compare('2.0.0', '1.0.0'), greaterThan(0));
        expect(VersionCompare.compare('1.2.4', '1.2.3'), greaterThan(0));
      });

      test('should handle versions with different number of parts', () {
        // 短版本用 0 填充
        expect(VersionCompare.compare('1.0', '1.0.0'), equals(0));
        expect(VersionCompare.compare('1', '1.0.0'), equals(0));
        expect(VersionCompare.compare('1.0.0.0', '1.0.0'), equals(0));
        expect(VersionCompare.compare('1.0.0.1', '1.0.0'), greaterThan(0));
      });

      test('should handle complex version comparisons', () {
        expect(VersionCompare.compare('1.2.3', '1.2.4'), lessThan(0));
        expect(VersionCompare.compare('2.0.0', '1.9.9'), greaterThan(0));
        expect(VersionCompare.compare('1.10.0', '1.9.9'), greaterThan(0));
        expect(VersionCompare.compare('1.0.10', '1.0.9'), greaterThan(0));
      });

      test('should handle versions with zeros correctly', () {
        expect(VersionCompare.compare('0.0.1', '0.0.0'), greaterThan(0));
        expect(VersionCompare.compare('0.1.0', '0.0.1'), greaterThan(0));
        expect(VersionCompare.compare('1.0.0', '0.9.9'), greaterThan(0));
      });

      test('should handle non-numeric parts gracefully', () {
        // 非数字部分会被解析为 0
        expect(VersionCompare.compare('1.a.0', '1.0.0'), equals(0));
        expect(VersionCompare.compare('1.x', '1.y'), equals(0));
      });
    });

    group('greaterThan', () {
      test('should return true when first version is greater', () {
        expect(VersionCompare.greaterThan('2.0.0', '1.0.0'), isTrue);
        expect(VersionCompare.greaterThan('1.1.0', '1.0.0'), isTrue);
        expect(VersionCompare.greaterThan('1.0.1', '1.0.0'), isTrue);
      });

      test('should return false when versions are equal', () {
        expect(VersionCompare.greaterThan('1.0.0', '1.0.0'), isFalse);
      });

      test('should return false when first version is smaller', () {
        expect(VersionCompare.greaterThan('1.0.0', '2.0.0'), isFalse);
        expect(VersionCompare.greaterThan('1.0.0', '1.1.0'), isFalse);
      });
    });

    group('greaterThanOrEqual', () {
      test('should return true when first version is greater', () {
        expect(VersionCompare.greaterThanOrEqual('2.0.0', '1.0.0'), isTrue);
      });

      test('should return true when versions are equal', () {
        expect(VersionCompare.greaterThanOrEqual('1.0.0', '1.0.0'), isTrue);
      });

      test('should return false when first version is smaller', () {
        expect(VersionCompare.greaterThanOrEqual('1.0.0', '2.0.0'), isFalse);
      });
    });

    group('lessThan', () {
      test('should return true when first version is smaller', () {
        expect(VersionCompare.lessThan('1.0.0', '2.0.0'), isTrue);
        expect(VersionCompare.lessThan('1.0.0', '1.1.0'), isTrue);
        expect(VersionCompare.lessThan('1.0.0', '1.0.1'), isTrue);
      });

      test('should return false when versions are equal', () {
        expect(VersionCompare.lessThan('1.0.0', '1.0.0'), isFalse);
      });

      test('should return false when first version is greater', () {
        expect(VersionCompare.lessThan('2.0.0', '1.0.0'), isFalse);
      });
    });

    group('lessThanOrEqual', () {
      test('should return true when first version is smaller', () {
        expect(VersionCompare.lessThanOrEqual('1.0.0', '2.0.0'), isTrue);
      });

      test('should return true when versions are equal', () {
        expect(VersionCompare.lessThanOrEqual('1.0.0', '1.0.0'), isTrue);
      });

      test('should return false when first version is greater', () {
        expect(VersionCompare.lessThanOrEqual('2.0.0', '1.0.0'), isFalse);
      });
    });

    group('real world scenarios', () {
      test('should correctly compare typical app versions', () {
        // 真实应用版本比较场景
        expect(VersionCompare.compare('3.0.0', '2.9.9'), greaterThan(0));
        expect(VersionCompare.compare('1.0.0', '1.0.0-beta'), greaterThan(0));
        expect(VersionCompare.compare('4.2.1', '4.2.0'), greaterThan(0));
      });

      test('should handle update detection scenario', () {
        const currentVersion = '1.2.3';
        const remoteVersion = '1.2.4';

        // 远程版本更高，需要更新
        expect(VersionCompare.lessThan(currentVersion, remoteVersion), isTrue);
      });
    });
  });
}