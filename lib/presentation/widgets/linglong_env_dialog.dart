import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/providers/linglong_env_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/platform/window_service.dart';
import '../../domain/models/linglong_env_check_result.dart';

/// 玲珑环境检测对话框
///
/// 在启动时检测玲珑环境，如果环境异常则显示此对话框，
/// 提供退出、手动安装、自动安装、重新检测等操作
class LinglongEnvDialog extends ConsumerWidget {
  const LinglongEnvDialog({super.key});

  /// 显示对话框
  ///
  /// [forceShow] 强制显示，即使环境正常
  static Future<void> show(BuildContext context, {bool forceShow = false}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LinglongEnvDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envState = ref.watch(linglongEnvProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.smRadius,
        side: const BorderSide(color: AppColors.modalBorder),
      ),
      elevation: 0,
      backgroundColor: context.appColors.surface,
      title: Row(
        children: [
          Icon(
            envState.checkState == LinglongEnvCheckState.checking
                ? Icons.info_outline
                : (envState.result?.isOk ?? false
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded),
            color: envState.checkState == LinglongEnvCheckState.checking
                ? AppColors.info
                : (envState.result?.isOk ?? false
                      ? AppColors.success
                      : AppColors.warning),
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            AppLocalizations.of(context)?.envCheckTitle ?? '环境检测',
            style: AppTextStyles.title3.copyWith(
              color: context.appColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: _buildContent(context, ref, envState),
      ),
      actions: envState.isInstalling
          ? null
          : _buildActions(context, ref, envState),
    );
  }

  /// 构建内容区域
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LinglongEnvState envState,
  ) {
    if (envState.isInstalling) {
      return _buildInstallProgress(context, ref, envState);
    }

    if (envState.isChecking) {
      return _buildCheckingContent(context);
    }

    return _buildResultContent(context, ref, envState);
  }

  /// 构建检测中内容
  Widget _buildCheckingContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          AppLocalizations.of(context)?.checkingLinglongEnv ?? '正在检测玲珑环境...',
          style: AppTextStyles.body.copyWith(
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// 构建检测结果内容
  Widget _buildResultContent(
    BuildContext context,
    WidgetRef ref,
    LinglongEnvState envState,
  ) {
    final result = envState.result;

    if (result == null) {
      return Text(
        AppLocalizations.of(context)?.unknownStatus ?? '未知状态',
        style: AppTextStyles.body.copyWith(
          color: context.appColors.textSecondary,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 状态摘要
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: result.isOk
                ? AppColors.success.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: AppRadius.smRadius,
          ),
          child: Row(
            children: [
              Icon(
                result.isOk ? Icons.check_circle : Icons.error_outline,
                color: result.isOk ? AppColors.success : AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  result.statusDescription,
                  style: AppTextStyles.body.copyWith(
                    color: result.isOk ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 详细信息
        _buildDetailItem(
          context,
          AppLocalizations.of(context)?.llCliVersion ?? 'll-cli 版本',
          AppLocalizations.of(context)?.notDetected ?? '未检测到',
          result.llCliVersion != null,
        ),

        // 错误信息
        if (result.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: AppRadius.smRadius,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      AppLocalizations.of(context)?.errorMessage ?? '错误信息',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  result.errorMessage ?? '',
                  style: AppTextStyles.caption.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
                if (result.errorDetail != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.errorDetail ?? '',
                    style: AppTextStyles.tiny.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 构建详情项
  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    bool isOk,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.appColors.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Icon(
                isOk ? Icons.check : Icons.close,
                color: isOk ? AppColors.success : AppColors.error,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建安装进度
  Widget _buildInstallProgress(
    BuildContext context,
    WidgetRef ref,
    LinglongEnvState envState,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: 280,
          child: LinearProgressIndicator(
            value: envState.installProgress,
            backgroundColor: context.appColors.cardBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          envState.installMessage ?? AppLocalizations.of(context)?.installingLinglong ?? '正在安装...',
          style: AppTextStyles.body.copyWith(
            color: context.appColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// 构建操作按钮
  List<Widget> _buildActions(
    BuildContext context,
    WidgetRef ref,
    LinglongEnvState envState,
  ) {
    final result = envState.result;
    final canSkip = result?.canSkip ?? false;

    return [
      // 退出商店按钮
      TextButton(
        onPressed: () => _handleExit(context),
        child: Text(
          AppLocalizations.of(context)?.exitStore ?? '退出商店',
          style: TextStyle(color: context.appColors.textSecondary),
        ),
      ),

      // 手动安装按钮
      TextButton.icon(
        onPressed: () => _handleManualInstall(context, ref),
        icon: const Icon(Icons.open_in_new, size: 16),
        label: Text(AppLocalizations.of(context)?.manualInstall ?? '手动安装'),
        style: TextButton.styleFrom(foregroundColor: AppColors.info),
      ),

      // 自动安装按钮
      ElevatedButton.icon(
        onPressed: result?.isOk == true
            ? null
            : () => _handleAutoInstall(context, ref),
        icon: const Icon(Icons.download, size: 16),
        label: Text(AppLocalizations.of(context)?.autoInstall ?? '自动安装'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),

      // 重新检测按钮
      OutlinedButton.icon(
        onPressed: () => _handleRecheck(context, ref),
        icon: const Icon(Icons.refresh, size: 16),
        label: Text(AppLocalizations.of(context)?.recheck ?? '重新检测'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.appColors.textPrimary,
          side: BorderSide(color: context.appColors.border),
        ),
      ),

      // 跳过按钮（仅在部分功能可用时显示）
      if (canSkip)
        TextButton(
          onPressed: () => _handleSkip(context, ref),
          child: Text(
            AppLocalizations.of(context)?.skipCheck ?? '跳过检测',
            style: TextStyle(color: context.appColors.textSecondary),
          ),
        ),
    ];
  }

  /// 处理退出
  void _handleExit(BuildContext context) {
    Navigator.of(context).pop();
    WindowService.close();
  }

  /// 处理手动安装
  Future<void> _handleManualInstall(BuildContext context, WidgetRef ref) async {
    final envNotifier = ref.read(linglongEnvProvider.notifier);
    final url = envNotifier.getInstallDocUrl();

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.cannotOpenLink(url) ??
                  '无法打开链接: $url',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 处理自动安装
  Future<void> _handleAutoInstall(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(linglongEnvProvider.notifier)
        .performAutoInstall();

    if (success && context.mounted) {
      // 自动安装成功后检查环境是否正常
      final envState = ref.read(linglongEnvProvider);
      if (envState.result?.isOk ?? false) {
        // 环境正常，关闭对话框，由 launch_page 继续启动流程
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.envCheckPassed ?? '安装完成，环境检测通过',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        // 环境仍异常，提示用户
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.envCheckFailed ?? '安装完成，但环境仍异常，请检查',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  /// 处理重新检测
  Future<void> _handleRecheck(BuildContext context, WidgetRef ref) async {
    await ref.read(linglongEnvProvider.notifier).recheck();
    // 重新检测后如果环境正常，关闭对话框
    final envState = ref.read(linglongEnvProvider);
    if (envState.result?.isOk ?? false) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// 处理跳过
  ///
  /// 跳过环境检测，允许用户继续使用应用
  /// 注意：跳过后部分功能可能不可用
  void _handleSkip(BuildContext context, WidgetRef ref) {
    // 标记环境为"跳过"状态，允许继续启动
    ref.read(linglongEnvProvider.notifier).skipCheck();
    Navigator.of(context).pop();
  }
}

/// 玲珑环境对话框包装器
///
/// 用于在启动时自动检测并显示对话框
class LinglongEnvDialogWrapper extends ConsumerStatefulWidget {
  const LinglongEnvDialogWrapper({
    super.key,
    required this.child,
    this.onEnvOk,
    this.onEnvFailed,
  });

  /// 子组件
  final Widget child;

  /// 环境正常回调
  final VoidCallback? onEnvOk;

  /// 环境异常回调
  final VoidCallback? onEnvFailed;

  @override
  ConsumerState<LinglongEnvDialogWrapper> createState() =>
      _LinglongEnvDialogWrapperState();
}

class _LinglongEnvDialogWrapperState
    extends ConsumerState<LinglongEnvDialogWrapper> {
  bool _hasChecked = false;
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkEnvironment();
    });
  }

  Future<void> _checkEnvironment() async {
    if (_hasChecked) return;
    _hasChecked = true;

    final result = await ref
        .read(linglongEnvProvider.notifier)
        .checkEnvironment();

    if (result.isOk) {
      widget.onEnvOk?.call();
    } else {
      widget.onEnvFailed?.call();
      if (mounted && !_dialogShown) {
        _dialogShown = true;
        await LinglongEnvDialog.show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
