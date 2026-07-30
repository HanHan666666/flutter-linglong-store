/// 应用详情页评论区域适配。
///
/// 该文件把评论模型、版本选择和提交回调传给既有评论组件，不读取 Provider，
/// 页面容器继续持有当前选择，异步提交由动作控制器完成。
library;

import 'package:flutter/material.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/app_comment.dart';
import '../../widgets/app_detail_comment_section.dart';

/// 展示应用评论列表和评论提交表单。
class AppDetailCommentsPanel extends StatelessWidget {
  /// 创建评论区域。
  const AppDetailCommentsPanel({
    required this.comments,
    required this.versionOptions,
    required this.selectedVersion,
    required this.isLoading,
    required this.canSubmitComment,
    required this.errorMessage,
    required this.onVersionChanged,
    required this.onRetry,
    required this.onSubmit,
    super.key,
  });

  /// 当前评论列表。
  final List<AppComment> comments;

  /// 评论可关联的应用版本。
  final List<String> versionOptions;

  /// 当前选中的评论版本。
  final String? selectedVersion;

  /// 评论是否正在加载。
  final bool isLoading;

  /// 当前用户是否满足提交评论的本地安装条件。
  final bool canSubmitComment;

  /// 评论加载错误。
  final String? errorMessage;

  /// 修改评论版本选择的回调。
  final ValueChanged<String?> onVersionChanged;

  /// 重试加载评论的回调。
  final VoidCallback onRetry;

  /// 提交评论的回调。
  final Future<bool> Function(String remark, String? version) onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.a11yCommentSection,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AppDetailCommentSection(
          comments: comments,
          versionOptions: versionOptions,
          selectedVersion: selectedVersion,
          isLoading: isLoading,
          canSubmitComment: canSubmitComment,
          errorMessage: errorMessage,
          onVersionChanged: onVersionChanged,
          onRetry: onRetry,
          onSubmit: onSubmit,
        ),
      ),
    );
  }
}
