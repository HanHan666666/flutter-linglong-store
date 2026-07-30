// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchState {

/// 搜索关键词（普通文本搜索模式使用）
 String get query;/// 标签搜索条件（标签模式使用；与 query 互斥，标签模式下 query 为空）
 AppTag? get tag;/// 搜索结果
 List<RecommendAppInfo> get results;/// 是否正在加载
 bool get isLoading;/// 是否正在加载更多
 bool get isLoadingMore;/// 错误信息
 String? get error;/// 当前页码
 int get currentPage;/// 是否还有更多数据
 bool get hasMore;/// 总结果数
 int get total;
/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateCopyWith<SearchState> get copyWith => _$SearchStateCopyWithImpl<SearchState>(this as SearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchState&&(identical(other.query, query) || other.query == query)&&(identical(other.tag, tag) || other.tag == tag)&&const DeepCollectionEquality().equals(other.results, results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,query,tag,const DeepCollectionEquality().hash(results),isLoading,isLoadingMore,error,currentPage,hasMore,total);

@override
String toString() {
  return 'SearchState(query: $query, tag: $tag, results: $results, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, currentPage: $currentPage, hasMore: $hasMore, total: $total)';
}


}

/// @nodoc
abstract mixin class $SearchStateCopyWith<$Res>  {
  factory $SearchStateCopyWith(SearchState value, $Res Function(SearchState) _then) = _$SearchStateCopyWithImpl;
@useResult
$Res call({
 String query, AppTag? tag, List<RecommendAppInfo> results, bool isLoading, bool isLoadingMore, String? error, int currentPage, bool hasMore, int total
});


$AppTagCopyWith<$Res>? get tag;

}
/// @nodoc
class _$SearchStateCopyWithImpl<$Res>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._self, this._then);

  final SearchState _self;
  final $Res Function(SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? tag = freezed,Object? results = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? currentPage = null,Object? hasMore = null,Object? total = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as AppTag?,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<RecommendAppInfo>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppTagCopyWith<$Res>? get tag {
    if (_self.tag == null) {
    return null;
  }

  return $AppTagCopyWith<$Res>(_self.tag!, (value) {
    return _then(_self.copyWith(tag: value));
  });
}
}


/// Adds pattern-matching-related methods to [SearchState].
extension SearchStatePatterns on SearchState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchState value)  $default,){
final _that = this;
switch (_that) {
case _SearchState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchState value)?  $default,){
final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  AppTag? tag,  List<RecommendAppInfo> results,  bool isLoading,  bool isLoadingMore,  String? error,  int currentPage,  bool hasMore,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.query,_that.tag,_that.results,_that.isLoading,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMore,_that.total);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  AppTag? tag,  List<RecommendAppInfo> results,  bool isLoading,  bool isLoadingMore,  String? error,  int currentPage,  bool hasMore,  int total)  $default,) {final _that = this;
switch (_that) {
case _SearchState():
return $default(_that.query,_that.tag,_that.results,_that.isLoading,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMore,_that.total);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  AppTag? tag,  List<RecommendAppInfo> results,  bool isLoading,  bool isLoadingMore,  String? error,  int currentPage,  bool hasMore,  int total)?  $default,) {final _that = this;
switch (_that) {
case _SearchState() when $default != null:
return $default(_that.query,_that.tag,_that.results,_that.isLoading,_that.isLoadingMore,_that.error,_that.currentPage,_that.hasMore,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _SearchState extends SearchState {
  const _SearchState({required this.query, this.tag, required final  List<RecommendAppInfo> results, this.isLoading = false, this.isLoadingMore = false, this.error, this.currentPage = 1, this.hasMore = true, this.total = 0}): _results = results,super._();
  

/// 搜索关键词（普通文本搜索模式使用）
@override final  String query;
/// 标签搜索条件（标签模式使用；与 query 互斥，标签模式下 query 为空）
@override final  AppTag? tag;
/// 搜索结果
 final  List<RecommendAppInfo> _results;
/// 搜索结果
@override List<RecommendAppInfo> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

/// 是否正在加载
@override@JsonKey() final  bool isLoading;
/// 是否正在加载更多
@override@JsonKey() final  bool isLoadingMore;
/// 错误信息
@override final  String? error;
/// 当前页码
@override@JsonKey() final  int currentPage;
/// 是否还有更多数据
@override@JsonKey() final  bool hasMore;
/// 总结果数
@override@JsonKey() final  int total;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchStateCopyWith<_SearchState> get copyWith => __$SearchStateCopyWithImpl<_SearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchState&&(identical(other.query, query) || other.query == query)&&(identical(other.tag, tag) || other.tag == tag)&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.error, error) || other.error == error)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,query,tag,const DeepCollectionEquality().hash(_results),isLoading,isLoadingMore,error,currentPage,hasMore,total);

@override
String toString() {
  return 'SearchState(query: $query, tag: $tag, results: $results, isLoading: $isLoading, isLoadingMore: $isLoadingMore, error: $error, currentPage: $currentPage, hasMore: $hasMore, total: $total)';
}


}

/// @nodoc
abstract mixin class _$SearchStateCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory _$SearchStateCopyWith(_SearchState value, $Res Function(_SearchState) _then) = __$SearchStateCopyWithImpl;
@override @useResult
$Res call({
 String query, AppTag? tag, List<RecommendAppInfo> results, bool isLoading, bool isLoadingMore, String? error, int currentPage, bool hasMore, int total
});


@override $AppTagCopyWith<$Res>? get tag;

}
/// @nodoc
class __$SearchStateCopyWithImpl<$Res>
    implements _$SearchStateCopyWith<$Res> {
  __$SearchStateCopyWithImpl(this._self, this._then);

  final _SearchState _self;
  final $Res Function(_SearchState) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? tag = freezed,Object? results = null,Object? isLoading = null,Object? isLoadingMore = null,Object? error = freezed,Object? currentPage = null,Object? hasMore = null,Object? total = null,}) {
  return _then(_SearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,tag: freezed == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as AppTag?,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<RecommendAppInfo>,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AppTagCopyWith<$Res>? get tag {
    if (_self.tag == null) {
    return null;
  }

  return $AppTagCopyWith<$Res>(_self.tag!, (value) {
    return _then(_self.copyWith(tag: value));
  });
}
}

// dart format on
