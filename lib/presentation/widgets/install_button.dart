import 'package:flutter/material.dart';
import '../../core/i18n/l10n/app_localizations.dart';

/// 安装按钮状态枚举
enum InstallButtonState {
  /// 未安装
  notInstalled,

  /// 安装中
  installing,

  /// 已安装
  installed,

  /// 需要更新
  update,

  /// 打开应用
  open,

  /// 卸载
  uninstall,
}

/// 安装按钮组件
///
/// 显示应用的安装状态和操作按钮
class InstallButton extends StatelessWidget {
  /// 按钮状态
  final InstallButtonState state;

  /// 安装进度 (0.0 - 1.0)
  final double progress;

  /// 按钮点击回调
  final VoidCallback? onPressed;

  /// 取消安装回调
  final VoidCallback? onCancel;

  /// 是否禁用
  final bool disabled;

  /// 按钮大小
  final ButtonSize size;

  const InstallButton({
    super.key,
    this.state = InstallButtonState.notInstalled,
    this.progress = 0.0,
    this.onPressed,
    this.onCancel,
    this.disabled = false,
    this.size = ButtonSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    // 根据状态构建不同的按钮样式
    switch (state) {
      case InstallButtonState.notInstalled:
        return _buildPrimaryButton(
          context,
          label: AppLocalizations.of(context)?.install ?? '安装',
          icon: Icons.download,
        );

      case InstallButtonState.installing:
        return _buildProgressButton(context);

      case InstallButtonState.installed:
        return _buildOutlinedButton(
          context,
          label: AppLocalizations.of(context)?.open ?? '打开',
          icon: Icons.open_in_new,
        );

      case InstallButtonState.update:
        return _buildPrimaryButton(
          context,
          label: AppLocalizations.of(context)?.update_action ?? '更新',
          icon: Icons.update,
        );

      case InstallButtonState.open:
        return _buildOutlinedButton(
          context,
          label: AppLocalizations.of(context)?.open ?? '打开',
          icon: Icons.open_in_new,
        );

      case InstallButtonState.uninstall:
        return _buildDestructiveButton(
          context,
          label: AppLocalizations.of(context)?.uninstall ?? '卸载',
          icon: Icons.delete_outline,
        );
    }
  }

  /// 构建主要按钮（安装/更新）
  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final buttonHeight = _getButtonHeight();

    return SizedBox(
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: Icon(icon, size: _getIconSize()),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
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
  }) {
    final buttonHeight = _getButtonHeight();

    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: Icon(icon, size: _getIconSize()),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight / 2),
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
  }) {
    final buttonHeight = _getButtonHeight();

    return SizedBox(
      height: buttonHeight,
      child: OutlinedButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: Icon(icon, size: _getIconSize(), color: Colors.red),
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
    );
  }

  /// 构建进度按钮（安装中）
  Widget _buildProgressButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttonHeight = _getButtonHeight();
    final progressPercent = (progress * 100).toStringAsFixed(0);
    final cancelLabel = l10n?.cancel ?? '取消';

    return SizedBox(
      height: buttonHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 进度背景
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(buttonHeight / 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(buttonHeight / 2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                minHeight: buttonHeight,
              ),
            ),
          ),
          // 进度文本和取消按钮
          Padding(
            padding: EdgeInsets.symmetric(horizontal: _getHorizontalPadding()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(width: 8),
                  Tooltip(
                    message: cancelLabel,
                    child: GestureDetector(
                      onTap: onCancel,
                      child: Icon(
                        Icons.close,
                        size: _getIconSize(),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 获取按钮高度
  double _getButtonHeight() {
    switch (size) {
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
    switch (size) {
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
    switch (size) {
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
enum ButtonSize {
  small,
  medium,
  large,
}