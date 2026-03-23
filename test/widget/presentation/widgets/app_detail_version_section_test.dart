import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/presentation/widgets/app_detail_version_section.dart';

import '../../../test_utils.dart';

void main() {
  List<AppVersionDTO> buildVersions(int count) {
    return List<AppVersionDTO>.generate(
      count,
      (index) => AppVersionDTO(
        versionNo: '4.1.1.${count - index}',
        releaseTime: '2026-03-${(index + 1).toString().padLeft(2, '0')}',
        packageSize: '${1024 * 1024 * (index + 1)}',
      ),
    );
  }

  Future<void> pumpVersionSection(
    WidgetTester tester, {
    required List<AppVersionDTO> versions,
    Set<String> installedVersions = const {},
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRetry,
    void Function(String version)? onInstallVersion,
  }) async {
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        SizedBox(
          width: 1120,
          child: AppDetailVersionSection(
            versions: versions,
            installedVersions: installedVersions,
            isLoading: isLoading,
            errorMessage: errorMessage,
            onRetry: onRetry ?? () {},
            onInstallVersion: onInstallVersion ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('默认仅展示前 8 个版本并支持展开收起', (tester) async {
    final versions = buildVersions(10);

    await pumpVersionSection(tester, versions: versions);

    expect(find.byType(OutlinedButton), findsNWidgets(8));
    expect(find.text('4.1.1.10'), findsOneWidget);
    expect(find.text('4.1.1.3'), findsOneWidget);
    expect(find.text('4.1.1.2'), findsNothing);
    expect(find.text('4.1.1.1'), findsNothing);
    expect(find.text('展开全部'), findsOneWidget);

    await tester.tap(find.text('展开全部'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNWidgets(10));
    expect(find.text('4.1.1.2'), findsOneWidget);
    expect(find.text('4.1.1.1'), findsOneWidget);
    expect(find.text('收起'), findsOneWidget);

    await tester.tap(find.text('收起'));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNWidgets(8));
    expect(find.text('4.1.1.1'), findsNothing);
  });

  testWidgets('未安装版本支持触发安装回调', (tester) async {
    String? tappedVersion;

    await pumpVersionSection(
      tester,
      versions: buildVersions(2),
      installedVersions: const {'4.1.1.2'},
      onInstallVersion: (version) => tappedVersion = version,
    );

    expect(find.text('已安装'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-detail-version-install-4.1.1.1')));
    await tester.pump();

    expect(tappedVersion, equals('4.1.1.1'));
  });
}
