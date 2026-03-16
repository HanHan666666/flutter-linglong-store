import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/data/models/api_dto.dart';

void main() {
  group('CarouselDTO 字段映射测试', () {
    /// 测试后端实际返回的 AppMainDto 结构
    test('应正确解析后端返回的 AppMainDto 结构', () {
      // 这是后端实际返回的 JSON 结构
      final appMainDtoJson = {
        "id": null,
        "appId": "com.qq.wemeet",
        "icon":
            "https://app-store-files.uniontech.com/icon/4a0087e8eef54489a993d286311763b0",
        "zhName": "腾讯会议",
        "categoryId": "02",
        "categoryName": "社交通讯",
        "name": "腾讯会议",
        "channel": null,
        "arch": "x86_64",
        "description": "随时随地，高清云视频会议。",
        "kind": null,
        "module": null,
        "repoName": null,
        "runtime": null,
        "size": null,
        "uabUrl": null,
        "user": null,
        "version": "3.19.1.401",
        "flag": null,
        "createTime": null,
        "updateTime": null,
        "isDelete": null,
        "installCount": null,
        "uninstallCount": null,
        "last30DownloadCount": null,
        "isWelcomed": null,
        "devId": "252184",
        "devName": "mozixun",
        "sort": null,
        "order": null,
        "iconNoShow": null,
        "lan": null,
        "filter": null
      };

      final dto = CarouselDTO.fromJson(appMainDtoJson);

      // 验证字段映射
      expect(dto.carouselId, equals('com.qq.wemeet'),
          reason: 'carouselId 应该从 appId 字段读取');
      expect(dto.carouselTitle, equals('腾讯会议'),
          reason: 'carouselTitle 应该从 zhName 字段读取');
      expect(dto.carouselImage,
          equals('https://app-store-files.uniontech.com/icon/4a0087e8eef54489a993d286311763b0'),
          reason: 'carouselImage 应该从 icon 字段读取');
      expect(dto.carouselDesc, equals('随时随地，高清云视频会议。'),
          reason: 'carouselDesc 应该从 description 字段读取');
      expect(dto.carouselUrl, isNull,
          reason: 'carouselUrl 后端没有此字段，应为 null');
    });

    /// 测试专门的轮播图结构（如果后端改用专用结构）
    test('应正确解析专用轮播图结构', () {
      final carouselJson = {
        "carouselId": "carousel-001",
        "carouselTitle": "轮播标题",
        "carouselImage": "https://example.com/banner.jpg",
        "carouselUrl": "https://example.com/target",
        "carouselDesc": "轮播描述",
        "sort": 1
      };

      final dto = CarouselDTO.fromJson(carouselJson);

      expect(dto.carouselId, equals('carousel-001'));
      expect(dto.carouselTitle, equals('轮播标题'));
      expect(dto.carouselImage, equals('https://example.com/banner.jpg'));
      expect(dto.carouselUrl, equals('https://example.com/target'));
      expect(dto.carouselDesc, equals('轮播描述'));
      expect(dto.sort, equals(1));
    });

    /// 测试混合字段（部分来自 AppMainDto，部分来自专用字段）
    test('应正确处理字段优先级', () {
      // zhName 优先于 name
      final jsonWithZhName = {
        "appId": "app-001",
        "zhName": "中文名",
        "name": "english_name",
        "icon": "https://example.com/icon.png",
      };

      final dto = CarouselDTO.fromJson(jsonWithZhName);
      expect(dto.carouselTitle, equals('中文名'),
          reason: 'zhName 应该优先于 name');
    });

    /// 测试完整的 API 响应解析
    test('应正确解析完整的 CarouselListResponse', () {
      final responseJson = {
        "code": 200,
        "message": "执行成功",
        "data": [
          {
            "appId": "com.qq.wemeet",
            "icon":
                "https://app-store-files.uniontech.com/icon/4a0087e8eef54489a993d286311763b0",
            "zhName": "腾讯会议",
            "name": "腾讯会议",
            "description": "随时随地，高清云视频会议。",
          },
          {
            "appId": "com.qq.weixin.work.deepin",
            "icon":
                "https://app-store-files.uniontech.com/icon/8b753ffa577a4f939f0c272d25d3fbec",
            "zhName": "企业微信",
            "name": "com.qq.weixin.work.deepin",
            "description": "工作沟通安全高效。",
          },
        ]
      };

      final response = CarouselListResponse.fromJson(responseJson);

      expect(response.code, equals(200));
      expect(response.message, equals('执行成功'));
      expect(response.data.length, equals(2));

      // 验证第一项
      expect(response.data[0].carouselId, equals('com.qq.wemeet'));
      expect(response.data[0].carouselTitle, equals('腾讯会议'));
      expect(response.data[0].carouselDesc, equals('随时随地，高清云视频会议。'));

      // 验证第二项
      expect(response.data[1].carouselId, equals('com.qq.weixin.work.deepin'));
      expect(response.data[1].carouselTitle, equals('企业微信'));
    });

    /// 测试缺失必填字段的情况
    test('应在缺失必填字段时抛出错误', () {
      final incompleteJson = {
        "appId": "app-001",
        // 缺少 icon 字段
        "zhName": "测试应用",
      };

      // 由于 icon 是必填字段（required），应该能够处理 null 的情况
      // 实际上 readValue 返回 null 时会尝试转换为 String，会抛出错误
      expect(() => CarouselDTO.fromJson(incompleteJson), throwsA(isA<TypeError>()));
    });
  });
}