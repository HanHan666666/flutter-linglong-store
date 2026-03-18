// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'network_speed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 网络速度 Provider
///
/// 通过每秒读取 /proc/net/dev 计算下载速度，仅在有订阅者时运行。
/// Auto-dispose：无人订阅时自动停止轮询。

@ProviderFor(NetworkSpeedNotifier)
final networkSpeedProvider = NetworkSpeedNotifierProvider._();

/// 网络速度 Provider
///
/// 通过每秒读取 /proc/net/dev 计算下载速度，仅在有订阅者时运行。
/// Auto-dispose：无人订阅时自动停止轮询。
final class NetworkSpeedNotifierProvider
    extends $NotifierProvider<NetworkSpeedNotifier, NetworkSpeed> {
  /// 网络速度 Provider
  ///
  /// 通过每秒读取 /proc/net/dev 计算下载速度，仅在有订阅者时运行。
  /// Auto-dispose：无人订阅时自动停止轮询。
  NetworkSpeedNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSpeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSpeedNotifierHash();

  @$internal
  @override
  NetworkSpeedNotifier create() => NetworkSpeedNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSpeed value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSpeed>(value),
    );
  }
}

String _$networkSpeedNotifierHash() =>
    r'1f3d3eef289ad4806b26d66b643086d0206bfc2e';

/// 网络速度 Provider
///
/// 通过每秒读取 /proc/net/dev 计算下载速度，仅在有订阅者时运行。
/// Auto-dispose：无人订阅时自动停止轮询。

abstract class _$NetworkSpeedNotifier extends $Notifier<NetworkSpeed> {
  NetworkSpeed build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<NetworkSpeed, NetworkSpeed>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkSpeed, NetworkSpeed>,
              NetworkSpeed,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
