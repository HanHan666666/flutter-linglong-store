// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'install_queue_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// InstallMessages Provider - 根据当前 locale 获取国际化消息

@ProviderFor(installMessages)
final installMessagesProvider = InstallMessagesProvider._();

/// InstallMessages Provider - 根据当前 locale 获取国际化消息

final class InstallMessagesProvider
    extends
        $FunctionalProvider<InstallMessages, InstallMessages, InstallMessages>
    with $Provider<InstallMessages> {
  /// InstallMessages Provider - 根据当前 locale 获取国际化消息
  InstallMessagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installMessagesHash();

  @$internal
  @override
  $ProviderElement<InstallMessages> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstallMessages create(Ref ref) {
    return installMessages(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstallMessages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstallMessages>(value),
    );
  }
}

String _$installMessagesHash() => r'8879119de40b13dee84e68c669030c72d88bdcae';

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. XDG Journal：应用崩溃后可恢复完整操作状态
/// 3. 持久化屏障：外部动作不得领先于可恢复事实
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"

@ProviderFor(InstallQueue)
final installQueueProvider = InstallQueueProvider._();

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. XDG Journal：应用崩溃后可恢复完整操作状态
/// 3. 持久化屏障：外部动作不得领先于可恢复事实
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"
final class InstallQueueProvider
    extends $NotifierProvider<InstallQueue, InstallQueueState> {
  /// 安装队列状态机 Provider
  ///
  /// 核心功能：
  /// 1. 严格串行安装：一次只处理一个安装任务
  /// 2. XDG Journal：应用崩溃后可恢复完整操作状态
  /// 3. 持久化屏障：外部动作不得领先于可恢复事实
  /// 4. 错误恢复：重试机制
  /// 5. 取消状态管理：区分"用户取消"和"真正失败"
  InstallQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installQueueHash();

  @$internal
  @override
  InstallQueue create() => InstallQueue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstallQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstallQueueState>(value),
    );
  }
}

String _$installQueueHash() => r'cd7df56ac2e69fc15f7055de155c38c7f276c033';

/// 安装队列状态机 Provider
///
/// 核心功能：
/// 1. 严格串行安装：一次只处理一个安装任务
/// 2. XDG Journal：应用崩溃后可恢复完整操作状态
/// 3. 持久化屏障：外部动作不得领先于可恢复事实
/// 4. 错误恢复：重试机制
/// 5. 取消状态管理：区分"用户取消"和"真正失败"

abstract class _$InstallQueue extends $Notifier<InstallQueueState> {
  InstallQueueState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<InstallQueueState, InstallQueueState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InstallQueueState, InstallQueueState>,
              InstallQueueState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 便捷访问 Provider

@ProviderFor(installQueueState)
final installQueueStateProvider = InstallQueueStateProvider._();

/// 便捷访问 Provider

final class InstallQueueStateProvider
    extends
        $FunctionalProvider<
          InstallQueueState,
          InstallQueueState,
          InstallQueueState
        >
    with $Provider<InstallQueueState> {
  /// 便捷访问 Provider
  InstallQueueStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installQueueStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installQueueStateHash();

  @$internal
  @override
  $ProviderElement<InstallQueueState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InstallQueueState create(Ref ref) {
    return installQueueState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstallQueueState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstallQueueState>(value),
    );
  }
}

String _$installQueueStateHash() => r'3d5d2ae10222e40d89e5c2cb4ea029e12f8bd01c';

@ProviderFor(currentInstallTask)
final currentInstallTaskProvider = CurrentInstallTaskProvider._();

final class CurrentInstallTaskProvider
    extends $FunctionalProvider<InstallTask?, InstallTask?, InstallTask?>
    with $Provider<InstallTask?> {
  CurrentInstallTaskProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentInstallTaskProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentInstallTaskHash();

  @$internal
  @override
  $ProviderElement<InstallTask?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InstallTask? create(Ref ref) {
    return currentInstallTask(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstallTask? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstallTask?>(value),
    );
  }
}

String _$currentInstallTaskHash() =>
    r'4efce55128c79a2e347f59f70abd82e652285f3f';

@ProviderFor(pendingInstallQueue)
final pendingInstallQueueProvider = PendingInstallQueueProvider._();

final class PendingInstallQueueProvider
    extends
        $FunctionalProvider<
          List<InstallTask>,
          List<InstallTask>,
          List<InstallTask>
        >
    with $Provider<List<InstallTask>> {
  PendingInstallQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInstallQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInstallQueueHash();

  @$internal
  @override
  $ProviderElement<List<InstallTask>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<InstallTask> create(Ref ref) {
    return pendingInstallQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InstallTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InstallTask>>(value),
    );
  }
}

String _$pendingInstallQueueHash() =>
    r'feaa0ec913aa2b9b6ad86ad48a44282425c8f0ad';

@ProviderFor(installHistory)
final installHistoryProvider = InstallHistoryProvider._();

final class InstallHistoryProvider
    extends
        $FunctionalProvider<
          List<InstallTask>,
          List<InstallTask>,
          List<InstallTask>
        >
    with $Provider<List<InstallTask>> {
  InstallHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installHistoryHash();

  @$internal
  @override
  $ProviderElement<List<InstallTask>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<InstallTask> create(Ref ref) {
    return installHistory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InstallTask> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InstallTask>>(value),
    );
  }
}

String _$installHistoryHash() => r'262543014b30a68e4b6003d7bb96174857668b85';

@ProviderFor(hasActiveInstallTasks)
final hasActiveInstallTasksProvider = HasActiveInstallTasksProvider._();

final class HasActiveInstallTasksProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  HasActiveInstallTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasActiveInstallTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasActiveInstallTasksHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasActiveInstallTasks(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasActiveInstallTasksHash() =>
    r'ad20d8e985e627136910691636ef5a9d085bd82f';
