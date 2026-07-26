import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/error_solution.dart';
import 'package:linglong_store/presentation/widgets/error_solution_dialog.dart';

/// 错误解决方案 Markdown 对话框测试。
///
/// 锁定完整 Markdown 渲染能力，同时确保图片只允许 HTTP/HTTPS，不让后端内容
/// 读取本地文件、resource 或 data URI。
void main() {
  testWidgets('仅构建 HTTP/HTTPS 远程图片并阻止本地图片协议', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ErrorSolutionDialog(
            solution: ErrorSolution(title: '图片方案', markdown: '# 图片协议测试'),
          ),
        ),
      ),
    );
    await tester.pump();

    final markdown = tester.widget<Markdown>(
      find.byKey(const Key('errorSolutionMarkdown')),
    );
    expect(markdown.imageBuilder, isNotNull);

    final remote = markdown.imageBuilder!(
      Uri.parse('https://example.com/guide.png'),
      null,
      '远程图',
    );
    final constrained = remote as ConstrainedBox;
    final clip = constrained.child! as ClipRRect;
    final image = clip.child as Image;
    final resizedProvider = image.image as ResizeImage;
    final networkProvider = resizedProvider.imageProvider as NetworkImage;
    expect(networkProvider.url, 'https://example.com/guide.png');

    final blocked = markdown.imageBuilder!(
      Uri.parse('file:///etc/passwd'),
      null,
      '本地图',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: blocked),
      ),
    );
    expect(find.text('已阻止非网络图片'), findsOneWidget);
  });
}
