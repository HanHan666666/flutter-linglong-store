import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/app_comment.dart';
import 'package:linglong_store/presentation/widgets/app_detail_comment_section.dart';

void main() {
  Future<void> pumpCommentSection(
    WidgetTester tester, {
    List<AppComment> comments = const [],
    List<String> versionOptions = const ['1.2.3'],
    String? selectedVersion = '1.2.3',
    bool isLoading = false,
    bool isSubmitting = false,
    bool canSubmitComment = true,
    String? errorMessage,
    Future<void> Function(String remark, String? version)? onSubmit,
    VoidCallback? onRetry,
    ValueChanged<String?>? onVersionChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: SizedBox(
            width: 960,
            child: AppDetailCommentSection(
              comments: comments,
              versionOptions: versionOptions,
              selectedVersion: selectedVersion,
              isLoading: isLoading,
              isSubmitting: isSubmitting,
              canSubmitComment: canSubmitComment,
              errorMessage: errorMessage,
              onSubmit: onSubmit ?? (_, __) async {},
              onRetry: onRetry ?? () {},
              onVersionChanged: onVersionChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('展示评论列表和发表评论表单', (tester) async {
    String? submittedRemark;
    String? submittedVersion;

    await pumpCommentSection(
      tester,
      versionOptions: const ['1.2.3', '1.2.2', '1.2.1'],
      selectedVersion: '1.2.2',
      comments: const [
        AppComment(
          id: 'comment-1',
          appId: 'org.deepin.album',
          version: '6.0.49.1',
          remark: '启动速度不错，截图浏览也很顺。',
          agreeNum: 12,
          disagreeNum: 1,
          createTime: '2026-03-23 09:15:00',
        ),
      ],
      onSubmit: (remark, version) async {
        submittedRemark = remark;
        submittedVersion = version;
      },
    );

    expect(find.text('评论区'), findsOneWidget);
    expect(find.text('启动速度不错，截图浏览也很顺。'), findsOneWidget);
    expect(find.text('6.0.49.1'), findsWidgets);
    expect(find.text('有帮助 12'), findsOneWidget);
    expect(find.text('没帮助 1'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(
      find.byKey(const ValueKey('comment-version-pill-1.2.3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comment-version-pill-1.2.2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comment-version-pill-1.2.1')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('app-detail-comment-input')),
      '  新版详情页做得更清楚了  ',
    );
    await tester.tap(find.byKey(const ValueKey('app-detail-comment-submit')));
    await tester.pump();

    expect(submittedRemark, equals('新版详情页做得更清楚了'));
    expect(submittedVersion, equals('1.2.2'));
  });

  testWidgets('未安装时隐藏评论表单但保留评论列表', (tester) async {
    await pumpCommentSection(
      tester,
      canSubmitComment: false,
      comments: const [
        AppComment(
          id: 'comment-1',
          appId: 'org.deepin.album',
          version: '6.0.49.1',
          remark: '未安装用户也应该能看到这条评论。',
          agreeNum: 8,
          disagreeNum: 0,
          createTime: '2026-04-11 10:00:00',
        ),
      ],
    );

    expect(
      find.byKey(const ValueKey('app-detail-comment-input')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('app-detail-comment-submit')),
      findsNothing,
    );
    expect(find.text('未安装用户也应该能看到这条评论。'), findsOneWidget);
    expect(find.text('有帮助 8'), findsOneWidget);
  });

  testWidgets('未安装且暂无评论时展示暂无评论文案', (tester) async {
    await pumpCommentSection(tester, canSubmitComment: false);

    expect(find.text('暂无评论'), findsOneWidget);
    expect(find.text('暂不评论'), findsNothing);
    expect(find.text('还没有评论，来写第一条吧'), findsNothing);
  });

  testWidgets('加载失败且暂无评论时展示重试入口', (tester) async {
    var retryTapped = false;

    await pumpCommentSection(
      tester,
      errorMessage: '评论加载失败',
      onRetry: () => retryTapped = true,
    );

    expect(find.text('评论加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    await tester.tap(find.text('重试'));
    await tester.pump();

    expect(retryTapped, isTrue);
  });

  testWidgets('关联版本胶囊默认展示前 8 个并支持展开', (tester) async {
    String? selectedVersion;
    final versions = List<String>.generate(
      10,
      (index) => '4.1.1.${10 - index}',
    );

    await pumpCommentSection(
      tester,
      versionOptions: versions,
      selectedVersion: '4.1.1.10',
      onVersionChanged: (value) {
        selectedVersion = value;
      },
      onSubmit: (_, __) async {},
    );

    expect(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.10')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.2')),
      findsNothing,
    );
    expect(find.text('展开全部'), findsOneWidget);

    await tester.tap(find.text('展开全部'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.2')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.1')),
      findsOneWidget,
    );
    expect(find.text('收起'), findsOneWidget);

    await pumpCommentSection(
      tester,
      versionOptions: versions,
      selectedVersion: '4.1.1.10',
      onVersionChanged: (value) {
        selectedVersion = value;
      },
      onSubmit: (_, version) async {
        selectedVersion = version;
      },
    );
    await tester.tap(
      find.byKey(const ValueKey('comment-version-pill-4.1.1.9')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('app-detail-comment-input')),
      '新的评论',
    );
    await tester.tap(find.byKey(const ValueKey('app-detail-comment-submit')));
    await tester.pump();

    expect(selectedVersion, equals('4.1.1.9'));
  });
}
