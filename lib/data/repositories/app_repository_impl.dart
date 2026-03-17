import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:linglong_store/core/config/app_config.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/core/storage/cache_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';

import '../../domain/models/installed_app.dart';
import '../../domain/repositories/app_repository.dart';
import '../datasources/remote/app_api_service.dart';

/// 应用 Repository 实现
///
/// 负责调用 API 服务并处理数据转换
class AppRepositoryImpl implements AppRepository {
  static const _detailsCachePrefix = 'app_details';

  /// 默认构造函数，使用 ApiClient 创建 AppApiService
  AppRepositoryImpl() : _apiService = AppApiService(ApiClient.instance);

  /// 测试用构造函数，允许注入 mock AppApiService
  @visibleForTesting
  AppRepositoryImpl.withService(this._apiService);

  final AppApiService _apiService;

  /// 缓存的系统架构，架构在运行时不会改变
  static String? _cachedArch;

  /// 获取当前系统架构
  ///
  /// 通过读取 `/proc/sys/kernel/arch` 获取 Linux 系统架构信息。
  /// 常见值包括：x86_64, aarch64, armv7l 等。
  /// 结果会被缓存以避免重复 IO 操作。
  String get _currentArch {
    if (_cachedArch != null) return _cachedArch!;

    try {
      // 读取 Linux 内核提供的架构信息文件
      final archFile = File('/proc/sys/kernel/arch');
      if (archFile.existsSync()) {
        _cachedArch = archFile.readAsStringSync().trim();
        return _cachedArch!;
      }
    } catch (e) {
      AppLogger.warning('读取 /proc/sys/kernel/arch 失败: $e');
    }

    // 回退方案：执行 uname -m 命令
    try {
      final result = Process.runSync('uname', ['-m']);
      if (result.exitCode == 0) {
        _cachedArch = (result.stdout as String).trim();
        return _cachedArch!;
      }
    } catch (e) {
      AppLogger.warning('执行 uname -m 失败: $e');
    }

    // 最终回退：默认使用 x86_64
    AppLogger.warning('无法获取系统架构，使用默认值 x86_64');
    _cachedArch = 'x86_64';
    return _cachedArch!;
  }

  @override
  Future<List<InstalledApp>> getRecommendApps({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.getWelcomeAppList(
        PageParams(pageNo: page, pageSize: pageSize),
      );

      if (response.data.data == null) return [];

      return response.data.data!.records
          .map((dto) => _mapListItemToInstalledApp(dto))
          .toList();
    } catch (e, s) {
      AppLogger.error('获取推荐应用失败', e, s);
      rethrow;
    }
  }

  @override
  Future<List<InstalledApp>> getAllApps({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    try {
      // 使用搜索接口获取全部应用
      final response = await _apiService.getSearchAppList(
        SearchAppListRequest(keyword: '', pageNo: page, pageSize: pageSize),
      );

      if (response.data.data == null) return [];

      return response.data.data!.records
          .map((dto) => _mapListItemToInstalledApp(dto))
          .toList();
    } catch (e, s) {
      AppLogger.error('获取全部应用失败', e, s);
      rethrow;
    }
  }

  @override
  Future<List<InstalledApp>> searchApps(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiService.getSearchAppList(
        SearchAppListRequest(
          keyword: keyword,
          pageNo: page,
          pageSize: pageSize,
        ),
      );

      if (response.data.data == null) return [];

      return response.data.data!.records
          .map((dto) => _mapListItemToInstalledApp(dto))
          .toList();
    } catch (e, s) {
      AppLogger.error('搜索应用失败: $keyword', e, s);
      rethrow;
    }
  }

  @override
  Future<AppDetailDTO> getAppDetail(String appId, {String? arch}) async {
    try {
      AppLogger.info('获取应用详情: $appId');

      // 后端期望请求体是数组格式
      final response = await _apiService.getAppDetail([
        AppDetailSearchBO(appId: appId, arch: arch ?? _currentArch),
      ]);

      // 后端返回 Map<String, List<AppDetailDTO>> 格式
      // data 是 Map<String, dynamic>，需要从中提取对应 appId 的详情列表
      final data = response.data.data;
      if (data == null) {
        throw Exception('应用详情不存在: $appId');
      }

      // 从 Map 中获取对应 appId 的详情列表
      final detailList = data[appId] as List<dynamic>?;
      if (detailList == null || detailList.isEmpty) {
        throw Exception('应用详情不存在: $appId');
      }

      // 返回第一个版本（通常是最新版本）
      return AppDetailDTO.fromJson(detailList.first as Map<String, dynamic>);
    } catch (e, s) {
      AppLogger.error('获取应用详情失败: $appId', e, s);
      rethrow;
    }
  }

  @override
  Future<List<AppVersionDTO>> getVersions(
    String appId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('获取应用版本列表: $appId');

      final response = await _apiService.getSearchAppVersionList(
        AppVersionListRequest(appId: appId, pageNo: page, pageSize: pageSize),
      );

      // 后端返回的是直接的数组，不是分页对象
      return response.data.data;
    } catch (e, s) {
      AppLogger.error('获取应用版本列表失败: $appId', e, s);
      rethrow;
    }
  }

  @override
  Future<List<InstalledApp>> getRanking({
    String type = 'new',
    int limit = 100,
  }) async {
    try {
      final response = type == 'new'
          ? await _apiService.getNewAppList(
              PageParams(pageNo: 1, pageSize: limit),
            )
          : await _apiService.getInstallAppList(
              PageParams(pageNo: 1, pageSize: limit),
            );

      if (response.data.data == null) return [];

      return response.data.data!.records
          .map((dto) => _mapListItemToInstalledApp(dto))
          .toList();
    } catch (e, s) {
      AppLogger.error('获取排行榜失败: $type', e, s);
      rethrow;
    }
  }

  /// 将列表项 DTO 转换为 InstalledApp 模型
  InstalledApp _mapListItemToInstalledApp(AppListItemDTO dto) {
    return InstalledApp(
      appId: dto.appId,
      name: dto.appName,
      version: dto.appVersion ?? '',
      arch: _currentArch,
      channel: 'stable',
      description: dto.appDesc,
      icon: dto.appIcon,
      kind: dto.appKind,
      size: dto.packageSize,
      repoName: dto.developerName,
    );
  }

  /// 将详情 DTO 转换为 InstalledApp 模型
  InstalledApp mapDetailToInstalledApp(AppDetailDTO dto) {
    return InstalledApp(
      appId: dto.appId,
      name: dto.appName,
      version: dto.appVersion,
      arch: dto.arch ?? _currentArch,
      channel: dto.channel ?? 'stable',
      description: dto.appDesc,
      icon: dto.appIcon,
      kind: dto.appKind,
      module: dto.appModule,
      runtime: dto.appRuntime,
      size: dto.packageSize,
      repoName: dto.repoName,
    );
  }

  @override
  Future<List<InstalledApp>> enrichInstalledAppsWithDetails(
    List<InstalledApp> apps,
  ) async {
    if (apps.isEmpty) return apps;

    final locale = ApiClient.getLocale?.call() ?? AppConfig.defaultLocale;
    final detailsMap = <String, AppListItemDTO>{};
    final missingApps = <InstalledApp>[];

    for (final app in apps) {
      final cacheKey = _buildDetailsCacheKey(app, locale);
      final cachedDetail = _readCachedAppDetail(cacheKey);
      if (cachedDetail != null) {
        detailsMap[cacheKey] = cachedDetail;
      } else {
        missingApps.add(app);
      }
    }

    try {
      if (missingApps.isNotEmpty) {
        final request = missingApps.map(_buildAppDetailsRequest).toList();

        final response = await _apiService.getAppDetails(request);
        final responseData = response.data.data;
        final remoteDetailsByAppId = <String, AppListItemDTO>{
          for (final dto in responseData) dto.appId: dto,
        };

        for (final app in missingApps) {
          final detail = remoteDetailsByAppId[app.appId];
          if (detail == null) {
            continue;
          }

          final cacheKey = _buildDetailsCacheKey(app, locale);
          detailsMap[cacheKey] = detail;
          await CacheService.set<Map<String, dynamic>>(
            cacheKey,
            detail.toJson(),
            ttl: const Duration(minutes: AppConfig.cacheExpirationMinutes),
          );
        }
      }

      return apps.map((app) {
        final detail = detailsMap[_buildDetailsCacheKey(app, locale)];
        if (detail != null) {
          return _mergeDetailIntoInstalledApp(app, detail);
        }
        return app;
      }).toList();
    } catch (e, s) {
      // 富化失败不应影响已安装列表的正常显示
      AppLogger.warning('批量获取应用详情失败，使用原始数据', e, s);
      return apps;
    }
  }

  AppDetailsBO _buildAppDetailsRequest(InstalledApp app) {
    return AppDetailsBO(
      appId: app.appId,
      name: app.name,
      version: app.version,
      channel: app.channel,
      module: app.module,
      arch: app.arch ?? _currentArch,
    );
  }

  InstalledApp _mergeDetailIntoInstalledApp(
    InstalledApp app,
    AppListItemDTO detail,
  ) {
    return app.copyWith(
      // 优先使用 API 返回的图标，其次保留原值
      icon: detail.appIcon ?? app.icon,
      name: detail.appName.isNotEmpty ? detail.appName : app.name,
      description: detail.appDesc ?? app.description,
      kind: detail.appKind ?? app.kind,
      size: detail.packageSize ?? app.size,
    );
  }

  String _buildDetailsCacheKey(InstalledApp app, String locale) {
    final normalizedArch = app.arch ?? _currentArch;
    final normalizedChannel = app.channel ?? '';
    final normalizedModule = app.module ?? '';

    return [
      _detailsCachePrefix,
      locale,
      app.appId,
      app.version,
      normalizedArch,
      normalizedChannel,
      normalizedModule,
    ].join('|');
  }

  AppListItemDTO? _readCachedAppDetail(String cacheKey) {
    final cached = CacheService.get<Map>(cacheKey);
    if (cached == null) {
      return null;
    }

    try {
      return AppListItemDTO.fromJson(Map<String, dynamic>.from(cached));
    } catch (e, s) {
      AppLogger.warning('解析应用详情缓存失败: $cacheKey', e, s);
      return null;
    }
  }
}
