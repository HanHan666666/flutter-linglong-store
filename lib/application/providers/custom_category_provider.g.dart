// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_category_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 自定义分类页状态 Provider

@ProviderFor(CustomCategory)
final customCategoryProvider = CustomCategoryFamily._();

/// 自定义分类页状态 Provider
final class CustomCategoryProvider
    extends $NotifierProvider<CustomCategory, CustomCategoryState> {
  /// 自定义分类页状态 Provider
  CustomCategoryProvider._({
    required CustomCategoryFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'customCategoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$customCategoryHash();

  @override
  String toString() {
    return r'customCategoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CustomCategory create() => CustomCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CustomCategoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CustomCategoryState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CustomCategoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$customCategoryHash() => r'7fc18c2d762017c39a59b22e424b83ff613d0e86';

/// 自定义分类页状态 Provider

final class CustomCategoryFamily extends $Family
    with
        $ClassFamilyOverride<
          CustomCategory,
          CustomCategoryState,
          CustomCategoryState,
          CustomCategoryState,
          String
        > {
  CustomCategoryFamily._()
    : super(
        retry: null,
        name: r'customCategoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 自定义分类页状态 Provider

  CustomCategoryProvider call(String code) =>
      CustomCategoryProvider._(argument: code, from: this);

  @override
  String toString() => r'customCategoryProvider';
}

/// 自定义分类页状态 Provider

abstract class _$CustomCategory extends $Notifier<CustomCategoryState> {
  late final _$args = ref.$arg as String;
  String get code => _$args;

  CustomCategoryState build(String code);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<CustomCategoryState, CustomCategoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CustomCategoryState, CustomCategoryState>,
              CustomCategoryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
