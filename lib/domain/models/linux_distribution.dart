import 'package:freezed_annotation/freezed_annotation.dart';

part 'linux_distribution.freezed.dart';
part 'linux_distribution.g.dart';

/// Linux 发行版标识。
///
/// 用于承载需要特殊提示或特殊适配的发行版画像，
/// 后续新增发行版时优先在这里扩展，而不是在 UI / Provider 中继续散落 `isXxx` 判断。
enum LinuxDistributionId {
  unknown,
  uos,
}

/// 发行版能力标签。
///
/// 这些能力不直接绑定某个页面，而是描述「当前发行版需要哪些特殊提示/适配」。
enum LinuxDistributionCapability {
  envInstallGuidance,
  envInstallRequiresDeveloperMode,
  envInstallRequiresRootPrivilege,
  appInstallFailureGuidance,
  appUpdateFailureGuidance,
}

/// 特殊提示场景。
///
/// 通过场景而不是硬编码页面名，让同一发行版能力可以在多个链路中复用。
enum LinuxDistributionGuidanceScenario {
  envInstallDialog,
  appInstallFailure,
  appUpdateFailure,
}

/// Linux 发行版画像。
///
/// 这是“发行版特殊适配”的单一结构化入口：
/// - resolver 负责识别当前系统并产出画像；
/// - 环境检测结果负责透传画像；
/// - UI / Provider 只基于画像和 scenario 消费，不再新增 `isUos` 之类布尔字段。
///
/// 后续如果要新增某个发行版的特殊提示，优先按这个顺序扩展：
/// 1. 在本文件补充新的发行版标识/能力画像；
/// 2. 在 `LinuxDistributionResolver` 补 matcher；
/// 3. 在 `InstallMessages.guidanceForDistribution()` 补场景到文案的映射；
/// 4. 补对应测试。
@freezed
sealed class LinuxDistribution with _$LinuxDistribution {
  const LinuxDistribution._();

  const factory LinuxDistribution({
    @Default(LinuxDistributionId.unknown) LinuxDistributionId id,
    @Default('') String displayName,
    /// 能力标签只描述“这个发行版在哪些业务场景需要特殊处理”，
    /// 不直接绑定某个页面实现，避免 UI 和 Provider 重新长出发行版分支。
    @Default(<LinuxDistributionCapability>[]) List<LinuxDistributionCapability> capabilities,
  }) = _LinuxDistribution;

  factory LinuxDistribution.fromJson(Map<String, dynamic> json) =>
      _$LinuxDistributionFromJson(json);

  /// 未知发行版默认画像。
  static const unknown = LinuxDistribution();

  /// 当前已知的 UOS 特殊适配画像。
  ///
  /// 注意：这里声明的是“能力”，不是最终文案。
  /// 最终哪个场景展示什么提示，统一由 `InstallMessages` 决定，
  /// 这样可以避免模型层和展示层互相耦合字符串。
  static const uos = LinuxDistribution(
    id: LinuxDistributionId.uos,
    displayName: 'UOS',
    capabilities: <LinuxDistributionCapability>[
      LinuxDistributionCapability.envInstallGuidance,
      LinuxDistributionCapability.envInstallRequiresDeveloperMode,
      LinuxDistributionCapability.envInstallRequiresRootPrivilege,
      LinuxDistributionCapability.appInstallFailureGuidance,
    ],
  );

  bool get isKnown => id != LinuxDistributionId.unknown;

  bool get hasSpecialAdaptation => capabilities.isNotEmpty;

  bool hasCapability(LinuxDistributionCapability capability) {
    return capabilities.contains(capability);
  }

  /// 将“能力标签”折叠成调用侧可消费的 guidance scenario。
  ///
  /// 调用侧只需要关心“当前场景是否支持特殊提示”，
  /// 不需要关心具体是哪个 capability 在支撑该场景。
  bool supportsGuidanceScenario(LinuxDistributionGuidanceScenario scenario) {
    return switch (scenario) {
      LinuxDistributionGuidanceScenario.envInstallDialog =>
        hasCapability(LinuxDistributionCapability.envInstallGuidance),
      LinuxDistributionGuidanceScenario.appInstallFailure =>
        hasCapability(LinuxDistributionCapability.appInstallFailureGuidance),
      LinuxDistributionGuidanceScenario.appUpdateFailure =>
        hasCapability(LinuxDistributionCapability.appUpdateFailureGuidance),
    };
  }
}