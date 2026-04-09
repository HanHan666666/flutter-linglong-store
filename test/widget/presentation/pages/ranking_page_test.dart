import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/application/providers/ranking_provider.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/core/i18n/l10n/app_localizations.dart';
import 'package:linglong_store/domain/models/ranking_models.dart';
import 'package:linglong_store/presentation/pages/ranking/ranking_page.dart';

void main() {
  group('RankingPage', () {
    testWidgets('hovering an inactive ranking tab does not throw layout exceptions', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.binding.setSurfaceSize(const Size(1280, 800));

      await tester.pumpWidget(
        _buildTestApp(const RankingState(selectedType: RankingType.download)),
      );
      await tester.pump();

      expect(find.text('更新榜'), findsOneWidget);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(find.text('更新榜')));
      await tester.pump();

      final exceptions = <Object>[];
      Object? exception;
      while ((exception = tester.takeException()) != null) {
        exceptions.add(exception!);
      }

      expect(
        exceptions,
        isEmpty,
        reason: 'Unexpected exceptions during tab hover: $exceptions',
      );
    });
  });
}

Widget _buildTestApp(RankingState state) {
  return ProviderScope(
    overrides: [rankingProvider.overrideWithValue(state)],
    child: MaterialApp(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RankingPage()),
    ),
  );
}
