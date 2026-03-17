import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import 'app_icon.dart';
import 'install_button.dart';

enum AppCardType { default_, recommend, list, grid }

/// 列表卡片的更多菜单动作。
class AppCardMenuAction {
  const AppCardMenuAction({
    required this.value,
    required this.label,
    required this.icon,
    required this.onSelected,
  });

  final String value;
  final String label;
  final IconData icon;
  final VoidCallback onSelected;
}

/// 通用应用卡片。
///
/// 页面层负责聚合状态并传入轻量 props，这里只负责展示与交互分发。
class AppCard extends StatefulWidget {
  const AppCard({
    required this.appId,
    required this.name,
    required this.buttonState,
    super.key,
    this.description,
    this.iconUrl,
    this.progress = 0.0,
    this.isInstalling = false,
    this.rank,
    this.type = AppCardType.default_,
    this.isLoading = false,
    this.onTap,
    this.onPrimaryPressed,
    this.menuActions = const [],
  });

  const AppCard.skeleton({super.key, this.type = AppCardType.default_})
    : appId = '',
      name = '',
      description = null,
      iconUrl = null,
      buttonState = InstallButtonState.notInstalled,
      progress = 0.0,
      isInstalling = false,
      rank = null,
      isLoading = true,
      onTap = null,
      onPrimaryPressed = null,
      menuActions = const [];

  final String appId;
  final String name;
  final String? description;
  final String? iconUrl;
  final InstallButtonState buttonState;
  final double progress;
  final bool isInstalling;
  final int? rank;
  final AppCardType type;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onPrimaryPressed;
  final List<AppCardMenuAction> menuActions;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildSkeletonCard(context);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: AppRadius.smRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: context.appColors.surface,
              borderRadius: AppRadius.smRadius,
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  if (widget.rank != null) ...[
                    _RankBadge(rank: widget.rank!),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  AppIcon(
                    iconUrl: widget.iconUrl,
                    size: 48,
                    borderRadius: 8,
                    appName: widget.name,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _buildInfo(context)),
                  const SizedBox(width: AppSpacing.sm),
                  _buildPrimaryButton(context),
                  if (widget.menuActions.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildOverflowMenu(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 14,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 56,
                height: 28,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          widget.description ?? '',
          style: TextStyle(fontSize: 12, color: context.appColors.textTertiary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLoading =
        widget.isInstalling &&
        (widget.buttonState == InstallButtonState.notInstalled ||
            widget.buttonState == InstallButtonState.update);
    final label = _resolveLabel(l10n, widget.buttonState, isLoading);

    if (widget.buttonState == InstallButtonState.open ||
        widget.buttonState == InstallButtonState.installed) {
      return SizedBox(
        height: 28,
        child: OutlinedButton(
          onPressed: widget.onPrimaryPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(56, 28),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            backgroundColor: context.appColors.openButtonBackground,
            foregroundColor: context.appColors.openButtonText,
            side: BorderSide(color: context.appColors.openButtonBorder),
            shape: const StadiumBorder(),
          ),
          child: Text(label),
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: FilledButton(
        onPressed: isLoading ? null : widget.onPrimaryPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(56, 28),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: const StadiumBorder(),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.65),
          disabledForegroundColor: Colors.white,
        ),
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      value: widget.progress > 0 ? widget.progress : null,
                      strokeWidth: 2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              )
            : Text(label),
      ),
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        for (final action in widget.menuActions) {
          if (action.value == value) {
            action.onSelected();
            return;
          }
        }
      },
      itemBuilder: (context) => widget.menuActions
          .map(
            (action) => PopupMenuItem<String>(
              value: action.value,
              child: Row(
                children: [
                  Icon(action.icon, size: 20),
                  const SizedBox(width: 12),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  String _resolveLabel(
    AppLocalizations? l10n,
    InstallButtonState state,
    bool isLoading,
  ) {
    if (isLoading) {
      final progressPercent = (widget.progress * 100).round();
      return progressPercent > 0
          ? '$progressPercent%'
          : (l10n?.installing ?? '安装中');
    }

    return switch (state) {
      InstallButtonState.notInstalled => l10n?.install ?? '安装',
      InstallButtonState.update => l10n?.update_action ?? '更新',
      InstallButtonState.installed => l10n?.open ?? '打开',
      InstallButtonState.open => l10n?.open ?? '打开',
      InstallButtonState.installing => l10n?.installing ?? '安装中',
      InstallButtonState.uninstall => l10n?.uninstall ?? '卸载',
    };
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = switch (rank) {
      1 => (const Color(0xFFFFD700), Colors.white),
      2 => (const Color(0xFFC0C0C0), Colors.white),
      3 => (const Color(0xFFCD7F32), Colors.white),
      _ => (context.appColors.cardBackground, context.appColors.textTertiary),
    };

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.xsRadius,
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
