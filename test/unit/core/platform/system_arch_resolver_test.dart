import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/system_arch_resolver.dart';

void main() {
  group('SystemArchResolver', () {
    test('keeps LoongArch old-world request arch as loongarch64', () {
      expect(
        SystemArchResolver.resolveLinuxRequestArch(
          kernelArch: 'loongarch64',
          debianArch: 'loongarch64',
        ),
        'loongarch64',
      );
    });

    test('maps LoongArch new-world Debian arch to loong64', () {
      expect(
        SystemArchResolver.resolveLinuxRequestArch(
          kernelArch: 'loongarch64',
          debianArch: 'loong64',
        ),
        'loong64',
      );
    });

    test('defaults LoongArch uname-only detection to old-world mapping', () {
      expect(
        SystemArchResolver.resolveLinuxRequestArch(kernelArch: 'loongarch64'),
        'loongarch64',
      );
    });

    test('preserves non-LoongArch kernel architectures', () {
      expect(
        SystemArchResolver.resolveLinuxRequestArch(
          kernelArch: 'AARCH64\n',
          debianArch: 'arm64',
        ),
        'aarch64',
      );
    });

    test('reads dpkg architecture only for LoongArch kernels', () {
      final result = SystemArchResolver.resolveCurrentLinuxRequestArch(
        kernelArchFile: _FakeFile('loongarch64\n'),
        runSync: (executable, arguments) {
          expect(executable, 'dpkg');
          expect(arguments, ['--print-architecture']);
          return ProcessResult(0, 0, 'loong64\n', '');
        },
      );

      expect(result, 'loong64');
    });
  });
}

class _FakeFile implements File {
  _FakeFile(this._content);

  final String _content;

  @override
  bool existsSync() => true;

  @override
  String readAsStringSync({Encoding encoding = utf8}) => _content;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
