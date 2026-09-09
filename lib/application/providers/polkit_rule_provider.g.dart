// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'polkit_rule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 免密安装开关控制器。

@ProviderFor(PolkitRule)
final polkitRuleProvider = PolkitRuleProvider._();

/// 免密安装开关控制器。
final class PolkitRuleProvider
    extends $NotifierProvider<PolkitRule, PasswordFreeInstallState> {
  /// 免密安装开关控制器。
  PolkitRuleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'polkitRuleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$polkitRuleHash();

  @$internal
  @override
  PolkitRule create() => PolkitRule();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordFreeInstallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordFreeInstallState>(value),
    );
  }
}

String _$polkitRuleHash() => r'3e647e0c7cbf5c81efbb7e7065fd4b0b035eb872';

/// 免密安装开关控制器。

abstract class _$PolkitRule extends $Notifier<PasswordFreeInstallState> {
  PasswordFreeInstallState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<PasswordFreeInstallState, PasswordFreeInstallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PasswordFreeInstallState, PasswordFreeInstallState>,
              PasswordFreeInstallState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 便捷访问：免密安装开关状态。

@ProviderFor(passwordFreeInstallState)
final passwordFreeInstallStateProvider = PasswordFreeInstallStateProvider._();

/// 便捷访问：免密安装开关状态。

final class PasswordFreeInstallStateProvider
    extends
        $FunctionalProvider<
          PasswordFreeInstallState,
          PasswordFreeInstallState,
          PasswordFreeInstallState
        >
    with $Provider<PasswordFreeInstallState> {
  /// 便捷访问：免密安装开关状态。
  PasswordFreeInstallStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'passwordFreeInstallStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$passwordFreeInstallStateHash();

  @$internal
  @override
  $ProviderElement<PasswordFreeInstallState> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PasswordFreeInstallState create(Ref ref) {
    return passwordFreeInstallState(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PasswordFreeInstallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PasswordFreeInstallState>(value),
    );
  }
}

String _$passwordFreeInstallStateHash() =>
    r'e62e077429d9d0982ac8828522f44443ad78c854';
