import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../application/providers/launch_provider.dart';
import '../../../application/providers/linglong_env_provider.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/routes.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../widgets/linglong_env_dialog.dart';

/// 启动页面
///
/// 应用启动时显示的初始化页面，包含：
/// - Logo 展示
/// - 进度条
/// - 步骤文案
/// - 错误处理
class LaunchPage extends ConsumerStatefulWidget {
  const LaunchPage({super.key});

  @override
  ConsumerState<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends ConsumerState<LaunchPage>
    with SingleTickerProviderStateMixin {
  /// 动画控制器
  late final AnimationController _animationController;

  /// Logo 缩放动画
  late final Animation<double> _logoScaleAnimation;

  /// Logo 透明度动画
  late final Animation<double> _logoOpacityAnimation;

  /// 环境对话框是否已显示
  bool _envDialogShown = false;

  /// 应用版本号（动态获取）
  String _appVersion = AppConfig.appVersion;

  @override
  void initState() {
    super.initState();

    // 初始化动画（零动画模式：瞬切）
    _animationController = AnimationController(
      duration: Duration.zero,
      vsync: this,
    );

    // Logo 缩放动画 (从 0.8 到 1.0)
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Logo 透明度动画 (从 0.0 到 1.0)
    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // 启动动画
    _animationController.forward();

    // 异步获取版本号
    _loadAppVersion();

    // 延迟执行启动序列
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLaunchSequence();
    });
  }

  /// 异步获取应用版本号
  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = packageInfo.version;
        });
      }
    } catch (_) {
      // 获取失败时保持使用 AppConfig.appVersion fallback
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 启动初始化序列
  Future<void> _startLaunchSequence() async {
    await ref.read(launchSequenceProvider.notifier).runSequence();
  }

  /// 导航到主页
  void _navigateToHome() {
    if (mounted) {
      context.go(AppRoutes.recommend);
    }
  }

  @override
  Widget build(BuildContext context) {
    final launchState = ref.watch(launchSequenceProvider);
    final envState = ref.watch(linglongEnvProvider);

    // 监听启动完成
    ref.listen<LaunchState>(launchSequenceProvider, (previous, next) {
      if (next.isCompleted && !next.hasError) {
        // 延迟一小段时间后跳转，让用户看到完成状态
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _navigateToHome();
          }
        });
      }
    });

    // 监听环境检测状态，显示对话框
    ref.listen<LinglongEnvState>(linglongEnvProvider, (previous, next) {
      if (next.shouldShowDialog && !_envDialogShown) {
        _envDialogShown = true;
        _showEnvDialog();
      }
    });

    return Scaffold(
      backgroundColor: context.appColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _logoOpacityAnimation.value,
              child: Transform.scale(
                scale: _logoScaleAnimation.value,
                child: child,
              ),
            );
          },
          child: _buildContent(context, launchState, envState),
        ),
      ),
    );
  }

  /// 显示环境检测对话框
  Future<void> _showEnvDialog() async {
    await LinglongEnvDialog.show(context);
    // 对话框关闭后，如果环境正常或用户跳过则继续启动
    final envState = ref.read(linglongEnvProvider);
    if (envState.canContinue) {
      ref.read(launchSequenceProvider.notifier).continueAfterEnvCheck();
    }
    _envDialogShown = false;
  }

  /// 构建内容
  Widget _buildContent(
    BuildContext context,
    LaunchState launchState,
    LinglongEnvState envState,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          _buildLogo(),

          const SizedBox(height: 48),

          // 应用名称
          _buildAppName(context),

          const SizedBox(height: 8),

          // 步骤文案
          _buildStepMessage(context, launchState, envState),

          const SizedBox(height: 32),

          // 进度条或错误提示
          if (launchState.hasError)
            _buildErrorSection(context, launchState)
          else
            _buildProgressSection(context, launchState),

          const SizedBox(height: 48),

          // 版本信息
          _buildVersionInfo(context),
        ],
      ),
    );
  }

  /// 构建 Logo
  Widget _buildLogo() {
    return SvgPicture.asset('assets/icons/logo.svg', width: 120, height: 120);
  }

  /// 构建应用名称
  Widget _buildAppName(BuildContext context) {
    return Text(
      AppLocalizations.of(context)?.appTitleShort ?? '玲珑应用商店',
      style: AppTextStyles.title1.copyWith(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// 构建步骤消息
  Widget _buildStepMessage(
    BuildContext context,
    LaunchState launchState,
    LinglongEnvState envState,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // 如果环境正在检测，显示环境检测状态
    String message;
    if (envState.isChecking) {
      message = l10n.detectingEnv;
    } else {
      // 根据当前步骤获取国际化步骤标签
      message = _stepLabel(launchState.currentStep, l10n);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        message,
        key: ValueKey(message),
        style: AppTextStyles.body.copyWith(
          color: context.appColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 根据启动步骤获取国际化标签
  String _stepLabel(LaunchStep step, AppLocalizations l10n) {
    switch (step) {
      case LaunchStep.environmentCheck:
        return l10n.detectingEnv;
      case LaunchStep.installedAppsInit:
        return l10n.loadingInstalledApps;
      case LaunchStep.updateCheck:
        return l10n.checkingUpdate;
      case LaunchStep.queueRecovery:
        return l10n.stepQueueRecovery;
      case LaunchStep.completed:
        return l10n.success;
      case LaunchStep.error:
        return l10n.launchFailedTitle;
    }
  }

  /// 构建进度区域
  Widget _buildProgressSection(BuildContext context, LaunchState launchState) {
    return Column(
      children: [
        // 进度条
        SizedBox(
          width: 280,
          child: LinearProgressIndicator(
            value: launchState.totalProgress,
            backgroundColor: context.appColors.cardBackground,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 16),

        // 步骤指示器
        _buildStepIndicators(context, launchState),
      ],
    );
  }

  /// 构建步骤指示器
  Widget _buildStepIndicators(BuildContext context, LaunchState launchState) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [
      (LaunchStep.environmentCheck, l10n.stepEnvCheck),
      (LaunchStep.installedAppsInit, l10n.stepAppLoad),
      (LaunchStep.updateCheck, l10n.stepUpdateCheck),
      (LaunchStep.queueRecovery, l10n.stepQueueRecovery),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final (step, label) = entry.value;
        final currentIndex = LaunchStep.values.indexOf(launchState.currentStep);
        final stepIndex = LaunchStep.values.indexOf(step);
        final isActive = stepIndex <= currentIndex;
        final isCurrent = step == launchState.currentStep;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 步骤点
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primary : context.appColors.border,
                border: isCurrent
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
              ),
            ),

            // 分隔线
            if (index < steps.length - 1)
              Container(
                width: 24,
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: context.appColors.border,
              ),
          ],
        );
      }).toList(),
    );
  }

  /// 构建错误区域
  Widget _buildErrorSection(BuildContext context, LaunchState launchState) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 错误图标
          const Icon(Icons.error_outline, color: AppColors.error, size: 32),

          const SizedBox(height: 12),

          // 错误消息
          Text(
            launchState.errorMessage ??
                AppLocalizations.of(context)?.launchFailedTitle ??
                '启动失败',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 重试按钮
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(launchSequenceProvider.notifier).retry();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(AppLocalizations.of(context)?.retry ?? '重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 跳过按钮
              TextButton(
                onPressed: () {
                  ref.read(launchSequenceProvider.notifier).skipCurrentStep();
                },
                child: Text(
                  AppLocalizations.of(context)?.skip ?? '跳过',
                  style: TextStyle(color: context.appColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建版本信息
  Widget _buildVersionInfo(BuildContext context) {
    return Text(
      'v$_appVersion',
      style: AppTextStyles.caption.copyWith(
        color: context.appColors.textTertiary,
      ),
    );
  }
}
