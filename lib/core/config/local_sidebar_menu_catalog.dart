import 'package:flutter/material.dart';

import '../../data/models/api_dto.dart';
import '../i18n/l10n/app_localizations.dart';

enum SidebarMenuLabelKey { office, system, develop, entertainment }

class SidebarMenuPresentation {
  const SidebarMenuPresentation({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class LocalSidebarMenuConfig {
  const LocalSidebarMenuConfig({
    required this.menu,
    required this.icon,
    required this.selectedIcon,
    required SidebarMenuLabelKey labelKey,
  }) : _labelKey = labelKey;

  final SidebarMenuDTO menu;
  final IconData icon;
  final IconData selectedIcon;
  final SidebarMenuLabelKey _labelKey;

  String resolveLabel(Locale locale) {
    final l10n = lookupAppLocalizations(normalizeSidebarMenuLocale(locale));
    return switch (_labelKey) {
      SidebarMenuLabelKey.office => l10n.office,
      SidebarMenuLabelKey.system => l10n.system,
      SidebarMenuLabelKey.develop => l10n.develop,
      SidebarMenuLabelKey.entertainment => l10n.entertainment,
    };
  }
}

const localSidebarMenuCatalog = <LocalSidebarMenuConfig>[
  LocalSidebarMenuConfig(
    menu: SidebarMenuDTO(
      menuCode: 'office',
      menuName: '办公',
      sortOrder: 2,
      enabled: true,
      categoryIds: ['07', '19'],
      rule: SidebarMenuRuleDTO(sortBy: 'last30Downloads', filterMinScore: 0),
    ),
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center,
    labelKey: SidebarMenuLabelKey.office,
  ),
  LocalSidebarMenuConfig(
    menu: SidebarMenuDTO(
      menuCode: 'system',
      menuName: '系统',
      sortOrder: 3,
      enabled: true,
      categoryIds: ['02', '01', '08', '16', '17', '18', '15'],
      rule: SidebarMenuRuleDTO(sortBy: 'last30Downloads', filterMinScore: 0),
    ),
    icon: Icons.desktop_windows_outlined,
    selectedIcon: Icons.desktop_windows,
    labelKey: SidebarMenuLabelKey.system,
  ),
  LocalSidebarMenuConfig(
    menu: SidebarMenuDTO(
      menuCode: 'dev',
      menuName: '开发',
      sortOrder: 4,
      enabled: true,
      categoryIds: ['03'],
      rule: SidebarMenuRuleDTO(sortBy: 'last30Downloads', filterMinScore: 0),
    ),
    icon: Icons.terminal_outlined,
    selectedIcon: Icons.terminal,
    labelKey: SidebarMenuLabelKey.develop,
  ),
  LocalSidebarMenuConfig(
    menu: SidebarMenuDTO(
      menuCode: 'entertainment',
      menuName: '娱乐',
      sortOrder: 5,
      enabled: true,
      categoryIds: ['06', '10', '04', '13'],
      rule: SidebarMenuRuleDTO(sortBy: 'last30Downloads', filterMinScore: 0),
    ),
    icon: Icons.movie_outlined,
    selectedIcon: Icons.movie,
    labelKey: SidebarMenuLabelKey.entertainment,
  ),
];

const _fallbackSidebarIcon = Icons.widgets_outlined;
const _fallbackSidebarSelectedIcon = Icons.widgets;

LocalSidebarMenuConfig? lookupLocalSidebarMenuConfig(String menuCode) {
  for (final config in localSidebarMenuCatalog) {
    if (config.menu.menuCode == menuCode) {
      return config;
    }
  }
  return null;
}

Locale normalizeSidebarMenuLocale(Locale locale) {
  if (locale.languageCode.toLowerCase().startsWith('en')) {
    return const Locale('en');
  }
  return const Locale('zh');
}

Locale resolveSidebarMenuLocale(String? localeName) {
  final normalized = localeName?.trim().replaceAll('-', '_').toLowerCase();
  if (normalized != null && normalized.startsWith('en')) {
    return const Locale('en');
  }
  return const Locale('zh');
}

SidebarMenuPresentation buildSidebarMenuPresentation({
  required String menuCode,
  required Locale locale,
  String? fallbackName,
}) {
  final config = lookupLocalSidebarMenuConfig(menuCode);
  if (config != null) {
    return SidebarMenuPresentation(
      label: config.resolveLabel(locale),
      icon: config.icon,
      selectedIcon: config.selectedIcon,
    );
  }

  return SidebarMenuPresentation(
    label: fallbackName ?? menuCode,
    icon: _fallbackSidebarIcon,
    selectedIcon: _fallbackSidebarSelectedIcon,
  );
}

String resolveSidebarMenuLabel({
  required String menuCode,
  required Locale locale,
  String? fallbackName,
}) {
  return buildSidebarMenuPresentation(
    menuCode: menuCode,
    locale: locale,
    fallbackName: fallbackName,
  ).label;
}

IconData resolveSidebarMenuIcon(String menuCode, {required bool selected}) {
  final config = lookupLocalSidebarMenuConfig(menuCode);
  if (config == null) {
    return selected ? _fallbackSidebarSelectedIcon : _fallbackSidebarIcon;
  }
  return selected ? config.selectedIcon : config.icon;
}
