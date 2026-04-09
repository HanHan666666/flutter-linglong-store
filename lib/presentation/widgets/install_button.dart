import 'package:flutter/material.dart';

import '../../core/accessibility/accessibility.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/install_button_state.dart';
import '../../domain/models/install_task.dart';

export '../../domain/models/install_button_state.dart' show InstallButtonState;

/// 安装按钮组件
///
/// 显示应用的安装状态和操作按钮
class InstallButton extends StatefulWidget {
  /// 应用名称（用于无障碍语义标签）
  final String appName;

  /// 按钮状态
  final InstallButtonState state;

  /// 安装进度 (0.0 - 1.0)
  final double progress;

  /// 按钮点击回调
  final VoidCallback? onPressed;

  /// 取消安装回调
  final VoidCallback? onCancel;

  /// 下载速度文本（如 "2.5 MB/s"），为空时不显示
  final String? downloadSpeed;

  /// 是否禁用
  final bool disabled;

  /// 按钮大小
  final ButtonSize size;

  const InstallButton({
    super.key,
    this.appName = '',
    this.state = InstallButtonState.notInstalled,
    this.progress = 0.0,
    this.onPressed,
    this.onCancel,
    this.downloadSpeed,
    this.disabled = false,
    this.size = ButtonSize.medium,
  });

  @override
  State<InstallButton> createState() => _InstallButtonState();
}

class _InstallButtonState extends State<InstallButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 根据状态构建语义标签
    final semanticsLabel = switch (widget.state) {
      InstallButtonState.notInstalled => l10n.a11yInstallApp(widget.appName),
      InstallButtonState.installing => l10n.installing,
      InstallButtonState.pending => l10n.waitingForInstall,
      InstallButtonState.installed => l10n.a11yOpenApp(widget.appName),
      InstallButtonState.update => l10n.a11yUpdateApp(widget.appName),
      InstallButtonState.open => l10n.a11yOpenApp(widget.appName),
      InstallButtonState.uninstall => l10n.a11yUninstallApp(widget.appName),
    };

    // 安装中/排队中时按钮禁用
    final isEnabled = widget.state != InstallButtonState.installing &&
        widget.state != InstallButtonState.pending;

    // 根据状态构建不同的按钮样式
    switch (widget.state) {
      case InstallButtonState.notInstalled:
        return _buildPrimaryButton(
          context,
          label: l10n.install,
          icon: Icons.download,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.installing:
        return _buildProgressButton(
          context,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.pending:
        return _buildPendingButton(
          context,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.installed:
        return _buildOutlinedButton(
          context,
          label: l10n.open,
          icon: Icons.open_in_new,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.update:
        return _buildPrimaryButton(
          context,
          label: l10n.update_action,
          icon: Icons.update,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.open:
        return _buildOutlinedButton(
          context,
          label: l10n.open,
          icon: Icons.open_in_new,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );

      case InstallButtonState.uninstall:
        return _buildDestructiveButton(
          context,
          label: l10n.uninstall,
          icon: Icons.delete_outline,
          semanticsLabel: semanticsLabel,
          enabled: isEnabled,
        );
    }
  }

  /// 构建主要按钮（安装/更新）
  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String semanticsLabel,
    required bool enabled,
  }) {
    final buttonHeight = _getButtonHeight();

    return A11yButton(
      semanticsLabel: semanticsLabel,
      onTap: widget.onPressed ?? () {},
      enabled: enabled && !widget.disabled,
      child: SizedBox(
        height: buttonHeight,
        child: ElevatedButton.icon(
          onPressed: widget.disabled || !enabled ? null : widget.onPressed,
          icon: ExcludeSemantics(child: Icon(icon, size: _getIconSize())),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建轮廓按钮（打开）
  Widget _buildOutlinedButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String semanticsLabel,
    required bool enabled,
  }) {
    final buttonHeight = _getButtonHeight();

    return A11yButton(
      semanticsLabel: semanticsLabel,
      onTap: widget.onPressed ?? () {},
      enabled: enabled && !widget.disabled,
      child: SizedBox(
        height: buttonHeight,
        child: OutlinedButton.icon(
          onPressed: widget.disabled || !enabled ? null : widget.onPressed,
          icon: ExcludeSemantics(child: Icon(icon, size: _getIconSize())),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建危险按钮（卸载）
  Widget _buildDestructiveButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String semanticsLabel,
    required bool enabled,
  }) {
    final buttonHeight = _getButtonHeight();

    return A11yButton(
      semanticsLabel: semanticsLabel,
      onTap: widget.onPressed ?? () {},
      enabled: enabled && !widget.disabled,
      child: SizedBox(
        height: buttonHeight,
        child: OutlinedButton.icon(
          onPressed: widget.disabled || !enabled ? null : widget.onPressed,
          icon: ExcludeSemantics(
            child: Icon(icon, size: _getIconSize(), color: Colors.red),
          ),
          label: Text(label, style: const TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建进度按钮（安装中）
  Widget _buildProgressButton(
    BuildContext context, {
    required String semanticsLabel,
    required bool enabled,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final buttonHeight = _getButtonHeight();
    final theme = Theme.of(context);
    final progressTrackColor = theme.colorScheme.surfaceContainerHighest;
    final progressFillColor = theme.colorScheme.primaryContainer;
    final progressForegroundColor = theme.colorScheme.onSurface;
    final task = InstallTask(
      id: 'install-button-preview',
      appId: 'install-button-preview',
      appName: 'install-button-preview',
      progress: widget.progress,
      createdAt: 0,
    );
    final cancelLabel = l10n.cancel;

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: SizedBox(
        height: buttonHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 让前景文本决定按钮宽度，避免在 Row 的无界宽度约束中请求 double.infinity。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // 进度填充和前景文案必须分离到不同色阶，避免蓝底蓝字融在一起。
                  color: progressTrackColor,
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(buttonHeight / 2),
                  child: LinearProgressIndicator(
                    value: task.progressValue,
                    color: progressFillColor,
                    backgroundColor: Colors.transparent,
                    minHeight: buttonHeight,
                  ),
                ),
              ),
            ),
            // 进度文本和取消按钮
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _getHorizontalPadding(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // 有速度时显示 "xx% · 2.5 MB/s"，否则仅显示进度
                    widget.downloadSpeed != null && widget.downloadSpeed!.isNotEmpty
                        ? '${task.progressPercentLabel} · ${widget.downloadSpeed}'
                        : task.progressPercentLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: progressForegroundColor,
                    ),
                  ),
                  if (widget.onCancel != null) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: cancelLabel,
                      child: GestureDetector(
                        onTap: widget.onCancel,
                        child: ExcludeSemantics(
                          child: Icon(
                            Icons.close,
                            size: _getIconSize(),
                            color: progressForegroundColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建等待按钮（排队中）
  ///
  /// 默认显示转圈 + "等待安装"，鼠标悬停时显示 "取消安装"
  Widget _buildPendingButton(
    BuildContext context, {
    required String semanticsLabel,
    required bool enabled,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final buttonHeight = _getButtonHeight();
    final theme = Theme.of(context);

    // 悬停时显示取消，否则显示等待
    final isHovering = _isHovering && widget.onCancel != null;
    final label = isHovering
        ? l10n.cancelInstall
        : l10n.waitingForInstall;

    return Semantics(
      button: true,
      label: semanticsLabel,
      enabled: enabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        cursor: widget.onCancel != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          onTap: isHovering ? widget.onCancel : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: buttonHeight,
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            decoration: BoxDecoration(
              color: isHovering
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(buttonHeight / 2),
              border: Border.all(
                color: isHovering
                    ? theme.colorScheme.error.withValues(alpha: 0.5)
                    : theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isHovering) ...[
                  ExcludeSemantics(
                    child: SizedBox(
                      width: _getIconSize(),
                      height: _getIconSize(),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else ...[
                  ExcludeSemantics(
                    child: Icon(
                      Icons.close,
                      size: _getIconSize(),
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isHovering
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 获取按钮高度
  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 28;
      case ButtonSize.medium:
        return 32;
      case ButtonSize.large:
        return 40;
    }
  }

  /// 获取图标大小
  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  /// 获取水平内边距
  double _getHorizontalPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 20;
    }
  }
}

/// 按钮大小枚举
enum ButtonSize { small, medium, large }