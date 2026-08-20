import 'package:dio/dio.dart';

import 'package:linglong_store/core/config/app_config.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/core/storage/visitor_identity_service.dart';
import 'package:linglong_store/data/datasources/remote/app_api_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/installed_app.dart';

import '../../domain/repositories/analytics_repository.dart';

/// 匿名统计上报 Repository 实现
///
/// 所有上报操作均为 fire-and-forget:
/// - 不抛出异常，失败只记录日志
/// - 上报内容不含任何个人隐私信息
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  static const _kClientIpKey = 'analytics_client_ip';
  static const _kClientIpUrl = 'https://api64.ipify.org?format=json';

  AnalyticsRepositoryImpl({
    AppApiService? apiService,
    Future<String?> Function()? clientIpResolver,
    VisitorIdentityService? visitorIdentityService,
  }) : _apiService = apiService ?? AppApiService(ApiClient.instance),
       _clientIpResolver = clientIpResolver ?? _defaultClientIpResolver,
       _visitorIdentityService =
           visitorIdentityService ?? const VisitorIdentityService();

  final AppApiService _apiService;
  final Future<String?> Function() _clientIpResolver;
  final VisitorIdentityService _visitorIdentityService;
  String? _cachedClientIp;

  /// 获取或解析客户端公网 IP。
  ///
  /// 旧版 Electron 会在启动阶段单独解析 clientIp 并附带到统计请求中。
  /// Flutter 端这里收敛为仓储内部能力：
  /// - 优先复用已缓存值，避免每次上报都打外网请求；
  /// - 解析失败时返回 null，不影响主流程。
  Future<String?> _getOrCreateClientIp() async {
    final cached =
        _cachedClientIp ?? PreferencesService.getString(_kClientIpKey);
    if (cached != null && cached.isNotEmpty) {
      _cachedClientIp = cached;
      return cached;
    }

    try {
      final resolved = (await _clientIpResolver())?.trim();
      if (resolved == null || resolved.isEmpty) {
        return null;
      }

      _cachedClientIp = resolved;
      PreferencesService.setString(_kClientIpKey, resolved).ignore();
      return resolved;
    } catch (e) {
      AppLogger.warning('[analytics] Failed to resolve client IP: $e');
      return null;
    }
  }

  static Future<String?> _defaultClientIpResolver() async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 1),
        receiveTimeout: const Duration(seconds: 1),
      ),
    );

    final response = await dio.get<Map<String, dynamic>>(_kClientIpUrl);
    final data = response.data;
    final value = data?['ip']?.toString() ?? data?['query']?.toString();
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  // ----------------------------------------------------------------
  // AnalyticsRepository 接口实现
  // ----------------------------------------------------------------

  @override
  Future<void> initializeSession() async {
    try {
      _visitorIdentityService.getOrCreateVisitorId();
      await _getOrCreateClientIp();
      AppLogger.info('[analytics] Session initialized');
    } catch (e) {
      AppLogger.warning('[analytics] Failed to initialize session: $e');
    }
  }

  @override
  Future<void> reportVisit({
    String? arch,
    String? llVersion,
    String? llBinVersion,
    String? detailMsg,
    String? osVersion,
    String? repoName,
    String? appVersion,
  }) async {
    try {
      final visitorId = _visitorIdentityService.getOrCreateVisitorId();
      final clientIp = await _getOrCreateClientIp();
      final request = SaveVisitRecordRequest(
        visitorId: visitorId,
        clientIp: clientIp,
        arch: arch,
        llVersion: llVersion,
        llBinVersion: llBinVersion ?? llVersion,
        detailMsg: detailMsg,
        osVersion: osVersion,
        repoName: repoName,
        appVersion: appVersion,
      );
      await _apiService.saveVisitRecord(request);
      AppLogger.info('[analytics] Visit record sent');
    } catch (e) {
      // 上报失败不影响应用正常使用
      AppLogger.warning('[analytics] Failed to send visit record: $e');
    }
  }

  @override
  Future<void> reportInstalledAppsDiff({
    required List<InstalledApp> addedItems,
    required List<InstalledApp> removedItems,
  }) async {
    // 双向都为空时无需请求，避免无效网络调用（首轮基线也可能为空列表）。
    if (addedItems.isEmpty && removedItems.isEmpty) {
      return;
    }
    try {
      final visitorId = _visitorIdentityService.getOrCreateVisitorId();
      final clientIp = await _getOrCreateClientIp();
      final request = SaveInstalledRecordRequest(
        visitorId: visitorId,
        clientIp: clientIp,
        addedItems: addedItems.map(_toRecordItem).toList(),
        removedItems: removedItems.map(_toRecordItem).toList(),
      );
      await _apiService.saveInstalledRecord(request);
      AppLogger.info(
        '[analytics] Installed diff sent: '
        '+${addedItems.length} -${removedItems.length}',
      );
    } catch (e) {
      // 上报失败不影响应用正常使用
      AppLogger.warning('[analytics] Failed to send installed diff: $e');
    }
  }

  /// 领域模型转服务端记录项。
  ///
  /// repoName 统一填默认仓库名：旧版 Electron 上报时无条件用 defaultRepoName
  /// 覆盖列表项，服务端按非空字段匹配主表，保持同口径可避免跨仓库误匹配。
  InstalledRecordItemDTO _toRecordItem(InstalledApp app) {
    return InstalledRecordItemDTO(
      appId: app.appId,
      name: app.name,
      version: app.version,
      arch: app.arch,
      module: app.module,
      channel: app.channel,
      repoName: AppConfig.defaultStoreRepoName,
      kind: app.kind,
    );
  }
}
