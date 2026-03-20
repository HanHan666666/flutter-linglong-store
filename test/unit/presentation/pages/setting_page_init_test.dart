import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/presentation/pages/setting/setting_page.dart';

void main() {
  test('runSettingPageInitialization skips total fetch after unmount', () async {
    final calls = <String>[];
    var isMounted = true;
    String? resolvedVersion;
    int? resolvedTotal;
    var fetchCalled = false;

    await runSettingPageInitialization(
      resolveAppVersion: () async {
        calls.add('resolveVersion');
        return '1.2.3';
      },
      setAppVersion: (version) {
        calls.add('setVersion');
        resolvedVersion = version;
      },
      refreshCacheSize: () async {
        calls.add('refreshCacheSize');
        isMounted = false;
      },
      isMounted: () => isMounted,
      fetchAppTotalCount: () async {
        fetchCalled = true;
        calls.add('fetchAppTotalCount');
        return 42;
      },
      setAppTotalCount: (total) {
        calls.add('setAppTotalCount');
        resolvedTotal = total;
      },
    );

    expect(calls, ['resolveVersion', 'setVersion', 'refreshCacheSize']);
    expect(resolvedVersion, '1.2.3');
    expect(fetchCalled, isFalse);
    expect(resolvedTotal, isNull);
  });

  test('runSettingPageInitialization updates total while mounted', () async {
    final calls = <String>[];
    String? resolvedVersion;
    int? resolvedTotal;

    await runSettingPageInitialization(
      resolveAppVersion: () async {
        calls.add('resolveVersion');
        return '2.0.0';
      },
      setAppVersion: (version) {
        calls.add('setVersion');
        resolvedVersion = version;
      },
      refreshCacheSize: () async {
        calls.add('refreshCacheSize');
      },
      isMounted: () => true,
      fetchAppTotalCount: () async {
        calls.add('fetchAppTotalCount');
        return 128;
      },
      setAppTotalCount: (total) {
        calls.add('setAppTotalCount');
        resolvedTotal = total;
      },
    );

    expect(
      calls,
      [
        'resolveVersion',
        'setVersion',
        'refreshCacheSize',
        'fetchAppTotalCount',
        'setAppTotalCount',
      ],
    );
    expect(resolvedVersion, '2.0.0');
    expect(resolvedTotal, 128);
  });
}
