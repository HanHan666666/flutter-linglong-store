import 'package:flutter/material.dart';

import '../../data/models/api_dto.dart';
import '../../core/i18n/l10n/app_localizations.dart';

class AppDetailCommentSection extends StatefulWidget {
  const AppDetailCommentSection({
    required this.comments,
    required this.versionOptions,
    required this.selectedVersion,
    required this.isLoading,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onRetry,
    this.errorMessage,
    this.onVersionChanged,
    super.key,
  });

  final List<AppCommentDTO> comments;
  final List<String> versionOptions;
  final String? selectedVersion;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final Future<void> Function(String remark, String? version) onSubmit;
  final VoidCallback onRetry;
  final ValueChanged<String?>? onVersionChanged;

  @override
  State<AppDetailCommentSection> createState() =>
      _AppDetailCommentSectionState();
}

class _AppDetailCommentSectionState extends State<AppDetailCommentSection> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final remark = _commentController.text.trim();
    if (remark.isEmpty) {
      return;
    }

    await widget.onSubmit(remark, widget.selectedVersion);
    if (!mounted) {
      return;
    }
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final title = l10n?.appComments ?? '评论区';
    final hint = l10n?.commentInputHint ?? '说说这个应用的使用体验';
    final emptyText = l10n?.appCommentsEmpty ?? '还没有评论，来写第一条吧';
    final retryLabel = l10n?.retry ?? '重试';
    final submitLabel = l10n?.submitComment ?? '发表评论';
    final versionLabel = l10n?.commentVersionLabel ?? '关联版本';
    final anonymousLabel = l10n?.anonymousComment ?? '匿名访客';
    final helpfulLabel = l10n?.commentHelpful ?? '有帮助';
    final notHelpfulLabel = l10n?.commentNotHelpful ?? '没帮助';
    final helperText = l10n?.commentAnonymousHint ?? '匿名评论，按最新时间排序展示';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.28,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('app-detail-comment-input'),
                controller: _commentController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (widget.versionOptions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 220),
                      child: DropdownButtonFormField<String>(
                        initialValue: widget.selectedVersion,
                        decoration: InputDecoration(
                          labelText: versionLabel,
                          border: const OutlineInputBorder(),
                        ),
                        items: widget.versionOptions
                            .map(
                              (version) => DropdownMenuItem<String>(
                                value: version,
                                child: Text(version),
                              ),
                            )
                            .toList(),
                        onChanged: widget.onVersionChanged,
                      ),
                    ),
                  FilledButton(
                    key: const ValueKey('app-detail-comment-submit'),
                    onPressed: widget.isSubmitting ? null : _handleSubmit,
                    child: widget.isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : Text(submitLabel),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                helperText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.isLoading && widget.comments.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (widget.errorMessage != null && widget.comments.isEmpty)
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.errorMessage!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onRetry,
                child: Text(retryLabel),
              ),
            ],
          )
        else if (widget.comments.isEmpty)
          Text(
            emptyText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final comment = widget.comments[index];
              final metaItems = <String>[
                anonymousLabel,
                if (comment.version?.isNotEmpty ?? false) comment.version!,
                if (comment.createTime?.isNotEmpty ?? false) comment.createTime!,
              ];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: metaItems
                          .map(
                            (item) => Text(
                              item,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      comment.remark,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          '$helpfulLabel ${comment.agreeNum}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$notHelpfulLabel ${comment.disagreeNum}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
