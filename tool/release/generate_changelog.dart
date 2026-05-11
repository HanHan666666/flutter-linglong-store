import 'dart:io';

// 正式 release commit 固定由 workflow 生成；历史上还存在带“Running build hooks...”噪音的异常样本，
// 这里仅兼容这些 bookkeeping 文案，避免误吞掉正常的 chore 提交。
final RegExp _releaseBookkeepingCommitPattern = RegExp(
  r'^chore(?:\([^)]+\))?!?: release (?:(?:Running build hooks\.\.\.)*)?v?\d+\.\d+\.\d+$',
);

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
    if (normalized.isEmpty || _isReleaseBookkeepingCommit(normalized)) {
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
  final previousTag = args.length == 2
      ? args.last.trim()
      : _readResolvedPreviousReleaseTag();
  final commits = previousTag == null
      ? const <String>[]
      : _readCommitSubjects(previousTag);

  stdout.write(
    generateChangelog(
      previousTag: previousTag,
      releaseVersion: releaseVersion,
      commits: commits,
    ),
  );
}

String? _readResolvedPreviousReleaseTag() {
  // release notes 必须跟随默认发布主线的最近 stable tag，而不是被合入的支线高版本 tag 抢走基线，
  // 因此这里显式使用 first-parent 约束最近可达 release tag。
  final result = Process.runSync('git', const [
    'describe',
    '--tags',
    '--abbrev=0',
    '--first-parent',
    '--match',
    'v[0-9]*.[0-9]*.[0-9]*',
    'HEAD',
  ], runInShell: true);
  final resolvedTag = result.stdout.toString().trim();

  if (result.exitCode == 0) {
    return resolvedTag.isEmpty ? null : resolvedTag;
  }

  final stderrOutput = result.stderr.toString();
  final normalizedError = stderrOutput.toLowerCase();
  if (normalizedError.contains('no names found') ||
      normalizedError.contains('cannot describe')) {
    return null;
  }

  if (result.exitCode != 0) {
    stderr.write(result.stderr);
    exit(result.exitCode);
  }

  return null;
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

bool _isReleaseBookkeepingCommit(String commit) =>
    _releaseBookkeepingCommitPattern.hasMatch(commit);
