// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_apps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 可更新应用 Provider
///
/// 管理可更新应用列表的状态

@ProviderFor(UpdateApps)
final updateAppsProvider = UpdateAppsProvider._();

/// 可更新应用 Provider
///
/// 管理可更新应用列表的状态
final class UpdateAppsProvider
    extends $NotifierProvider<UpdateApps, UpdateAppsState> {
  /// 可更新应用 Provider
  ///
  /// 管理可更新应用列表的状态
  UpdateAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateAppsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateAppsHash();

  @$internal
  @override
  UpdateApps create() => UpdateApps();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateAppsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateAppsState>(value),
    );
  }
}

String _$updateAppsHash() => r'6876a6b70ede1f6a5c2a376285935bdbe93b657b';

/// 可更新应用 Provider
///
/// 管理可更新应用列表的状态

abstract class _$UpdateApps extends $Notifier<UpdateAppsState> {
  UpdateAppsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateAppsState, UpdateAppsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateAppsState, UpdateAppsState>,
              UpdateAppsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 便捷访问 Provider
/// 可更新应用列表

@ProviderFor(updatableAppsList)
final updatableAppsListProvider = UpdatableAppsListProvider._();

/// 便捷访问 Provider
/// 可更新应用列表

final class UpdatableAppsListProvider
    extends
        $FunctionalProvider<
          List<UpdatableApp>,
          List<UpdatableApp>,
          List<UpdatableApp>
        >
    with $Provider<List<UpdatableApp>> {
  /// 便捷访问 Provider
  /// 可更新应用列表
  UpdatableAppsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updatableAppsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updatableAppsListHash();

  @$internal
  @override
  $ProviderElement<List<UpdatableApp>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<UpdatableApp> create(Ref ref) {
    return updatableAppsList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<UpdatableApp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<UpdatableApp>>(value),
    );
  }
}

String _$updatableAppsListHash() => r'00b637f63edb7ace8997d8b9290a2635741f3023';

/// 可更新应用数量

@ProviderFor(updatableAppsCount)
final updatableAppsCountProvider = UpdatableAppsCountProvider._();

/// 可更新应用数量

final class UpdatableAppsCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 可更新应用数量
  UpdatableAppsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updatableAppsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updatableAppsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return updatableAppsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$updatableAppsCountHash() =>
    r'05af36f62193a5593c8a0544e049a8461ed4e84f';

/// 是否有可更新应用

@ProviderFor(hasUpdatableApps)
final hasUpdatableAppsProvider = HasUpdatableAppsProvider._();

/// 是否有可更新应用

final class HasUpdatableAppsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 是否有可更新应用
  HasUpdatableAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasUpdatableAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasUpdatableAppsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasUpdatableApps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasUpdatableAppsHash() => r'35fcece4365ecaefb0c9519d64c0358ab4641110';
