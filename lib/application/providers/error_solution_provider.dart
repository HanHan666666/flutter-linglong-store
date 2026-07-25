import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/repository_provider.dart';
import '../services/error_solution_lookup_service.dart';

/// 安装错误解决方案查询服务 Provider。
///
/// Provider 只复用无状态服务实例，不缓存任何查询结果；每次按钮点击都会调用
/// [ErrorSolutionLookupService.find] 发起新的后端请求。
final errorSolutionLookupServiceProvider = Provider<ErrorSolutionLookupService>(
  (ref) {
    return ErrorSolutionLookupService(
      repository: ref.watch(errorSolutionRepositoryProvider),
    );
  },
);
