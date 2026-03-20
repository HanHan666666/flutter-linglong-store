import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/release/generate_changelog.dart';

void main() {
  group('generateChangelog', () {
    test('returns the exact first release body when no previous tag exists', () {
      final firstReleaseBody = generateChangelog(
        previousTag: null,
        releaseVersion: '3.0.7',
        commits: const [],
      );

      expect(
        firstReleaseBody,
        equals('''## Release Notes

首个 GitHub Release，后续版本将从上一版 tag 自动生成变更日志。
'''),
      );
    });

    test('renders grouped changelog output without the release commit', () {
      final changelogBody = generateChangelog(
        previousTag: 'v3.0.6',
        releaseVersion: '3.0.7',
        commits: const [
          'feat: add release tooling baseline',
          'fix: align release note contract',
          'docs: document the release baseline',
          'chore: release 3.0.7',
          'not a conventional commit',
        ],
      );

      expect(
        changelogBody,
        equals('''## Release Notes

## feat
- add release tooling baseline

## fix
- align release note contract

## docs
- document the release baseline

## other
- not a conventional commit
'''),
      );
    });
  });
}
