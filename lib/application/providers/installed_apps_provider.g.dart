// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_apps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 已安装应用 Provider
///
/// 管理已安装应用列表的状态

@ProviderFor(InstalledApps)
final installedAppsProvider = InstalledAppsProvider._();

/// 已安装应用 Provider
///
/// 管理已安装应用列表的状态
final class InstalledAppsProvider
    extends $NotifierProvider<InstalledApps, InstalledAppsState> {
  /// 已安装应用 Provider
  ///
  /// 管理已安装应用列表的状态
  InstalledAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppsHash();

  @$internal
  @override
  InstalledApps create() => InstalledApps();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InstalledAppsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InstalledAppsState>(value),
    );
  }
}

String _$installedAppsHash() => r'1412659d0cbe0312386f45edebaf2fc064bddf4b';

/// 已安装应用 Provider
///
/// 管理已安装应用列表的状态

abstract class _$InstalledApps extends $Notifier<InstalledAppsState> {
  InstalledAppsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<InstalledAppsState, InstalledAppsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<InstalledAppsState, InstalledAppsState>,
              InstalledAppsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// 便捷访问 Provider
/// 已安装应用列表

@ProviderFor(installedAppsList)
final installedAppsListProvider = InstalledAppsListProvider._();

/// 便捷访问 Provider
/// 已安装应用列表

final class InstalledAppsListProvider
    extends
        $FunctionalProvider<
          List<InstalledApp>,
          List<InstalledApp>,
          List<InstalledApp>
        >
    with $Provider<List<InstalledApp>> {
  /// 便捷访问 Provider
  /// 已安装应用列表
  InstalledAppsListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppsListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppsListHash();

  @$internal
  @override
  $ProviderElement<List<InstalledApp>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<InstalledApp> create(Ref ref) {
    return installedAppsList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InstalledApp> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InstalledApp>>(value),
    );
  }
}

String _$installedAppsListHash() => r'4452caba630214a3a113a98d50bdae4e06fdf6b8';

/// 已安装应用数量

@ProviderFor(installedAppsCount)
final installedAppsCountProvider = InstalledAppsCountProvider._();

/// 已安装应用数量

final class InstalledAppsCountProvider
    extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// 已安装应用数量
  InstalledAppsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'installedAppsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$installedAppsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return installedAppsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$installedAppsCountHash() =>
    r'deba6a26ea6775869baae7e921332ada221a49d0';

/// 是否正在加载已安装应用

@ProviderFor(isLoadingInstalledApps)
final isLoadingInstalledAppsProvider = IsLoadingInstalledAppsProvider._();

/// 是否正在加载已安装应用

final class IsLoadingInstalledAppsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 是否正在加载已安装应用
  IsLoadingInstalledAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLoadingInstalledAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLoadingInstalledAppsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLoadingInstalledApps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLoadingInstalledAppsHash() =>
    r'7117a39cd2940562507141ba3a24e4ef1455aa3a';

/// 检查应用是否已安装

@ProviderFor(isAppInstalled)
final isAppInstalledProvider = IsAppInstalledFamily._();

/// 检查应用是否已安装

final class IsAppInstalledProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 检查应用是否已安装
  IsAppInstalledProvider._({
    required IsAppInstalledFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'isAppInstalledProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$isAppInstalledHash();

  @override
  String toString() {
    return r'isAppInstalledProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    final argument = this.argument as String;
    return isAppInstalled(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is IsAppInstalledProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$isAppInstalledHash() => r'93fd6e8f90fee2a3adb8a3fc713ad833f553e95c';

/// 检查应用是否已安装

final class IsAppInstalledFamily extends $Family
    with $FunctionalFamilyOverride<bool, String> {
  IsAppInstalledFamily._()
    : super(
        retry: null,
        name: r'isAppInstalledProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 检查应用是否已安装

  IsAppInstalledProvider call(String appId) =>
      IsAppInstalledProvider._(argument: appId, from: this);

  @override
  String toString() => r'isAppInstalledProvider';
}
