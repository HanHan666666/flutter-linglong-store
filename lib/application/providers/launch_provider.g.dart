// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'launch_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 启动序列 Provider
///
/// 管理应用启动时的初始化序列：
/// 1. 环境检测 - 检查 ll-cli 是否可用
/// 2. 已安装应用初始化 - 加载已安装应用列表
/// 3. 更新检查 - 检查应用更新
/// 4. 安装队列恢复 - 恢复未完成的安装任务
/// 5. 完成后跳转到主页

@ProviderFor(LaunchSequence)
final launchSequenceProvider = LaunchSequenceProvider._();

/// 启动序列 Provider
///
/// 管理应用启动时的初始化序列：
/// 1. 环境检测 - 检查 ll-cli 是否可用
/// 2. 已安装应用初始化 - 加载已安装应用列表
/// 3. 更新检查 - 检查应用更新
/// 4. 安装队列恢复 - 恢复未完成的安装任务
/// 5. 完成后跳转到主页
final class LaunchSequenceProvider
    extends $NotifierProvider<LaunchSequence, LaunchState> {
  /// 启动序列 Provider
  ///
  /// 管理应用启动时的初始化序列：
  /// 1. 环境检测 - 检查 ll-cli 是否可用
  /// 2. 已安装应用初始化 - 加载已安装应用列表
  /// 3. 更新检查 - 检查应用更新
  /// 4. 安装队列恢复 - 恢复未完成的安装任务
  /// 5. 完成后跳转到主页
  LaunchSequenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchSequenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchSequenceHash();

  @$internal
  @override
  LaunchSequence create() => LaunchSequence();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchState>(value),
    );
  }
}

String _$launchSequenceHash() => r'9a0ecbebfcc04894cc3af452d8a1e3edafb8e564';

/// 启动序列 Provider
///
/// 管理应用启动时的初始化序列：
/// 1. 环境检测 - 检查 ll-cli 是否可用
/// 2. 已安装应用初始化 - 加载已安装应用列表
/// 3. 更新检查 - 检查应用更新
/// 4. 安装队列恢复 - 恢复未完成的安装任务
/// 5. 完成后跳转到主页

abstract class _$LaunchSequence extends $Notifier<LaunchState> {
  LaunchState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LaunchState, LaunchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LaunchState, LaunchState>,
              LaunchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 便捷访问 Provider
/// 是否启动完成

@ProviderFor(isLaunchCompleted)
final isLaunchCompletedProvider = IsLaunchCompletedProvider._();

/// 便捷访问 Provider
/// 是否启动完成

final class IsLaunchCompletedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 便捷访问 Provider
  /// 是否启动完成
  IsLaunchCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLaunchCompletedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLaunchCompletedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLaunchCompleted(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLaunchCompletedHash() => r'0292ea928d2acebebafc32eb66afc4cd47f831f6';

/// 启动是否有错误

@ProviderFor(hasLaunchError)
final hasLaunchErrorProvider = HasLaunchErrorProvider._();

/// 启动是否有错误

final class HasLaunchErrorProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 启动是否有错误
  HasLaunchErrorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasLaunchErrorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasLaunchErrorHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasLaunchError(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasLaunchErrorHash() => r'c657a445452d1f7824fbca74965d8719ccdb5e1f';

/// 当前启动进度

@ProviderFor(launchProgress)
final launchProgressProvider = LaunchProgressProvider._();

/// 当前启动进度

final class LaunchProgressProvider
    extends $FunctionalProvider<double, double, double>
    with $Provider<double> {
  /// 当前启动进度
  LaunchProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'launchProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$launchProgressHash();

  @$internal
  @override
  $ProviderElement<double> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  double create(Ref ref) {
    return launchProgress(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$launchProgressHash() => r'ed232fca6e772eea8254b9f5e2f02cce8e1a2477';

/// 当前启动步骤

@ProviderFor(currentLaunchStep)
final currentLaunchStepProvider = CurrentLaunchStepProvider._();

/// 当前启动步骤

final class CurrentLaunchStepProvider
    extends $FunctionalProvider<LaunchStep, LaunchStep, LaunchStep>
    with $Provider<LaunchStep> {
  /// 当前启动步骤
  CurrentLaunchStepProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLaunchStepProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLaunchStepHash();

  @$internal
  @override
  $ProviderElement<LaunchStep> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LaunchStep create(Ref ref) {
    return currentLaunchStep(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LaunchStep value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LaunchStep>(value),
    );
  }
}

String _$currentLaunchStepHash() => r'f01514ac2d114f3e1df7f18997f699e331ad0e1d';
