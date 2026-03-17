import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/data/mappers/cli_output_parser.dart';

void main() {
  group('CliOutputParser', () {
    group('parseInstalledApps', () {
      test('should return empty list when output is empty', () {
        expect(CliOutputParser.parseInstalledApps(''), isEmpty);
        expect(CliOutputParser.parseInstalledApps('   '), isEmpty);
        expect(CliOutputParser.parseInstalledApps('\n\n'), isEmpty);
      });

      test('should parse single app correctly', () {
        const output = '''
AppID                     Version    Arch    Channel    Size
com.tencent.wechat        4.0.0      x86_64  stable     256M
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('com.tencent.wechat'));
        expect(apps[0].version, equals('4.0.0'));
        expect(apps[0].arch, equals('x86_64'));
        expect(apps[0].channel, equals('stable'));
        expect(apps[0].size, equals('256M'));
      });

      test('should parse multiple apps correctly', () {
        const output = '''
AppID                     Version    Arch    Channel    Size
com.tencent.wechat        4.0.0      x86_64  stable     256M
cn.wps.wps-office         11.1.0     x86_64  stable     512M
com.baidu.netdisk         5.0.0      x86_64  stable     128M
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(3));
        expect(apps[0].appId, equals('com.tencent.wechat'));
        expect(apps[1].appId, equals('cn.wps.wps-office'));
        expect(apps[2].appId, equals('com.baidu.netdisk'));
      });

      test('should skip header line', () {
        const output = '''
AppID                     Version    Arch    Channel    Size
com.example.app           1.0.0      x86_64  stable     10M
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('com.example.app'));
      });

      test('should handle lowercase header', () {
        const output = '''
appid                     version    arch    channel    size
com.example.app           1.0.0      x86_64  stable     10M
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('com.example.app'));
      });

      test('should skip lines with insufficient columns', () {
        const output = '''
AppID                     Version    Arch    Channel    Size
com.example.app           1.0.0      x86_64  stable     10M
invalid_line
another_invalid
com.example.app2          2.0.0      x86_64  stable     20M
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(2));
        expect(apps[0].appId, equals('com.example.app'));
        expect(apps[1].appId, equals('com.example.app2'));
      });

      test('should extract app name from appId correctly', () {
        const output = '''
AppID                     Version
com.tencent.wechat        4.0.0
cn.wps.wps-office         11.1.0
org.example.my.app        1.0.0
simple                    1.0.0
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps[0].name, equals('wechat'));
        expect(apps[1].name, equals('wps-office'));
        expect(apps[2].name, equals('my.app'));
        expect(apps[3].name, equals('simple'));
      });

      test('should handle missing optional fields', () {
        const output = '''
AppID                     Version
com.example.app           1.0.0
''';
        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('com.example.app'));
        expect(apps[0].version, equals('1.0.0'));
        expect(apps[0].arch, equals(''));
        expect(apps[0].channel, equals(''));
      });

      test('should parse current ll-cli table layout correctly', () {
        const output = '''
ID                                         Name                             Version         Channel         Module      Description
cn.wps.wps-office                          WPS Office                       12.1.2.23579    main            binary      Office suite
''';

        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('cn.wps.wps-office'));
        expect(apps[0].name, equals('WPS Office'));
        expect(apps[0].version, equals('12.1.2.23579'));
        expect(apps[0].channel, equals('main'));
        expect(apps[0].module, equals('binary'));
        expect(apps[0].description, equals('Office suite'));
      });

      test('should parse ll-cli json output correctly', () {
        const output = '''
[
  {
    "appId": "com.tencent.wechat",
    "name": "微信",
    "version": "4.1.0.16",
    "arch": ["x86_64"],
    "channel": "main",
    "kind": "app",
    "module": "binary",
    "runtime": "main:org.deepin.runtime.dtk/23.1.0/x86_64",
    "size": 123456,
    "description": "测试描述"
  }
]
''';

        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('com.tencent.wechat'));
        expect(apps[0].name, equals('微信'));
        expect(apps[0].arch, equals('x86_64'));
        expect(apps[0].kind, equals('app'));
        expect(apps[0].module, equals('binary'));
        expect(apps[0].size, equals('123456'));
        expect(apps[0].description, equals('测试描述'));
      });
    });

    group('parseRunningApps', () {
      test('should return empty list when output is empty', () {
        expect(CliOutputParser.parseRunningApps(''), isEmpty);
        expect(CliOutputParser.parseRunningApps('   '), isEmpty);
      });

      test('should parse single running app correctly', () {
        const output = '''
App              ContainerID   Pid
com.tencent.wechat  abcdef123456  12345
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].id, equals('abcdef123456'));
        expect(apps[0].name, equals('com.tencent.wechat'));
        expect(apps[0].pid, equals(12345));
        expect(apps[0].appId, equals('com.tencent.wechat'));
        expect(apps[0].containerId, equals('abcdef123456'));
      });

      test('should parse multiple running apps correctly', () {
        const output = '''
App              ContainerID   Pid
com.tencent.wechat  abcdef123456  12345
cn.wps.wps-office  bcdefa234567  12346
com.baidu.netdisk  cdefab345678  12347
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(3));
        expect(apps[0].appId, equals('com.tencent.wechat'));
        expect(apps[1].appId, equals('cn.wps.wps-office'));
        expect(apps[2].appId, equals('com.baidu.netdisk'));
      });

      test('should skip header line with container id columns', () {
        const output = '''
App              ContainerID   Pid
com.tencent.wechat  abcdef123456  12345
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(1));
      });

      test('should ignore invalid header layouts', () {
        const output = '''
PID                       APP     ContainerID
12345                     com.tencent.wechat abcdef123456
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(0));
      });

      test('should skip invalid lines', () {
        const output = '''
App              ContainerID   Pid
com.tencent.wechat  abcdef123456  12345
invalid line
cn.wps.wps-office  bcdefa234567  12346
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(2));
      });

      test('should skip lines with invalid PID', () {
        const output = '''
App              ContainerID   Pid
com.tencent.wechat  abcdef123456  invalid
cn.wps.wps-office  bcdefa234567  12346
''';
        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('cn.wps.wps-office'));
      });

      test('should strip ansi color codes from output', () {
        const output =
            '\u001B[38;5;214mApp              ContainerID   Pid     \u001B[0m\n'
            'org.deepin.calculator  f327f606eadc  213845\n';

        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps.length, equals(1));
        expect(apps[0].appId, equals('org.deepin.calculator'));
        expect(apps[0].containerId, equals('f327f606eadc'));
        expect(apps[0].pid, equals(213845));
      });
    });

    group('parseAppInfo', () {
      test('should return empty map when output is empty', () {
        expect(CliOutputParser.parseAppInfo(''), isEmpty);
      });

      test('should parse key-value pairs correctly', () {
        const output = '''
AppID: com.tencent.wechat
Name: WeChat
Version: 4.0.0
Arch: x86_64
''';
        final info = CliOutputParser.parseAppInfo(output);

        expect(info['appid'], equals('com.tencent.wechat'));
        expect(info['name'], equals('WeChat'));
        expect(info['version'], equals('4.0.0'));
        expect(info['arch'], equals('x86_64'));
      });

      test('should convert keys to lowercase', () {
        const output = '''
AppID: value1
NAME: value2
Version: value3
''';
        final info = CliOutputParser.parseAppInfo(output);

        expect(info['appid'], equals('value1'));
        expect(info['name'], equals('value2'));
        expect(info['version'], equals('value3'));
      });

      test('should handle lines without colon', () {
        const output = '''
AppID: com.example.app
Invalid line without colon
Name: Test App
''';
        final info = CliOutputParser.parseAppInfo(output);

        expect(info.length, equals(2));
        expect(info['appid'], equals('com.example.app'));
        expect(info['name'], equals('Test App'));
      });

      test('should trim whitespace from key and value', () {
        const output = '''
  AppID  :   com.example.app
Name:Test App
''';
        final info = CliOutputParser.parseAppInfo(output);

        expect(info['appid'], equals('com.example.app'));
        expect(info['name'], equals('Test App'));
      });
    });

    group('parseInstallProgress', () {
      test('should detect downloading phase', () {
        final info = CliOutputParser.parseInstallProgress('downloading... 50%');

        expect(info.phase, equals(InstallPhase.downloading));
        expect(info.progress, equals(0.5)); // 50% 归一化为 0.5
      });

      test('should detect installing phase', () {
        final info = CliOutputParser.parseInstallProgress('installing... 80%');

        expect(info.phase, equals(InstallPhase.installing));
        expect(info.progress, equals(0.8)); // 80% 归一化为 0.8
      });

      test('should detect completed phase', () {
        final completedPhrases = [
          'success',
          'completed',
          'finished',
          'complete',
          'done',
          'ok',
        ];

        for (final phrase in completedPhrases) {
          final info = CliOutputParser.parseInstallProgress(phrase);
          expect(
            info.phase,
            equals(InstallPhase.completed),
            reason: 'Failed for: $phrase',
          );
          expect(info.progress, equals(1.0)); // 完成时归一化为 1.0
        }
      });

      test('should detect failed phase', () {
        final failedPhrases = [
          'error: something went wrong',
          'failed to install',
          'failure in download',
        ];

        for (final phrase in failedPhrases) {
          final info = CliOutputParser.parseInstallProgress(phrase);
          expect(
            info.phase,
            equals(InstallPhase.failed),
            reason: 'Failed for: $phrase',
          );
          expect(info.errorMessage, isNotNull);
        }
      });

      test('should parse percentage correctly', () {
        final info1 = CliOutputParser.parseInstallProgress(
          'downloading... 75.5%',
        );
        expect(info1.progress, equals(0.755)); // 75.5% 归一化为 0.755

        final info2 = CliOutputParser.parseInstallProgress('Downloading 30%');
        expect(info2.progress, equals(0.3)); // 30% 归一化为 0.3
      });

      test('should parse size progress correctly', () {
        final info = CliOutputParser.parseInstallProgress(
          'Downloaded 50/100 MB',
        );

        expect(info.phase, equals(InstallPhase.downloading));
        expect(info.progress, equals(0.5)); // 50/100 = 0.5 归一化
      });

      test('should detect unpacking as installing', () {
        final info = CliOutputParser.parseInstallProgress('unpacking files...');

        expect(info.phase, equals(InstallPhase.installing));
      });

      test('should detect extracting as installing', () {
        final info = CliOutputParser.parseInstallProgress(
          'extracting package...',
        );

        expect(info.phase, equals(InstallPhase.installing));
      });

      test('should preserve raw line', () {
        const line = 'downloading... 50%';
        final info = CliOutputParser.parseInstallProgress(line);

        expect(info.rawLine, equals(line));
      });

      test('should default to pending phase when no keyword matches', () {
        final info = CliOutputParser.parseInstallProgress('some random output');

        expect(info.phase, equals(InstallPhase.pending));
        expect(info.progress, equals(0.0));
      });
    });

    group('isInstallComplete', () {
      test('should return true for success messages', () {
        expect(CliOutputParser.isInstallComplete('success'), isTrue);
        expect(
          CliOutputParser.isInstallComplete('Installation completed'),
          isTrue,
        );
        expect(CliOutputParser.isInstallComplete('finished'), isTrue);
        expect(CliOutputParser.isInstallComplete('installed'), isTrue);
      });

      test('should return false for non-complete messages', () {
        expect(CliOutputParser.isInstallComplete('downloading...'), isFalse);
        expect(CliOutputParser.isInstallComplete('installing...'), isFalse);
        expect(CliOutputParser.isInstallComplete('error'), isFalse);
      });

      test('should be case insensitive', () {
        expect(CliOutputParser.isInstallComplete('SUCCESS'), isTrue);
        expect(CliOutputParser.isInstallComplete('Completed'), isTrue);
        expect(CliOutputParser.isInstallComplete('INSTALLED'), isTrue);
      });
    });

    group('isInstallFailed', () {
      test('should return true for failure messages', () {
        expect(CliOutputParser.isInstallFailed('error: something'), isTrue);
        expect(CliOutputParser.isInstallFailed('failed to install'), isTrue);
        expect(CliOutputParser.isInstallFailed('unable to complete'), isTrue);
      });

      test('should return false for non-failure messages', () {
        expect(CliOutputParser.isInstallFailed('success'), isFalse);
        expect(CliOutputParser.isInstallFailed('downloading...'), isFalse);
      });

      test('should be case insensitive', () {
        expect(CliOutputParser.isInstallFailed('ERROR'), isTrue);
        expect(CliOutputParser.isInstallFailed('FAILED'), isTrue);
        expect(CliOutputParser.isInstallFailed('Unable'), isTrue);
      });
    });

    group('extractErrorCode', () {
      test('should extract error code from "Error code: 123"', () {
        final code = CliOutputParser.extractErrorCode('Error code: 123');
        expect(code, equals(123));
      });

      test('should extract error code from "E123" format', () {
        final code = CliOutputParser.extractErrorCode('E123');
        expect(code, equals(123));
      });

      test('should extract error code from "(123)" format', () {
        final code = CliOutputParser.extractErrorCode('(123)');
        expect(code, equals(123));
      });

      test('should return null when no error code found', () {
        expect(CliOutputParser.extractErrorCode('no error code here'), isNull);
        expect(CliOutputParser.extractErrorCode(''), isNull);
      });

      test('should extract error code with "error 456" format', () {
        final code = CliOutputParser.extractErrorCode('error 456');
        expect(code, equals(456));
      });

      test('should be case insensitive', () {
        final code = CliOutputParser.extractErrorCode('ERROR: 789');
        expect(code, equals(789));
      });
    });

    group('parseSearchResults', () {
      test('should parse search results same as installed apps', () {
        const output = '''
AppID                     Version
com.example.app1          1.0.0
com.example.app2          2.0.0
''';
        final results = CliOutputParser.parseSearchResults(output);

        expect(results.length, equals(2));
        expect(results[0].appId, equals('com.example.app1'));
        expect(results[1].appId, equals('com.example.app2'));
      });
    });
  });

  group('InstallProgressInfo', () {
    test('should create with default values', () {
      final info = InstallProgressInfo(rawLine: 'test');

      expect(info.rawLine, equals('test'));
      expect(info.phase, equals(InstallPhase.pending));
      expect(info.progress, equals(0.0));
      expect(info.errorMessage, isNull);
    });

    test('should allow phase mutation', () {
      final info = InstallProgressInfo(rawLine: 'test');
      info.phase = InstallPhase.downloading;
      info.progress = 50.0;

      expect(info.phase, equals(InstallPhase.downloading));
      expect(info.progress, equals(50.0));
    });

    test('should store error message', () {
      final info = InstallProgressInfo(rawLine: 'error line');
      info.phase = InstallPhase.failed;
      info.errorMessage = 'Something went wrong';

      expect(info.phase, equals(InstallPhase.failed));
      expect(info.errorMessage, equals('Something went wrong'));
    });
  });

  group('InstallPhase', () {
    test('should have correct enum values', () {
      expect(InstallPhase.values.length, equals(5));
      expect(InstallPhase.values, contains(InstallPhase.pending));
      expect(InstallPhase.values, contains(InstallPhase.downloading));
      expect(InstallPhase.values, contains(InstallPhase.installing));
      expect(InstallPhase.values, contains(InstallPhase.completed));
      expect(InstallPhase.values, contains(InstallPhase.failed));
    });
  });

  group('parseJsonLine', () {
    test('should return null for empty line', () {
      expect(CliOutputParser.parseJsonLine(''), isNull);
      expect(CliOutputParser.parseJsonLine('   '), isNull);
      expect(CliOutputParser.parseJsonLine('\n'), isNull);
    });

    test('should return null for non-JSON line', () {
      expect(CliOutputParser.parseJsonLine('downloading... 50%'), isNull);
      expect(CliOutputParser.parseJsonLine('some random text'), isNull);
    });

    test('should parse progress event with percentage', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Downloading files","percentage":38.4}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, equals(JsonEventType.progress));
      expect(event.percentage, equals(38.4));
      expect(event.message, equals('Downloading files'));
      expect(event.code, isNull);
    });

    test('should parse error event with code', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Network failed","code":3001}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, equals(JsonEventType.error));
      expect(event.code, equals(3001));
      expect(event.message, equals('Network failed'));
      expect(event.percentage, isNull);
    });

    test('should parse message event with only message', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Install success"}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, equals(JsonEventType.message));
      expect(event.message, equals('Install success'));
      expect(event.percentage, isNull);
      expect(event.code, isNull);
    });

    test(
      'should prioritize code over percentage (code > percentage > message)',
      () {
        // 当同时存在 code 和 percentage 时，code 优先
        final event = CliOutputParser.parseJsonLine(
          '{"message":"Error at 50%","percentage":50.0,"code":2001}',
        );

        expect(event, isNotNull);
        expect(event!.eventType, equals(JsonEventType.error));
        expect(event.code, equals(2001));
        // 由于 code 存在，percentage 被忽略
      },
    );

    test(
      'should prioritize percentage over message (code > percentage > message)',
      () {
        // 当只存在 percentage 和 message 时，percentage 优先
        final event = CliOutputParser.parseJsonLine(
          '{"message":"Installing","percentage":75.0}',
        );

        expect(event, isNotNull);
        expect(event!.eventType, equals(JsonEventType.progress));
        expect(event.percentage, equals(75.0));
        expect(event.message, equals('Installing'));
      },
    );

    test('should handle percentage 100 correctly', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Done","percentage":100.0}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, equals(JsonEventType.progress));
      expect(event.percentage, equals(100.0));
    });

    test('should handle zero percentage', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Starting","percentage":0}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, equals(JsonEventType.progress));
      expect(event.percentage, equals(0.0));
    });

    test('should handle missing message field', () {
      final event1 = CliOutputParser.parseJsonLine('{"percentage":50.0}');
      expect(event1!.message, equals(''));

      final event2 = CliOutputParser.parseJsonLine('{"code":1000}');
      expect(event2!.message, equals(''));

      final event3 = CliOutputParser.parseJsonLine('{}');
      expect(event3!.message, equals(''));
      expect(event3.eventType, equals(JsonEventType.message));
    });

    test('should handle integer percentage', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Progress","percentage":50}',
      );

      expect(event, isNotNull);
      expect(event!.percentage, equals(50.0));
    });
  });

  group('parseInstallProgressEx', () {
    test('should parse JSON progress event', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Downloading files","percentage":45.5}',
      );

      expect(info.phase, equals(InstallPhase.downloading));
      expect(info.progress, equals(0.455)); // 45.5% 归一化为 0.455
    });

    test('should parse JSON error event', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Network error","code":3001}',
      );

      expect(info.phase, equals(InstallPhase.failed));
      expect(info.errorMessage, contains('网络错误'));
    });

    test('should fallback to text parsing for non-JSON', () {
      final info = CliOutputParser.parseInstallProgressEx('downloading... 50%');

      expect(info.phase, equals(InstallPhase.downloading));
      expect(info.progress, equals(0.5)); // 50% 归一化为 0.5
    });

    test('should handle JSON success message', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Install success"}',
      );

      expect(info.phase, equals(InstallPhase.completed));
      expect(info.progress, equals(1.0)); // 完成归一化为 1.0
    });

    test('should preserve raw line from JSON input', () {
      const line = '{"message":"test","percentage":30}';
      final info = CliOutputParser.parseInstallProgressEx(line);

      expect(info.rawLine, equals(line));
    });
  });
}
