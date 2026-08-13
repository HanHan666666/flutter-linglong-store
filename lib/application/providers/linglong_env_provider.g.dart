// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'linglong_env_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 玲珑环境检测 Provider
///
/// 负责检测和管理玲珑运行环境状态

@ProviderFor(LinglongEnv)
final linglongEnvProvider = LinglongEnvProvider._();

/// 玲珑环境检测 Provider
///
/// 负责检测和管理玲珑运行环境状态
final class LinglongEnvProvider
    extends $NotifierProvider<LinglongEnv, LinglongEnvState> {
  /// 玲珑环境检测 Provider
  ///
  /// 负责检测和管理玲珑运行环境状态
  LinglongEnvProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linglongEnvProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linglongEnvHash();

  @$internal
  @override
  LinglongEnv create() => LinglongEnv();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinglongEnvState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinglongEnvState>(value),
    );
  }
}

String _$linglongEnvHash() => r'fc697533f86bd8d7be44ad0ed9fe601de8d60b7d';

/// 玲珑环境检测 Provider
///
/// 负责检测和管理玲珑运行环境状态

abstract class _$LinglongEnv extends $Notifier<LinglongEnvState> {
  LinglongEnvState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LinglongEnvState, LinglongEnvState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LinglongEnvState, LinglongEnvState>,
              LinglongEnvState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 便捷访问 Provider
/// 环境检测结果

@ProviderFor(linglongEnvResult)
final linglongEnvResultProvider = LinglongEnvResultProvider._();

/// 便捷访问 Provider
/// 环境检测结果

final class LinglongEnvResultProvider
    extends
        $FunctionalProvider<
          LinglongEnvCheckResult?,
          LinglongEnvCheckResult?,
          LinglongEnvCheckResult?
        >
    with $Provider<LinglongEnvCheckResult?> {
  /// 便捷访问 Provider
  /// 环境检测结果
  LinglongEnvResultProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'linglongEnvResultProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$linglongEnvResultHash();

  @$internal
  @override
  $ProviderElement<LinglongEnvCheckResult?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LinglongEnvCheckResult? create(Ref ref) {
    return linglongEnvResult(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LinglongEnvCheckResult? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LinglongEnvCheckResult?>(value),
    );
  }
}

String _$linglongEnvResultHash() => r'ab99da5d78c4db6cbbbe75dcef3508f5d78e628b';

/// 环境是否正常

@ProviderFor(isLinglongEnvOk)
final isLinglongEnvOkProvider = IsLinglongEnvOkProvider._();

/// 环境是否正常

final class IsLinglongEnvOkProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 环境是否正常
  IsLinglongEnvOkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLinglongEnvOkProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLinglongEnvOkHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isLinglongEnvOk(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLinglongEnvOkHash() => r'7a88beedbbac8243cb839a063d9e8d23016f7683';

/// 是否需要显示环境对话框

@ProviderFor(shouldShowEnvDialog)
final shouldShowEnvDialogProvider = ShouldShowEnvDialogProvider._();

/// 是否需要显示环境对话框

final class ShouldShowEnvDialogProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// 是否需要显示环境对话框
  ShouldShowEnvDialogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shouldShowEnvDialogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shouldShowEnvDialogHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return shouldShowEnvDialog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$shouldShowEnvDialogHash() =>
    r'ef63fe5967ddeb31fd8cab183783540a1cc25f42';
