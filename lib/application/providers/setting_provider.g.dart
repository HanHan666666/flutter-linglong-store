// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'setting_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 设置页面状态管理 Provider

@ProviderFor(Setting)
final settingProvider = SettingProvider._();

/// 设置页面状态管理 Provider
final class SettingProvider extends $NotifierProvider<Setting, SettingState> {
  /// 设置页面状态管理 Provider
  SettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingHash();

  @$internal
  @override
  Setting create() => Setting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingState>(value),
    );
  }
}

String _$settingHash() => r'1cfbb4862ad363dc1eee134302b60a447fd5c279';

/// 设置页面状态管理 Provider

abstract class _$Setting extends $Notifier<SettingState> {
  SettingState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SettingState, SettingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettingState, SettingState>,
              SettingState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
