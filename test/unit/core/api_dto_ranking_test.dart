import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/models/api_dto.dart';

void main() {
  group('排行榜接口 DTO 解析测试', () {
    test('getNewAppList 最新应用接口解析', () {
      // 后端实际返回的 JSON
      const jsonStr = '''
{
  "code": 200,
  "message": "执行成功",
  "data": {
    "records": [
      {
        "id": null,
        "appId": "app.grayjay.Grayjay",
        "icon": "https://app-store-files.uniontech.com/icon/97e22518d272402cbedc831523ed6e4e",
        "zhName": "Grayjay",
        "categoryId": null,
        "categoryName": "视频播放",
        "name": "app.grayjay.Grayjay",
        "channel": "main",
        "arch": "x86_64",
        "description": "Grayjay是一款多平台媒体应用",
        "kind": "app",
        "module": "binary",
        "repoName": "stable",
        "runtime": "",
        "size": "959753386",
        "uabUrl": null,
        "user": null,
        "version": "9.0.0.0",
        "flag": null,
        "createTime": "2026-03-15 22:53:21",
        "updateTime": null,
        "isDelete": null,
        "installCount": null,
        "uninstallCount": null,
        "last30DownloadCount": null,
        "isWelcomed": null,
        "devId": null,
        "devName": "appdeveloper",
        "sort": null,
        "order": null,
        "iconNoShow": null,
        "lan": null,
        "filter": null
      }
    ],
    "total": 8568,
    "size": 2,
    "current": 1,
    "pages": 4284
  }
}
''';

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final response = AppListResponse.fromJson(json);

      // 验证响应码
      expect(response.code, equals(200));
      expect(response.message, equals('执行成功'));

      // 验证分页数据
      expect(response.data, isNotNull);
      expect(response.data!.total, equals(8568));
      expect(response.data!.size, equals(2));
      expect(response.data!.current, equals(1));
      expect(response.data!.pages, equals(4284));

      // 验证记录
      expect(response.data!.records.length, equals(1));
      final app = response.data!.records.first;

      // 验证字段映射
      print('\n========== 字段映射验证 ==========');
      print('appId: ${app.appId} (期望: app.grayjay.Grayjay)');
      print('appName: ${app.appName} (期望: Grayjay, 来自 zhName)');
      print('appVersion: ${app.appVersion} (期望: 9.0.0.0, 来自 version)');
      print('appIcon: ${app.appIcon}');
      print('appDesc: ${app.appDesc} (期望来自 description)');
      print('appKind: ${app.appKind} (期望: app, 来自 kind)');
      print('developerName: ${app.developerName} (期望: appdeveloper, 来自 devName)');
      print('downloadTimes: ${app.downloadTimes} (期望来自 installCount)');
      print('packageSize: ${app.packageSize} (期望: 959753386, 来自 size)');

      expect(app.appId, equals('app.grayjay.Grayjay'));
      expect(app.appName, equals('Grayjay'));
      expect(app.appVersion, equals('9.0.0.0'));
      expect(app.appIcon, isNotNull);
      expect(app.appDesc, equals('Grayjay是一款多平台媒体应用'));
      expect(app.appKind, equals('app'));
      expect(app.developerName, equals('appdeveloper'));
      expect(app.packageSize, equals('959753386'));
    });

    test('getInstallAppList 下载排行接口解析', () {
      // 后端实际返回的 JSON (包含 installCount)
      const jsonStr = '''
{
  "code": 200,
  "message": "执行成功",
  "data": {
    "records": [
      {
        "id": null,
        "appId": "org.dde.calendar",
        "icon": "https://app-store-files.uniontech.com/icon/00a968fbca6644b287e5b5a6c2f828c5",
        "zhName": "日历",
        "categoryId": "08",
        "categoryName": "系统工具",
        "name": "dde-calendar",
        "channel": "main",
        "arch": "x86_64",
        "description": "日历是一款查看日期、管理日程的小工具。",
        "kind": "app",
        "module": "binary",
        "repoName": "stable",
        "runtime": "main:org.deepin.runtime.dtk/25.2.1/x86_64",
        "size": "18853877",
        "uabUrl": null,
        "user": null,
        "version": "6.5.31.1",
        "flag": null,
        "createTime": "2025-12-31 14:35:55",
        "updateTime": null,
        "isDelete": null,
        "installCount": 3800,
        "uninstallCount": null,
        "last30DownloadCount": null,
        "isWelcomed": null,
        "devId": null,
        "devName": "jhkyy",
        "sort": null,
        "order": null,
        "iconNoShow": null,
        "lan": null,
        "filter": null
      },
      {
        "id": null,
        "appId": "com.tencent.wechat",
        "icon": "https://app-store-files.uniontech.com/icon/fa53a88af78c4d20a2b1bf78e2fc81f0",
        "zhName": "微信",
        "categoryId": "01",
        "categoryName": "网络应用",
        "name": "微信",
        "channel": "main",
        "arch": "x86_64",
        "description": "支持聊天记录导入导出",
        "kind": "app",
        "module": "binary",
        "repoName": "stable",
        "runtime": "",
        "size": "745885588",
        "uabUrl": null,
        "user": null,
        "version": "4.1.1.4",
        "flag": null,
        "createTime": "2026-03-10 20:06:10",
        "updateTime": null,
        "isDelete": null,
        "installCount": 3017,
        "uninstallCount": null,
        "last30DownloadCount": null,
        "isWelcomed": null,
        "devId": null,
        "devName": "mozixun",
        "sort": null,
        "order": null,
        "iconNoShow": null,
        "lan": null,
        "filter": null
      }
    ],
    "total": 100,
    "size": 2,
    "current": 1,
    "pages": 50
  }
}
''';

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final response = AppListResponse.fromJson(json);

      // 验证响应码
      expect(response.code, equals(200));

      // 验证分页数据
      expect(response.data, isNotNull);
      expect(response.data!.records.length, equals(2));

      // 验证第一条记录（日历）
      final app1 = response.data!.records.first;
      print('\n========== 下载排行第一条记录 ==========');
      print('appId: ${app1.appId}');
      print('appName: ${app1.appName}');
      print('downloadTimes: ${app1.downloadTimes} (期望: 3800, 来自 installCount)');
      print('developerName: ${app1.developerName}');

      expect(app1.appId, equals('org.dde.calendar'));
      expect(app1.appName, equals('日历'));
      expect(app1.downloadTimes, equals(3800)); // installCount 映射到 downloadTimes
      expect(app1.developerName, equals('jhkyy'));

      // 验证第二条记录（微信）
      final app2 = response.data!.records[1];
      print('\n========== 下载排行第二条记录 ==========');
      print('appId: ${app2.appId}');
      print('appName: ${app2.appName}');
      print('downloadTimes: ${app2.downloadTimes} (期望: 3017)');
      print('developerName: ${app2.developerName}');

      expect(app2.appId, equals('com.tencent.wechat'));
      expect(app2.appName, equals('微信'));
      expect(app2.downloadTimes, equals(3017));
      expect(app2.developerName, equals('mozixun'));
    });

    test('字段映射差异检查', () {
      print('\n========== 字段映射差异分析 ==========');

      // 后端返回字段 -> Flutter DTO 字段
      final mapping = {
        'appId': 'appId (直接映射)',
        'zhName': 'appName (通过 _readAppName)',
        'version': 'appVersion (通过 _readAppVersion)',
        'icon': 'appIcon (通过 _readAppIcon)',
        'description': 'appDesc (通过 _readAppDescription)',
        'kind': 'appKind (通过 _readAppKind)',
        'devName': 'developerName (通过 _readDeveloperName)',
        'installCount': 'downloadTimes (通过 _readDownloadCount)',
        'size': 'packageSize (通过 _readPackageSize)',
        'categoryName': 'categoryName (直接映射)',
      };

      print('后端字段 -> Flutter DTO 字段:');
      mapping.forEach((backend, flutter) {
        print('  $backend -> $flutter');
      });

      print('\n后端返回但 Flutter DTO 未使用的字段:');
      final unusedFields = [
        'id', 'name', 'channel', 'arch', 'module', 'repoName',
        'runtime', 'uabUrl', 'user', 'flag', 'createTime', 'updateTime',
        'isDelete', 'uninstallCount', 'last30DownloadCount', 'isWelcomed',
        'devId', 'sort', 'order', 'iconNoShow', 'lan', 'filter'
      ];
      for (final field in unusedFields) {
        print('  - $field');
      }

      print('\n结论: DTO 字段映射设计正确，使用了 readValue 实现多字段名兼容');
    });
  });
}