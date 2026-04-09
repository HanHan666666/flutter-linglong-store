import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/keepalive_paint_gate.dart';

void main() {
  group('KeepAlivePaintGate', () {
    testWidgets('hidden children stay mounted but leave the paint tree', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: KeepAlivePaintGate(
            isVisible: false,
            child: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('hidden-content'),
            ),
          ),
        ),
      );

      expect(find.text('hidden-content'), findsNothing);
      expect(find.text('hidden-content', skipOffstage: false), findsOneWidget);

      final gateOffstage = find.descendant(
        of: find.byType(KeepAlivePaintGate),
        matching: find.byType(Offstage),
      );

      await tester.tap(
        find.text('hidden-content', skipOffstage: false),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(tapped, isFalse);
      expect(tester.widget<Offstage>(gateOffstage).offstage, isTrue);
    });

    testWidgets('visible children stay interactive', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: KeepAlivePaintGate(
            isVisible: true,
            child: ElevatedButton(
              onPressed: () => tapped = true,
              child: const Text('visible-content'),
            ),
          ),
        ),
      );

      expect(find.text('visible-content'), findsOneWidget);

      final gateOffstage = find.descendant(
        of: find.byType(KeepAlivePaintGate),
        matching: find.byType(Offstage),
      );
      expect(tester.widget<Offstage>(gateOffstage).offstage, isFalse);

      await tester.tap(find.text('visible-content'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('hidden children cannot take keyboard focus', (tester) async {
      final hiddenFocusNode = FocusNode(debugLabel: 'hidden-node');
      addTearDown(hiddenFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: KeepAlivePaintGate(
            isVisible: false,
            child: Focus(
              focusNode: hiddenFocusNode,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      hiddenFocusNode.requestFocus();
      await tester.pump();

      expect(hiddenFocusNode.hasFocus, isFalse);

      final visibleFocusNode = FocusNode(debugLabel: 'visible-node');
      addTearDown(visibleFocusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: KeepAlivePaintGate(
            isVisible: true,
            child: Focus(
              focusNode: visibleFocusNode,
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
        ),
      );

      visibleFocusNode.requestFocus();
      await tester.pump();

      expect(visibleFocusNode.hasFocus, isTrue);
    });
  });
}
