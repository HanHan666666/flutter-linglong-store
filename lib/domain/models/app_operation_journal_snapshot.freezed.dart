// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_operation_journal_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppOperationJournalSnapshot {

/// 持久化结构版本。
 int get schemaVersion;/// 等待执行的任务。
 List<InstallTask> get pendingTasks;/// 当前执行中的任务。
 InstallTask? get currentTask;/// 有界任务历史。
 List<InstallTask> get history;/// 活跃和近期完成的批次。
 List<AppOperationBatch> get batches;/// 等待生命周期协调器消费的副作用。
 List<AppOperationEffect> get outbox;
/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppOperationJournalSnapshotCopyWith<AppOperationJournalSnapshot> get copyWith => _$AppOperationJournalSnapshotCopyWithImpl<AppOperationJournalSnapshot>(this as AppOperationJournalSnapshot, _$identity);

  /// Serializes this AppOperationJournalSnapshot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppOperationJournalSnapshot&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.pendingTasks, pendingTasks)&&(identical(other.currentTask, currentTask) || other.currentTask == currentTask)&&const DeepCollectionEquality().equals(other.history, history)&&const DeepCollectionEquality().equals(other.batches, batches)&&const DeepCollectionEquality().equals(other.outbox, outbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(pendingTasks),currentTask,const DeepCollectionEquality().hash(history),const DeepCollectionEquality().hash(batches),const DeepCollectionEquality().hash(outbox));

@override
String toString() {
  return 'AppOperationJournalSnapshot(schemaVersion: $schemaVersion, pendingTasks: $pendingTasks, currentTask: $currentTask, history: $history, batches: $batches, outbox: $outbox)';
}


}

/// @nodoc
abstract mixin class $AppOperationJournalSnapshotCopyWith<$Res>  {
  factory $AppOperationJournalSnapshotCopyWith(AppOperationJournalSnapshot value, $Res Function(AppOperationJournalSnapshot) _then) = _$AppOperationJournalSnapshotCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, List<InstallTask> pendingTasks, InstallTask? currentTask, List<InstallTask> history, List<AppOperationBatch> batches, List<AppOperationEffect> outbox
});


$InstallTaskCopyWith<$Res>? get currentTask;

}
/// @nodoc
class _$AppOperationJournalSnapshotCopyWithImpl<$Res>
    implements $AppOperationJournalSnapshotCopyWith<$Res> {
  _$AppOperationJournalSnapshotCopyWithImpl(this._self, this._then);

  final AppOperationJournalSnapshot _self;
  final $Res Function(AppOperationJournalSnapshot) _then;

/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? pendingTasks = null,Object? currentTask = freezed,Object? history = null,Object? batches = null,Object? outbox = null,}) {
  return _then(AppOperationJournalSnapshot(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,pendingTasks: null == pendingTasks ? _self.pendingTasks : pendingTasks // ignore: cast_nullable_to_non_nullable
as List<InstallTask>,currentTask: freezed == currentTask ? _self.currentTask : currentTask // ignore: cast_nullable_to_non_nullable
as InstallTask?,history: null == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as List<InstallTask>,batches: null == batches ? _self.batches : batches // ignore: cast_nullable_to_non_nullable
as List<AppOperationBatch>,outbox: null == outbox ? _self.outbox : outbox // ignore: cast_nullable_to_non_nullable
as List<AppOperationEffect>,
  ));
}
/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallTaskCopyWith<$Res>? get currentTask {
    if (_self.currentTask == null) {
    return null;
  }

  return $InstallTaskCopyWith<$Res>(_self.currentTask!, (value) {
    return _then(_self.copyWith(currentTask: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppOperationJournalSnapshot].
extension AppOperationJournalSnapshotPatterns on AppOperationJournalSnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppOperationJournalSnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppOperationJournalSnapshot value)  $default,){
final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppOperationJournalSnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  List<InstallTask> pendingTasks,  InstallTask? currentTask,  List<InstallTask> history,  List<AppOperationBatch> batches,  List<AppOperationEffect> outbox)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot() when $default != null:
return $default(_that.schemaVersion,_that.pendingTasks,_that.currentTask,_that.history,_that.batches,_that.outbox);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  List<InstallTask> pendingTasks,  InstallTask? currentTask,  List<InstallTask> history,  List<AppOperationBatch> batches,  List<AppOperationEffect> outbox)  $default,) {final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot():
return $default(_that.schemaVersion,_that.pendingTasks,_that.currentTask,_that.history,_that.batches,_that.outbox);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  List<InstallTask> pendingTasks,  InstallTask? currentTask,  List<InstallTask> history,  List<AppOperationBatch> batches,  List<AppOperationEffect> outbox)?  $default,) {final _that = this;
switch (_that) {
case _AppOperationJournalSnapshot() when $default != null:
return $default(_that.schemaVersion,_that.pendingTasks,_that.currentTask,_that.history,_that.batches,_that.outbox);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppOperationJournalSnapshot implements AppOperationJournalSnapshot {
  const _AppOperationJournalSnapshot({this.schemaVersion = currentAppOperationJournalSchemaVersion,  List<InstallTask> pendingTasks = const <InstallTask>[], this.currentTask,  List<InstallTask> history = const <InstallTask>[],  List<AppOperationBatch> batches = const <AppOperationBatch>[],  List<AppOperationEffect> outbox = const <AppOperationEffect>[]}): _pendingTasks = pendingTasks,_history = history,_batches = batches,_outbox = outbox;
  factory _AppOperationJournalSnapshot.fromJson(Map<String, dynamic> json) => _$AppOperationJournalSnapshotFromJson(json);

/// 持久化结构版本。
@override@JsonKey() final  int schemaVersion;
/// 等待执行的任务。
 final  List<InstallTask> _pendingTasks;
/// 等待执行的任务。
@override@JsonKey() List<InstallTask> get pendingTasks {
  if (_pendingTasks is EqualUnmodifiableListView) return _pendingTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingTasks);
}

/// 当前执行中的任务。
@override final  InstallTask? currentTask;
/// 有界任务历史。
 final  List<InstallTask> _history;
/// 有界任务历史。
@override@JsonKey() List<InstallTask> get history {
  if (_history is EqualUnmodifiableListView) return _history;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_history);
}

/// 活跃和近期完成的批次。
 final  List<AppOperationBatch> _batches;
/// 活跃和近期完成的批次。
@override@JsonKey() List<AppOperationBatch> get batches {
  if (_batches is EqualUnmodifiableListView) return _batches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_batches);
}

/// 等待生命周期协调器消费的副作用。
 final  List<AppOperationEffect> _outbox;
/// 等待生命周期协调器消费的副作用。
@override@JsonKey() List<AppOperationEffect> get outbox {
  if (_outbox is EqualUnmodifiableListView) return _outbox;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_outbox);
}


/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppOperationJournalSnapshotCopyWith<_AppOperationJournalSnapshot> get copyWith => __$AppOperationJournalSnapshotCopyWithImpl<_AppOperationJournalSnapshot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppOperationJournalSnapshotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppOperationJournalSnapshot&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other._pendingTasks, _pendingTasks)&&(identical(other.currentTask, currentTask) || other.currentTask == currentTask)&&const DeepCollectionEquality().equals(other._history, _history)&&const DeepCollectionEquality().equals(other._batches, _batches)&&const DeepCollectionEquality().equals(other._outbox, _outbox));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(_pendingTasks),currentTask,const DeepCollectionEquality().hash(_history),const DeepCollectionEquality().hash(_batches),const DeepCollectionEquality().hash(_outbox));

@override
String toString() {
  return 'AppOperationJournalSnapshot(schemaVersion: $schemaVersion, pendingTasks: $pendingTasks, currentTask: $currentTask, history: $history, batches: $batches, outbox: $outbox)';
}


}

/// @nodoc
abstract mixin class _$AppOperationJournalSnapshotCopyWith<$Res> implements $AppOperationJournalSnapshotCopyWith<$Res> {
  factory _$AppOperationJournalSnapshotCopyWith(_AppOperationJournalSnapshot value, $Res Function(_AppOperationJournalSnapshot) _then) = __$AppOperationJournalSnapshotCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, List<InstallTask> pendingTasks, InstallTask? currentTask, List<InstallTask> history, List<AppOperationBatch> batches, List<AppOperationEffect> outbox
});


@override $InstallTaskCopyWith<$Res>? get currentTask;

}
/// @nodoc
class __$AppOperationJournalSnapshotCopyWithImpl<$Res>
    implements _$AppOperationJournalSnapshotCopyWith<$Res> {
  __$AppOperationJournalSnapshotCopyWithImpl(this._self, this._then);

  final _AppOperationJournalSnapshot _self;
  final $Res Function(_AppOperationJournalSnapshot) _then;

/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? pendingTasks = null,Object? currentTask = freezed,Object? history = null,Object? batches = null,Object? outbox = null,}) {
  return _then(_AppOperationJournalSnapshot(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,pendingTasks: null == pendingTasks ? _self._pendingTasks : pendingTasks // ignore: cast_nullable_to_non_nullable
as List<InstallTask>,currentTask: freezed == currentTask ? _self.currentTask : currentTask // ignore: cast_nullable_to_non_nullable
as InstallTask?,history: null == history ? _self._history : history // ignore: cast_nullable_to_non_nullable
as List<InstallTask>,batches: null == batches ? _self._batches : batches // ignore: cast_nullable_to_non_nullable
as List<AppOperationBatch>,outbox: null == outbox ? _self._outbox : outbox // ignore: cast_nullable_to_non_nullable
as List<AppOperationEffect>,
  ));
}

/// Create a copy of AppOperationJournalSnapshot
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstallTaskCopyWith<$Res>? get currentTask {
    if (_self.currentTask == null) {
    return null;
  }

  return $InstallTaskCopyWith<$Res>(_self.currentTask!, (value) {
    return _then(_self.copyWith(currentTask: value));
  });
}
}

// dart format on
