import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/generate_changelog.dart';

void main() {
  group('generateChangelog', () {
    test('returns the first release guidance when no previous tag exists', () {
      final firstReleaseBody = generateChangelog(
        previousTag: null,
        releaseVersion: '3.0.7',
        commits: const [],
      );

      expect(firstReleaseBody, contains('首个 GitHub Release'));
    });

    test('omits the release commit from generated notes and keeps feat grouping', () {
      final changelogBody = generateChangelog(
        previousTag: 'v3.0.6',
        releaseVersion: '3.0.7',
        commits: const [
          'feat: add release tooling baseline',
          'chore: release 3.0.7',
        ],
      );

      expect(changelogBody, isNot(contains('chore: release 3.0.7')));
      expect(changelogBody, contains('## feat'));
    });
  });
}
