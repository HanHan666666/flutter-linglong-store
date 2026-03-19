import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linglong_store/core/config/routes.dart';
import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/presentation/widgets/title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/icons/logo.svg') {
            final bytes = Uint8List.fromList(
              utf8.encode(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>',
              ),
            );
            return ByteData.view(bytes.buffer);
          }
          return null;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  testWidgets('submitting header search navigates to search page with q query', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: CustomTitleBar(
              isMaximized: false,
              onMinimize: () {},
              onMaximize: () {},
              onClose: () {},
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.searchList,
          builder: (context, state) => Scaffold(
            body: Text(
              'route:${state.uri.path}?q=${state.uri.queryParameters['q'] ?? ''}',
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'firefox');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('route:/search_list?q=firefox'), findsOneWidget);
  });

  testWidgets('header search uses single-layer pill styling by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CustomTitleBar(
            isMaximized: false,
            onMinimize: () {},
            onMaximize: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    final textField = tester.widget<TextField>(find.byType(TextField));
    final decoration = textField.decoration!;
    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final searchSize = tester.getSize(searchContainerFinder);
    final border = boxDecoration.border as Border?;

    expect(decoration.filled, isFalse);
    expect(decoration.enabledBorder, InputBorder.none);
    expect(decoration.focusedBorder, InputBorder.none);
    expect(border, isNotNull);
    expect(border!.top.color, AppColors.borderSecondary);
    expect(border.top.width, 1);
    expect(boxDecoration.color, AppColors.surfaceContainerHighest);
    expect(searchSize.height, 32);
  });

  testWidgets('header search border turns blue when focused', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: CustomTitleBar(
            isMaximized: false,
            onMinimize: () {},
            onMaximize: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    final searchContainerFinder = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxWidth == 534,
    );
    final searchContainer = tester.widget<Container>(searchContainerFinder);
    final boxDecoration = searchContainer.decoration! as BoxDecoration;
    final border = boxDecoration.border as Border?;

    expect(border, isNotNull);
    expect(border!.top.color, AppColors.primary);
    expect(border.top.width, 1);
  });
}
