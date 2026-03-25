import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/models/api_dto.dart';

void main() {
  group('SearchAppListRequest JSON Serialization', () {
    test('should serialize keyword to name field', () {
      // Arrange
      const request = SearchAppListRequest(
        keyword: 'wps',
        pageNo: 1,
        pageSize: 10,
        repoName: 'stable',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['name'], equals('wps'));
      expect(json['pageNo'], equals(1));
      expect(json['pageSize'], equals(10));
      expect(json['repoName'], equals('stable'));
      // keyword 字段不应该出现在 JSON 中
      expect(json.containsKey('keyword'), isFalse);
    });

    test('should include optional fields when provided', () {
      // Arrange
      const request = SearchAppListRequest(
        keyword: 'test',
        pageNo: 2,
        pageSize: 20,
        arch: 'x86_64',
        lan: 'zh_CN',
        sort: 'downloadTimes',
        order: 'desc',
      );

      // Act
      final json = request.toJson();

      // Assert
      expect(json['name'], equals('test'));
      expect(json['arch'], equals('x86_64'));
      expect(json['lan'], equals('zh_CN'));
      expect(json['sort'], equals('downloadTimes'));
      expect(json['order'], equals('desc'));
    });

    test('should deserialize JSON with name field to keyword', () {
      // Arrange
      final json = {
        'name': 'wps',
        'pageNo': 1,
        'pageSize': 10,
        'repoName': 'stable',
      };

      // Act
      final request = SearchAppListRequest.fromJson(json);

      // Assert
      expect(request.keyword, equals('wps'));
      expect(request.pageNo, equals(1));
      expect(request.pageSize, equals(10));
      expect(request.repoName, equals('stable'));
    });
  });

  group('AppListResponse JSON Deserialization', () {
    test('should parse backend search response correctly', () {
      // This is the actual response from the backend
      final jsonResponse = {
        'code': 200,
        'message': '执行成功',
        'data': {
          'records': [
            {
              'id': null,
              'appId': 'cn.wps.wps-office',
              'icon': 'https://app-store-files.uniontech.com/icon/test',
              'zhName': 'WPS 2023 个人版',
              'categoryId': '07',
              'categoryName': '效率办公',
              'name': 'WPS Office',
              'channel': 'main',
              'arch': 'x86_64',
              'description': 'WPS 2023是国内领先的办公软件',
              'kind': 'app',
              'module': 'binary',
              'repoName': 'stable',
              'runtime': '',
              'size': '2475782005',
              'uabUrl': null,
              'user': null,
              'version': '12.1.2.24722',
              'flag': null,
              'createTime': '2026-01-20 16:01:04',
              'updateTime': null,
              'isDelete': null,
              'installCount': 1111,
              'uninstallCount': null,
              'last30DownloadCount': null,
              'isWelcomed': null,
              'devId': null,
              'devName': 'mozixun',
              'sort': null,
              'order': null,
              'iconNoShow': null,
              'lan': null,
              'filter': null
            }
          ],
          'total': 1,
          'size': 10,
          'current': 1,
          'pages': 1
        }
      };

      // Act
      final response = AppListResponse.fromJson(jsonResponse);

      // Assert
      expect(response.code, equals(200));
      expect(response.message, equals('执行成功'));
      expect(response.data, isNotNull);
      expect(response.data!.records.length, equals(1));
      expect(response.data!.total, equals(1));
      expect(response.data!.current, equals(1));
      expect(response.data!.pages, equals(1));

      final app = response.data!.records.first;
      expect(app.appId, equals('cn.wps.wps-office'));
      // zhName 应该被读取为 appName (通过 _readAppName)
      expect(app.appName, equals('WPS 2023 个人版'));
      // icon 应该被读取为 appIcon (通过 _readAppIcon)
      expect(app.appIcon, equals('https://app-store-files.uniontech.com/icon/test'));
      // description 应该被读取为 appDesc (通过 _readAppDescription)
      expect(app.appDesc, equals('WPS 2023是国内领先的办公软件'));
      // installCount 应该被读取为 downloadTimes (通过 _readDownloadCount)
      expect(app.downloadTimes, equals(1111));
      // size 应该被读取为 packageSize (通过 _readPackageSize)
      expect(app.packageSize, equals('2475782005'));
      // devName 应该被读取为 developerName (通过 _readDeveloperName)
      expect(app.developerName, equals('mozixun'));
      // version 应该被读取为 appVersion (通过 _readAppVersion)
      expect(app.appVersion, equals('12.1.2.24722'));
      // categoryName 直接映射
      expect(app.categoryName, equals('效率办公'));
    });

    test('should handle fallback field names', () {
      // Test with different field names that fallback should work
      final jsonResponse = {
        'code': 200,
        'data': {
          'records': [
            {
              'appId': 'com.test.app',
              'name': 'Test App Name',  // name field should fallback to appName
              'appName': 'App Name Override',  // This takes priority over name
              'zhName': 'Chinese Name',  // zhName has highest priority
              'version': '1.0.0',
              'icon': 'https://example.com/icon.png',
              'description': 'Test description',
              'devName': 'Test Developer',
              'installCount': 500,
              'size': '123456',
            }
          ],
          'total': 1,
          'size': 10,
          'current': 1,
          'pages': 1
        }
      };

      // Act
      final response = AppListResponse.fromJson(jsonResponse);

      // Assert
      final app = response.data!.records.first;
      // zhName has highest priority
      expect(app.appName, equals('Chinese Name'));
    });
  });

  group('Full Request-Response Integration', () {
    test('request JSON matches backend API expectations', () {
      // Arrange
      const request = SearchAppListRequest(
        keyword: 'wps',
        pageNo: 1,
        pageSize: 10,
        repoName: 'stable',
      );

      // Act
      final json = request.toJson();

      // Assert - This JSON should match what the backend expects
      // Backend expects: {"name":"wps","pageNo":1,"pageSize":10,"repoName":"stable"}
      expect(json['name'], equals('wps'));
      expect(json['pageNo'], equals(1));
      expect(json['pageSize'], equals(10));
      expect(json['repoName'], equals('stable'));

      // Verify this matches the curl command we tested:
      // curl -X POST "https://storeapi.linyaps.org.cn/visit/getSearchAppList" \
      //   -H "Content-Type: application/json" \
      //   -d '{"name":"wps","pageNo":1,"pageSize":10,"repoName":"stable"}'
    });
  });

  group('SearchAppListRequest categoryId Contract', () {
    test('should serialize categoryId when provided', () {
      const request = SearchAppListRequest(
        keyword: '',
        categoryId: '07',
        pageNo: 1,
        pageSize: 30,
        repoName: 'stable',
      );

      final json = request.toJson();

      expect(json['name'], equals(''));
      expect(json['categoryId'], equals('07'));
      expect(json['pageSize'], equals(30));
    });

    test('should omit categoryId when null', () {
      const request = SearchAppListRequest(
        keyword: '',
        pageNo: 1,
        pageSize: 30,
        repoName: 'stable',
      );

      final json = request.toJson();

      // null \u5b57\u6bb5\u4e0d\u5e94\u51fa\u73b0\u5728 JSON \u4e2d\uff0c\u4e0e\u540e\u7aef "\u7a7a\u503c\u8868\u793a\u5168\u90e8\u5e94\u7528" \u7684\u8bed\u4e49\u4e00\u81f4
      expect(json.containsKey('categoryId'), isFalse);
    });
  });
}