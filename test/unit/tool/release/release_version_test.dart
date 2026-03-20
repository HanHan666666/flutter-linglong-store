import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/release_version.dart';

void main() {
  group('resolveReleaseVersion', () {
    test('increments the latest release tag patch version', () {
      expect(
        resolveReleaseVersion(
          tags: ['v3.0.9', 'v3.0.10'],
          manualVersion: null,
        ),
        '3.0.11',
      );
    });

    test('falls back to the first release version when no tags exist', () {
      expect(
        resolveReleaseVersion(
          tags: const [],
          manualVersion: null,
        ),
        '3.0.0',
      );
    });

    test('rejects manual versions that do not move past the latest tag', () {
      expect(
        () => resolveReleaseVersion(
          tags: ['v3.0.10'],
          manualVersion: '3.0.2',
        ),
        throwsArgumentError,
      );
    });
  });
}
