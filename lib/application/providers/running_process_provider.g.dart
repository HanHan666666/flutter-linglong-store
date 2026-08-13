// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'running_process_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 运行中进程 Provider
///
/// 对齐 Rust 版本的行为：
/// - 仅在“玲珑进程”标签激活且页面可见时轮询
/// - 并发保护
/// - 失败退避
/// - 恢复可见时立即补刷新
/// - 行级停止 loading

@ProviderFor(RunningProcess)
final runningProcessProvider = RunningProcessProvider._();

/// 运行中进程 Provider
///
/// 对齐 Rust 版本的行为：
/// - 仅在“玲珑进程”标签激活且页面可见时轮询
/// - 并发保护
/// - 失败退避
/// - 恢复可见时立即补刷新
/// - 行级停止 loading
final class RunningProcessProvider
    extends $NotifierProvider<RunningProcess, RunningProcessState> {
  /// 运行中进程 Provider
  ///
  /// 对齐 Rust 版本的行为：
  /// - 仅在“玲珑进程”标签激活且页面可见时轮询
  /// - 并发保护
  /// - 失败退避
  /// - 恢复可见时立即补刷新
  /// - 行级停止 loading
  RunningProcessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningProcessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningProcessHash();

  @$internal
  @override
  RunningProcess create() => RunningProcess();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RunningProcessState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RunningProcessState>(value),
    );
  }
}

String _$runningProcessHash() => r'6fdcb40a01259d7ca2ee2b2ad9d10860a27b80d7';

/// 运行中进程 Provider
///
/// 对齐 Rust 版本的行为：
/// - 仅在“玲珑进程”标签激活且页面可见时轮询
/// - 并发保护
/// - 失败退避
/// - 恢复可见时立即补刷新
/// - 行级停止 loading

abstract class _$RunningProcess extends $Notifier<RunningProcessState> {
  RunningProcessState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RunningProcessState, RunningProcessState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RunningProcessState, RunningProcessState>,
              RunningProcessState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 运行中应用列表

@ProviderFor(runningAppsList)
final runningAppsListProvider = RunningAppsListProvider._();

/// 运行中应用列表

final class RunningAppsListProvider
    extends
        $FunctionalProvider<
          List<RunningApp>,
          List<RunningApp>,
          List<RunningApp>
        >
    with $Provider<List<RunningApp>> {
  /// 运行中应用列表
  RunningAppsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningAppsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningAppsListHash();

  @$internal
  @override
  $ProviderElement<List<RunningApp>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<RunningApp> create(Ref ref) {
    return runningAppsList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<RunningApp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<RunningApp>>(value),
    );
  }
}

String _$runningAppsListHash() => r'7222c29c12ecb709102f07e57449c4665c70c49e';

/// 运行中应用数量

@ProviderFor(runningAppsCount)
final runningAppsCountProvider = RunningAppsCountProvider._();

/// 运行中应用数量

final class RunningAppsCountProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 运行中应用数量
  RunningAppsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'runningAppsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$runningAppsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return runningAppsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$runningAppsCountHash() => r'9a3febae90338d072dbc0c6ae2ae461dea20dbba';
