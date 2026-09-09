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

String _$polkitRuleHash() => r'9160adf43c71e0653b9fc5f55bd3dc00a3f57b78';

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
