import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/data/mappers/cli_output_parser.dart';

void main() {
  group('CliOutputParser', () {
    group('parseInstalledApps', () {
      test('returns empty list when output is empty', () {
        expect(CliOutputParser.parseInstalledApps(''), isEmpty);
        expect(CliOutputParser.parseInstalledApps('   '), isEmpty);
        expect(CliOutputParser.parseInstalledApps('\n\n'), isEmpty);
      });

      test('parses ll-cli list json output', () {
        const output = '''
[
  {
    "id": "com.tencent.wechat",
    "name": "微信",
    "version": "4.1.1.7",
    "arch": ["x86_64"],
    "channel": "main",
    "kind": "app",
    "module": "binary",
    "runtime": "org.deepin.runtime.dtk/25.2.2",
    "size": 752377742,
    "description": "微信是一款国内知名的免费即时通讯应用程序"
  }
]
''';

        final apps = CliOutputParser.parseInstalledApps(output);

        expect(apps, hasLength(1));
        expect(apps.single.appId, 'com.tencent.wechat');
        expect(apps.single.name, '微信');
        expect(apps.single.version, '4.1.1.7');
        expect(apps.single.arch, 'x86_64');
        expect(apps.single.channel, 'main');
        expect(apps.single.kind, 'app');
        expect(apps.single.module, 'binary');
        expect(apps.single.runtime, 'org.deepin.runtime.dtk/25.2.2');
        expect(apps.single.size, '752377742');
        expect(apps.single.description, '微信是一款国内知名的免费即时通讯应用程序');
      });

      test('does not parse legacy text table output', () {
        const output = '''
AppID                     Version    Arch    Channel    Size
com.tencent.wechat        4.0.0      x86_64  stable     256M
''';

        expect(CliOutputParser.parseInstalledApps(output), isEmpty);
      });
    });

    group('parseRunningApps', () {
      test('returns empty list when output is empty', () {
        expect(CliOutputParser.parseRunningApps(''), isEmpty);
        expect(CliOutputParser.parseRunningApps('   '), isEmpty);
      });

      test('parses ll-cli --json ps array output', () {
        const output = '''
[
  {"app":"org.deepin.calculator","containerId":"abc123","pid":1234},
  {"appId":"com.tencent.wechat","container_id":"def456","pid":"5678"}
]
''';

        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps, hasLength(2));
        expect(apps[0].id, 'abc123');
        expect(apps[0].appId, 'org.deepin.calculator');
        expect(apps[0].name, 'org.deepin.calculator');
        expect(apps[0].pid, 1234);
        expect(apps[0].containerId, 'abc123');
        expect(apps[1].id, 'def456');
        expect(apps[1].appId, 'com.tencent.wechat');
        expect(apps[1].pid, 5678);
      });

      test('parses real ll-cli ps package refs', () {
        const output = '''
[
  {"id":"c2f817d3caf2","package":"main:com.xunlei.download/1.0.0.6/x86_64","pid":34635},
  {"id":"80e57cd4642f","package":"main:com.qq.wemeet/3.26.10.404/x86_64","pid":34598}
]
''';

        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps, hasLength(2));
        expect(apps[0].id, 'c2f817d3caf2');
        expect(apps[0].containerId, 'c2f817d3caf2');
        expect(apps[0].appId, 'com.xunlei.download');
        expect(apps[0].pid, 34635);
        expect(apps[1].id, '80e57cd4642f');
        expect(apps[1].appId, 'com.qq.wemeet');
        expect(apps[1].pid, 34598);
      });

      test('parses wrapped process list output', () {
        const output = '''
{"processes":[{"id":"org.deepin.editor","containerID":"ghi789","pid":9012}]}
''';

        final apps = CliOutputParser.parseRunningApps(output);

        expect(apps, hasLength(1));
        expect(apps.single.appId, 'org.deepin.editor');
        expect(apps.single.containerId, 'ghi789');
        expect(apps.single.pid, 9012);
      });

      test('does not parse legacy ps text table output', () {
        const output = '''
App              ContainerID   Pid
org.deepin.calculator  abcdef123456  12345
''';

        expect(CliOutputParser.parseRunningApps(output), isEmpty);
      });
    });

    group('parseSearchResults', () {
      test('parses ll-cli search json grouped by repository', () {
        const output = '''
{
  "stable": [
    {
      "id": "org.deepin.calculator",
      "name": "deepin-calculator",
      "version": "6.5.34.1",
      "arch": ["x86_64"],
      "channel": "main",
      "kind": "app",
      "module": "binary",
      "runtime": "main:org.deepin.runtime.dtk/25.2.2/x86_64",
      "size": 5624947
    }
  ],
  "testing": [
    {
      "id": "org.deepin.calculator",
      "name": "deepin-calculator",
      "version": "6.5.35.1",
      "arch": ["x86_64"],
      "channel": "main",
      "repoName": "testing"
    }
  ]
}
''';

        final results = CliOutputParser.parseSearchResults(output);

        expect(results, hasLength(2));
        expect(results[0].appId, 'org.deepin.calculator');
        expect(results[0].version, '6.5.34.1');
        expect(results[0].repoName, 'stable');
        expect(results[1].version, '6.5.35.1');
        expect(results[1].repoName, 'testing');
      });

      test('does not parse legacy search text table output', () {
        const output = '''
AppID                     Version
com.example.app1          1.0.0
com.example.app2          2.0.0
''';

        expect(CliOutputParser.parseSearchResults(output), isEmpty);
      });
    });
  });

  group('InstallProgressInfo', () {
    test('creates with default values', () {
      final info = InstallProgressInfo(rawLine: 'test');

      expect(info.rawLine, 'test');
      expect(info.phase, InstallPhase.pending);
      expect(info.progress, 0.0);
      expect(info.errorMessage, isNull);
    });

    test('allows phase mutation', () {
      final info = InstallProgressInfo(rawLine: 'test');
      info.phase = InstallPhase.downloading;
      info.progress = 50.0;

      expect(info.phase, InstallPhase.downloading);
      expect(info.progress, 50.0);
    });

    test('stores error message', () {
      final info = InstallProgressInfo(rawLine: 'error line');
      info.phase = InstallPhase.failed;
      info.errorMessage = 'Something went wrong';

      expect(info.phase, InstallPhase.failed);
      expect(info.errorMessage, 'Something went wrong');
    });
  });

  group('InstallPhase', () {
    test('has correct enum values', () {
      expect(InstallPhase.values.length, 5);
      expect(InstallPhase.values, contains(InstallPhase.pending));
      expect(InstallPhase.values, contains(InstallPhase.downloading));
      expect(InstallPhase.values, contains(InstallPhase.installing));
      expect(InstallPhase.values, contains(InstallPhase.completed));
      expect(InstallPhase.values, contains(InstallPhase.failed));
    });
  });

  group('parseJsonLine', () {
    test('returns null for empty or non-json lines', () {
      expect(CliOutputParser.parseJsonLine(''), isNull);
      expect(CliOutputParser.parseJsonLine('   '), isNull);
      expect(CliOutputParser.parseJsonLine('\n'), isNull);
      expect(CliOutputParser.parseJsonLine('downloading... 50%'), isNull);
      expect(CliOutputParser.parseJsonLine('some random text'), isNull);
    });

    test('parses progress event with percentage', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Downloading files","percentage":38.4}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, JsonEventType.progress);
      expect(event.percentage, 38.4);
      expect(event.message, 'Downloading files');
      expect(event.code, isNull);
    });

    test('parses error event with code', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Network failed","code":3001}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, JsonEventType.error);
      expect(event.code, 3001);
      expect(event.message, 'Network failed');
      expect(event.percentage, isNull);
    });

    test('parses message event with only message', () {
      final event = CliOutputParser.parseJsonLine(
        '{"message":"Install success"}',
      );

      expect(event, isNotNull);
      expect(event!.eventType, JsonEventType.message);
      expect(event.message, 'Install success');
      expect(event.percentage, isNull);
      expect(event.code, isNull);
    });

    test('prioritizes code over percentage and percentage over message', () {
      final errorEvent = CliOutputParser.parseJsonLine(
        '{"message":"Error at 50%","percentage":50.0,"code":2001}',
      );
      final progressEvent = CliOutputParser.parseJsonLine(
        '{"message":"Installing","percentage":75.0}',
      );

      expect(errorEvent!.eventType, JsonEventType.error);
      expect(errorEvent.code, 2001);
      expect(progressEvent!.eventType, JsonEventType.progress);
      expect(progressEvent.percentage, 75.0);
    });

    test('handles missing message and integer percentage', () {
      final progressEvent = CliOutputParser.parseJsonLine('{"percentage":50}');
      final errorEvent = CliOutputParser.parseJsonLine('{"code":1000}');
      final messageEvent = CliOutputParser.parseJsonLine('{}');

      expect(progressEvent!.message, '');
      expect(progressEvent.percentage, 50.0);
      expect(errorEvent!.message, '');
      expect(messageEvent!.message, '');
      expect(messageEvent.eventType, JsonEventType.message);
    });
  });

  group('parseInstallProgressEx', () {
    test('parses JSON progress event', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Downloading files","percentage":45.5}',
      );

      expect(info.phase, InstallPhase.downloading);
      expect(info.progress, 0.455);
    });

    test('parses JSON error event', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Network error","code":3001}',
      );

      expect(info.phase, InstallPhase.failed);
      expect(info.errorMessage, contains('网络错误'));
    });

    test('keeps non-json progress lines pending', () {
      final info = CliOutputParser.parseInstallProgressEx('downloading... 50%');

      expect(info.phase, InstallPhase.pending);
      expect(info.progress, 0.0);
      expect(info.errorMessage, isNull);
    });

    test('handles JSON success message', () {
      final info = CliOutputParser.parseInstallProgressEx(
        '{"message":"Install success"}',
      );

      expect(info.phase, InstallPhase.completed);
      expect(info.progress, 1.0);
    });

    test('preserves raw line from JSON input', () {
      const line = '{"message":"test","percentage":30}';
      final info = CliOutputParser.parseInstallProgressEx(line);

      expect(info.rawLine, line);
    });
  });

  group('getStatusFromMessage', () {
    test('keeps long unknown messages complete', () {
      const longMessage =
          'Resolving dependency org.deepin.runtime.webengine version 25.2.1 '
          'from repo stable with additional package metadata';

      expect(InstallErrorCode.getStatusFromMessage(longMessage), longMessage);
      expect(
        InstallErrorCode.getStatusFromMessage(longMessage),
        isNot(endsWith('...')),
      );
    });
  });
}
