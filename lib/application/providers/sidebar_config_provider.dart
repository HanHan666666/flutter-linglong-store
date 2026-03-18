import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/logging/app_logger.dart';
import '../../data/models/api_dto.dart';
import 'api_provider.dart';

part 'sidebar_config_provider.g.dart';

/// 侧边栏服务端动态菜单 Provider
///
/// - `keepAlive`：侧边栏始终可见，不需要自动销毁。
/// - 返回已启用且按 [SidebarMenuDTO.sortOrder] 排序的菜单列表。
/// - 失败时返回空列表（不影响静态菜单的正常显示）。
@Riverpod(keepAlive: true)
Future<List<SidebarMenuDTO>> sidebarConfig(Ref ref) async {
  try {
    final apiService = ref.read(appApiServiceProvider);
    final response = await apiService.getSidebarConfig();

    final menus = response.data.data?.menus ?? [];

    // 过滤禁用菜单，并按 sortOrder 升序排列（null 排末尾）
    final enabled = menus.where((m) => m.enabled).toList()
      ..sort((a, b) {
        final oa = a.sortOrder ?? 9999;
        final ob = b.sortOrder ?? 9999;
        return oa.compareTo(ob);
      });

    return enabled;
  } catch (e, s) {
    AppLogger.error('获取侧边栏配置失败', e, s);
    return [];
  }
}
