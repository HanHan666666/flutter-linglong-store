import 'dart:io';

String updatePubspecVersion(String input, String version) {
  return _replaceVersionLine(input, 'version: $version+1');
}

String updateLinuxPubspecVersion(String input, String version) {
  return _replaceVersionLine(input, 'version: $version+1');
}

String updateAppConfigVersion(String input, String version) {
  return _replaceAppVersionConstant(input, version);
}

String updateAppConstantsVersion(String input, String version) {
  return _replaceAppVersionConstant(input, version);
}

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/release/update_version_files.dart <version>',
    );
    exitCode = 64;
    return;
  }

  final version = args.single.trim();
  _rewriteFileAtomically(
    'pubspec.yaml',
    (content) => updatePubspecVersion(content, version),
  );
  _rewriteFileAtomically(
    'linux/pubspec.yaml',
    (content) => updateLinuxPubspecVersion(content, version),
  );
  _rewriteFileAtomically(
    'lib/core/config/app_config.dart',
    (content) => updateAppConfigVersion(content, version),
  );
  _rewriteFileAtomically(
    'lib/core/constants/app_constants.dart',
    (content) => updateAppConstantsVersion(content, version),
  );
}

final RegExp _versionLinePattern = RegExp(r'^version:\s*.+$', multiLine: true);
final RegExp _appVersionPattern = RegExp(
  r"static const String appVersion = '[^']*';",
);

String _replaceVersionLine(String input, String replacement) {
  final updated = input.replaceFirst(_versionLinePattern, replacement);
  if (updated == input) {
    throw ArgumentError('Unable to find version line to update.');
  }
  return _normalizeTrailingNewline(updated);
}

String _replaceAppVersionConstant(String input, String version) {
  final updated = input.replaceFirst(
    _appVersionPattern,
    "static const String appVersion = '$version';",
  );
  if (updated == input) {
    throw ArgumentError('Unable to find appVersion constant to update.');
  }
  return _normalizeTrailingNewline(updated);
}

String _normalizeTrailingNewline(String input) {
  return input.replaceFirst(RegExp(r'\n+$'), '\n');
}

void _rewriteFileAtomically(
  String path,
  String Function(String input) updater,
) {
  final file = File(path);
  final original = file.readAsStringSync();
  final updated = updater(original);
  final tempFile = File('$path.tmp');
  tempFile.writeAsStringSync(updated);
  tempFile.renameSync(path);
}
