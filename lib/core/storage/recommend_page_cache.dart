import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/recommend_models.dart';
import 'cache_service.dart';

const _recommendPageCacheKeyPrefix = 'recommend_page_cache';

/// 构建包含 locale 的缓存 key
String _buildCacheKey(String locale) => '$_recommendPageCacheKeyPrefix|$locale';

/// 推荐页缓存快照。
///
/// 仅缓存 Rust 首页对齐所需的轮播列表、推荐列表和当前页信息。
class RecommendPageCacheSnapshot {
  const RecommendPageCacheSnapshot({
    required this.banners,
    required this.apps,
    required this.currentPage,
  });

  final List<BannerInfo> banners;
  final PaginatedResponse<RecommendAppInfo> apps;
  final int currentPage;
}

/// 推荐页缓存读写接口，便于测试时用内存实现覆盖。
abstract class RecommendPageCacheStore {
  Future<RecommendPageCacheSnapshot?> read(String locale);

  Future<void> write(RecommendPageCacheSnapshot snapshot, String locale);

  Future<void> clear(String locale);
}

final recommendPageCacheStoreProvider = Provider<RecommendPageCacheStore>((ref) {
  return const HiveRecommendPageCacheStore();
});

class HiveRecommendPageCacheStore implements RecommendPageCacheStore {
  const HiveRecommendPageCacheStore();

  @override
  Future<RecommendPageCacheSnapshot?> read(String locale) async {
    final cacheKey = _buildCacheKey(locale);
    final raw = CacheService.get<Map>(cacheKey);
    if (raw == null) {
      return null;
    }

    final normalized = Map<String, dynamic>.from(raw);
    final rawBanners = (normalized['banners'] as List<dynamic>? ?? const [])
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final rawApps = (normalized['apps'] as List<dynamic>? ?? const [])
        .cast<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return RecommendPageCacheSnapshot(
      banners: rawBanners.map(_bannerFromJson).toList(),
      apps: PaginatedResponse<RecommendAppInfo>(
        items: rawApps.map(_appFromJson).toList(),
        total: normalized['total'] as int? ?? 0,
        page: normalized['page'] as int? ?? 1,
        pageSize: normalized['pageSize'] as int? ?? 10,
        hasMore: normalized['hasMore'] as bool? ?? false,
      ),
      currentPage: normalized['currentPage'] as int? ?? 1,
    );
  }

  @override
  Future<void> write(RecommendPageCacheSnapshot snapshot, String locale) async {
    final cacheKey = _buildCacheKey(locale);
    await CacheService.set<Map<String, dynamic>>(cacheKey, {
      'banners': snapshot.banners.map(_bannerToJson).toList(),
      'apps': snapshot.apps.items.map(_appToJson).toList(),
      'total': snapshot.apps.total,
      'page': snapshot.apps.page,
      'pageSize': snapshot.apps.pageSize,
      'hasMore': snapshot.apps.hasMore,
      'currentPage': snapshot.currentPage,
    });
  }

  @override
  Future<void> clear(String locale) async {
    final cacheKey = _buildCacheKey(locale);
    await CacheService.delete(cacheKey);
  }

  static BannerInfo _bannerFromJson(Map<String, dynamic> json) {
    return BannerInfo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      arch: json['arch']?.toString(),
      targetAppId: json['targetAppId']?.toString(),
      targetUrl: json['targetUrl']?.toString(),
      description: json['description']?.toString(),
    );
  }

  static Map<String, dynamic> _bannerToJson(BannerInfo banner) {
    return {
      'id': banner.id,
      'title': banner.title,
      'imageUrl': banner.imageUrl,
      'version': banner.version,
      'arch': banner.arch,
      'targetAppId': banner.targetAppId,
      'targetUrl': banner.targetUrl,
      'description': banner.description,
    };
  }

  static RecommendAppInfo _appFromJson(Map<String, dynamic> json) {
    return RecommendAppInfo(
      appId: json['appId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      developer: json['developer']?.toString(),
      category: json['category']?.toString(),
      size: json['size']?.toString(),
      arch: json['arch']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      downloadCount: json['downloadCount'] as int?,
      isInstalled: json['isInstalled'] as bool? ?? false,
      hasUpdate: json['hasUpdate'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> _appToJson(RecommendAppInfo app) {
    return {
      'appId': app.appId,
      'name': app.name,
      'version': app.version,
      'description': app.description,
      'icon': app.icon,
      'developer': app.developer,
      'category': app.category,
      'size': app.size,
      'arch': app.arch,
      'rating': app.rating,
      'downloadCount': app.downloadCount,
      'isInstalled': app.isInstalled,
      'hasUpdate': app.hasUpdate,
    };
  }
}
