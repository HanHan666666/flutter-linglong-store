import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/local_sidebar_menu_catalog.dart';

void main() {
  group('local sidebar menu catalog', () {
    test('known menu code resolves localized labels for zh and en', () {
      final office = lookupLocalSidebarMenuConfig('office');

      expect(office, isNotNull);
      expect(office!.resolveLabel(const Locale('zh')), '办 公');
      expect(office.resolveLabel(const Locale('en')), 'Office');
    });

    test('unknown menu code falls back to backend name and generic icons', () {
      final fallback = buildSidebarMenuPresentation(
        menuCode: 'unknown',
        locale: const Locale('en'),
        fallbackName: 'Experimental',
      );

      expect(fallback.label, 'Experimental');
      expect(fallback.icon, Icons.widgets_outlined);
      expect(fallback.selectedIcon, Icons.widgets);
    });
  });
}
