// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sidebar_width_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 侧边栏展开宽度状态
///
/// 业务定位：侧边栏可拖拽调宽（issue #27）的唯一宽度事实来源。
/// 采用「帧内预览、结束时落盘」的两阶段契约：
/// - [previewWidth]：拖拽帧高频调用，只更新内存状态，保证帧内零 IO；
/// - [commitWidth]：拖拽结束调用一次，把当前宽度持久化；
/// - [resetWidth]：恢复默认宽度并清除持久化键。
///
/// 持久化读取发生在 [build]（同步）：SharedPreferences 在 main 阶段
/// 已完成初始化并注入 [sharedPreferencesProvider]，不存在异步竞态；
/// 读取失败时回退默认宽度，绝不阻塞首帧。

@ProviderFor(SidebarWidth)
final sidebarWidthProvider = SidebarWidthProvider._();

/// 侧边栏展开宽度状态
///
/// 业务定位：侧边栏可拖拽调宽（issue #27）的唯一宽度事实来源。
/// 采用「帧内预览、结束时落盘」的两阶段契约：
/// - [previewWidth]：拖拽帧高频调用，只更新内存状态，保证帧内零 IO；
/// - [commitWidth]：拖拽结束调用一次，把当前宽度持久化；
/// - [resetWidth]：恢复默认宽度并清除持久化键。
///
/// 持久化读取发生在 [build]（同步）：SharedPreferences 在 main 阶段
/// 已完成初始化并注入 [sharedPreferencesProvider]，不存在异步竞态；
/// 读取失败时回退默认宽度，绝不阻塞首帧。
final class SidebarWidthProvider
    extends $NotifierProvider<SidebarWidth, double> {
  /// 侧边栏展开宽度状态
  ///
  /// 业务定位：侧边栏可拖拽调宽（issue #27）的唯一宽度事实来源。
  /// 采用「帧内预览、结束时落盘」的两阶段契约：
  /// - [previewWidth]：拖拽帧高频调用，只更新内存状态，保证帧内零 IO；
  /// - [commitWidth]：拖拽结束调用一次，把当前宽度持久化；
  /// - [resetWidth]：恢复默认宽度并清除持久化键。
  ///
  /// 持久化读取发生在 [build]（同步）：SharedPreferences 在 main 阶段
  /// 已完成初始化并注入 [sharedPreferencesProvider]，不存在异步竞态；
  /// 读取失败时回退默认宽度，绝不阻塞首帧。
  SidebarWidthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sidebarWidthProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sidebarWidthHash();

  @$internal
  @override
  SidebarWidth create() => SidebarWidth();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$sidebarWidthHash() => r'6c8db13e26abc47e64ea402d57001406622f302e';

/// 侧边栏展开宽度状态
///
/// 业务定位：侧边栏可拖拽调宽（issue #27）的唯一宽度事实来源。
/// 采用「帧内预览、结束时落盘」的两阶段契约：
/// - [previewWidth]：拖拽帧高频调用，只更新内存状态，保证帧内零 IO；
/// - [commitWidth]：拖拽结束调用一次，把当前宽度持久化；
/// - [resetWidth]：恢复默认宽度并清除持久化键。
///
/// 持久化读取发生在 [build]（同步）：SharedPreferences 在 main 阶段
/// 已完成初始化并注入 [sharedPreferencesProvider]，不存在异步竞态；
/// 读取失败时回退默认宽度，绝不阻塞首帧。

abstract class _$SidebarWidth extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
