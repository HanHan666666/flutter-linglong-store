import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/routes.dart';
import '../../core/config/theme.dart';

/// 自定义标题栏
///
/// 包含：Logo + 应用名 + 搜索框 + 窗口控制按钮
/// 支持窗口拖拽和双击最大化
class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({
    required this.isMaximized,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
    this.showSearch = true,
    super.key,
  });

  /// 窗口是否最大化
  final bool isMaximized;

  /// 最小化回调
  final VoidCallback onMinimize;

  /// 最大化/还原回调
  final VoidCallback onMaximize;

  /// 关闭回调
  final VoidCallback onClose;

  /// 是否显示搜索框
  final bool showSearch;

  /// 标题栏高度 - 57.6px (3.6rem)
  static const double height = 57.6;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 拖拽移动窗口
      onPanStart: (_) => windowManager.startDragging(),
      // 双击最大化/还原
      onDoubleTap: onMaximize,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        // decoration 需要读取 context 颜色，不能使用 const
        decoration: BoxDecoration(color: context.appColors.background),
        child: Row(
          children: [
            // 左侧：Logo + 应用名
            _buildLogoSection(context),
            // 中间：搜索框
            if (showSearch) _buildSearchSection(context),
            const Spacer(),
            // 右侧：窗口控制按钮
            _WindowControls(
              isMaximized: isMaximized,
              onMinimize: onMinimize,
              onMaximize: onMaximize,
              onClose: onClose,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建 Logo 区域
  Widget _buildLogoSection(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo 图标
        SvgPicture.asset(
          'assets/icons/logo.svg',
          width: AppSpacing.x2l,
          height: AppSpacing.x2l,
        ),
        const SizedBox(width: AppSpacing.sm),
        // 应用名称
        const Text(
          '玲珑应用商店社区版',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            // 标题区文字颜色跟随主题变化，需在生成时通过 context 获取
          ),
        ),
      ],
    );
  }

  /// 构建搜索框区域
  Widget _buildSearchSection(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: _TitleSearchBox(onTap: () => context.go(AppRoutes.searchList)),
      ),
    );
  }
}

/// 标题栏搜索框
class _TitleSearchBox extends StatefulWidget {
  const _TitleSearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_TitleSearchBox> createState() => _TitleSearchBoxState();
}

class _TitleSearchBoxState extends State<_TitleSearchBox> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 534),
          height: 32,
          decoration: BoxDecoration(
            color: _isFocused
                ? context.appColors.surface
                : context.appColors.surfaceContainerLow,
            borderRadius: AppRadius.lgRadius,
            border: Border.all(
              color: _isFocused
                  ? AppColors.primary
                  : context.appColors.borderSecondary,
              width: _isFocused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // 搜索图标区域
              Container(
                width: 48,
                height: 24,
                margin: const EdgeInsets.only(left: AppSpacing.sm),
                alignment: Alignment.center,
                child: Icon(
                  Icons.search,
                  size: 18,
                  color: _isFocused
                      ? AppColors.primary
                      : context.appColors.textTertiary,
                ),
              ),
              // 占位文字
              Expanded(
                child: Text(
                  '在这里搜索你想搜索的应用',
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 窗口控制按钮组
class _WindowControls extends StatelessWidget {
  const _WindowControls({
    required this.isMaximized,
    required this.onMinimize,
    required this.onMaximize,
    required this.onClose,
  });

  final bool isMaximized;
  final VoidCallback onMinimize;
  final VoidCallback onMaximize;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: onMinimize,
          tooltip: '最小化',
        ),
        _WindowButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          onPressed: onMaximize,
          tooltip: isMaximized ? '还原' : '最大化',
        ),
        _WindowButton(
          icon: Icons.close,
          onPressed: onClose,
          tooltip: '关闭',
          isClose: true,
        ),
      ],
    );
  }
}

/// 窗口控制按钮
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isClose;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: CustomTitleBar.height,
            color: _isHovered
                ? (widget.isClose
                      ? AppColors.error
                      : context.appColors.surfaceContainerLow)
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: AppSpacing.windowControlIconSize,
              color: _isHovered && widget.isClose
                  ? AppColors.textLight
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
