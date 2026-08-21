import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/api_provider.dart';
import '../../../application/providers/app_self_update_provider.dart';
import '../../../application/providers/global_provider.dart';
import '../../../application/providers/linux_renderer_provider.dart';
import '../../../application/providers/setting_provider.dart';
import '../../../application/services/version_check_service.dart';
import '../../../core/accessibility/a11y_semantics.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/app_locale.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/platform/linux_renderer_service.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../data/datasources/remote/app_api_service.dart';
import '../../../data/models/api_dto.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/feedback_dialog.dart';
import '../../widgets/linglong_environment_management_dialog.dart';
import '../../widgets/app_update_flow.dart';
import '../../widgets/update_available_dialog.dart';
import '../../widgets/user_experience_program_dialog.dart';
import 'widgets/app_language_selector.dart';
import 'widgets/renderer_preference_tile.dart';

/// 设置页
class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

@visibleForTesting
Future<void> runSettingPageInitialization({
  required Future<String> Function() resolveAppVersion,
  required void Function(String version) setAppVersion,
  required Future<void> Function() refreshCacheSize,
  required bool Function() isMounted,
  required Future<int?> Function() fetchAppTotalCount,
  required void Function(int total) setAppTotalCount,
}) async {
  final version = await resolveAppVersion();
  setAppVersion(version);

  if (!isMounted()) return;
  await refreshCacheSize();

  if (!isMounted()) return;
  final total = await fetchAppTotalCount();
  if (!isMounted() || total == null) return;

  setAppTotalCount(total);
}

class _SettingPageState extends ConsumerState<SettingPage> {
  /// 已收录应用数量（-1 表示加载中）
  int _appTotalCount = -1;

  /// 是否正在检查商店自身的新版本
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  /// 初始化设置
  Future<void> _initSettings() async {
    final notifier = ref.read(settingProvider.notifier);
    final apiService = ref.read(appApiServiceProvider);

    await runSettingPageInitialization(
      resolveAppVersion: () async {
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          return packageInfo.version;
        } catch (_) {
          return AppConfig.appVersion;
        }
      },
      setAppVersion: notifier.setAppVersion,
      refreshCacheSize: notifier.refreshCacheSize,
      isMounted: () => mounted,
      fetchAppTotalCount: () => _fetchAppTotalCount(apiService),
      setAppTotalCount: (total) {
        if (!mounted) return;
        setState(() => _appTotalCount = total);
      },
    );
  }

  /// 获取已收录应用总数（空关键词搜索，取 total 字段）
  Future<int?> _fetchAppTotalCount(AppApiService apiService) async {
    try {
      final arch = resolveRequestArch(ref);
      final response = await apiService.getSearchAppList(
        SearchAppListRequest(
          keyword: '',
          pageNo: 1,
          pageSize: 1,
          // 设置页不再暴露仓库切换，统计统一读取默认仓库视图。
          repoName: AppConfig.defaultStoreRepoName,
          arch: arch,
        ),
      );
      return response.data.data?.total;
    } catch (e) {
      AppLogger.warning('[SettingPage] 获取应用总数失败: $e');
      return null;
    }
  }

  /// 检查商店自身的新版本（调用 Gitee Release API）
  Future<void> _checkForUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    try {
      final service = VersionCheckService();
      final currentVersion =
          ref.read(settingProvider).appVersion ?? AppConfig.appVersion;
      final result = await service.checkForUpdate(currentVersion);

      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      switch (result) {
        case VersionCheckResultNoUpdate(:final currentVersion):
          showAppNotification(context, l10n.alreadyLatest(currentVersion));
        case VersionCheckResultUpdateAvailable():
          showDialog(
            context: context,
            builder: (ctx) => UpdateAvailableDialog(
              update: result,
              onOpenUrl: _openUrl,
              onUpdateNow: () {
                Navigator.of(ctx).pop();
                // Controller 先取得 Release 快照，弹窗只观察应用级任务状态。
                unawaited(
                  ref
                      .read(appSelfUpdateControllerProvider.notifier)
                      .start(result),
                );
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AppUpdateFlowDialog(),
                );
              },
            ),
          );
        case VersionCheckResultVersionInfoMissing():
          showAppError(context, l10n.cannotGetVersion);
        case VersionCheckResultNetworkError():
          showAppError(context, l10n.checkUpdateNetworkError);
      }
    } catch (e) {
      if (mounted) {
        showAppError(
          context,
          AppLocalizations.of(context)!.checkUpdateNetworkError,
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingProvider);
    final globalState = ref.watch(globalAppProvider);
    final rendererRuntime = ref.watch(linuxRendererRuntimeProvider);
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 语言设置
          Semantics(
            label: l10n.a11ySettingsPage,
            child: _buildSectionTitle(context, l10n.languageSettings),
          ),
          _buildLanguageSection(context, globalState),

          const SizedBox(height: 24),

          // 主题设置
          _buildSectionTitle(context, l10n.themeSettings),
          _buildThemeSection(context, globalState),

          const SizedBox(height: 24),

          // 字体设置
          _buildSectionTitle(context, l10n.fontSettings),
          _buildTypographySection(context, globalState.userPreferences),

          const SizedBox(height: 24),

          // 缓存管理
          _buildSectionTitle(context, l10n.cacheManagement),
          _buildCacheSection(context, state),

          const SizedBox(height: 24),

          // 商店选项
          _buildSectionTitle(context, l10n.storeOptions),
          _buildStoreOptionsSection(
            context,
            state,
            globalState.userPreferences,
            rendererRuntime,
          ),

          const SizedBox(height: 24),

          // 关于
          Semantics(
            label: l10n.about,
            child: _buildSectionTitle(context, l10n.about),
          ),
          _buildAboutSection(context, state, globalState),
        ],
      ),
    );
  }

  /// 构建章节标题
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: context.appFontWeight(FontWeight.w600),
        ),
      ),
    );
  }

  /// 构建语言设置部分
  Widget _buildLanguageSection(BuildContext context, GlobalAppState state) {
    final l10n = AppLocalizations.of(context)!;
    return AppLanguageSelector(
      currentLocale: state.locale,
      locales: selectableAppLocales,
      label: l10n.languageSettings,
      onSelected: ref.read(globalAppProvider.notifier).setLocale,
    );
  }

  /// 构建主题设置部分
  Widget _buildThemeSection(BuildContext context, GlobalAppState state) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildThemeTile(
            context,
            mode: ThemeMode.system,
            label: l10n.themeFollowSystem,
            icon: Icons.brightness_auto,
            isSelected: state.themeMode == ThemeMode.system,
          ),
          _buildDivider(context),
          _buildThemeTile(
            context,
            mode: ThemeMode.light,
            label: l10n.themeLight,
            icon: Icons.light_mode,
            isSelected: state.themeMode == ThemeMode.light,
          ),
          _buildDivider(context),
          _buildThemeTile(
            context,
            mode: ThemeMode.dark,
            label: l10n.themeDark,
            icon: Icons.dark_mode,
            isSelected: state.themeMode == ThemeMode.dark,
          ),
        ],
      ),
    );
  }

  /// 构建字体设置部分。
  ///
  /// 字体大小与字重都会在系统设置基础上叠加用户手动调整值，
  /// 这样既保留平台一致性，又允许用户做轻量个性化微调。
  Widget _buildTypographySection(
    BuildContext context,
    UserPreferences preferences,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fontSettingsHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.fontSizeAdjustment,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.text_decrease,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: preferences.fontScaleFactor,
                    min: kMinUserFontScaleFactor,
                    max: kMaxUserFontScaleFactor,
                    divisions: 9,
                    label: l10n.fontScalePercent(
                      (preferences.fontScaleFactor * 100).round(),
                    ),
                    onChanged: (value) {
                      ref
                          .read(globalAppProvider.notifier)
                          .setFontScaleFactor(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.text_increase,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 52,
                  child: Text(
                    l10n.fontScalePercent(
                      (preferences.fontScaleFactor * 100).round(),
                    ),
                    // 数值跟随文本方向：RTL 下靠左显示
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: context.appFontWeight(FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.fontWeightAdjustmentLabel,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: context.appFontWeight(FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<AppFontWeightAdjustment>(
              segments: [
                ButtonSegment<AppFontWeightAdjustment>(
                  value: AppFontWeightAdjustment.lighter,
                  label: Text(l10n.fontWeightLighter),
                ),
                ButtonSegment<AppFontWeightAdjustment>(
                  value: AppFontWeightAdjustment.normal,
                  label: Text(l10n.fontWeightNormal),
                ),
                ButtonSegment<AppFontWeightAdjustment>(
                  value: AppFontWeightAdjustment.bolder,
                  label: Text(l10n.fontWeightBolder),
                ),
              ],
              selected: <AppFontWeightAdjustment>{
                preferences.fontWeightAdjustment,
              },
              onSelectionChanged: (selection) {
                final value = selection.first;
                ref
                    .read(globalAppProvider.notifier)
                    .setFontWeightAdjustment(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主题选项
  Widget _buildThemeTile(
    BuildContext context, {
    required ThemeMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        ref.read(globalAppProvider.notifier).setThemeMode(mode);
      },
    );
  }

  /// 构建缓存管理部分
  Widget _buildCacheSection(BuildContext context, SettingState state) {
    final cacheSizeText = formatBytes(state.cacheSize);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.cacheSize,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cacheSizeText,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: context.appFontWeight(FontWeight.w700),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: state.isClearingCache
                      ? null
                      : () => _clearCache(context),
                  icon: state.isClearingCache
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromRGBO(26, 26, 26, 0.38),
                          ),
                        )
                      : const Icon(Icons.cleaning_services, size: 18),
                  label: Text(
                    state.isClearingCache
                        ? (l10n.clearingCache)
                        : (l10n.clearCache),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.clearCacheHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 清除缓存
  Future<void> _clearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.clearCacheConfirm,
      message: l10n.clearCacheMessage,
      confirmText: l10n.clearCache,
      cancelText: l10n.cancel,
    );

    if (confirmed != true) return;

    final success = await ref.read(settingProvider.notifier).clearCache();

    if (!context.mounted) return;

    if (success) {
      showAppSuccess(context, l10n.cacheCleared);
    } else {
      showAppError(context, l10n.clearCacheFailed);
    }
  }

  /// 构建商店选项部分
  ///
  /// 收口渲染方式、启动检查、系统通知和本地环境维护等商店级行为。
  Widget _buildStoreOptionsSection(
    BuildContext context,
    SettingState state,
    UserPreferences userPreferences,
    AsyncValue<LinuxRendererRuntimeState> rendererRuntime,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          RendererPreferenceTile(
            rendererRuntime: rendererRuntime,
            rendererPreference: state.rendererPreference,
            rendererService: ref.read(linuxRendererServiceProvider),
            onPreferenceSelected: (preference) {
              return ref
                  .read(settingProvider.notifier)
                  .setRendererPreference(preference);
            },
          ),
          _buildDivider(context),
          // 启动时检查商店版本更新
          SwitchListTile(
            title: Text(l10n.startupCheckUpdate),
            subtitle: Text(l10n.startupCheckUpdateDesc),
            value: state.checkVersionOnStartup,
            onChanged: (value) {
              ref
                  .read(settingProvider.notifier)
                  .setCheckVersionOnStartup(value);
            },
          ),
          _buildDivider(context),
          // 该偏好只控制商店主动发出的完成通知；桌面环境仍保留最终展示权。
          SwitchListTile(
            secondary: const ExcludeSemantics(
              child: Icon(Icons.notifications_outlined),
            ),
            title: Text(l10n.systemNotifications),
            subtitle: Text(l10n.systemNotificationsDescription),
            value: userPreferences.enableNotifications,
            onChanged: (value) {
              ref
                  .read(globalAppProvider.notifier)
                  .setEnableNotifications(value);
            },
          ),
          _buildDivider(context),
          // 用户体验计划是全部匿名统计的总开关：关闭后启动访问记录、
          // 安装差量统计与客户端 IP 预热全部停止；感叹号入口弹窗说明
          // 计划会采集哪些信息，帮助用户放心地保持开启。
          //
          // 布局约束：A11yIconButton 固定 48x48 交互尺寸，不能塞进 title 行
          // （会把整行撑高约 28px，与相邻设置行高度不一致）；放在 trailing
          // 与开关并排，两行 tile 的高度由标题副标题决定，48px 尾件不会
          // 撑高行高。同时按钮脱离 SwitchListTile 的 MergeSemantics，
          // 屏幕阅读器可将「查看说明」作为独立按钮聚焦。
          ListTile(
            leading: const ExcludeSemantics(
              child: Icon(Icons.privacy_tip_outlined),
            ),
            title: Text(l10n.userExperienceProgram),
            subtitle: Text(l10n.userExperienceProgramDesc),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                A11yIconButton(
                  icon: const Icon(Icons.info_outline_rounded),
                  semanticsLabel: l10n.a11yUserExperienceProgramInfo,
                  tooltip: l10n.userExperienceProgram,
                  onTap: () => UserExperienceProgramDialog.show(context),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: userPreferences.joinUserExperienceProgram,
                  onChanged: (value) {
                    ref
                        .read(globalAppProvider.notifier)
                        .setJoinUserExperienceProgram(value);
                  },
                ),
              ],
            ),
            onTap: () {
              ref.read(globalAppProvider.notifier).setJoinUserExperienceProgram(
                !userPreferences.joinUserExperienceProgram,
              );
            },
          ),
          _buildDivider(context),
          // 已安装列表中显示基础运行服务
          SwitchListTile(
            title: Text(l10n.showBaseServices),
            subtitle: Text(l10n.showBaseServicesDesc),
            value: state.showBaseService,
            onChanged: (value) {
              ref.read(settingProvider.notifier).setShowBaseService(value);
            },
          ),
          _buildDivider(context),
          ListTile(
            // 入口图标统一使用中性灰（onSurfaceVariant），与主题选项等其他列表项保持一致，
            // 避免单独使用主题蓝（primary）造成视觉上与其他设置项不一致。
            leading: Icon(
              Icons.settings_suggest_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: Text(l10n.envManagementTitle),
            subtitle: Text(l10n.envManagementDescription),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLinglongEnvironmentManagementDialog(context),
          ),
          _buildDivider(context),
          // 清理废弃基础服务
          ListTile(
            leading: Icon(
              Icons.cleaning_services_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text(l10n.cleanDeprecatedServices),
            subtitle: Text(l10n.cleanDeprecatedServicesDesc),
            trailing: state.isPruningBaseService
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            onTap: state.isPruningBaseService
                ? null
                : () => _pruneBaseService(context),
          ),
        ],
      ),
    );
  }

  /// 执行清理废弃基础服务
  Future<void> _pruneBaseService(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ConfirmDialog.show(
      context,
      title: l10n.cleanDeprecatedServices,
      message: l10n.pruneBaseServiceMessage,
      confirmText: l10n.clean,
      cancelText: l10n.cancel,
    );

    if (confirmed != true) return;

    final success = await ref.read(settingProvider.notifier).pruneBaseService();

    if (!context.mounted) return;

    if (success) {
      showAppSuccess(context, l10n.baseServiceCleaned);
    } else {
      showAppError(context, l10n.cleanFailed);
    }
  }

  /// 构建关于部分
  Widget _buildAboutSection(
    BuildContext context,
    SettingState state,
    GlobalAppState globalState,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 应用图标和名称
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.store,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: context.appFontWeight(FontWeight.w700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 版本信息
            _buildInfoRow(
              context,
              label: l10n.appVersion,
              value: state.appVersion ?? AppConfig.appVersion,
            ),
            _buildDivider(context),

            // 开发者信息
            _buildInfoRow(
              context,
              label: l10n.developer,
              value: l10n.linglongCommunity,
            ),
            _buildDivider(context),

            // 已收录应用数量
            _buildInfoRow(
              context,
              label: l10n.appCount,
              value: _appTotalCount < 0
                  ? (l10n.loading)
                  : l10n.appCountValue(_appTotalCount),
            ),
            _buildDivider(context),

            // 系统架构
            _buildInfoRow(
              context,
              label: l10n.systemArch,
              value: globalState.arch ?? (l10n.unknown),
            ),
            _buildDivider(context),

            // 玲珑版本（即 ll-cli 版本，二者相同）
            _buildInfoRow(
              context,
              label: l10n.linglongVersion,
              value: globalState.llVersion ?? (l10n.unknown),
            ),

            const SizedBox(height: 16),

            // 检查更新 + 意见反馈
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _isCheckingUpdate ? null : _checkForUpdate,
                  icon: _isCheckingUpdate
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.system_update_alt, size: 18),
                  label: Text(l10n.checkNewVersion),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const FeedbackDialog(),
                  ),
                  icon: const Icon(Icons.feedback_outlined, size: 18),
                  label: Text(l10n.feedbackMenu),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 链接数量较多，使用 Wrap 避免窄窗口下按钮溢出。
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _openUrl(
                    'https://github.com/HanHan666666/flutter-linglong-store',
                  ),
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('GitHub'),
                ),
                TextButton.icon(
                  onPressed: () => _openUrl(
                    'https://gitee.com/hanplus/flutter-linglong-store',
                  ),
                  icon: const Icon(Icons.code_outlined, size: 18),
                  label: const Text('Gitee'),
                ),
                TextButton.icon(
                  onPressed: () => _openUrl('https://linyaps.org.cn/'),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(l10n.officialWebsite),
                ),
                // 社区交流入口与其他关于区外链保持同级展示。
                TextButton.icon(
                  onPressed: () => _openUrl(AppConfig.communityForumUrl),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text(l10n.communityExchange),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _openUrl('https://linyaps.org.cn/linyaps-store-sig'),
                  icon: const Icon(Icons.groups_2_outlined, size: 18),
                  label: Text(l10n.aboutDevelopers),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: context.appFontWeight(FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分割线
  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  /// 打开外部链接
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      showLinkOpenError(context, url);
    }
  }
}
