// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar_config_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 侧边栏服务端动态菜单 Provider
///
/// - `keepAlive`：侧边栏始终可见，不需要自动销毁。
/// - 返回已启用且按 [SidebarMenuDTO.sortOrder] 排序的菜单列表。
/// - 失败时返回空列表（不影响静态菜单的正常显示）。

@ProviderFor(sidebarConfig)
final sidebarConfigProvider = SidebarConfigProvider._();

/// 侧边栏服务端动态菜单 Provider
///
/// - `keepAlive`：侧边栏始终可见，不需要自动销毁。
/// - 返回已启用且按 [SidebarMenuDTO.sortOrder] 排序的菜单列表。
/// - 失败时返回空列表（不影响静态菜单的正常显示）。

final class SidebarConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SidebarMenuDTO>>,
          List<SidebarMenuDTO>,
          FutureOr<List<SidebarMenuDTO>>
        >
    with
        $FutureModifier<List<SidebarMenuDTO>>,
        $FutureProvider<List<SidebarMenuDTO>> {
  /// 侧边栏服务端动态菜单 Provider
  ///
  /// - `keepAlive`：侧边栏始终可见，不需要自动销毁。
  /// - 返回已启用且按 [SidebarMenuDTO.sortOrder] 排序的菜单列表。
  /// - 失败时返回空列表（不影响静态菜单的正常显示）。
  SidebarConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarConfigHash();

  @$internal
  @override
  $FutureProviderElement<List<SidebarMenuDTO>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SidebarMenuDTO>> create(Ref ref) {
    return sidebarConfig(ref);
  }
}

String _$sidebarConfigHash() => r'943bf813f8c5a5d4906aabeb7731e9ca1acbba58';
