import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/global_provider.dart';
import 'core/accessibility/accessibility.dart';
import 'core/config/routes.dart';
import 'core/config/theme.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/platform/native_menu_theme_sync.dart';

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
    final platformBoldText =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.boldText;

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
          final systemIsDark =
              mediaQuery.platformBrightness == Brightness.dark;
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
                  child: child ?? const SizedBox.shrink(),
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
