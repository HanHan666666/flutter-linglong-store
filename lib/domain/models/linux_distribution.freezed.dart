// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linux_distribution.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LinuxDistribution {

 LinuxDistributionId get id; String get displayName;/// 能力标签只描述“这个发行版在哪些业务场景需要特殊处理”，
/// 不直接绑定某个页面实现，避免 UI 和 Provider 重新长出发行版分支。
 List<LinuxDistributionCapability> get capabilities;
/// Create a copy of LinuxDistribution
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinuxDistributionCopyWith<LinuxDistribution> get copyWith => _$LinuxDistributionCopyWithImpl<LinuxDistribution>(this as LinuxDistribution, _$identity);

  /// Serializes this LinuxDistribution to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinuxDistribution&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other.capabilities, capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,const DeepCollectionEquality().hash(capabilities));

@override
String toString() {
  return 'LinuxDistribution(id: $id, displayName: $displayName, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class $LinuxDistributionCopyWith<$Res>  {
  factory $LinuxDistributionCopyWith(LinuxDistribution value, $Res Function(LinuxDistribution) _then) = _$LinuxDistributionCopyWithImpl;
@useResult
$Res call({
 LinuxDistributionId id, String displayName, List<LinuxDistributionCapability> capabilities
});




}
/// @nodoc
class _$LinuxDistributionCopyWithImpl<$Res>
    implements $LinuxDistributionCopyWith<$Res> {
  _$LinuxDistributionCopyWithImpl(this._self, this._then);

  final LinuxDistribution _self;
  final $Res Function(LinuxDistribution) _then;

/// Create a copy of LinuxDistribution
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? displayName = null,Object? capabilities = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as LinuxDistributionId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,capabilities: null == capabilities ? _self.capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<LinuxDistributionCapability>,
  ));
}

}


/// Adds pattern-matching-related methods to [LinuxDistribution].
extension LinuxDistributionPatterns on LinuxDistribution {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LinuxDistribution value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LinuxDistribution() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LinuxDistribution value)  $default,){
final _that = this;
switch (_that) {
case _LinuxDistribution():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LinuxDistribution value)?  $default,){
final _that = this;
switch (_that) {
case _LinuxDistribution() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LinuxDistributionId id,  String displayName,  List<LinuxDistributionCapability> capabilities)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LinuxDistribution() when $default != null:
return $default(_that.id,_that.displayName,_that.capabilities);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LinuxDistributionId id,  String displayName,  List<LinuxDistributionCapability> capabilities)  $default,) {final _that = this;
switch (_that) {
case _LinuxDistribution():
return $default(_that.id,_that.displayName,_that.capabilities);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LinuxDistributionId id,  String displayName,  List<LinuxDistributionCapability> capabilities)?  $default,) {final _that = this;
switch (_that) {
case _LinuxDistribution() when $default != null:
return $default(_that.id,_that.displayName,_that.capabilities);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LinuxDistribution extends LinuxDistribution {
  const _LinuxDistribution({this.id = LinuxDistributionId.unknown, this.displayName = '', final  List<LinuxDistributionCapability> capabilities = const <LinuxDistributionCapability>[]}): _capabilities = capabilities,super._();
  factory _LinuxDistribution.fromJson(Map<String, dynamic> json) => _$LinuxDistributionFromJson(json);

@override@JsonKey() final  LinuxDistributionId id;
@override@JsonKey() final  String displayName;
/// 能力标签只描述“这个发行版在哪些业务场景需要特殊处理”，
/// 不直接绑定某个页面实现，避免 UI 和 Provider 重新长出发行版分支。
 final  List<LinuxDistributionCapability> _capabilities;
/// 能力标签只描述“这个发行版在哪些业务场景需要特殊处理”，
/// 不直接绑定某个页面实现，避免 UI 和 Provider 重新长出发行版分支。
@override@JsonKey() List<LinuxDistributionCapability> get capabilities {
  if (_capabilities is EqualUnmodifiableListView) return _capabilities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capabilities);
}


/// Create a copy of LinuxDistribution
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LinuxDistributionCopyWith<_LinuxDistribution> get copyWith => __$LinuxDistributionCopyWithImpl<_LinuxDistribution>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LinuxDistributionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LinuxDistribution&&(identical(other.id, id) || other.id == id)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&const DeepCollectionEquality().equals(other._capabilities, _capabilities));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,displayName,const DeepCollectionEquality().hash(_capabilities));

@override
String toString() {
  return 'LinuxDistribution(id: $id, displayName: $displayName, capabilities: $capabilities)';
}


}

/// @nodoc
abstract mixin class _$LinuxDistributionCopyWith<$Res> implements $LinuxDistributionCopyWith<$Res> {
  factory _$LinuxDistributionCopyWith(_LinuxDistribution value, $Res Function(_LinuxDistribution) _then) = __$LinuxDistributionCopyWithImpl;
@override @useResult
$Res call({
 LinuxDistributionId id, String displayName, List<LinuxDistributionCapability> capabilities
});




}
/// @nodoc
class __$LinuxDistributionCopyWithImpl<$Res>
    implements _$LinuxDistributionCopyWith<$Res> {
  __$LinuxDistributionCopyWithImpl(this._self, this._then);

  final _LinuxDistribution _self;
  final $Res Function(_LinuxDistribution) _then;

/// Create a copy of LinuxDistribution
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? displayName = null,Object? capabilities = null,}) {
  return _then(_LinuxDistribution(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as LinuxDistributionId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,capabilities: null == capabilities ? _self._capabilities : capabilities // ignore: cast_nullable_to_non_nullable
as List<LinuxDistributionCapability>,
  ));
}


}

// dart format on
