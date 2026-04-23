import 'package:dio/dio.dart';
import 'dart:math';

import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/network/api_client.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/data/datasources/remote/app_api_service.dart';
import 'package:linglong_store/data/models/api_dto.dart';

import '../../domain/repositories/analytics_repository.dart';

/// 匿名统计上报 Repository 实现
///
/// 所有上报操作均为 fire-and-forget:
/// - 不抛出异常，失败只记录日志
/// - 上报内容不含任何个人隐私信息
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  static const _kVisitorIdKey = 'analytics_visitor_id';
  static const _kClientIpKey = 'analytics_client_ip';
  static const _kClientIpUrl = 'https://api64.ipify.org?format=json';

  AnalyticsRepositoryImpl({
    AppApiService? apiService,
    Future<String?> Function()? clientIpResolver,
  }) : _apiService = apiService ?? AppApiService(ApiClient.instance),
       _clientIpResolver = clientIpResolver ?? _defaultClientIpResolver;

  final AppApiService _apiService;
  final Future<String?> Function() _clientIpResolver;
  String? _cachedClientIp;

  // ----------------------------------------------------------------
  // Visitor ID — 首次生成后持久化，之后复用
  // ----------------------------------------------------------------

  /// 获取或生成匿名访问者 ID
  String _getOrCreateVisitorId() {
    final existing = PreferencesService.getString(_kVisitorIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    // 使用时间戳 + 随机数生成唯一 ID（不含任何敏感信息）
    final rand = Random.secure();
    final bytes = List<int>.generate(8, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final visitorId = '${DateTime.now().millisecondsSinceEpoch}-$hex';
    // 持久化（忽略写入失败，下次会重新生成）
    PreferencesService.setString(_kVisitorIdKey, visitorId).ignore();
    return visitorId;
  }

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
      final visitorId = _getOrCreateVisitorId();
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
  Future<void> reportInstall(
    String appId,
    String version, {
    String? appName,
  }) async {
    try {
      final visitorId = _getOrCreateVisitorId();
      final clientIp = await _getOrCreateClientIp();
      final request = SaveInstalledRecordRequest(
        visitorId: visitorId,
        clientIp: clientIp,
        addedItems: [
          InstalledRecordItemDTO(appId: appId, name: appName, version: version),
        ],
      );
      await _apiService.saveInstalledRecord(request);
      AppLogger.info('[analytics] Install record sent: $appId $version');
    } catch (e) {
      AppLogger.warning('[analytics] Failed to send install record: $e');
    }
  }

  @override
  Future<void> reportUninstall(
    String appId,
    String version, {
    String? appName,
  }) async {
    try {
      final visitorId = _getOrCreateVisitorId();
      final clientIp = await _getOrCreateClientIp();
      final request = SaveInstalledRecordRequest(
        visitorId: visitorId,
        clientIp: clientIp,
        removedItems: [
          InstalledRecordItemDTO(appId: appId, name: appName, version: version),
        ],
      );
      await _apiService.saveInstalledRecord(request);
      AppLogger.info('[analytics] Uninstall record sent: $appId $version');
    } catch (e) {
      AppLogger.warning('[analytics] Failed to send uninstall record: $e');
    }
  }
}
