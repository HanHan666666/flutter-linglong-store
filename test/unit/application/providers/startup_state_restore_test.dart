import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linglong_store/application/providers/global_provider.dart';
import 'package:linglong_store/application/providers/install_queue_provider.dart';
import 'package:linglong_store/application/providers/setting_provider.dart';
import 'package:linglong_store/core/logging/app_logger.dart';

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('startup state restore', () {
    test(
      'global provider restores locale, theme and user preferences on first build',
      () async {
        SharedPreferences.setMockInitialValues({
          'linglong-store-language': 'en',
          'linglong-store-theme-mode': ThemeMode.dark.index,
          'linglong-store-user-preferences': jsonEncode({
            'autoCheckUpdate': false,
            'showBetaApps': true,
            'showSystemApps': true,
            'enableNotifications': false,
            'autoCreateShortcut': false,
            'downloadConcurrency': 5,
            'autoRunAfterInstall': true,
            'compactMode': true,
            'customCategories': ['office'],
          }),
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final state = container.read(globalAppProvider);

        expect(state.isInitialized, isTrue);
        expect(state.locale, const Locale('en'));
        expect(state.themeMode, ThemeMode.dark);
        expect(state.userPreferences.autoCheckUpdate, isFalse);
        expect(state.userPreferences.downloadConcurrency, 5);
        expect(state.userPreferences.customCategories, ['office']);
      },
    );

    test(
      'setting provider restores locale and theme without reviving repo preference',
      () async {
        SharedPreferences.setMockInitialValues({
          'linglong-store-language': 'en',
          'linglong-store-theme-mode': ThemeMode.light.index,
          'repo_name': 'repo:test',
        });
        final prefs = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(container.dispose);

        final state = container.read(settingProvider);

        expect(state.locale, const Locale('en'));
        expect(state.themeMode, ThemeMode.light);
        // 仓库配置能力已移除，旧偏好键不应再污染设置状态。
        expect(state.toString(), isNot(contains('repo:test')));
        expect(state.cacheSize, 0);
      },
    );
  });
}
