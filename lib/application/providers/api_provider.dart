import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/remote/app_api_service.dart';
import '../../core/network/api_client.dart';

/// 提供 AppApiService 单例
///
/// 使用 ApiClient 中的 Dio 实例创建 Retrofit 服务
final appApiServiceProvider = Provider<AppApiService>((ref) {
  return AppApiService(ApiClient.instance);
});