import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/app_logger.dart';
import 'shell_command_executor.dart';

final localPathOpenerProvider = Provider<LocalPathOpener>((ref) {
  return LocalPathOpener();
});

/// 打开本地目录位置。
class LocalPathOpener {
  LocalPathOpener({ShellCommandExecutor? executor})
    : _executor = executor ?? ShellCommandExecutor();

  final ShellCommandExecutor _executor;

  Future<bool> openDirectory(String directoryPath) async {
    final result = await _executor.run(['xdg-open', directoryPath]);
    if (!result.success) {
      AppLogger.warning('打开目录失败: $directoryPath | ${result.primaryMessage}');
    }
    return result.success;
  }
}
