import 'package:freezed_annotation/freezed_annotation.dart';

part 'running_app.freezed.dart';
part 'running_app.g.dart';

/// 运行中应用模型
@freezed
sealed class RunningApp with _$RunningApp {
  const factory RunningApp({
    /// 稳定唯一键，和 Rust 版本保持一致，使用 containerId。
    required String id,

    /// 应用 ID，如 org.deepin.calculator。
    required String appId,

    /// 展示名称；优先使用 list 结果中的名称，缺失时回退为 appId。
    required String name,

    /// 运行中的版本号。
    required String version,

    /// 架构，如 x86_64。
    required String arch,

    /// 渠道，如 main。
    required String channel,

    /// 来源，通常取 runtime 前缀。
    required String source,

    required int pid,

    /// 容器 ID，来自 `ll-cli ps`。
    required String containerId,

    String? icon,
  }) = _RunningApp;

  factory RunningApp.fromJson(Map<String, dynamic> json) =>
      _$RunningAppFromJson(json);
}
