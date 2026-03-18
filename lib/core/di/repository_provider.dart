import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/analytics_repository_impl.dart';
import '../../data/repositories/app_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/repositories/app_repository.dart';

/// 应用 Repository Provider
///
/// 提供应用相关的数据访问能力
final appRepositoryProvider = Provider<AppRepository>((ref) {
  return AppRepositoryImpl();
});

/// 统计上报 Repository Provider
///
/// 提供匿名统计上报能力，所有上报失败不抛异常
final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl();
});
