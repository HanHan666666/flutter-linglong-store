import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/logging/app_logger.dart';

import '../../application/providers/search_hint_provider.dart';
import '../../application/providers/title_search_suggestions_provider.dart';
import '../../core/config/routes.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/app_detail.dart';
import '../../domain/models/installed_app.dart';

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
    this.currentSearchTag,
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

  /// 当前搜索关键词（普通文本搜索模式）
  final String currentSearchQuery;

  /// 当前标签搜索条件（标签模式，与 [currentSearchQuery] 互斥）
  final AppTag? currentSearchTag;

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
          currentTag: currentSearchTag,
          onSearch: context.goToSearch,
        ),
      ),
    );
  }
}

/// 标题栏搜索框
class _TitleSearchBox extends ConsumerStatefulWidget {
  const _TitleSearchBox({
    required this.currentQuery,
    required this.onSearch,
    this.currentTag,
  });

  final String currentQuery;
  final ValueChanged<String> onSearch;

  /// 标签搜索条件；非空时进入标签模式，渲染不可拆分 Tag 胶囊（Task 9 实现）
  final AppTag? currentTag;

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

  /// 标签胶囊专用焦点节点，用于接收 Backspace/Delete 删除快捷键。
  ///
  /// 标签模式下不构建 TextField，必须用独立 FocusNode + CallbackShortcuts
  /// 承接键盘删除事件，保证与输入框模式一致的键盘可操作性。
  final FocusNode _tagFocusNode = FocusNode(debugLabel: 'title-search-tag');

  /// placeholder 轮播相关状态。
  ///
  /// 下载量榜数据由 [searchHintAppsProvider] 提供，到位后每 5 秒切换一个应用名
  /// 作为搜索框 placeholder；空输入回车时跳转当前 placeholder 对应应用的详情页。
  /// 数据未就绪或为空时回退到静态文案 [l10n.searchPlaceholder]。
  ///
  /// 轮播顺序为每次数据到位时随机洗牌后顺序循环，单轮内不重复、每次启动顺序不同。
  Timer? _hintTimer;
  int _hintIndex = 0;
  SearchHintApp? _currentHintApp;

  /// 洗牌后的轮播序列，由 [_resetHintRotation] 在数据到位时生成。
  List<SearchHintApp> _hintSequence = const <SearchHintApp>[];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentQuery);
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChange);

    // 订阅下载量榜数据：非空时启动 5 秒轮播，空则回退静态文案。
    // 下载量榜仅取前 20 条，循环轮播；组件销毁时在 dispose 取消 Timer。
    ref.listenManual(searchHintAppsProvider, (previous, next) {
      _resetHintRotation(next);
    }, fireImmediately: true);

    if (widget.currentTag != null) {
      _scheduleEnterTagMode();
    }
  }

  @override
  void didUpdateWidget(covariant _TitleSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTag != widget.currentTag) {
      if (widget.currentTag != null) {
        _scheduleEnterTagMode();
      } else {
        _scheduleRestoreTextFocus();
      }
    }
    if (oldWidget.currentQuery != widget.currentQuery &&
        _controller.text != widget.currentQuery) {
      _controller.value = TextEditingValue(
        text: widget.currentQuery,
        selection: TextSelection.collapsed(offset: widget.currentQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _hintTimer?.cancel();
    _removeSuggestionsOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    _tagFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 标签模式没有文本搜索语义，清空控制器时不得触发普通候选请求。
    if (widget.currentTag != null) {
      return;
    }
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

    // 失焦后延迟关闭 overlay，给候选点击留足窗口。
    // 候选面板的 GestureDetector 在 overlay 内，失焦不会立即影响它。
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted || _focusNode.hasFocus) {
        return;
      }
      _removeSuggestionsOverlay();
      _selectedIndex = -1;
    });
  }

  void _submitSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      // 空输入回车：若当前 placeholder 正轮播某个下载量榜应用，
      // 直接跳转该应用详情页；否则维持原行为（什么都不做）。
      final hint = _currentHintApp;
      if (hint != null) {
        _debounceTimer?.cancel();
        ref.read(titleSearchSuggestionsProvider.notifier).clear();
        _removeSuggestionsOverlay();
        _focusNode.unfocus();
        // 跳转必须带全身份字段，避免详情页接口回退匹配到错误条目。
        context.goToAppDetail(
          hint.appId,
          appInfo: InstalledApp(
            appId: hint.appId,
            name: hint.name,
            version: hint.version,
            arch: hint.arch,
            repoName: hint.repoName,
            module: hint.module,
          ),
        );
      }
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

  /// 根据下载量榜数据重置 placeholder 轮播。
  ///
  /// 列表非空时随机洗牌后顺序轮播：每次数据到位都重新洗牌，保证每次启动
  /// 轮播顺序不同；单轮内每个应用只出现一次，循环到末尾后从头再来。
  /// 列表为空（未就绪/失败/无数据）时停止轮播并清空当前 placeholder 应用，
  /// 由 UI 侧回退到静态文案。
  void _resetHintRotation(List<SearchHintApp> apps) {
    _hintTimer?.cancel();
    _hintTimer = null;

    if (apps.isEmpty) {
      _hintIndex = 0;
      _hintSequence = const <SearchHintApp>[];
      if (_currentHintApp != null) {
        _currentHintApp = null;
        if (mounted) setState(() {});
      }
      return;
    }

    // 随机洗牌生成本轮轮播序列，避免每次启动顺序固定。
    _hintSequence = List<SearchHintApp>.of(apps)..shuffle();
    _hintIndex = 0;
    final next = _hintSequence.first;
    final changed =
        _currentHintApp?.appId != next.appId ||
        _currentHintApp?.name != next.name;
    _currentHintApp = next;
    if (changed && mounted) setState(() {});

    _hintTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        _hintTimer?.cancel();
        return;
      }
      _hintIndex = (_hintIndex + 1) % _hintSequence.length;
      _currentHintApp = _hintSequence[_hintIndex];
      setState(() {});
    });
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
    debugPrint(
      '[SearchSuggestion] _openSuggestion 被调用: appId=${item.appId}, name=${item.name}',
    );
    _debounceTimer?.cancel();
    ref.read(titleSearchSuggestionsProvider.notifier).clear();
    _selectedIndex = -1;
    _focusNode.unfocus();
    // 先导航再清理 overlay，避免 overlay 销毁后导航失败。
    try {
      debugPrint('[SearchSuggestion] 准备跳转: /app/${item.appId}');
      context.goToAppDetail(item.appId, appInfo: _suggestionToAppInfo(item));
      debugPrint('[SearchSuggestion] 跳转调用完成');
    } catch (e, stack) {
      debugPrint('[SearchSuggestion] 跳转异常: $e\n$stack');
      AppLogger.error('[SearchSuggestion] 跳转详情页失败: ${item.appId}', e, stack);
    }
    _removeSuggestionsOverlay();
  }

  InstalledApp _suggestionToAppInfo(SuggestionItem item) {
    // 详情页需要这些身份字段做精确查询，不能只传 appId 后依赖回退匹配。
    return InstalledApp(
      appId: item.appId,
      name: item.name,
      version: item.version ?? '',
      arch: item.arch,
      repoName: item.repoName,
      module: item.module,
    );
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
        debugPrint(
          '[SearchSuggestion] Enter 键: selectedIndex=$_selectedIndex, items.length=${items.length}',
        );
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
      // 候选浮层属于搜索输入组合控件，点击候选项时不能被 TextField
      // 识别为外部点击，否则桌面端会在 onTap 前先失焦并销毁 overlay。
      child: TextFieldTapRegion(
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
                      debugPrint(
                        '[SearchSuggestion] overlay onTap 触发: index=$index, appId=${item.appId}',
                      );
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

  /// 删除当前标签胶囊，回到普通文本搜索模式（空查询）。
  ///
  /// 设计原因：标签与文本模式互斥；删除标签等同于清空搜索条件，
  /// 统一导航到无 query 的搜索页，由标题栏恢复为可编辑输入框。
  void _removeTag() {
    _tagFocusNode.unfocus();
    // 进入标签模式前已清空输入控制器，这里导航后页面重建会切回输入框
    widget.onSearch('');
  }

  /// 在进入标签模式后的首个稳定帧中清理普通搜索状态并建立键盘焦点。
  ///
  /// 该操作只在模式切换时调度，避免在 [build] 中反复清理 Provider 或请求焦点。
  void _scheduleEnterTagMode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.currentTag == null) {
        return;
      }
      if (_controller.text.isNotEmpty) {
        _controller.clear();
      }
      _removeSuggestionsOverlay();
      _debounceTimer?.cancel();
      ref.read(titleSearchSuggestionsProvider.notifier).clear();
      _tagFocusNode.requestFocus();
    });
  }

  /// 删除标签并恢复普通搜索模式后，将键盘焦点交还输入框。
  void _scheduleRestoreTextFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.currentTag != null) {
        return;
      }
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 两种模式共用同一个搜索框外壳，仅切换内部内容，保证标题栏布局稳定。
    final tag = widget.currentTag;
    if (tag == null) {
      ref.watch(titleSearchSuggestionsProvider);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _syncSuggestionsOverlay();
      });
    }

    return CompositedTransformTarget(
      key: const Key('title-search-box'),
      link: _suggestionsLayerLink,
      child: Container(
        key: _searchBoxKey,
        constraints: const BoxConstraints(maxWidth: 534),
        height: 32,
        decoration: BoxDecoration(
          color: context.appColors.surfaceContainerHighest,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(
            color: tag == null && _isFocused
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
                onTap: tag == null ? _submitSearch : null,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.search,
                  size: 16,
                  color: tag == null && _isFocused
                      ? AppColors.primary
                      : context.appColors.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: tag != null
                    ? _buildTagChip(context, tag, l10n)
                    : KeyboardListener(
                        focusNode: _keyboardFocusNode,
                        onKeyEvent: _onKeyEvent,
                        child: Stack(
                          children: [
                            // 底层输入框：承载真实输入与光标，不再使用 InputDecoration.hintText，
                            // 改由上层 [_AnimatedSearchHint] 负责带过渡动画的 placeholder 展示。
                            TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              maxLines: 1,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
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
                            // 上层动画 placeholder：仅输入为空时展示当前轮播应用名/兜底文案。
                            // IgnorePointer 保证点击会穿透到下层 TextField，聚焦与候选浮层逻辑不受影响。
                            // Positioned.fill 让其撑满整个 Stack，使内部文案能垂直居中到搜索框中心，
                            // 与底层 TextField 的 textAlignVertical.center 对齐。
                            Positioned.fill(
                              child: IgnorePointer(
                                key: const Key('title-search-placeholder'),
                                child: _AnimatedSearchHint(
                                  // 输入非空时清空展示文案，等价于原 hintText 被输入覆盖的行为。
                                  text: _controller.text.isEmpty
                                      ? (_currentHintApp?.name ??
                                            l10n.searchPlaceholder)
                                      : '',
                                  // 与原 hintText 的字体/颜色保持完全一致，避免视觉漂移。
                                  style: context.appTextStyles.bodyMedium
                                      .copyWith(
                                        color: context.appColors.textTertiary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建标签模式下的不可拆分 Tag 胶囊。
  ///
  /// - 不构建 TextField，胶囊不可编辑；
  /// - 通过关闭按钮或 Backspace/Delete 删除后回到普通文本搜索；
  /// - 复用原搜索框的 32px 外壳，使用项目色彩和圆角构建紧凑视觉；
  /// - 提供本地化标签语义和独立删除按钮语义；
  /// - 进入标签模式后自动聚焦，便于键盘删除。
  Widget _buildTagChip(
    BuildContext context,
    AppTag tag,
    AppLocalizations l10n,
  ) {
    // 标签模式没有 TextField，直接通过 FocusNode 拦截 Backspace/Delete。
    return Focus(
      focusNode: _tagFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.delete)) {
          _removeTag();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        key: const Key('title-search-tag-chip'),
        label: l10n.a11ySearchByTag(tag.name),
        container: true,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 24,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              color: context.appColors.primaryLight,
              borderRadius: AppRadius.fullRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ExcludeSemantics(
                    child: Text(
                      tag.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.tiny.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: l10n.a11yRemoveSearchTag(tag.name),
                  child: Tooltip(
                    message: l10n.a11yRemoveSearchTag(tag.name),
                    child: InkWell(
                      key: const Key('title-search-tag-remove'),
                      onTap: _removeTag,
                      borderRadius: AppRadius.fullRadius,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: ExcludeSemantics(
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

///
/// 替代 `InputDecoration.hintText`（后者只能瞬切，无法挂自定义进出动画）。
/// 通过 [AnimatedSwitcher] 以「淡入淡出 + 轻微上滑」交叉切换文案，文案变化由
/// [ValueKey] 触发。
///
/// 遵循系统「减少动态效果」无障碍设置：当 [MediaQuery.disableAnimations] 为真
/// （或平台 accessibilityFeatures 同样声明禁用动画）时，duration 降级为
/// [Duration.zero]，等价于瞬切，保持与全局零动画策略一致。
/// 参见 `install_to_download_flyout.dart` 中同样的系统偏好读取约定。
class _AnimatedSearchHint extends StatelessWidget {
  const _AnimatedSearchHint({required this.text, required this.style});

  /// 当前展示的 placeholder 文案，输入非空时由上层置为空串以隐藏。
  final String text;

  /// 文案样式，需与原 hintText 的 hintStyle 完全一致。
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    // 读取系统「减少动态效果」设置；MediaQuery 不可用时回退到平台无障碍特性。
    final mediaQuery = MediaQuery.maybeOf(context);
    final animationsDisabled =
        mediaQuery?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;
    const animDuration = Duration(milliseconds: 500);

    // 外层 SizedBox.expand + Align 把 placeholder 文案垂直居中到搜索框可用区，
    // 对齐底层 TextField 的 textAlignVertical.center，避免动画 Text 贴在 Stack
    // 顶部导致与输入文字基线不一致。水平方向居左，保持从左到右阅读。
    return SizedBox.expand(
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedSwitcher(
          // 关闭系统动画时降级为瞬切，遵守无障碍偏好。
          duration: animationsDisabled ? Duration.zero : animDuration,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          // 淡入淡出叠加轻微上滑：新词从下方淡入上移，旧词向上淡出。
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          layoutBuilder: (currentChild, previousChildren) {
            // 让新旧文案在切换瞬间重叠堆叠，避免切换期高度跳动。
            return Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: Text(
            text,
            // ValueKey 随文案变化，触发 AnimatedSwitcher 的新旧交替动画。
            key: ValueKey<String>(text),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
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
