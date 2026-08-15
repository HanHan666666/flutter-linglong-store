// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'all_apps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 全部应用页状态 Provider

@ProviderFor(AllApps)
final allAppsProvider = AllAppsProvider._();

/// 全部应用页状态 Provider
final class AllAppsProvider extends $NotifierProvider<AllApps, AllAppsState> {
  /// 全部应用页状态 Provider
  AllAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAppsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAppsHash();

  @$internal
  @override
  AllApps create() => AllApps();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AllAppsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AllAppsState>(value),
    );
  }
}

String _$allAppsHash() => r'66454a91903dd0ab7755cfdf5135fdd6968a9d0b';

/// 全部应用页状态 Provider

abstract class _$AllApps extends $Notifier<AllAppsState> {
  AllAppsState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AllAppsState, AllAppsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AllAppsState, AllAppsState>,
              AllAppsState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
