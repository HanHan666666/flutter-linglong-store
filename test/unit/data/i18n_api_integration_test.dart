/// i18n API 集成测试
///
/// 目标：验证 lan 参数在以下两个层面均工作正常：
///   1. 序列化层——DTO 的 toJson 正确携带 lan 字段（无需网络，flutter test 可跑）
///   2. 真实网络层——调真实后端接口，返回 code=200 且 records 非空
///
/// 重要：网络测试必须用 dart test 跑（避免 TestWidgetsFlutterBinding 拦截 HTTP）：
///   dart test test/unit/data/i18n_api_integration_test.dart -p vm
///   dart test test/unit/data/i18n_api_integration_test.dart -p vm --tags network
///
/// 序列化测试（无需网络）：
///   flutter test test/unit/data/i18n_api_integration_test.dart --name "I18n DTO"
///
/// 如果 CI 环境无法访问后端，可通过环境变量跳过网络测试：
///   SKIP_NETWORK_TESTS=true dart test test/unit/data/i18n_api_integration_test.dart -p vm
///
/// 注意：flutter test 会使用 TestWidgetsFlutterBinding，导致所有 HTTP 返回 400。
///       真实 API 测试必须使用 dart test -p vm 运行。
// @dart=2.19
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/config/app_config.dart';
import 'package:linglong_store/data/datasources/remote/app_api_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';

/// 是否跳过需要真实网络的测试（CI 离线环境设置此变量）
bool get _skipNetworkTests =>
    Platform.environment['SKIP_NETWORK_TESTS'] == 'true';

/// 构建一个最小化的 Dio 实例，直接对接后端
Dio _buildDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  return dio;
}

void main() {
  // ===========================================================
  // Part 1：序列化单元测试（无网络，始终运行）
  // ===========================================================
  group('I18n DTO 序列化验证', () {
    group('PageParams', () {
      test('lan 字段被正确序列化到 JSON', () {
        final params = PageParams(
          pageNo: 1,
          pageSize: 10,
          lan: 'zh_CN',
        );
        final json = params.toJson();
        expect(json['lan'], equals('zh_CN'));
      });

      test('lan 为 en_US 时正确序列化', () {
        final params = PageParams(pageNo: 1, pageSize: 10, lan: 'en_US');
        final json = params.toJson();
        expect(json['lan'], equals('en_US'));
      });

      test('lan 为 null 时不包含该字段（或为 null）', () {
        final params = PageParams(pageNo: 1, pageSize: 10);
        final json = params.toJson();
        // null 字段可以不序列化，也可以序列化为 null，均可接受
        expect(json['lan'], isNull);
      });
    });

    group('SearchAppListRequest', () {
      test('lan=zh_CN 正确序列化', () {
        final req = SearchAppListRequest(
          keyword: 'wps',
          pageNo: 1,
          pageSize: 10,
          lan: 'zh_CN',
        );
        final json = req.toJson();
        // keyword 应序列化为 name（后端字段名）
        expect(json['name'], equals('wps'));
        expect(json['lan'], equals('zh_CN'));
      });

      test('lan=en_US 正确序列化', () {
        final req = SearchAppListRequest(
          keyword: 'test',
          pageNo: 1,
          pageSize: 5,
          lan: 'en_US',
        );
        final json = req.toJson();
        expect(json['lan'], equals('en_US'));
      });
    });

    group('AppWelcomeSearchRequest', () {
      test('lan 为 null 时可正确序列化（不再硬编码 zh）', () {
        // 修改前 lan 硬编码为 AppConfig.defaultLocale('zh')
        // 修改后 lan 是可空字段，由调用者决定传什么
        const req = AppWelcomeSearchRequest();
        final json = req.toJson();
        // 关键：lan 应为 null 而非硬编码的 'zh'
        expect(json['lan'], isNull, reason: 'lan 不应再硬编码为 zh，应由调用处动态注入');
      });

      test('传入 zh_CN 时正确序列化', () {
        const req = AppWelcomeSearchRequest(lan: 'zh_CN');
        final json = req.toJson();
        expect(json['lan'], equals('zh_CN'));
      });

      test('传入 en_US 时正确序列化', () {
        const req = AppWelcomeSearchRequest(lan: 'en_US');
        final json = req.toJson();
        expect(json['lan'], equals('en_US'));
      });
    });

    group('AppVersionListRequest', () {
      test('新增的 lan 字段正确序列化', () {
        final req = AppVersionListRequest(
          appId: 'cn.wps.wps-office',
          lan: 'zh_CN',
        );
        final json = req.toJson();
        expect(json['appId'], equals('cn.wps.wps-office'));
        expect(json['lan'], equals('zh_CN'));
      });

      test('lan 为 null 时不影响其他字段', () {
        final req = AppVersionListRequest(appId: 'com.example.app');
        final json = req.toJson();
        expect(json['appId'], equals('com.example.app'));
        expect(json['lan'], isNull);
      });
    });

    group('SidebarAppsRequest', () {
      test('lan 字段若存在则正确序列化', () {
        // SidebarAppsRequest 已有 String? lan 字段
        // 此处只测 PageParams 路径，SidebarAppsRequest 同理
        final params = PageParams(
          pageNo: 1,
          pageSize: 20,
          lan: 'zh_CN',
          repoName: 'stable',
        );
        final json = params.toJson();
        expect(json['lan'], equals('zh_CN'));
        expect(json['repoName'], equals('stable'));
      });
    });
  });

  // ===========================================================
  // Part 2：真实 API 网络集成测试
  // 验证：传入 lan 参数后，后端返回非空数据
  // ===========================================================
  group('真实 API 集成测试（需要网络）', () {
    late AppApiService apiService;

    setUpAll(() {
      if (_skipNetworkTests) return;
      apiService = AppApiService(_buildDio(), baseUrl: AppConfig.apiBaseUrl);
    });

    test('getSearchAppList lan=zh_CN 返回非空记录', () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getSearchAppList(
        const SearchAppListRequest(
          keyword: '',
          pageNo: 1,
          pageSize: 5,
          lan: 'zh_CN',
        ),
      );

      // 验证 HTTP 状态
      expect(response.response.statusCode, equals(200));

      // 验证业务层
      final body = response.data;
      expect(body.code, equals(200), reason: '后端业务 code 应为 200');
      expect(body.data, isNotNull, reason: 'data 字段不应为 null');
      expect(
        body.data!.records,
        isNotEmpty,
        reason: 'lan=zh_CN 时应返回非空应用列表',
      );
    });

    test('getSearchAppList lan=en_US 返回非空记录', () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getSearchAppList(
        const SearchAppListRequest(
          keyword: '',
          pageNo: 1,
          pageSize: 5,
          lan: 'en_US',
        ),
      );

      expect(response.response.statusCode, equals(200));
      final body = response.data;
      expect(body.code, equals(200));
      expect(body.data, isNotNull);
      expect(
        body.data!.records,
        isNotEmpty,
        reason: 'lan=en_US 时应返回非空应用列表',
      );
    });

    test('getWelcomeAppList（PageParams 携带 lan=zh_CN）返回非空记录', () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getWelcomeAppList(
        const PageParams(pageNo: 1, pageSize: 5, lan: 'zh_CN'),
      );

      expect(response.response.statusCode, equals(200));
      expect(response.data.code, equals(200));
      expect(
        response.data.data?.records,
        isNotEmpty,
        reason: '推荐列表（zh_CN）应返回非空数据',
      );
    });

    test('getNewAppList（PageParams 携带 lan=zh_CN）返回非空记录', () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getNewAppList(
        const PageParams(pageNo: 1, pageSize: 5, lan: 'zh_CN'),
      );

      expect(response.response.statusCode, equals(200));
      expect(response.data.code, equals(200));
      expect(
        response.data.data?.records,
        isNotEmpty,
        reason: '新上架列表（zh_CN）应返回非空数据',
      );
    });

    test('getInstallAppList（PageParams 携带 lan=zh_CN）返回非空记录', () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getInstallAppList(
        const PageParams(pageNo: 1, pageSize: 5, lan: 'zh_CN'),
      );

      expect(response.response.statusCode, equals(200));
      expect(response.data.code, equals(200));
      expect(
        response.data.data?.records,
        isNotEmpty,
        reason: '热门下载列表（zh_CN）应返回非空数据',
      );
    });

    test('getSearchAppVersionList（AppVersionListRequest 携带 lan=zh_CN）返回非空记录',
        () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      // 用一个已知存在的应用来测试版本列表
      final response = await apiService.getSearchAppVersionList(
        AppVersionListRequest(
          appId: 'cn.wps.wps-office',
          repoName: AppConfig.defaultStoreRepoName,
          pageNo: 1,
          pageSize: 10,
          lan: 'zh_CN',
        ),
      );

      expect(response.response.statusCode, equals(200));
      expect(response.data.code, equals(200));
      expect(
        response.data.data,
        isNotEmpty,
        reason: 'WPS 版本列表（zh_CN）应返回非空数据',
      );
    });

    test('getWelcomeCarouselList（AppWelcomeSearchRequest 携带 lan=zh_CN）返回非空记录',
        () async {
      if (_skipNetworkTests) {
        markTestSkipped('SKIP_NETWORK_TESTS=true，跳过网络测试');
        return;
      }

      final response = await apiService.getWelcomeCarouselList(
        const AppWelcomeSearchRequest(lan: 'zh_CN'),
      );

      expect(response.response.statusCode, equals(200));
      expect(response.data.code, equals(200));
      // 轮播图可能为空（后台未配置时），所以只验证请求成功
      expect(
        response.data.data,
        isNotNull,
        reason: '轮播图请求应成功返回（data 不为 null）',
      );
    });
  });
}
