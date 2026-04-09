import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/ranking_provider.dart';
import '../../../core/config/shell_primary_route.dart';
import '../../../core/config/shell_branch_visibility.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/ranking_models.dart';
import '../../widgets/app_card_actions.dart';
import '../../widgets/widgets.dart';

/// 排行榜页
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage>
    with SingleTickerProviderStateMixin, ShellBranchVisibilityMixin<RankingPage> {
  late TabController _tabController;

  /// 页面是否可见（用于控制副作用）
  bool _isPageVisible = true;

  @override
  ShellPrimaryRoute get watchedPrimaryRoute => ShellPrimaryRoute.ranking;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: RankingType.values.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    // 页面不可见时跳过 Tab 切换处理
    if (!_isPageVisible) return;
    if (!_tabController.indexIsChanging) {
      final type = RankingType.values[_tabController.index];
      ref.read(rankingProvider.notifier).selectType(type);
    }
  }

  /// 可见性变更回调
  @override
  void onPrimaryRouteVisibilityChanged({
    required bool isActive,
    required bool isInitial,
  }) {
    if (isActive) {
      _isPageVisible = true;
      return;
    }
    _isPageVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    // watch selectedType 建立 provider 依赖，保证 Tab 切换时触发 rebuild。
    // 不在 build() 中设置 _tabController.index，避免 build 副作用触发额外 listener 回调。
    final selectedType = ref.watch(
      rankingProvider.select((s) => s.selectedType),
    );

    return Column(
      children: [
        // Tab 栏
        _buildTabBar(selectedType),

        // Tab 内容：每个 Tab 独立管理自己的状态 watch
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: RankingType.values.map((type) {
              return _RankingTabContent(type: type);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(RankingType selectedType) {
    // Tab 内容区和分隔线颜色跟随主题
    final palette = context.appColors;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(bottom: BorderSide(color: palette.divider, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelColor: AppColors.primary,
        unselectedLabelColor: palette.textSecondary,
        // 使用 14px 字号 + 紧凑行高，保证文字在按钮内垂直居中
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium.copyWith(height: 1.0),
        indicator: BoxDecoration(
          color: palette.primaryLight,
          borderRadius: BorderRadius.circular(48), // 胶囊形圆角，与 Tab 高度匹配
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        // 收紧内边距：水平 12px、垂直 6px，indicator 更紧凑不溢出
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        dividerColor: Colors.transparent,
        // 禁用默认矩形 splash，用自定义胶囊形 InkWell 包裹每个 Tab
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: RankingType.values.map((type) {
          return _roundedTab(
            text: _rankingTypeLabel(type, l10n),
            isSelected: type == selectedType,
          );
        }).toList(),
      ),
    );
  }

  /// 获取排行榜类型的国际化标签
  String _rankingTypeLabel(RankingType type, AppLocalizations l10n) {
    switch (type) {
      case RankingType.download:
        return l10n.rankingTabDownload;
      case RankingType.rising:
        return l10n.rankingTabRising;
      case RankingType.update:
        return l10n.rankingTabUpdate;
      case RankingType.hot:
        return l10n.rankingTabHot;
    }
  }

  /// 胶囊形 Tab，悬浮态保持与 active 一致的整块范围，但只使用极简弱高亮。
  Widget _roundedTab({required String text, required bool isSelected}) {
    return _HoverableTab(text: text, isSelected: isSelected);
  }
}

/// 可交互的胶囊形 Tab 组件
class _HoverableTab extends StatefulWidget {
  const _HoverableTab({required this.text, required this.isSelected});

  final String text;
  final bool isSelected;

  @override
  State<_HoverableTab> createState() => _HoverableTabState();
}

class _HoverableTabState extends State<_HoverableTab> {
  static const _kHoverHighlightPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );
  static const _kTabHeight = 46.0;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showHoverHighlight = !widget.isSelected && (_isHovered || _isPressed);
    final hoverBackground = _isPressed
        ? AppColors.primary.withValues(alpha: isDark ? 0.24 : 0.10)
        : AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.06);
    final textColor = widget.isSelected || _isHovered || _isPressed
        ? AppColors.primary
        : palette.textSecondary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      // 用 Listener 而不是 GestureDetector，这样不会吸收点击事件
      child: Listener(
        onPointerDown: (_) => setState(() => _isPressed = true),
        onPointerUp: (_) => setState(() => _isPressed = false),
        onPointerCancel: (_) => setState(() => _isPressed = false),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: _kTabHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                // 与 active indicator 使用同一组边距，保证 hover 是完整胶囊而不是小圆鼓包。
                padding: _kHoverHighlightPadding,
                child: AnimatedContainer(
                  duration: AppAnimation.fast,
                  curve: AppAnimation.ease,
                  decoration: BoxDecoration(
                    color: showHoverHighlight
                        ? hoverBackground
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(48),
                  ),
                ),
              ),
              Center(
                child: Text(
                  widget.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    color: textColor,
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

/// 非活跃 Tab 使用的常量空状态，避免 copyWith 创建新对象导致误触发重建。
const _kInactiveRankingState = RankingState();

/// 排行榜 Tab 内容
///
/// 每个 Tab 独立 watch 自己类型的数据，避免整个 RankingState 变化导致其他 Tab 重建。
class _RankingTabContent extends ConsumerWidget {
  const _RankingTabContent({required this.type});

  final RankingType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    // 只 watch 当前 Tab 对应的类型数据
    // 非活跃 Tab 返回常量引用，避免 copyWith 创建新对象误触发重建
    final state = ref.watch(
      rankingProvider.select(
        (s) => s.selectedType == type ? s : _kInactiveRankingState,
      ),
    );

    // 加载中状态（仅在从未加载过时显示）
    if (state.isLoading && state.data == null) {
      return _buildLoadingState(context, l10n);
    }

    // 错误状态（仅在从未加载过时显示）
    if (state.error != null && state.data == null) {
      return ErrorState.generic(
        description: state.error,
        onRetry: () => ref.read(rankingProvider.notifier).loadData(),
      );
    }

    // 空数据状态
    if (state.data == null || state.data!.apps.isEmpty) {
      return EmptyState.noData(
        title: l10n.noRanking,
        description: l10n.errorNetworkDetail,
      );
    }

    // 正常显示
    return RefreshIndicator(
      onRefresh: () => ref.read(rankingProvider.notifier).refresh(),
      child: Semantics(
        label: l10n.a11yAppListArea,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: _AppsGrid(apps: state.data!.apps),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, AppLocalizations l10n) {
    return Semantics(
      label: l10n.loading,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppGridShimmer(itemCount: 8),
        ),
      ),
    );
  }
}

/// 应用网格（已迁移到共享 ResponsiveAppGrid）
class _AppsGrid extends StatelessWidget {
  const _AppsGrid({required this.apps});

  final List<RankingAppInfo> apps;

  @override
  Widget build(BuildContext context) {
    return ResponsiveAppGrid<RankingAppInfo>(
      items: apps,
      itemBuilder: (ref, index, app, cardState) {
        return AppCard(
          appId: app.appId,
          name: app.name,
          description: app.description,
          iconUrl: app.icon,
          rank: app.rank,
          buttonState: cardState.buttonState,
          progress: cardState.progress,
          isInstalling: cardState.isInstalling,
          onTap: () => context.push('/app/${app.appId}'),
          onPrimaryPressed: () => handleAppCardPrimaryAction(
            context: context,
            ref: ref,
            buttonState: cardState.buttonState,
            appId: app.appId,
            appName: app.name,
            icon: app.icon,
            version: app.version,
          ),
        );
      },
    );
  }
}
