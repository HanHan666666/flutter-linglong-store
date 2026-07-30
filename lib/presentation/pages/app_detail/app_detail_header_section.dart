/// 应用详情页头部适配区域。
///
/// 该文件只把页面容器已经派生的安装状态和动作传给现有 Hero Header，
/// 不读取 Provider，也不重新判断安装、更新或卸载语义。
library;

import 'package:flutter/material.dart';

import '../../../domain/models/app_detail.dart';
import '../../../domain/models/install_button_state.dart';
import '../../../domain/models/install_task.dart';
import '../../../domain/models/installed_app.dart';
import '../../widgets/app_detail_hero_header.dart';
import 'app_detail_page_logic.dart';

/// 展示应用身份、主操作、次级操作和当前安装状态。
class AppDetailHeaderSection extends StatelessWidget {
  /// 创建详情页头部区域。
  const AppDetailHeaderSection({
    required this.app,
    required this.installSourceKey,
    required this.buttonState,
    required this.installTask,
    required this.downloadSpeed,
    required this.showInstalledActions,
    required this.description,
    required this.tags,
    required this.statusMessage,
    required this.onTagPressed,
    required this.onPrimaryPressed,
    required this.onCancel,
    required this.onCreateShortcut,
    required this.onUninstall,
    required this.onShare,
    super.key,
  });

  /// 当前详情页应用。
  final InstalledApp app;

  /// 下载飞入动画的源锚点。
  final GlobalKey installSourceKey;

  /// 页面纯规则计算后的主按钮状态。
  final InstallButtonState buttonState;

  /// 当前应用的安装或更新任务。
  final InstallTask? installTask;

  /// 安装中展示的 CLI 或系统回退速度。
  final String? downloadSpeed;

  /// 是否展示快捷方式和卸载等已安装操作。
  final bool showInstalledActions;

  /// 详情接口提供的简短描述。
  final String? description;

  /// 保留 name 和 language 的应用标签。
  final List<AppTag> tags;

  /// 当前 locale 下的安装状态文案。
  final String? statusMessage;

  /// 标签搜索回调。
  final ValueChanged<AppTag> onTagPressed;

  /// 主安装、更新或打开操作。
  final VoidCallback onPrimaryPressed;

  /// 取消当前安装或更新。
  final VoidCallback onCancel;

  /// 创建桌面快捷方式。
  final VoidCallback onCreateShortcut;

  /// 发起头部整体卸载。
  final VoidCallback onUninstall;

  /// 分享应用链接。
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return AppDetailHeroHeader(
      app: app,
      installSourceKey: installSourceKey,
      buttonState: buttonState,
      progress: installTask?.progress ?? 0.0,
      downloadSpeed: buttonState == InstallButtonState.installing
          ? downloadSpeed
          : null,
      showInstalledActions: showInstalledActions,
      description: description,
      tags: tags,
      onTagPressed: onTagPressed,
      statusMessage: statusMessage,
      statusLogCopyText: AppDetailPageLogic.installLogCopyText(installTask),
      isStatusFailed: installTask?.isFailed ?? false,
      onPrimaryPressed: onPrimaryPressed,
      onCancel: onCancel,
      onCreateShortcut: onCreateShortcut,
      onUninstall: onUninstall,
      onShare: onShare,
    );
  }
}
