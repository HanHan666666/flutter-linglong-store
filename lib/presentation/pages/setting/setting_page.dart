import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/api_provider.dart';
import '../../../application/providers/global_provider.dart';
import '../../../application/providers/setting_provider.dart';
import '../../../application/services/version_check_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/app_notification_helpers.dart';
import '../../../data/datasources/remote/app_api_service.dart';
import '../../../data/models/api_dto.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/feedback_dialog.dart';

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
        case VersionCheckResultUpdateAvailable(
          :final latestVersion,
          :final currentVersion,
        ):
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.checkUpdate),
              content: Text(
                l10n.newVersionFound(latestVersion, currentVersion),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _openUrl(
                      'https://gitee.com/Shirosu/linglong-store/releases/latest',
                    );
                  },
                  child: Text(l10n.goDownload),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.confirm),
                ),
              ],
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
          AppLocalizations.of(context)?.checkUpdateNetworkError ??
              '检查更新失败，请检查网络连接',
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

          // 缓存管理
          _buildSectionTitle(context, l10n.cacheManagement),
          _buildCacheSection(context, state),

          const SizedBox(height: 24),

          // 商店选项
          _buildSectionTitle(context, l10n.storeOptions),
          _buildStoreOptionsSection(context, state),

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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 构建语言设置部分
  Widget _buildLanguageSection(BuildContext context, GlobalAppState state) {
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
          _buildLanguageTile(
            context,
            locale: const Locale('zh'),
            label: l10n.languageZh,
            isSelected: state.locale.languageCode == 'zh',
          ),
          _buildDivider(context),
          _buildLanguageTile(
            context,
            locale: const Locale('en'),
            label: 'English',
            isSelected: state.locale.languageCode == 'en',
          ),
        ],
      ),
    );
  }

  /// 构建语言选项
  Widget _buildLanguageTile(
    BuildContext context, {
    required Locale locale,
    required String label,
    required bool isSelected,
  }) {
    return RadioListTile<Locale>(
      title: Text(label),
      value: locale,
      groupValue: isSelected ? locale : null, // ignore: deprecated_member_use
      // ignore: deprecated_member_use
      onChanged: (value) {
        if (value != null) {
          ref.read(globalAppProvider.notifier).setLocale(value);
        }
      },
      activeColor: Theme.of(context).colorScheme.primary,
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
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: state.isClearingCache
                      ? null
                      : () => _clearCache(context),
                  icon: state.isClearingCache
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cleaning_services, size: 18),
                  label: Text(
                    state.isClearingCache
                        ? (l10n.clearingCache)
                        : (l10n.clearCache),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onErrorContainer,
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
  /// 包含三个行为开关和一个清理废弃基础服务的操作按钮。
  Widget _buildStoreOptionsSection(BuildContext context, SettingState state) {
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
          // 容器内自动更新商店本体
          SwitchListTile(
            title: Text(l10n.autoUpdateInContainer),
            subtitle: Text(l10n.autoUpdateInContainerDesc),
            value: state.autoUpdateStoreInContainer,
            onChanged: (value) {
              ref
                  .read(settingProvider.notifier)
                  .setAutoUpdateStoreInContainer(value);
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
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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

            // 项目链接
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _openUrl(
                    'https://github.com/HanHan666666/flutter-linglong-store',
                  ),
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('GitHub'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _openUrl('https://linyaps.org.cn/'),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(l10n.officialWebsite),
                ),
                const SizedBox(width: 16),
                // 社区交流入口与其他关于区外链保持同级展示。
                TextButton.icon(
                  onPressed: () =>
                      _openUrl('https://bbs.deepin.org.cn/module/detail/230'),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text(l10n.communityExchange),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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
