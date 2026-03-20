import 'dart:io';

String resolveReleaseVersion({
  required List<String> tags,
  required String? manualVersion,
}) {
  final latestVersion = _findLatestVersion(tags);

  if (manualVersion != null) {
    final parsedManualVersion = _parseVersion(manualVersion);
    if (latestVersion != null &&
        _compareVersions(parsedManualVersion, latestVersion) <= 0) {
      throw ArgumentError(
        'Manual version must be greater than the latest release tag: ${_formatVersion(latestVersion)}',
      );
    }
    return _formatVersion(parsedManualVersion);
  }

  if (latestVersion == null) {
    return '3.0.0';
  }

  return '3.0.${latestVersion.patch + 1}';
}

void main(List<String> args) {
  try {
    final manualVersion = _readManualVersion(args);
    final tagsResult = Process.runSync('git', const [
      'tag',
      '--list',
      'v3.0.*',
    ], runInShell: true);
    if (tagsResult.exitCode != 0) {
      stderr.write(tagsResult.stderr);
      exit(tagsResult.exitCode);
    }

    final tags = tagsResult.stdout
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    stdout.writeln(
      resolveReleaseVersion(tags: tags, manualVersion: manualVersion),
    );
  } on ArgumentError catch (error) {
    stderr.writeln(error.message);
    exitCode = 64;
  }
}

final RegExp _semverPattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');
final RegExp _tagPattern = RegExp(r'^v3\.0\.(\d+)$');

_Version? _findLatestVersion(List<String> tags) {
  _Version? latest;

  for (final tag in tags) {
    final match = _tagPattern.firstMatch(tag.trim());
    if (match == null) {
      continue;
    }

    final version = _Version(3, 0, int.parse(match.group(1)!));
    if (latest == null || _compareVersions(version, latest) > 0) {
      latest = version;
    }
  }

  return latest;
}

_Version _parseVersion(String input) {
  final normalized = input.trim();
  final match = _semverPattern.firstMatch(normalized);
  if (match == null) {
    throw ArgumentError('Invalid version: $input');
  }

  return _Version(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

int _compareVersions(_Version left, _Version right) {
  if (left.major != right.major) {
    return left.major.compareTo(right.major);
  }
  if (left.minor != right.minor) {
    return left.minor.compareTo(right.minor);
  }
  return left.patch.compareTo(right.patch);
}

String _formatVersion(_Version version) =>
    '${version.major}.${version.minor}.${version.patch}';

String? _readManualVersion(List<String> args) {
  if (args.isEmpty) {
    return null;
  }

  if (args.length == 1) {
    return args.first;
  }

  if (args.length == 2 && args.first == '--manual-version') {
    return args.last;
  }

  throw ArgumentError(
    'Usage: dart run tool/release/release_version.dart [--manual-version <version>]',
  );
}

class _Version {
  const _Version(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;
}
