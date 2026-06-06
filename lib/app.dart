import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/global_provider.dart';
import 'application/providers/og_install_controller.dart';
import 'core/accessibility/accessibility.dart';
import 'core/config/routes.dart';
import 'core/config/theme.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/platform/native_menu_theme_sync.dart';
import 'core/platform/single_instance.dart';
import 'core/utils/app_notification_helpers.dart';

/// 玲珑应用商店 MaterialApp 配置
class LinglongStoreApp extends ConsumerWidget {
  const LinglongStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听语言和主题状态
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(currentThemeModeProvider);
    final fontScaleFactor = ref.watch(
      globalAppProvider.select(
        (state) => state.userPreferences.fontScaleFactor,
      ),
    );
    final fontWeightAdjustment = ref.watch(
      globalAppProvider.select(
        (state) => state.userPreferences.fontWeightAdjustment,
      ),
    );
    final router = ref.watch(routerProvider);
    final platformBoldText = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .boldText;

    ThemeData buildTypographyTheme({
      required bool isDark,
      required bool systemBoldText,
    }) {
      return isDark
          ? AppTheme.buildDarkTheme(
              fontWeightAdjustment: fontWeightAdjustment,
              systemBoldText: systemBoldText,
            )
          : AppTheme.buildLightTheme(
              fontWeightAdjustment: fontWeightAdjustment,
              systemBoldText: systemBoldText,
            );
    }

    return A11yKeyboardHandler(
      child: MaterialApp.router(
        title: '玲珑应用商店社区版',
        debugShowCheckedModeBanner: false,

        // 国际化配置
        localizationsDelegates: AppLocalizations.localizationsDelegates,

        // 语言配置
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,

        // 主题配置
        theme: buildTypographyTheme(
          isDark: false,
          systemBoldText: platformBoldText,
        ),
        darkTheme: buildTypographyTheme(
          isDark: true,
          systemBoldText: platformBoldText,
        ),
        themeMode: themeMode,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          final systemIsDark = mediaQuery.platformBrightness == Brightness.dark;
          final effectiveIsDark = switch (themeMode) {
            ThemeMode.system => systemIsDark,
            ThemeMode.light => false,
            ThemeMode.dark => true,
          };
          final resolvedTheme = buildTypographyTheme(
            isDark: effectiveIsDark,
            systemBoldText: mediaQuery.boldText,
          );
          final resolvedMediaQuery = mediaQuery.copyWith(
            textScaler: composeTextScaler(
              mediaQuery.textScaler,
              userScaleFactor: fontScaleFactor,
            ),
          );

          return MediaQuery(
            data: resolvedMediaQuery,
            child: NativeMenuThemeSync(
              isDark: effectiveIsDark,
              child: Theme(
                data: resolvedTheme,
                child: A11yFocusScope(
                  child: _OgProtocolInstallBootstrap(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          );
        },

        // 路由配置
        routerConfig: router,
      ),
    );
  }
}

/// og 协议安装入口桥接组件。
///
/// 根组件负责把平台层收到的 `og://appId` 链接交给 Application 层控制器，
/// 并把控制器事件转换为用户可见通知。这样协议拉起、详情加载和安装入队
/// 不会散落在具体页面，也不会让业务控制器直接依赖 BuildContext。
class _OgProtocolInstallBootstrap extends ConsumerStatefulWidget {
  const _OgProtocolInstallBootstrap({required this.child});

  /// MaterialApp 当前渲染的路由内容。
  final Widget child;

  @override
  ConsumerState<_OgProtocolInstallBootstrap> createState() =>
      _OgProtocolInstallBootstrapState();
}

class _OgProtocolInstallBootstrapState
    extends ConsumerState<_OgProtocolInstallBootstrap> {
  StreamSubscription<String>? _protocolUrlSubscription;
  StreamSubscription<OgInstallEvent>? _eventSubscription;
  bool _initialUrlsHandled = false;

  @override
  void initState() {
    super.initState();

    // 等 MaterialApp 的 Localizations、Theme 和 ScaffoldMessenger 就绪后再订阅，
    // 避免冷启动首帧前展示通知时拿不到完整的 Flutter 上下文。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startOgInstallBridge();
    });
  }

  @override
  void dispose() {
    _protocolUrlSubscription?.cancel();
    _eventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _startOgInstallBridge() {
    final controller = ref.read(ogInstallControllerProvider);
    _protocolUrlSubscription ??= SingleInstance.protocolUrls.listen(
      controller.acceptRawUrl,
    );
    _eventSubscription ??= controller.events.listen(_showOgInstallEvent);

    if (_initialUrlsHandled) {
      return;
    }

    _initialUrlsHandled = true;
    final initialUrls = ref.read(initialOgProtocolUrlsProvider);
    for (final url in initialUrls) {
      controller.acceptRawUrl(url);
    }
  }

  void _showOgInstallEvent(OgInstallEvent event) {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final displayName = event.appName ?? event.appId ?? '应用';
    switch (event.type) {
      case OgInstallEventType.received:
        showAppNotification(
          context,
          l10n?.ogInstallRequestReceived(displayName) ??
              '已收到来自网页的安装请求：$displayName',
        );
        break;
      case OgInstallEventType.enqueued:
        showAppSuccess(
          context,
          l10n?.ogInstallEnqueued(displayName) ?? '已加入下载管理：$displayName',
        );
        break;
      case OgInstallEventType.invalid:
        showAppError(
          context,
          l10n?.ogInstallInvalidLink ?? '无法识别网页安装链接，仅支持 og://appId',
        );
        break;
      case OgInstallEventType.environmentUnavailable:
        showAppWarning(
          context,
          l10n?.ogInstallEnvironmentUnavailable ?? '玲珑运行环境不可用，暂不能从网页自动安装',
        );
        break;
      case OgInstallEventType.duplicate:
        showAppNotification(
          context,
          l10n?.ogInstallDuplicate(displayName) ?? '$displayName 已在下载管理中',
        );
        break;
      case OgInstallEventType.detailFailed:
        final error = event.error;
        showAppError(
          context,
          error == null || error.isEmpty
              ? l10n?.ogInstallDetailFailed ?? '无法获取应用信息，安装未开始'
              : l10n?.ogInstallDetailFailedWithError(error) ??
                    '无法获取应用信息，安装未开始：$error',
        );
        break;
    }
  }
}
