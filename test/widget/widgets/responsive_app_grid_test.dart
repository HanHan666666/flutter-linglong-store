import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/core/config/theme.dart';
import 'package:linglong_store/presentation/widgets/responsive_app_grid.dart';

void main() {
  group('ResponsiveAppGrid.calculateChildAspectRatio', () {
    test(
      'uses the shared 96px app card baseline when no override is provided',
      () {
        const width = 720.0;
        const crossAxisCount = 2;
        final itemWidth =
            (width - (crossAxisCount - 1) * AppSpacing.sm) / crossAxisCount;

        final ratio = ResponsiveAppGrid.calculateChildAspectRatio(
          width,
          crossAxisCount,
        );

        expect(ratio, closeTo(itemWidth / 96.0, 0.0001));
      },
    );

    test('returns the explicit ratio override unchanged', () {
      final ratio = ResponsiveAppGrid.calculateChildAspectRatio(
        720,
        2,
        childAspectRatio: 3.2,
      );

      expect(ratio, 3.2);
    });
  });
}
