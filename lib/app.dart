import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers/global_provider.dart';
import 'core/config/routes.dart';
import 'core/config/theme.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/platform/native_menu_theme_sync.dart';
import 'main.dart';

/// 玲珑应用商店 MaterialApp 配置
class LinglongStoreApp extends ConsumerWidget {
  const LinglongStoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听语言和主题状态
    final locale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(currentThemeModeProvider);
    final router = ref.watch(routerProvider);

    return AppInitializer(
      child: MaterialApp.router(
        title: '玲珑应用商店社区版',
        debugShowCheckedModeBanner: false,

        // 国际化配置
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // 语言配置
        locale: locale,
        supportedLocales: const [Locale('zh'), Locale('en')],

        // 主题配置
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        builder: (context, child) {
          final systemIsDark =
              MediaQuery.platformBrightnessOf(context) == Brightness.dark;
          final effectiveIsDark = switch (themeMode) {
            ThemeMode.system => systemIsDark,
            ThemeMode.light => false,
            ThemeMode.dark => true,
          };

          return NativeMenuThemeSync(
            isDark: effectiveIsDark,
            child: child ?? const SizedBox.shrink(),
          );
        },

        // 路由配置
        routerConfig: router,
      ),
    );
  }
}
