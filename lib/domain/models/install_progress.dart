import 'package:freezed_annotation/freezed_annotation.dart';

part 'install_progress.freezed.dart';
part 'install_progress.g.dart';

/// 安装进度状态枚举
enum InstallStatus {
  pending,
  downloading,
  installing,
  success,
  failed,
  cancelled,
}

/// 安装进度事件
@freezed
sealed class InstallProgress with _$InstallProgress {
  const factory InstallProgress({
    required String appId,
    required InstallStatus status,
    @Default(0.0) double progress,
    String? message,
    String? error,
    int? errorCode,
  }) = _InstallProgress;

  factory InstallProgress.fromJson(Map<String, dynamic> json) =>
      _$InstallProgressFromJson(json);
}