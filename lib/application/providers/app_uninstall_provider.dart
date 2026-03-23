import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/app_uninstall_service.dart';

part 'app_uninstall_provider.g.dart';

/// 应用卸载服务 Provider
@riverpod
AppUninstallService appUninstallService(Ref ref) {
  return AppUninstallService(ref);
}