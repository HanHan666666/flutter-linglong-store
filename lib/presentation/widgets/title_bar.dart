import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/config/routes.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';

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
    this.currentSearchQuery = '',
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

  /// 当前搜索关键词
  final String currentSearchQuery;

  /// 是否显示搜索框
  final bool showSearch;

  /// 标题栏高度 - 57.6px (3.6rem)
  static const double height = 57.6;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      // decoration 需要读取 context 颜色，不能使用 const
      decoration: BoxDecoration(color: context.appColors.background),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: Row(
                children: [
                  // 搜索框改为真实输入后，拖拽区域需要避开输入控件。
                  _WindowDragHandle(
                    onDoubleTap: onMaximize,
                    child: _buildLogoSection(context),
                  ),
                  if (showSearch) _buildSearchSection(context),
                  Expanded(child: _WindowDragSpacer(onDoubleTap: onMaximize)),
                ],
              ),
            ),
          ),
          // 右侧：窗口控制按钮
          _WindowControls(
            isMaximized: isMaximized,
            onMinimize: onMinimize,
            onMaximize: onMaximize,
            onClose: onClose,
          ),
        ],
      ),
    );
  }

  /// 构建 Logo 区域
  Widget _buildLogoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        // 应用名称（标题栏级别：16px shell 文字）
        Text(
          l10n?.appTitle ?? '玲珑应用商店社区版',
          style: const TextStyle(
            fontSize: 16,
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
        child: _TitleSearchBox(
          currentQuery: currentSearchQuery,
          onSearch: context.goToSearch,
        ),
      ),
    );
  }
}

/// 标题栏搜索框
class _TitleSearchBox extends StatefulWidget {
  const _TitleSearchBox({required this.currentQuery, required this.onSearch});

  final String currentQuery;
  final ValueChanged<String> onSearch;

  @override
  State<_TitleSearchBox> createState() => _TitleSearchBoxState();
}

class _TitleSearchBoxState extends State<_TitleSearchBox> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentQuery);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant _TitleSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuery == widget.currentQuery ||
        _controller.text == widget.currentQuery) {
      return;
    }
    _controller.value = TextEditingValue(
      text: widget.currentQuery,
      selection: TextSelection.collapsed(offset: widget.currentQuery.length),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    widget.onSearch(query);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 534),
      height: 32,
      decoration: BoxDecoration(
        color: context.appColors.surfaceContainerHighest,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: _isFocused
              ? AppColors.primary
              : context.appColors.borderSecondary,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _submitSearch,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                Icons.search,
                size: 16,
                color: _isFocused
                    ? AppColors.primary
                    : context.appColors.textTertiary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: l10n?.searchPlaceholder ?? '在这里搜索你想搜索的应用',
                  // 搜索框 placeholder：14px 常规说明文字
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: context.appColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  // 上下 8px padding 使文字在 32px 容器内垂直居中
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 16,
                            color: context.appColors.textTertiary,
                          ),
                          onPressed: _clearSearch,
                          splashRadius: 14,
                          padding: EdgeInsets.zero,
                          tooltip: l10n?.clearSearch ?? '清除搜索词',
                        )
                      : null,
                ),
                // 搜索框输入文字：14px 常规说明文字
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.appColors.textPrimary,
                ),
                textAlignVertical: TextAlignVertical.center,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submitSearch(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowDragHandle extends StatelessWidget {
  const _WindowDragHandle({required this.onDoubleTap, required this.child});

  final VoidCallback onDoubleTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class _WindowDragSpacer extends StatelessWidget {
  const _WindowDragSpacer({required this.onDoubleTap});

  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: const SizedBox.expand(),
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: onMinimize,
          tooltip: l10n?.minimize ?? '最小化',
        ),
        _WindowButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          onPressed: onMaximize,
          tooltip: isMaximized
              ? (l10n?.restore ?? '还原')
              : (l10n?.maximize ?? '最大化'),
        ),
        _WindowButton(
          icon: Icons.close,
          onPressed: onClose,
          tooltip: l10n?.close ?? '关闭',
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
