import 'dart:io';

String generateChangelog({
  required String? previousTag,
  required String releaseVersion,
  required List<String> commits,
}) {
  if (previousTag == null) {
    return '''## Release Notes

首个 GitHub Release，后续版本将从上一版 tag 自动生成变更日志。
''';
  }

  const orderedGroups = <String>[
    'feat',
    'fix',
    'docs',
    'refactor',
    'perf',
    'test',
    'build',
    'ci',
    'style',
    'revert',
    'chore',
  ];

  final grouped = <String, List<String>>{};

  for (final commit in commits) {
    final normalized = commit.trim();
    if (normalized.isEmpty || normalized == 'chore: release $releaseVersion') {
      continue;
    }

    final match = RegExp(
      r'^([a-z]+)(?:\([^)]+\))?!?: (.+)$',
    ).firstMatch(normalized);
    if (match == null) {
      grouped.putIfAbsent('other', () => <String>[]).add(normalized);
      continue;
    }

    final type = match.group(1)!;
    final subject = match.group(2)!;
    final bucket = orderedGroups.contains(type) ? type : 'other';
    grouped.putIfAbsent(bucket, () => <String>[]).add(subject);
  }

  final buffer = StringBuffer('## Release Notes\n');

  for (final group in <String>[...orderedGroups, 'other']) {
    final entries = grouped[group];
    if (entries == null || entries.isEmpty) {
      continue;
    }

    buffer
      ..writeln()
      ..writeln('## $group');
    for (final entry in entries) {
      buffer.writeln('- $entry');
    }
  }

  return buffer.toString();
}

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/release/generate_changelog.dart <release-version> [previous-tag]',
    );
    exitCode = 64;
    return;
  }

  final releaseVersion = args.first.trim();
  final previousTag = args.length == 2 ? args.last.trim() : null;
  final commits = _readCommitSubjects(previousTag);

  stdout.write(
    generateChangelog(
      previousTag: previousTag,
      releaseVersion: releaseVersion,
      commits: commits,
    ),
  );
}

List<String> _readCommitSubjects(String? previousTag) {
  final gitArgs = <String>['log', '--format=%s'];
  if (previousTag != null && previousTag.isNotEmpty) {
    gitArgs.add('$previousTag..HEAD');
  }

  final result = Process.runSync('git', gitArgs, runInShell: true);
  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  return result.stdout
      .toString()
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
}
