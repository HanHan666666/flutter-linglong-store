// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_badge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 菜单红点 Provider
///
/// 计算各菜单项的红点数量：
/// - 更新页：显示可更新应用数量
/// - 下载管理：显示当前任务 + 等待队列数量

@ProviderFor(menuBadge)
final menuBadgeProvider = MenuBadgeProvider._();

/// 菜单红点 Provider
///
/// 计算各菜单项的红点数量：
/// - 更新页：显示可更新应用数量
/// - 下载管理：显示当前任务 + 等待队列数量

final class MenuBadgeProvider
    extends $FunctionalProvider<MenuBadgeState, MenuBadgeState, MenuBadgeState>
    with $Provider<MenuBadgeState> {
  /// 菜单红点 Provider
  ///
  /// 计算各菜单项的红点数量：
  /// - 更新页：显示可更新应用数量
  /// - 下载管理：显示当前任务 + 等待队列数量
  MenuBadgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuBadgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuBadgeHash();

  @$internal
  @override
  $ProviderElement<MenuBadgeState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MenuBadgeState create(Ref ref) {
    return menuBadge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MenuBadgeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MenuBadgeState>(value),
    );
  }
}

String _$menuBadgeHash() => r'37b06cfed19023c43ffd6c722db17743e0555f43';

/// 便捷访问 Provider
/// 更新页红点数量

@ProviderFor(menuUpdateBadgeCount)
final menuUpdateBadgeCountProvider = MenuUpdateBadgeCountProvider._();

/// 便捷访问 Provider
/// 更新页红点数量

final class MenuUpdateBadgeCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 便捷访问 Provider
  /// 更新页红点数量
  MenuUpdateBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuUpdateBadgeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuUpdateBadgeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return menuUpdateBadgeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$menuUpdateBadgeCountHash() =>
    r'09fd24ab524759c5d4e31845dbad91db3a41c70a';

/// 下载管理红点数量

@ProviderFor(menuInstallingBadgeCount)
final menuInstallingBadgeCountProvider = MenuInstallingBadgeCountProvider._();

/// 下载管理红点数量

final class MenuInstallingBadgeCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 下载管理红点数量
  MenuInstallingBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuInstallingBadgeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuInstallingBadgeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return menuInstallingBadgeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$menuInstallingBadgeCountHash() =>
    r'06b61062988b2d9a95431c5ffef6b324487dbfb7';

/// 是否有任何菜单红点

@ProviderFor(hasMenuBadge)
final hasMenuBadgeProvider = HasMenuBadgeProvider._();

/// 是否有任何菜单红点

final class HasMenuBadgeProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 是否有任何菜单红点
  HasMenuBadgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hasMenuBadgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hasMenuBadgeHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return hasMenuBadge(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$hasMenuBadgeHash() => r'57c0bf38058a57a83eb5ea0336257f4dab027849';

/// 菜单总红点数量

@ProviderFor(menuTotalBadgeCount)
final menuTotalBadgeCountProvider = MenuTotalBadgeCountProvider._();

/// 菜单总红点数量

final class MenuTotalBadgeCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 菜单总红点数量
  MenuTotalBadgeCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'menuTotalBadgeCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$menuTotalBadgeCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return menuTotalBadgeCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$menuTotalBadgeCountHash() =>
    r'f3b0831699e386d806d4e56c3105041b610b1f1b';
