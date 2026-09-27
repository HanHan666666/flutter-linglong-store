/// 验证下载卡片的依赖记录只补充父任务展示，不产生虚构的逐项进度。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/install_progress.dart';
import 'package:linglong_store/domain/models/install_task.dart';
import 'package:linglong_store/presentation/widgets/download_manager/download_dependency_steps.dart';
import 'package:linglong_store/presentation/widgets/download_manager/download_task_card.dart';
import 'package:linglong_store/presentation/widgets/download_manager/download_task_view_data.dart';

void main() {
  /// 用真实主卡片验证依赖行与父任务进度条的组合关系。
  Future<void> pumpCard(WidgetTester tester, InstallTask task) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              child: DownloadTaskCard(
                data: DownloadTaskViewData(task: task, statusMessage: '安装中'),
                featured: true,
                showProgress: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'shows current and earlier dependency under one global progress bar',
    (tester) async {
      await pumpCard(
        tester,
        const InstallTask(
          id: 'task-1',
          appId: 'org.example.app',
          appName: 'Example',
          status: InstallStatus.installing,
          progress: 0.42,
          observedDependencyIds: ['org.deepin.base', 'org.deepin.runtime.dtk'],
          activeDependencyId: 'org.deepin.runtime.dtk',
          createdAt: 1,
        ),
      );

      expect(find.text('依赖处理记录'), findsOneWidget);
      expect(find.text('org.deepin.base'), findsOneWidget);
      expect(find.text('org.deepin.runtime.dtk'), findsOneWidget);
      expect(find.text('此前处理'), findsOneWidget);
      expect(find.text('正在处理'), findsOneWidget);
      expect(find.byType(DownloadDependencySteps), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo(0.42, 0.0001),
      );
    },
  );

  testWidgets('hides dependency area when ll-cli has not reported any', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const InstallTask(
        id: 'task-2',
        appId: 'org.example.app',
        appName: 'Example',
        status: InstallStatus.installing,
        progress: 0.42,
        createdAt: 1,
      ),
    );

    expect(find.byType(DownloadDependencySteps), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
