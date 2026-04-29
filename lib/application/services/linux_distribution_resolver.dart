import '../../domain/models/linux_distribution.dart';

/// Linux 发行版识别器。
///
/// 统一负责把 `/etc/os-release` 解析结果收敛为结构化发行版画像，
/// 避免各页面/Provider 继续维护零散的 `isUos` / `isDeepin` 条件判断。
class LinuxDistributionResolver {
  const LinuxDistributionResolver();

  /// 所有“已知需要特殊适配的发行版”都集中注册在这里。
  ///
  /// 维护约定：
  /// - 识别规则优先收敛到 resolver，不要在业务层直接读 `/etc/os-release`；
  /// - distribution 画像来自 `linux_distribution.dart`，这里仅负责匹配；
  /// - 如果某发行版未来不再需要特殊适配，只需移除对应 matcher / 画像映射。
  static const List<_LinuxDistributionMatcher> _matchers = <
    _LinuxDistributionMatcher
  >[
    _LinuxDistributionMatcher(
      distribution: LinuxDistribution.uos,
      aliases: <String>['uos', 'uniontech', 'union tech'],
    ),
  ];

  LinuxDistribution resolve(Map<String, String>? osRelease) {
    if (osRelease == null || osRelease.isEmpty) {
      return LinuxDistribution.unknown;
    }

    // 先匹配“已知需要特殊适配”的发行版，命中后返回带能力标签的画像；
    // 未命中时仍尽量保留 displayName，方便诊断和未来扩展，但不附加任何特殊能力。
    final candidates = _buildNormalizedCandidates(osRelease);
    for (final matcher in _matchers) {
      if (!matcher.matches(candidates)) {
        continue;
      }

      final displayName = _resolveDisplayName(
        osRelease,
        fallback: matcher.distribution.displayName,
      );

      return matcher.distribution.copyWith(
        displayName: displayName ?? matcher.distribution.displayName,
      );
    }

    final displayName = _resolveDisplayName(osRelease);
    if (displayName == null || displayName.isEmpty) {
      return LinuxDistribution.unknown;
    }

    return LinuxDistribution(displayName: displayName);
  }

  List<String> _buildNormalizedCandidates(Map<String, String> osRelease) {
    return <String?>[
          osRelease['ID'],
          osRelease['NAME'],
          osRelease['PRETTY_NAME'],
          osRelease['ID_LIKE'],
          osRelease['VERSION'],
          osRelease['VERSION_ID'],
        ]
        .whereType<String>()
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  String? _resolveDisplayName(
    Map<String, String> osRelease, {
    String? fallback,
  }) {
    final prettyName = osRelease['PRETTY_NAME']?.trim();
    if (prettyName != null && prettyName.isNotEmpty) {
      return prettyName;
    }

    final name = osRelease['NAME']?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    return fallback;
  }
}

class _LinuxDistributionMatcher {
  const _LinuxDistributionMatcher({
    required this.distribution,
    required this.aliases,
  });

  final LinuxDistribution distribution;
  final List<String> aliases;

  /// 当前匹配策略刻意保持“宽松包含匹配”，
  /// 以兼容 `/etc/os-release` 中 `ID / NAME / PRETTY_NAME / ID_LIKE` 的不同写法。
  /// 如果以后引入更复杂的匹配逻辑，也应继续收敛在这里，而不是让上层感知解析细节。
  bool matches(Iterable<String> candidates) {
    for (final candidate in candidates) {
      for (final alias in aliases) {
        if (candidate.contains(alias)) {
          return true;
        }
      }
    }
    return false;
  }
}