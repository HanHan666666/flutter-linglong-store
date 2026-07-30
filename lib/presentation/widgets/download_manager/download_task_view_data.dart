/// 下载管理任务的轻量展示数据。
///
/// 该文件只保存容器按当前语言和发行版画像生成的展示属性，避免每张任务卡
/// 分别订阅全局 Provider，同时保留原始任务作为日志和诊断的唯一事实来源。
library;

import '../../../domain/models/install_task.dart';

/// 单个下载任务在当前界面上下文中的不可变展示数据。
class DownloadTaskViewData {
  /// 创建任务展示数据。
  const DownloadTaskViewData({
    required this.task,
    required this.statusMessage,
    this.errorMessage,
  });

  /// 安装队列持有的原始任务事实。
  final InstallTask task;

  /// 当前 locale 下的任务状态文案。
  final String statusMessage;

  /// 当前 locale 下的失败摘要，非失败任务为空。
  final String? errorMessage;
}
