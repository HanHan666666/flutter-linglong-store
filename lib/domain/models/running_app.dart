import 'package:freezed_annotation/freezed_annotation.dart';

part 'running_app.freezed.dart';
part 'running_app.g.dart';

/// 运行中应用模型
@freezed
sealed class RunningApp with _$RunningApp {
  const factory RunningApp({
    required String appId,
    required String name,
    required int pid,
    String? icon,
  }) = _RunningApp;

  factory RunningApp.fromJson(Map<String, dynamic> json) =>
      _$RunningAppFromJson(json);
}