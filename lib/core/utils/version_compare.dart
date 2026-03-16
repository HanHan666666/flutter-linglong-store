/// 版本号比较工具
class VersionCompare {
  VersionCompare._();

  /// 比较两个版本号
  /// 返回值：<0 表示 a < b, 0 表示相等, >0 表示 a > b
  static int compare(String a, String b) {
    final partsA = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final partsB = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < maxLen; i++) {
      final numA = i < partsA.length ? partsA[i] : 0;
      final numB = i < partsB.length ? partsB[i] : 0;

      if (numA != numB) {
        return numA.compareTo(numB);
      }
    }

    final hasPrereleaseA = a.contains('-');
    final hasPrereleaseB = b.contains('-');
    if (hasPrereleaseA != hasPrereleaseB) {
      return hasPrereleaseA ? -1 : 1;
    }

    return 0;
  }

  /// a > b
  static bool greaterThan(String a, String b) => compare(a, b) > 0;

  /// a >= b
  static bool greaterThanOrEqual(String a, String b) => compare(a, b) >= 0;

  /// a < b
  static bool lessThan(String a, String b) => compare(a, b) < 0;

  /// a <= b
  static bool lessThanOrEqual(String a, String b) => compare(a, b) <= 0;
}