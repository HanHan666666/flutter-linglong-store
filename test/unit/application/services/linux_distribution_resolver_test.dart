import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/application/services/linux_distribution_resolver.dart';
import 'package:linglong_store/domain/models/linux_distribution.dart';

void main() {
  group('LinuxDistributionResolver', () {
    const resolver = LinuxDistributionResolver();

    test('resolves UOS from os-release identity fields', () {
      final distribution = resolver.resolve(const <String, String>{
        'ID': 'uos',
        'NAME': 'UnionTech OS Desktop',
        'PRETTY_NAME': 'UOS 1070',
      });

      expect(distribution.id, LinuxDistributionId.uos);
      expect(distribution.displayName, 'UOS 1070');
      expect(
        distribution.supportsGuidanceScenario(
          LinuxDistributionGuidanceScenario.envInstallDialog,
        ),
        isTrue,
      );
    });

    test('resolves UOS from ID_LIKE when ID itself is not explicit', () {
      final distribution = resolver.resolve(const <String, String>{
        'ID': 'deepin-desktop',
        'ID_LIKE': 'debian uniontech',
        'NAME': 'Deepin Pro',
      });

      expect(distribution.id, LinuxDistributionId.uos);
      expect(distribution.displayName, 'Deepin Pro');
    });

    test(
      'returns a plain distribution profile when no special rule matches',
      () {
        final distribution = resolver.resolve(const <String, String>{
          'ID': 'deepin',
          'PRETTY_NAME': 'Deepin 23',
        });

        expect(distribution.id, LinuxDistributionId.unknown);
        expect(distribution.displayName, 'Deepin 23');
        expect(distribution.hasSpecialAdaptation, isFalse);
      },
    );

    test('returns unknown profile for empty os-release data', () {
      final distribution = resolver.resolve(const <String, String>{});

      expect(distribution, LinuxDistribution.unknown);
    });
  });
}
