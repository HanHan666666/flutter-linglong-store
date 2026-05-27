import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/mappers/app_list_mapper.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/recommend_models.dart';

void main() {
  group('mapAppListToRecommendApps', () {
    test('keeps detail identity fields when converting search results', () {
      final data = AppListPagedData(
        records: const [
          AppListItemDTO(
            appId: 'org.example.browser',
            appName: '浏览器',
            appVersion: '1.2.3',
            arch: 'arm64',
            module: 'binary',
            repoName: 'repo',
          ),
        ],
        total: 1,
        size: 8,
        current: 1,
        pages: 1,
      );

      final mapped = mapAppListToRecommendApps(data, pageSize: 8).items.single;
      final installed = mapped.toInstalledApp();

      expect(installed.arch, 'arm64');
      expect(installed.module, 'binary');
      expect(installed.repoName, 'repo');
    });
  });
}
