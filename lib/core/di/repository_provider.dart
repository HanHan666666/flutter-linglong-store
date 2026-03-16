import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_repository_impl.dart';
import '../../domain/repositories/app_repository.dart';

/// 应用 Repository Provider
///
/// 提供应用相关的数据访问能力
final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepositoryImpl();
});