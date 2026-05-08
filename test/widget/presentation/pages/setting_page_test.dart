import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/presentation/pages/setting/setting_page.dart';

void main() {
  group('runSettingPageInitialization', () {
    test(
      'updates version, cache and app count while the page stays mounted',
      () async {
        final callOrder = <String>[];
        String? version;
        int? total;

        await runSettingPageInitialization(
          resolveAppVersion: () async {
            callOrder.add('resolve-version');
            return '3.4.0';
          },
          setAppVersion: (value) {
            callOrder.add('set-version');
            version = value;
          },
          refreshCacheSize: () async {
            callOrder.add('refresh-cache');
          },
          isMounted: () => true,
          fetchAppTotalCount: () async {
            callOrder.add('fetch-total');
            return 123;
          },
          setAppTotalCount: (value) {
            callOrder.add('set-total');
            total = value;
          },
        );

        expect(version, '3.4.0');
        expect(total, 123);
        expect(callOrder, [
          'resolve-version',
          'set-version',
          'refresh-cache',
          'fetch-total',
          'set-total',
        ]);
      },
    );

    test(
      'stops after resolving the version when the page is already unmounted',
      () async {
        var refreshCalled = false;
        var fetchCalled = false;
        var setTotalCalled = false;
        String? version;

        await runSettingPageInitialization(
          resolveAppVersion: () async => '3.4.0',
          setAppVersion: (value) => version = value,
          refreshCacheSize: () async => refreshCalled = true,
          isMounted: () => false,
          fetchAppTotalCount: () async {
            fetchCalled = true;
            return 123;
          },
          setAppTotalCount: (_) => setTotalCalled = true,
        );

        expect(version, '3.4.0');
        expect(refreshCalled, isFalse);
        expect(fetchCalled, isFalse);
        expect(setTotalCalled, isFalse);
      },
    );

    test(
      'stops before fetching app totals when the page unmounts after cache refresh',
      () async {
        var mountChecks = 0;
        var refreshCalled = false;
        var fetchCalled = false;
        var setTotalCalled = false;

        await runSettingPageInitialization(
          resolveAppVersion: () async => '3.4.0',
          setAppVersion: (_) {},
          refreshCacheSize: () async => refreshCalled = true,
          isMounted: () {
            mountChecks += 1;
            return mountChecks == 1;
          },
          fetchAppTotalCount: () async {
            fetchCalled = true;
            return 123;
          },
          setAppTotalCount: (_) => setTotalCalled = true,
        );

        expect(refreshCalled, isTrue);
        expect(fetchCalled, isFalse);
        expect(setTotalCalled, isFalse);
      },
    );
  });
}
