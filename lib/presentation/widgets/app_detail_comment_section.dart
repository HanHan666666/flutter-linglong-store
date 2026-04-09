import 'package:flutter/material.dart';

import '../../data/models/api_dto.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/config/theme.dart';

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
  static const int _collapsedVersionCount = 8;

  final TextEditingController _commentController = TextEditingController();
  String? _localSelectedVersion;
  bool _isVersionExpanded = false;

  String? get _effectiveSelectedVersion =>
      _localSelectedVersion ?? widget.selectedVersion;

  @override
  void initState() {
    super.initState();
    _localSelectedVersion = widget.selectedVersion;
  }

  @override
  void didUpdateWidget(covariant AppDetailCommentSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedVersion != oldWidget.selectedVersion) {
      _localSelectedVersion = widget.selectedVersion;
    }
  }

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

    await widget.onSubmit(remark, _effectiveSelectedVersion);
    if (!mounted) {
      return;
    }
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final title = l10n.appComments;
    final hint = l10n.commentInputHint;
    final emptyText = l10n.appCommentsEmpty;
    final retryLabel = l10n.retry;
    final submitLabel = l10n.submitComment;
    final versionLabel = l10n.commentVersionLabel;
    final anonymousLabel = l10n.anonymousComment;
    final helpfulLabel = l10n.commentHelpful;
    final notHelpfulLabel = l10n.commentNotHelpful;
    final helperText = l10n.commentAnonymousHint;

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
              if (widget.versionOptions.isNotEmpty) ...[
                Text(
                  versionLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                _buildVersionPills(context),
                const SizedBox(height: 12),
              ],
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

              return Semantics(
                label: metaItems.join(', '),
                child: Container(
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
              ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVersionPills(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final versions = _isVersionExpanded ||
            widget.versionOptions.length <= _collapsedVersionCount
        ? widget.versionOptions
        : widget.versionOptions.take(_collapsedVersionCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: versions.map((version) {
            final isSelected = version == _effectiveSelectedVersion;
            return _CommentVersionPill(
              key: ValueKey('comment-version-pill-$version'),
              label: version,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _localSelectedVersion = version;
                });
                widget.onVersionChanged?.call(version);
              },
            );
          }).toList(),
        ),
        if (widget.versionOptions.length > _collapsedVersionCount) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isVersionExpanded = !_isVersionExpanded;
              });
            },
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: theme.colorScheme.primary,
            ),
            icon: Icon(_isVersionExpanded ? Icons.expand_less : Icons.expand_more),
            label: Text(
              _isVersionExpanded
                  ? l10n.collapse
                  : l10n.expandAll,
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentVersionPill extends StatefulWidget {
  const _CommentVersionPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CommentVersionPill> createState() => _CommentVersionPillState();
}

class _CommentVersionPillState extends State<_CommentVersionPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = widget.isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.32)
        : _isHovered
        ? (isDark ? const Color(0xFF4A4A4A) : const Color(0xFFCBD5E1))
        : theme.colorScheme.outlineVariant;
    final backgroundColor = widget.isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.10)
        : _isHovered
        ? (isDark ? const Color(0xFF353535) : Colors.white)
        : theme.colorScheme.surface;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimation.fast,
        curve: AppAnimation.ease,
        transform: Matrix4.translationValues(0, _isHovered ? -1 : 0, 0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: AppRadius.fullRadius,
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.fullRadius,
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Text(
                widget.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
