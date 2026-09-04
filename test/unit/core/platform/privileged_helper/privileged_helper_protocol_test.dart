// 特权 helper NDJSON 协议 DTO 单测（docs/47 §13.2）。
//
// 覆盖：请求编码的合法/非法字段与字符集、帧上限、事件解码的类型严格性、
// 版本不匹配与未知事件拒绝。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_exception.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_protocol.dart';

void main() {
  group('request encode', () {
    test('encodes install with version and force', () {
      const request = PrivilegedHelperStartRequest(
        requestId: 'install_org.deepin.demo',
        operation: PrivilegedHelperOperation.install,
        appId: 'org.deepin.demo',
        version: '1.2.3',
        force: true,
      );
      final decoded = jsonDecode(request.encode()) as Map<String, dynamic>;
      expect(decoded['v'], 1);
      expect(decoded['type'], 'start');
      expect(decoded['operation'], 'install');
      expect(decoded['appId'], 'org.deepin.demo');
      expect(decoded['version'], '1.2.3');
      expect(decoded['force'], isTrue);
      expect(request.encode().endsWith('\n'), isTrue,
          reason: 'NDJSON 帧必须以换行结尾');
    });

    test('encodes install without version', () {
      const request = PrivilegedHelperStartRequest(
        requestId: 'install_a.b',
        operation: PrivilegedHelperOperation.install,
        appId: 'a.b',
        force: false,
      );
      final decoded = jsonDecode(request.encode()) as Map<String, dynamic>;
      expect(decoded.containsKey('version'), isFalse);
      expect(decoded['force'], isFalse);
    });

    test('encodes update without version or force', () {
      const request = PrivilegedHelperStartRequest(
        requestId: 'update_a.b',
        operation: PrivilegedHelperOperation.update,
        appId: 'a.b',
        force: false,
      );
      final decoded = jsonDecode(request.encode()) as Map<String, dynamic>;
      expect(decoded['operation'], 'update');
      expect(decoded.containsKey('version'), isFalse);
      expect(decoded.containsKey('force'), isFalse);
    });

    test('rejects update carrying version', () {
      const request = PrivilegedHelperStartRequest(
        requestId: 'update_a.b',
        operation: PrivilegedHelperOperation.update,
        appId: 'a.b',
        version: '1.0.0',
        force: false,
      );
      expect(
        () => request.encode(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
    });

    test('rejects invalid request charset before sending', () {
      const slash = PrivilegedHelperStartRequest(
        requestId: 'bad/id',
        operation: PrivilegedHelperOperation.install,
        appId: 'a.b',
        force: false,
      );
      expect(
        () => slash.encode(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );

      const space = PrivilegedHelperStartRequest(
        requestId: 'ok',
        operation: PrivilegedHelperOperation.install,
        appId: 'a b',
        force: false,
      );
      expect(
        () => space.encode(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
    });

    test('rejects oversized frame', () {
      final request = PrivilegedHelperCancelRequest(
        requestId: List.filled(129, 'a').join(),
      );
      expect(
        () => request.encode(),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
    });

    test('encodes cancel and shutdown', () {
      expect(
        jsonDecode(
          const PrivilegedHelperCancelRequest(requestId: 't-1').encode(),
        ),
        containsPair('requestId', 't-1'),
      );
      expect(
        const PrivilegedHelperShutdownRequest().encode(),
        '{"v":1,"type":"shutdown"}\n',
      );
    });
  });

  group('event decode', () {
    test('decodes ready', () {
      const decoder = decodePrivilegedHelperEvent;
      final event = decoder('{"v":1,"type":"ready"}');
      expect(event, isA<PrivilegedHelperReadyEvent>());
    });

    test('decodes started, output, cancelAccepted and exited', () {
      final started = decodePrivilegedHelperEvent(
        '{"v":1,"type":"started","requestId":"t-1","pid":42}',
      ) as PrivilegedHelperStartedEvent;
      expect(started.pid, 42);

      final output = decodePrivilegedHelperEvent(
        '{"v":1,"type":"output","requestId":"t-1","stream":"stderr","line":"x"}',
      ) as PrivilegedHelperOutputEvent;
      expect(output.isStderr, isTrue);
      expect(output.line, 'x');

      final accepted = decodePrivilegedHelperEvent(
        '{"v":1,"type":"cancelAccepted","requestId":"t-1"}',
      ) as PrivilegedHelperCancelAcceptedEvent;
      expect(accepted.requestId, 't-1');

      final exited = decodePrivilegedHelperEvent(
        '{"v":1,"type":"exited","requestId":"t-1","exitCode":1,'
        '"cancelRequested":true}',
      ) as PrivilegedHelperExitedEvent;
      expect(exited.exitCode, 1);
      expect(exited.cancelRequested, isTrue);
    });

    test('decodes error event with and without requestId', () {
      final withId = decodePrivilegedHelperEvent(
        '{"v":1,"type":"error","requestId":"t-1","code":"busy",'
        '"message":"m","fatal":false}',
      ) as PrivilegedHelperErrorEvent;
      expect(withId.code, PrivilegedHelperErrorCodes.busy);
      expect(withId.fatal, isFalse);

      final withoutId = decodePrivilegedHelperEvent(
        '{"v":1,"type":"error","code":"internal","message":"m","fatal":true}',
      ) as PrivilegedHelperErrorEvent;
      expect(withoutId.requestId, isNull);
    });

    test('rejects protocol version mismatch', () {
      expect(
        () => decodePrivilegedHelperEvent('{"v":2,"type":"ready"}'),
        throwsA(
          isA<PrivilegedHelperProtocolException>().having(
            (error) => error.code,
            'code',
            PrivilegedHelperErrorCodes.protocolMismatch,
          ),
        ),
      );
    });

    test('rejects malformed json, unknown type and bad field types', () {
      expect(
        () => decodePrivilegedHelperEvent('not json'),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
      expect(
        () => decodePrivilegedHelperEvent('{"v":1,"type":"explode"}'),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
      expect(
        () => decodePrivilegedHelperEvent('{"v":1,"type":"exited",'
            '"requestId":"t","exitCode":"0","cancelRequested":false}'),
        throwsA(isA<PrivilegedHelperProtocolException>()),
        reason: 'exitCode 必须是整数',
      );
    });

    test('rejects oversized event frame', () {
      final hugeLine = '{"v":1,"type":"output","requestId":"t",'
          '"stream":"stdout","line":"${'x' * (1024 * 1024 + 8192)}"}';
      expect(
        () => decodePrivilegedHelperEvent(hugeLine),
        throwsA(isA<PrivilegedHelperProtocolException>()),
      );
    });
  });

  group('charset validators', () {
    test('requestId boundaries', () {
      expect(isValidPrivilegedHelperRequestId('a'), isTrue);
      expect(isValidPrivilegedHelperRequestId(List.filled(128, 'a').join()),
          isTrue);
      expect(isValidPrivilegedHelperRequestId(List.filled(129, 'a').join()),
          isFalse);
      expect(isValidPrivilegedHelperRequestId(''), isFalse);
      expect(isValidPrivilegedHelperRequestId('中文'), isFalse);
      expect(isValidPrivilegedHelperRequestId('a:b'), isFalse);
    });

    test('appId and version charsets', () {
      expect(isValidPrivilegedHelperAppId('org.deepin.demo-1_x'), isTrue);
      expect(isValidPrivilegedHelperAppId('org/deepin'), isFalse);
      expect(isValidPrivilegedHelperVersion('1.2.3+deepin~1-2'), isTrue);
      expect(isValidPrivilegedHelperVersion('1 2'), isFalse);
    });
  });
}
