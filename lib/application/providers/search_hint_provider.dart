import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';
import 'global_provider.dart';

part 'search_hint_provider.g.dart';

/// 搜索框 placeholder 轮播条目。
///
/// 仅承载跳转详情页所需的最小信息：应用名用于展示，其余身份字段
/// （appId/arch/repoName/module）用于在空输入回车时精确打开详情页，
/// 避免详情页接口回退匹配导致跨架构/跨仓库错配。
class SearchHintApp {
  const SearchHintApp({
    required this.appId,
    required this.name,
    required this.version,
    required this.arch,
    required this.repoName,
    required this.module,
  });

  /// 应用唯一标识。
  final String appId;

  /// 应用名称，直接作为搜索框 placeholder 文案展示。
  final String name;

  /// 版本号，详情页身份字段之一。
  final String version;

  /// 架构，详情页精确查询所需，缺失时回退为本次请求使用的架构。
  final String arch;

  /// 仓库名，详情页身份字段之一。
  final String repoName;

  /// 模块，详情页身份字段之一。
  final String module;
}

/// 搜索框 placeholder 轮播数据 Provider。
///
/// 数据来源为下载量榜 `/visit/getInstallAppList`，与排行页 `Ranking` provider
/// 保持独立：
/// 1. 避免被排行页 Tab 切换污染当前选中类型；
/// 2. 直接消费底层 `AppListItemDTO`（含 repoName/module），而排行页裁剪过的
///    `RankingAppInfo` 缺失跳转详情页所需身份字段。
///
/// 仅取前 20 条，由搜索框每 5 秒顺序轮播；网络失败或结果为空时返回空列表，
/// 调用方回退到静态 placeholder 文案，不抛错。
@riverpod
class SearchHintApps extends _$SearchHintApps {
  @override
  List<SearchHintApp> build() {
    // 初始返回空列表，UI 此时展示静态 placeholder；数据就绪后驱动轮播。
    Future.microtask(_load);
    return const <SearchHintApp>[];
  }

  /// 拉取下载量榜前 20 条应用。
  Future<void> _load() async {
    try {
      final apiService = ref.read(appApiServiceProvider);
      final arch = resolveRequestArch(ref);

      final response = await apiService.getInstallAppList(
        PageParams(pageNo: 1, pageSize: 20, arch: arch),
      );

      final records = response.data.data?.records ?? const <AppListItemDTO>[];
      if (records.isEmpty) {
        return;
      }

      state = records
          .map((dto) => SearchHintApp(
                appId: dto.appId,
                name: dto.appName,
                version: dto.appVersion ?? '',
                // 后端部分条目可能不带 arch，回退为本次请求架构，保证身份字段可用。
                arch: dto.arch?.isNotEmpty == true ? dto.arch! : arch,
                repoName: dto.repoName ?? '',
                module: dto.module ?? '',
              ))
          .toList();
    } catch (e, s) {
      // 轮播数据属锦上添花，失败不影响搜索功能，仅记日志后维持空列表。
      AppLogger.warning('加载搜索框 placeholder 轮播数据失败', e, s);
    }
  }
}
