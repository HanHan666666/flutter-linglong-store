import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/presentation/widgets/app_detail_info_section.dart';

import '../../../test_utils.dart';

void main() {
  Future<void> pumpInfoSection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      createTestApp(
        const SizedBox(
          width: 900,
          child: AppDetailInfoSection(
            entries: [
              AppDetailInfoEntry(label: '版本', value: '6.0.49.1'),
              AppDetailInfoEntry(label: '架构', value: 'x86_64'),
              AppDetailInfoEntry(label: '渠道', value: 'main'),
              AppDetailInfoEntry(
                label: '包名',
                value: 'org.deepin.album',
                isCopyable: true,
                span: AppDetailInfoSpan.full,
              ),
              AppDetailInfoEntry(
                label: '运行时',
                value: 'main:org.deepin.runtime.webengine/25.2.1/x86_64',
                span: AppDetailInfoSpan.full,
              ),
              AppDetailInfoEntry(label: '大小', value: '119.77 MB'),
              AppDetailInfoEntry(label: '类型', value: 'app'),
              AppDetailInfoEntry(label: '分类', value: '图形图像'),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('短字段按三列排列，长字段独占整行', (tester) async {
    await pumpInfoSection(tester);

    final versionCard = find.byKey(const ValueKey('app-detail-info-版本'));
    final archCard = find.byKey(const ValueKey('app-detail-info-架构'));
    final channelCard = find.byKey(const ValueKey('app-detail-info-渠道'));
    final packageCard = find.byKey(const ValueKey('app-detail-info-包名'));
    final runtimeCard = find.byKey(const ValueKey('app-detail-info-运行时'));
    final sizeCard = find.byKey(const ValueKey('app-detail-info-大小'));
    final typeCard = find.byKey(const ValueKey('app-detail-info-类型'));
    final categoryCard = find.byKey(const ValueKey('app-detail-info-分类'));

    final versionTop = tester.getTopLeft(versionCard);
    final archTop = tester.getTopLeft(archCard);
    final channelTop = tester.getTopLeft(channelCard);
    final packageTop = tester.getTopLeft(packageCard);
    final runtimeTop = tester.getTopLeft(runtimeCard);
    final sizeTop = tester.getTopLeft(sizeCard);
    final typeTop = tester.getTopLeft(typeCard);
    final categoryTop = tester.getTopLeft(categoryCard);
    final compactWidth = tester.getSize(versionCard).width;
    final fullWidth = tester.getSize(packageCard).width;

    expect(versionTop.dy, equals(archTop.dy));
    expect(archTop.dy, equals(channelTop.dy));
    expect(packageTop.dy, greaterThan(versionTop.dy));
    expect(runtimeTop.dy, greaterThan(packageTop.dy));
    expect(sizeTop.dy, greaterThan(runtimeTop.dy));
    expect(sizeTop.dy, equals(typeTop.dy));
    expect(typeTop.dy, equals(categoryTop.dy));
    expect(fullWidth, greaterThan(compactWidth));
  });

  testWidgets('可复制字段展示复制按钮并可触发反馈', (tester) async {
    const clipboardChannel = SystemChannels.platform;
    MethodCall? clipboardCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(clipboardChannel, (call) async {
          clipboardCall = call;
          return null;
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboardChannel, null);
    });

    await pumpInfoSection(tester);

    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pump();

    expect(clipboardCall?.method, equals('Clipboard.setData'));
    expect(
      clipboardCall?.arguments,
      equals(<String, dynamic>{'text': 'org.deepin.album'}),
    );
  });

  testWidgets('复制按钮紧挨包名文本显示', (tester) async {
    await pumpInfoSection(tester);

    final packageValue = find.text('org.deepin.album');
    final copyButton = find.byIcon(Icons.copy_outlined);
    final packageRect = tester.getRect(packageValue);
    final copyButtonRect = tester.getRect(copyButton);

    // 复制按钮应跟随包名文本，而不是被整行宽度推到最右侧。
    expect(copyButtonRect.left - packageRect.right, inInclusiveRange(0, 12));
  });

  testWidgets('点击复制后显示对勾反馈且不弹出底部通知条', (tester) async {
    const clipboardChannel = SystemChannels.platform;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(clipboardChannel, (call) async => null);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(clipboardChannel, null);
    });

    await pumpInfoSection(tester);

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pump();

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
  });
}
