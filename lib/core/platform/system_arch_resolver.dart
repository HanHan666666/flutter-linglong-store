import 'dart:io';

typedef SyncProcessRunner =
    ProcessResult Function(String executable, List<String> arguments);

class SystemArchResolver {
  static const String loongArchOldWorld = 'loongarch64';
  static const String loongArchNewWorld = 'loong64';
  static const String defaultArch = 'x86_64';

  const SystemArchResolver._();

  static bool isLoongArchKernelArch(String? arch) {
    final normalized = _normalize(arch);
    return normalized == loongArchOldWorld || normalized == loongArchNewWorld;
  }

  static String resolveLinuxRequestArch({
    required String? kernelArch,
    String? debianArch,
    String fallbackArch = defaultArch,
  }) {
    final normalizedKernelArch = _normalize(kernelArch);
    if (normalizedKernelArch == null) {
      return fallbackArch;
    }

    switch (normalizedKernelArch) {
      case loongArchOldWorld:
        return _normalize(debianArch) == loongArchNewWorld
            ? loongArchNewWorld
            : loongArchOldWorld;
      case loongArchNewWorld:
        return loongArchNewWorld;
      default:
        return normalizedKernelArch;
    }
  }

  static String resolveCurrentLinuxRequestArch({
    File? kernelArchFile,
    SyncProcessRunner? runSync,
    String fallbackArch = defaultArch,
  }) {
    final kernelArch = _readKernelArch(
      kernelArchFile: kernelArchFile,
      runSync: runSync,
    );
    final debianArch = isLoongArchKernelArch(kernelArch)
        ? _readDebianArch(runSync: runSync)
        : null;

    return resolveLinuxRequestArch(
      kernelArch: kernelArch,
      debianArch: debianArch,
      fallbackArch: fallbackArch,
    );
  }

  static String? _readKernelArch({
    File? kernelArchFile,
    SyncProcessRunner? runSync,
  }) {
    try {
      final archFile = kernelArchFile ?? File('/proc/sys/kernel/arch');
      if (archFile.existsSync()) {
        final arch = _normalize(archFile.readAsStringSync());
        if (arch != null) {
          return arch;
        }
      }
    } catch (_) {}

    try {
      final runner = runSync ?? Process.runSync;
      final result = runner('uname', ['-m']);
      if (result.exitCode == 0) {
        return _normalize(result.stdout.toString());
      }
    } catch (_) {}

    return null;
  }

  static String? _readDebianArch({SyncProcessRunner? runSync}) {
    try {
      final runner = runSync ?? Process.runSync;
      final result = runner('dpkg', ['--print-architecture']);
      if (result.exitCode == 0) {
        return _normalize(result.stdout.toString());
      }
    } catch (_) {}

    return null;
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
