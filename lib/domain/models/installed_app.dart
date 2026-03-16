import 'package:freezed_annotation/freezed_annotation.dart';

part 'installed_app.freezed.dart';
part 'installed_app.g.dart';

/// 已安装应用模型
@freezed
sealed class InstalledApp with _$InstalledApp {
  const factory InstalledApp({
    @JsonKey(name: 'app_id') required String appId,
    required String name,
    required String version,
    String? arch,
    String? channel,
    String? description,
    String? icon,
    String? kind,
    String? module,
    String? runtime,
    String? size,
    @JsonKey(name: 'repo_name') String? repoName,
  }) = _InstalledApp;

  factory InstalledApp.fromJson(Map<String, dynamic> json) =>
      _$InstalledAppFromJson(json);
}