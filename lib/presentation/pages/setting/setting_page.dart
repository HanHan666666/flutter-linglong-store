import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/providers/api_provider.dart';
import '../../../application/providers/global_provider.dart';
import '../../../application/providers/setting_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/logging/app_logger.dart';
import '../../../data/models/api_dto.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/feedback_dialog.dart';

/// 设置页
class SettingPage extends ConsumerStatefulWidget {
  const SettingPage({super.key});

  @override
  ConsumerState<SettingPage> createState() => _SettingPageState();
}

/// Gitee Latest Release API
const _kGiteeLatestApi =
    'https://gitee.com/api/v5/repos/Shirosu/linglong-store/releases/latest';

class _SettingPageState extends ConsumerState<SettingPage> {
  /// 仓库输入控制器
  final _repoController = TextEditingController();

  /// 已收录应用数量（-1 表示加载中）
  int _appTotalCount = -1;

  /// 是否正在检查商店自身的新版本
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    _initSettings();
  }

  @override
  void dispose() {
    _repoController.dispose();
    super.dispose();
  }

  /// 初始化设置
  Future<void> _initSettings() async {
    final notifier = ref.read(settingProvider.notifier);

    // 获取应用版本
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      notifier.setAppVersion(packageInfo.version);
    } catch (e) {
      notifier.setAppVersion(AppConfig.appVersion);
    }

    // 缓存体积属于非启动关键路径，进入设置页后再异步刷新即可。
    await notifier.refreshCacheSize();

    // 异步获取已收录应用总数
    _fetchAppTotalCount();
  }

  /// 获取已收录应用总数（空关键词搜索，取 total 字段）
  Future<void> _fetchAppTotalCount() async {
    try {
      final apiService = ref.read(appApiServiceProvider);
      final settingState = ref.read(settingProvider);
      final response = await apiService.getSearchAppList(
        SearchAppListRequest(
          keyword: '',
          pageNo: 1,
          pageSize: 1,
          repoName: settingState.repoName,
        ),
      );
      final total = response.data.data?.total;
      if (mounted && total != null) setState(() => _appTotalCount = total);
    } catch (e) {
      AppLogger.warning('[SettingPage] 获取应用总数失败: $e');
    }
  }

  /// 检查商店自身的新版本（调用 Gitee Release API）
  Future<void> _checkForUpdate() async {
    if (_isCheckingUpdate) return;
    setState(() => _isCheckingUpdate = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        _kGiteeLatestApi,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      final tagName = response.data['tag_name'] as String?;
      if (!mounted) return;
      if (tagName == null) {
        _showSnackBar('无法获取版本信息');
        return;
      }
      final currentVersion =
          ref.read(settingProvider).appVersion ?? AppConfig.appVersion;
      final isNewer = _isVersionNewer(currentVersion, tagName);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.checkUpdate ?? '检查更新'),
          content: isNewer
              ? Text(
                  l10n?.newVersionFound(tagName, currentVersion) ??
                      '发现新版本 $tagName！\n当前版本：$currentVersion',
                )
              : Text(
                  l10n?.alreadyLatest(currentVersion) ??
                      '当前已是最新版本 ($currentVersion)',
                ),
          actions: [
            if (isNewer)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openUrl(
                    'https://gitee.com/Shirosu/linglong-store/releases/latest',
                  );
                },
                child: Text(l10n?.goDownload ?? '前往下载'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.confirm ?? '确定'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) _showSnackBar('检查更新失败，请检查网络连接');
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  /// 简单 semver 比较，返回 latest 是否比 current 新
  bool _isVersionNewer(String current, String latest) {
    (int, int, int)? parse(String s) {
      s = s.replaceAll(RegExp(r'^v'), '');
      final parts = s.split('.');
      if (parts.length < 3) return null;
      final major = int.tryParse(parts[0]);
      final minor = int.tryParse(parts[1]);
      final patch = int.tryParse(parts[2].split(RegExp(r'[^0-9]')).first);
      if (major == null || minor == null || patch == null) return null;
      return (major, minor, patch);
    }

    final c = parse(current);
    final l = parse(latest);
    if (c == null || l == null) return false;
    if (l.$1 != c.$1) return l.$1 > c.$1;
    if (l.$2 != c.$2) return l.$2 > c.$2;
    return l.$3 > c.$3;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingProvider);
    final globalState = ref.watch(globalAppProvider);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 语言设置
          _buildSectionTitle(context, l10n?.languageSettings ?? '语言设置'),
          _buildLanguageSection(context, state),

          const SizedBox(height: 24),

          // 主题设置
          _buildSectionTitle(context, l10n?.themeSettings ?? '主题设置'),
          _buildThemeSection(context, state),

          const SizedBox(height: 24),

          // 仓库配置
          _buildSectionTitle(context, l10n?.repoConfig ?? '仓库配置'),
          _buildRepoSection(context, state),

          const SizedBox(height: 24),

          // 缓存管理
          _buildSectionTitle(context, l10n?.cacheManagement ?? '缓存管理'),
          _buildCacheSection(context, state),

          const SizedBox(height: 24),

          // 商店选项
          _buildSectionTitle(context, l10n?.storeOptions ?? '商店选项'),
          _buildStoreOptionsSection(context, state),

          const SizedBox(height: 24),

          // 关于
          _buildSectionTitle(context, l10n?.about ?? '关于'),
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
  Widget _buildLanguageSection(BuildContext context, SettingState state) {
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
            label: '中文',
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
      groupValue: isSelected ? locale : null,
      onChanged: (value) {
        if (value != null) {
          // 同时更新两个 Provider
          ref.read(settingProvider.notifier).setLocale(value);
          ref.read(globalAppProvider.notifier).setLocale(value);
        }
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  /// 构建主题设置部分
  Widget _buildThemeSection(BuildContext context, SettingState state) {
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
            label: '跟随系统',
            icon: Icons.brightness_auto,
            isSelected: state.themeMode == ThemeMode.system,
          ),
          _buildDivider(context),
          _buildThemeTile(
            context,
            mode: ThemeMode.light,
            label: '浅色模式',
            icon: Icons.light_mode,
            isSelected: state.themeMode == ThemeMode.light,
          ),
          _buildDivider(context),
          _buildThemeTile(
            context,
            mode: ThemeMode.dark,
            label: '深色模式',
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
        // 同时更新两个 Provider
        ref.read(settingProvider.notifier).setThemeMode(mode);
        ref.read(globalAppProvider.notifier).setThemeMode(mode);
      },
    );
  }

  /// 构建仓库配置部分
  Widget _buildRepoSection(BuildContext context, SettingState state) {
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
            Text(
              '当前仓库源',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.repoName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showRepoEditDialog(context, state),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(AppLocalizations.of(context)?.modifyBtn ?? '修改'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '可选仓库',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: defaultRepos.map((repo) {
                final isSelected = repo == state.repoName;
                return FilterChip(
                  label: Text(repo),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      _updateRepo(repo);
                    }
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 更新仓库
  void _updateRepo(String repoName) {
    ref.read(settingProvider.notifier).setRepoName(repoName);
    ref.read(globalAppProvider.notifier).setRepoName(repoName);

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.repoSwitched(repoName) ?? '仓库已切换为: $repoName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 显示仓库编辑对话框
  Future<void> _showRepoEditDialog(
    BuildContext context,
    SettingState state,
  ) async {
    _repoController.text = state.repoName;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n?.editRepo ?? '修改仓库源'),
          content: TextField(
            controller: _repoController,
            decoration: const InputDecoration(
              labelText: '仓库名称',
              hintText: '例如: repo:linglong',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.cancel ?? '取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = _repoController.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(context).pop(value);
                }
              },
              child: Text(l10n?.confirm ?? '确定'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      _updateRepo(result);
    }
  }

  /// 构建缓存管理部分
  Widget _buildCacheSection(BuildContext context, SettingState state) {
    final cacheSizeText = formatBytes(state.cacheSize);

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
                      AppLocalizations.of(context)?.cacheSize ?? '缓存大小',
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
                  label: Text(state.isClearingCache ? '清除中...' : '清除缓存'),
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
              '清除缓存可以释放存储空间，但可能会导致应用需要重新加载数据。',
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
    final confirmed = await ConfirmDialog.show(
      context,
      title: '确认清除缓存',
      message: '确定要清除所有缓存数据吗？这可能会影响应用的加载速度。',
      confirmText: '清除',
      cancelText: '取消',
    );

    if (confirmed != true) return;

    final success = await ref.read(settingProvider.notifier).clearCache();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '缓存已清除' : '清除缓存失败'),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 构建商店选项部分
  ///
  /// 包含三个行为开关和一个清理废弃基础服务的操作按钮。
  Widget _buildStoreOptionsSection(BuildContext context, SettingState state) {
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
            title: Text(
              AppLocalizations.of(context)?.startupCheckUpdate ?? '启动时检查商店版本更新',
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.startupCheckUpdateDesc ??
                  '每次启动时检测是否有新版本可用',
            ),
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
            title: Text(
              AppLocalizations.of(context)?.autoUpdateInContainer ??
                  '容器内自动更新商店本体',
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.autoUpdateInContainerDesc ??
                  '在玲珑容器内运行时自动更新商店应用',
            ),
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
            title: Text(
              AppLocalizations.of(context)?.showBaseServices ?? '显示基础运行服务',
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.showBaseServicesDesc ??
                  '在已安装列表中显示底层基础运行服务',
            ),
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
            title: Text(
              AppLocalizations.of(context)?.cleanDeprecatedServices ??
                  '清理废弃基础服务',
            ),
            subtitle: Text(
              AppLocalizations.of(context)?.cleanDeprecatedServicesDesc ??
                  '移除已不再使用的基础运行服务，释放磁盘空间',
            ),
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
    final confirmed = await ConfirmDialog.show(
      context,
      title: '清理废弃基础服务',
      message:
          '将执行 ll-cli prune 命令，移除所有已不再被任何应用依赖的基础运行服务。\n\n清理后可节省磁盘空间，但如进行中有其他操作可能需要重新下载。',
      confirmText: '清理',
      cancelText: '取消',
    );

    if (confirmed != true) return;

    final success = await ref.read(settingProvider.notifier).pruneBaseService();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '废弃基础服务已清理' : '清理失败，请稍后重试'),
        backgroundColor: success
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// 构建关于部分
  Widget _buildAboutSection(
    BuildContext context,
    SettingState state,
    GlobalAppState globalState,
  ) {
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
              label: '应用版本',
              value: state.appVersion ?? AppConfig.appVersion,
            ),
            _buildDivider(context),

            // 开发者信息
            _buildInfoRow(context, label: '开发者', value: '玲珑社区'),
            _buildDivider(context),

            // 已收录应用数量
            _buildInfoRow(
              context,
              label: '已收录应用数量',
              value: _appTotalCount < 0 ? '加载中...' : '$_appTotalCount 个',
            ),
            _buildDivider(context),

            // 系统架构
            _buildInfoRow(
              context,
              label: '系统架构',
              value: globalState.arch ?? '未知',
            ),
            _buildDivider(context),

            // 玲珑版本
            _buildInfoRow(
              context,
              label: '玲珑版本',
              value: globalState.llVersion ?? '未知',
            ),
            _buildDivider(context),

            // ll-cli 版本
            _buildInfoRow(
              context,
              label: 'll-cli 版本',
              value: globalState.llBinVersion ?? '未知',
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
                  label: Text(
                    AppLocalizations.of(context)?.checkNewVersion ?? '检查新版本',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const FeedbackDialog(),
                  ),
                  icon: const Icon(Icons.feedback_outlined, size: 18),
                  label: Text(
                    AppLocalizations.of(context)?.feedbackMenu ?? '意见反馈',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 项目链接
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _openUrl('https://github.com/linglong-dev'),
                  icon: const Icon(Icons.code, size: 18),
                  label: const Text('GitHub'),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _openUrl('https://linglong.dev'),
                  icon: const Icon(Icons.language, size: 18),
                  label: Text(
                    AppLocalizations.of(context)?.officialWebsite ?? '官网',
                  ),
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
      _showSnackBar(
        AppLocalizations.of(context)?.cannotOpenLink(url) ?? '无法打开链接: $url',
      );
    }
  }
}
