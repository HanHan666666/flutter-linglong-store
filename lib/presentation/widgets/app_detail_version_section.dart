import 'package:flutter/material.dart';

import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/utils/format_utils.dart';
import '../../data/models/api_dto.dart';

class AppDetailVersionSection extends StatefulWidget {
  const AppDetailVersionSection({
    required this.versions,
    required this.installedVersions,
    required this.isLoading,
    required this.onRetry,
    required this.onInstallVersion,
    this.errorMessage,
    super.key,
  });

  final List<AppVersionDTO> versions;
  final Set<String> installedVersions;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<String> onInstallVersion;

  @override
  State<AppDetailVersionSection> createState() => _AppDetailVersionSectionState();
}

class _AppDetailVersionSectionState extends State<AppDetailVersionSection> {
  static const int _collapsedVisibleCount = 8;

  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final versions = widget.versions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n?.versionHistory ?? '版本历史',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        if (widget.errorMessage != null && versions.isEmpty)
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
                child: Text(l10n?.retry ?? '重试'),
              ),
            ],
          )
        else if (widget.errorMessage != null)
          Text(
            l10n?.versionListUpdateFailed ?? '版本列表更新失败，显示最近一次结果',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          const SizedBox.shrink(),
        if (widget.errorMessage != null) const SizedBox(height: 12),
        if (versions.isEmpty && !widget.isLoading)
          Text(l10n?.noVersionHistory ?? '暂无版本历史')
        else ...[
          _VersionGrid(
            versions: _visibleVersions,
            installedVersions: widget.installedVersions,
            onInstallVersion: widget.onInstallVersion,
          ),
          if (versions.length > _collapsedVisibleCount) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _isExpanded
                    ? (l10n?.collapse ?? '收起')
                    : (l10n?.expandAll ?? '展开全部'),
              ),
            ),
          ],
        ],
      ],
    );
  }

  List<AppVersionDTO> get _visibleVersions {
    if (_isExpanded || widget.versions.length <= _collapsedVisibleCount) {
      return widget.versions;
    }
    return widget.versions.take(_collapsedVisibleCount).toList();
  }
}

class _VersionGrid extends StatelessWidget {
  const _VersionGrid({
    required this.versions,
    required this.installedVersions,
    required this.onInstallVersion,
  });

  final List<AppVersionDTO> versions;
  final Set<String> installedVersions;
  final ValueChanged<String> onInstallVersion;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const runSpacing = 12.0;
        final columnCount = _resolveColumnCount(constraints.maxWidth);
        final cardWidth = columnCount == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: versions.map((version) {
            return SizedBox(
              width: cardWidth,
              child: _VersionCard(
                version: version,
                isInstalled: installedVersions.contains(version.versionNo),
                onInstallVersion: onInstallVersion,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  int _resolveColumnCount(double maxWidth) {
    if (maxWidth >= 1120) {
      return 4;
    }
    if (maxWidth >= 800) {
      return 3;
    }
    if (maxWidth >= 520) {
      return 2;
    }
    return 1;
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.version,
    required this.isInstalled,
    required this.onInstallVersion,
  });

  final AppVersionDTO version;
  final bool isInstalled;
  final ValueChanged<String> onInstallVersion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final sizeLabel = FormatUtils.formatFileSizeValue(version.packageSize);
    final metaParts = <String>[
      if (version.releaseTime?.isNotEmpty ?? false) version.releaseTime!,
      if (sizeLabel != '--') sizeLabel,
    ];

    return OutlinedButton(
      onPressed: isInstalled ? null : () => onInstallVersion(version.versionNo),
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: theme.colorScheme.surface,
        disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.32),
        side: BorderSide(
          color: isInstalled
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    version.versionNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isInstalled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n?.installedBadge ?? '已安装',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              metaParts.isEmpty ? '--' : metaParts.join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            if (!isInstalled)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: ValueKey(
                    'app-detail-version-install-${version.versionNo}',
                  ),
                  onPressed: () => onInstallVersion(version.versionNo),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(l10n?.install ?? '安装'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
