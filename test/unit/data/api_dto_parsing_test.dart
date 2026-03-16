import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/models/api_dto.dart';

void main() {
  group('AppListResponse 解析测试', () {
    test('应该正确解析 getWelcomeAppList 接口返回的数据', () {
      // 模拟后端返回的实际 JSON 数据
      final jsonResponse = {
        "code": 200,
        "message": "执行成功",
        "data": {
          "records": [
            {
              "id": null,
              "appId": "com.tencent.wechat",
              "icon": "https://app-store-files.uniontech.com/icon/fa53a88af78c4d20a2b1bf78e2fc81f0",
              "zhName": "微信",
              "categoryId": null,
              "categoryName": "网络应用",
              "name": "微信",
              "channel": "main",
              "arch": "x86_64",
              "description": "支持聊天记录导入导出",
              "kind": "app",
              "module": "binary",
              "repoName": "stable",
              "runtime": "",
              "size": "759577252",
              "uabUrl": null,
              "user": null,
              "version": "4.1.1.4",
              "flag": null,
              "createTime": "2026-03-10 20:06:10",
              "updateTime": null,
              "isDelete": null,
              "installCount": 2865,
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
          "total": 7489,
          "size": 10,
          "current": 1,
          "pages": 749
        }
      };

      // 解析 JSON
      final response = AppListResponse.fromJson(jsonResponse);

      // 验证响应结构
      expect(response.code, equals(200));
      expect(response.message, equals('执行成功'));
      expect(response.data, isNotNull);
      
      // 验证分页数据
      expect(response.data!.total, equals(7489));
      expect(response.data!.size, equals(10));
      expect(response.data!.current, equals(1));
      expect(response.data!.pages, equals(749));
      
      // 验证记录列表
      expect(response.data!.records.length, equals(1));
      
      // 验证应用数据
      final app = response.data!.records.first;
      expect(app.appId, equals('com.tencent.wechat'));
      
      // 打印实际解析结果
      print('===== 解析结果 =====');
      print('appId: ${app.appId}');
      print('appName: ${app.appName}');
      print('appVersion: ${app.appVersion}');
      print('appIcon: ${app.appIcon}');
      print('appDesc: ${app.appDesc}');
      print('appKind: ${app.appKind}');
      print('developerName: ${app.developerName}');
      print('categoryName: ${app.categoryName}');
      print('downloadTimes: ${app.downloadTimes}');
      print('packageSize: ${app.packageSize}');
      
      // 验证字段映射
      // zhName -> appName
      expect(app.appName, equals('微信'));
      // version -> appVersion
      expect(app.appVersion, equals('4.1.1.4'));
      // icon -> appIcon
      expect(app.appIcon, contains('app-store-files.uniontech.com'));
      // description -> appDesc
      expect(app.appDesc, equals('支持聊天记录导入导出'));
      // kind -> appKind
      expect(app.appKind, equals('app'));
      // devName -> developerName
      expect(app.developerName, equals('mozixun'));
      // categoryName 直接映射
      expect(app.categoryName, equals('网络应用'));
      // installCount -> downloadTimes (转为 int)
      expect(app.downloadTimes, equals(2865));
      // size -> packageSize
      expect(app.packageSize, equals('759577252'));
    });

    test('应该正确处理空数据响应', () {
      final jsonResponse = {
        "code": 200,
        "message": "执行成功",
        "data": {
          "records": [],
          "total": 0,
          "size": 10,
          "current": 1,
          "pages": 0
        }
      };

      final response = AppListResponse.fromJson(jsonResponse);

      expect(response.code, equals(200));
      expect(response.data!.records.isEmpty, isTrue);
      expect(response.data!.total, equals(0));
    });
  });
}
