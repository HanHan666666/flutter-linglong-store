// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 应用详情 Provider

@ProviderFor(AppDetail)
final appDetailProvider = AppDetailFamily._();

/// 应用详情 Provider
final class AppDetailProvider
    extends $NotifierProvider<AppDetail, AppDetailState> {
  /// 应用详情 Provider
  AppDetailProvider._({
    required AppDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'appDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$appDetailHash();

  @override
  String toString() {
    return r'appDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AppDetail create() => AppDetail();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$appDetailHash() => r'3e4cbdaf3b84bf6f81d023771c8a1ecb876db81d';

/// 应用详情 Provider

final class AppDetailFamily extends $Family
    with
        $ClassFamilyOverride<
          AppDetail,
          AppDetailState,
          AppDetailState,
          AppDetailState,
          String
        > {
  AppDetailFamily._()
    : super(
        retry: null,
        name: r'appDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 应用详情 Provider

  AppDetailProvider call(String appId) =>
      AppDetailProvider._(argument: appId, from: this);

  @override
  String toString() => r'appDetailProvider';
}

/// 应用详情 Provider

abstract class _$AppDetail extends $Notifier<AppDetailState> {
  late final _$args = ref.$arg as String;
  String get appId => _$args;

  AppDetailState build(String appId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AppDetailState, AppDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppDetailState, AppDetailState>,
              AppDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
