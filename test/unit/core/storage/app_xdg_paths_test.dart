import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:linglong_store/core/storage/app_xdg_paths.dart';

void main() {
  group('AppXdgPaths - XDG 根目录解析', () {
    test('XDG_DATA_HOME 优先于 HOME', () {
      expect(
        AppXdgPaths.resolveDataHome(environment: {
          'XDG_DATA_HOME': '/custom/xdg',
          'HOME': '/home/user',
        }),
        '/custom/xdg',
      );
    });

    test('XDG_DATA_HOME 为空时回退到 HOME/.local/share', () {
      expect(
        AppXdgPaths.resolveDataHome(environment: {
          'XDG_DATA_HOME': '',
          'HOME': '/home/user',
        }),
        p.join('/home/user', '.local', 'share'),
      );
    });

    test('XDG_CONFIG_HOME 默认 \$HOME/.config', () {
      expect(
        AppXdgPaths.resolveConfigHome(environment: {
          'HOME': '/home/user',
        }),
        p.join('/home/user', '.config'),
      );
    });

    test('XDG_CACHE_HOME 默认 \$HOME/.cache', () {
      expect(
        AppXdgPaths.resolveCacheHome(environment: {
          'HOME': '/home/user',
        }),
        p.join('/home/user', '.cache'),
      );
    });

    test('XDG_RUNTIME_DIR 未设置时返回 null', () {
      expect(
        AppXdgPaths.resolveRuntimeDir(environment: {}),
        isNull,
      );
    });

    test('XDG_RUNTIME_DIR 已设置时返回原值', () {
      expect(
        AppXdgPaths.resolveRuntimeDir(environment: {
          'XDG_RUNTIME_DIR': '/run/user/1000',
        }),
        '/run/user/1000',
      );
    });

    test('HOME 缺失时所有 home-fallback 都返回 null', () {
      expect(AppXdgPaths.resolveDataHome(environment: {}), isNull);
      expect(AppXdgPaths.resolveConfigHome(environment: {}), isNull);
      expect(AppXdgPaths.resolveCacheHome(environment: {}), isNull);
    });
  });

  group('AppXdgPaths - 应用级目录', () {
    test('resolveAppDataDirectory 拼接 applicationId', () {
      expect(
        AppXdgPaths.resolveAppDataDirectory(environment: {
          'XDG_DATA_HOME': '/data',
        }),
        '/data/${AppXdgPaths.applicationId}',
      );
    });

    test('resolveAppConfigDirectory 拼接 applicationId', () {
      expect(
        AppXdgPaths.resolveAppConfigDirectory(environment: {
          'XDG_CONFIG_HOME': '/config',
        }),
        '/config/${AppXdgPaths.applicationId}',
      );
    });

    test('resolveAppCacheDirectory 拼接 applicationId', () {
      expect(
        AppXdgPaths.resolveAppCacheDirectory(environment: {
          'XDG_CACHE_HOME': '/cache',
        }),
        '/cache/${AppXdgPaths.applicationId}',
      );
    });

    test('resolveAppRuntimeDirectory 拼接 applicationId', () {
      expect(
        AppXdgPaths.resolveAppRuntimeDirectory(environment: {
          'XDG_RUNTIME_DIR': '/run/user/1000',
        }),
        '/run/user/1000/${AppXdgPaths.applicationId}',
      );
    });

    test('resolveAppRuntimeDirectory 在 XDG_RUNTIME_DIR 缺失时返回 null', () {
      expect(
        AppXdgPaths.resolveAppRuntimeDirectory(environment: {}),
        isNull,
      );
    });

    test('resolveLegacyAppDataDirectory 拼接 legacyApplicationId', () {
      expect(
        AppXdgPaths.resolveLegacyAppDataDirectory(environment: {
          'XDG_DATA_HOME': '/data',
        }),
        '/data/${AppXdgPaths.legacyApplicationId}',
      );
    });
  });

  group('AppXdgPaths - 具体文件路径', () {
    test('resolveCurrentLogFilePath 路径结构正确', () {
      final path = AppXdgPaths.resolveCurrentLogFilePath(environment: {
        'XDG_DATA_HOME': '/data',
      });
      expect(
        path,
        p.join(
          '/data',
          AppXdgPaths.applicationId,
          AppXdgPaths.logsDirectoryName,
          AppXdgPaths.logFileName,
        ),
      );
    });

    test('resolveLogsDirectoryPath 路径结构正确', () {
      final path = AppXdgPaths.resolveLogsDirectoryPath(environment: {
        'XDG_DATA_HOME': '/data',
      });
      expect(
        path,
        p.join('/data', AppXdgPaths.applicationId, AppXdgPaths.logsDirectoryName),
      );
    });

    test('resolveMigrationStateFilePath 路径结构正确', () {
      final path = AppXdgPaths.resolveMigrationStateFilePath(environment: {
        'XDG_DATA_HOME': '/data',
      });
      expect(
        path,
        p.join(
          '/data',
          AppXdgPaths.applicationId,
          AppXdgPaths.migrationStateFileName,
        ),
      );
    });

    test('resolveMigrationLockFilePath 路径结构正确', () {
      final path = AppXdgPaths.resolveMigrationLockFilePath(environment: {
        'XDG_DATA_HOME': '/data',
      });
      expect(
        path,
        p.join(
          '/data',
          AppXdgPaths.applicationId,
          AppXdgPaths.migrationLockFileName,
        ),
      );
    });

    test('resolveSingleInstanceLockFilePath 走 XDG_RUNTIME_DIR', () {
      final path = AppXdgPaths.resolveSingleInstanceLockFilePath(environment: {
        'XDG_RUNTIME_DIR': '/run/user/1000',
      });
      expect(
        path,
        p.join(
          '/run/user/1000',
          AppXdgPaths.applicationId,
          AppXdgPaths.singleInstanceLockFileName,
        ),
      );
    });

    test('resolveSingleInstanceSocketFilePath 走 XDG_RUNTIME_DIR', () {
      final path = AppXdgPaths.resolveSingleInstanceSocketFilePath(environment: {
        'XDG_RUNTIME_DIR': '/run/user/1000',
      });
      expect(
        path,
        p.join(
          '/run/user/1000',
          AppXdgPaths.applicationId,
          AppXdgPaths.singleInstanceSocketFileName,
        ),
      );
    });

    test('resolveSingleInstanceLockFilePath 在 XDG_RUNTIME_DIR 缺失时返回 null', () {
      expect(
        AppXdgPaths.resolveSingleInstanceLockFilePath(environment: {}),
        isNull,
      );
    });

    test('resolveRendererConfigFilePath 走 XDG_CONFIG_HOME', () {
      final path = AppXdgPaths.resolveRendererConfigFilePath(environment: {
        'XDG_CONFIG_HOME': '/config',
      });
      expect(
        path,
        p.join(
          '/config',
          AppXdgPaths.applicationId,
          'startup',
          'renderer_preferences.ini',
        ),
      );
    });

    test('resolveLegacyRendererConfigFilePath 走 XDG_DATA_HOME（旧位置）', () {
      final path = AppXdgPaths.resolveLegacyRendererConfigFilePath(environment: {
        'XDG_DATA_HOME': '/data',
      });
      expect(
        path,
        p.join(
          '/data',
          AppXdgPaths.applicationId,
          'startup',
          'renderer_preferences.ini',
        ),
      );
    });
  });

  group('AppXdgPaths - 身份常量', () {
    test('applicationId 与 legacyApplicationId 不相同', () {
      expect(
        AppXdgPaths.applicationId,
        isNot(equals(AppXdgPaths.legacyApplicationId)),
      );
    });
  });
}
