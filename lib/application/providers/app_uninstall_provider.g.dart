// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_uninstall_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用卸载服务 Provider

@ProviderFor(appUninstallService)
final appUninstallServiceProvider = AppUninstallServiceProvider._();

/// 应用卸载服务 Provider

final class AppUninstallServiceProvider
    extends
        $FunctionalProvider<
          AppUninstallService,
          AppUninstallService,
          AppUninstallService
        >
    with $Provider<AppUninstallService> {
  /// 应用卸载服务 Provider
  AppUninstallServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appUninstallServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appUninstallServiceHash();

  @$internal
  @override
  $ProviderElement<AppUninstallService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AppUninstallService create(Ref ref) {
    return appUninstallService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUninstallService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUninstallService>(value),
    );
  }
}

String _$appUninstallServiceHash() =>
    r'd6a12cbef538acb84bf8461e5388cc5e660d63c1';
