import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/app_logger.dart';

import '../../application/providers/title_search_suggestions_provider.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
          l10n.appTitle,
          style: context.appTextStyles.body.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: context.appFontWeight(FontWeight.w400),
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
class _TitleSearchBox extends ConsumerStatefulWidget {
  const _TitleSearchBox({required this.currentQuery, required this.onSearch});

  final String currentQuery;
  final ValueChanged<String> onSearch;

  @override
  ConsumerState<_TitleSearchBox> createState() => _TitleSearchBoxState();
}

class _TitleSearchBoxState extends ConsumerState<_TitleSearchBox> {
  bool _isFocused = false;
  int _selectedIndex = -1;
  final FocusNode _focusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final LayerLink _suggestionsLayerLink = LayerLink();
  final GlobalKey _searchBoxKey = GlobalKey(debugLabel: 'title-search-box');
  late final TextEditingController _controller;
  OverlayEntry? _suggestionsOverlayEntry;
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _removeSuggestionsOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _selectedIndex = -1;
    });
    _queueSuggestionsFetch();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _syncSuggestionsOverlay();
      return;
    }

    // 失焦后延迟收起，给候选点击事件留出命中窗口。
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || _focusNode.hasFocus) {
        return;
      }
      _removeSuggestionsOverlay();
    });
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }
    _debounceTimer?.cancel();
    ref.read(titleSearchSuggestionsProvider.notifier).clear();
    _removeSuggestionsOverlay();
    widget.onSearch(query);
    _focusNode.unfocus();
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    ref.read(titleSearchSuggestionsProvider.notifier).clear();
    _removeSuggestionsOverlay();
    _controller.clear();
  }

  void _queueSuggestionsFetch() {
    _debounceTimer?.cancel();

    final query = _controller.text.trim();
    if (query.isEmpty) {
      ref.read(titleSearchSuggestionsProvider.notifier).clear();
      _selectedIndex = -1;
      _syncSuggestionsOverlay();
      return;
    }

    // 本地匹配足够快，100ms 防抖即可。
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) {
        return;
      }
      ref
          .read(titleSearchSuggestionsProvider.notifier)
          .updateQuery(_controller.text);
    });
  }

  void _openSuggestion(SuggestionItem item) {
    debugPrint('[SearchSuggestion] _openSuggestion 被调用: appId=${item.appId}, name=${item.name}');
    _debounceTimer?.cancel();
    ref.read(titleSearchSuggestionsProvider.notifier).clear();
    _selectedIndex = -1;
    _focusNode.unfocus();
    // 先导航再清理 overlay，避免 overlay 销毁后导航失败。
    try {
      debugPrint('[SearchSuggestion] 准备跳转: /app/${item.appId}');
      context.goToAppDetail(item.appId);
      debugPrint('[SearchSuggestion] 跳转调用完成');
    } catch (e, stack) {
      debugPrint('[SearchSuggestion] 跳转异常: $e\n$stack');
      AppLogger.error('[SearchSuggestion] 跳转详情页失败: ${item.appId}', e, stack);
    }
    _removeSuggestionsOverlay();
  }

  bool _shouldShowSuggestions(TitleSearchSuggestionsState state) {
    return _focusNode.hasFocus &&
        _controller.text.trim().isNotEmpty &&
        state.items.isNotEmpty;
  }

  void _syncSuggestionsOverlay() {
    final state = ref.read(titleSearchSuggestionsProvider);
    if (!_shouldShowSuggestions(state)) {
      _removeSuggestionsOverlay();
      return;
    }

    if (_suggestionsOverlayEntry == null) {
      debugPrint('[SearchSuggestion] 创建 overlay, ${state.items.length} 个候选');
      _suggestionsOverlayEntry = OverlayEntry(
        builder: (overlayContext) => _buildSuggestionsOverlay(overlayContext),
      );
      Overlay.of(context, rootOverlay: true).insert(_suggestionsOverlayEntry!);
      return;
    }

    _suggestionsOverlayEntry!.markNeedsBuild();
  }

  void _removeSuggestionsOverlay() {
    _suggestionsOverlayEntry?.remove();
    _suggestionsOverlayEntry = null;
  }

  /// 键盘事件处理：↑↓ 选中、Enter 跳转、Escape 关闭。
  KeyEventResult _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final state = ref.read(titleSearchSuggestionsProvider);
    if (!_shouldShowSuggestions(state) || state.items.isEmpty) {
      return KeyEventResult.ignored;
    }

    final items = state.items;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % items.length;
        });
        _syncSuggestionsOverlay();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() {
          _selectedIndex = _selectedIndex <= 0
              ? items.length - 1
              : _selectedIndex - 1;
        });
        _syncSuggestionsOverlay();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        debugPrint('[SearchSuggestion] Enter 键: selectedIndex=$_selectedIndex, items.length=${items.length}');
        if (_selectedIndex >= 0 && _selectedIndex < items.length) {
          _openSuggestion(items[_selectedIndex]);
        } else {
          _submitSearch();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _removeSuggestionsOverlay();
        _selectedIndex = -1;
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  Widget _buildSuggestionsOverlay(BuildContext overlayContext) {
    final state = ref.read(titleSearchSuggestionsProvider);
    final renderBox =
        _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
    final width = renderBox?.size.width ?? 534.0;

    // 直接用 Positioned 定位，不依赖 CompositedTransformFollower
    final boxOffset = _getSearchBoxOffset();
    final left = boxOffset.dx;
    final top = boxOffset.dy + 36;

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Material(
        elevation: 4,
        borderRadius: AppRadius.mdRadius,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 240),
          decoration: BoxDecoration(
            color: overlayContext.appColors.surface,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(
              color: overlayContext.appColors.borderSecondary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(6),
            shrinkWrap: true,
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              final isSelected = index == _selectedIndex;

              return MouseRegion(
                onEnter: (_) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: GestureDetector(
                  onTap: () {
                    debugPrint('[SearchSuggestion] overlay onTap 触发: index=$index, appId=${item.appId}');
                    _openSuggestion(item);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? overlayContext.appColors.primaryLight
                          : Colors.transparent,
                      borderRadius: AppRadius.xsRadius,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: overlayContext.appTextStyles.bodyMedium
                                .copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : overlayContext.appColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: ExcludeSemantics(
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 获取搜索框在屏幕上的偏移量
  Offset _getSearchBoxOffset() {
    final renderBox =
        _searchBoxKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    return renderBox.localToGlobal(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(titleSearchSuggestionsProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncSuggestionsOverlay();
    });

    return CompositedTransformTarget(
      link: _suggestionsLayerLink,
      child: Container(
        key: _searchBoxKey,
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
                child: KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  onKeyEvent: _onKeyEvent,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 1,
                    decoration: InputDecoration(
                      hintText: l10n.searchPlaceholder,
                      hintStyle: context.appTextStyles.bodyMedium.copyWith(
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
                              tooltip: l10n.clearSearch,
                            )
                          : null,
                    ),
                    style: context.appTextStyles.bodyMedium.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submitSearch(),
                  ),
                ),
              ),
            ],
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.remove,
          onPressed: onMinimize,
          tooltip: l10n.minimize,
        ),
        _WindowButton(
          icon: isMaximized ? Icons.filter_none : Icons.crop_square,
          onPressed: onMaximize,
          tooltip: isMaximized ? l10n.restore : l10n.maximize,
        ),
        _WindowButton(
          icon: Icons.close,
          onPressed: onClose,
          tooltip: l10n.close,
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
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
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
              child: ExcludeSemantics(
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
        ),
      ),
    );
  }
}
