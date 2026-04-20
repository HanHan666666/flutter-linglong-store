import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/linglong_install_script_service.dart';

void main() {
  group('LinglongInstallScriptService', () {
    test('throws when backend returns an empty shell script', () async {
      final service = LinglongInstallScriptService(loadScript: () async => '');

      expect(service.fetchInstallScript, throwsA(isA<StateError>()));
    });

    test(
      'returns the trimmed shell script when backend returns content',
      () async {
        final service = LinglongInstallScriptService(
          loadScript: () async => '  #!/bin/bash\necho ok\n  ',
        );

        final script = await service.fetchInstallScript();

        expect(script, '#!/bin/bash\necho ok');
      },
    );
  });
}
