import 'package:flutter_test/flutter_test.dart';

import 'package:linglong_store/domain/models/install_state_machine.dart';

void main() {
  group('InstallStateMachine', () {
    late InstallStateMachine stateMachine;

    setUp(() {
      stateMachine = InstallStateMachine();
    });

    tearDown(() {
      stateMachine.dispose();
    });

    group('initial state', () {
      test('should start in idle state', () {
        expect(stateMachine.state, equals(InstallStateMachineState.idle));
      });

      test('should have zero percentage initially', () {
        expect(stateMachine.lastPercentage, equals(0.0));
      });
    });

    group('state transitions', () {
      test('should transition from idle to waiting on start', () {
        stateMachine.start();

        expect(stateMachine.state, equals(InstallStateMachineState.waiting));
      });

      test('should transition from waiting to installing on first progress', () {
        stateMachine.start();
        stateMachine.onProgress(25.0);

        expect(stateMachine.state, equals(InstallStateMachineState.installing));
      });

      test('should stay in installing state on subsequent progress', () {
        stateMachine.start();
        stateMachine.onProgress(25.0);
        stateMachine.onProgress(50.0);
        stateMachine.onProgress(75.0);

        expect(stateMachine.state, equals(InstallStateMachineState.installing));
        expect(stateMachine.lastPercentage, equals(75.0));
      });

      test('should transition to succeeded on onSuccess', () {
        stateMachine.start();
        stateMachine.onProgress(100.0);
        stateMachine.onSuccess();

        expect(stateMachine.state, equals(InstallStateMachineState.succeeded));
      });

      test('should transition to failed on onFailure', () {
        stateMachine.start();
        stateMachine.onFailure();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });

      test('should transition to failed on onError', () {
        stateMachine.start();
        stateMachine.onError();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });

      test('should transition to failed from waiting state', () {
        stateMachine.start();
        // 不调用 onProgress，直接从 waiting 状态失败
        stateMachine.onFailure();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });
    });

    group('progress tracking', () {
      test('should update percentage on progress', () {
        stateMachine.start();
        stateMachine.onProgress(30.0);

        expect(stateMachine.lastPercentage, equals(30.0));
      });

      test('should track latest percentage', () {
        stateMachine.start();
        stateMachine.onProgress(30.0);
        stateMachine.onProgress(60.0);
        stateMachine.onProgress(90.0);

        expect(stateMachine.lastPercentage, equals(90.0));
      });
    });

    group('timeout check', () {
      test('should not timeout immediately after start', () {
        stateMachine.start();

        expect(stateMachine.checkTimeout(), isFalse);
      });

      test('should not timeout in idle state', () {
        // idle 状态不检查超时
        expect(stateMachine.checkTimeout(), isFalse);
      });

      test('should not timeout in succeeded state', () {
        stateMachine.start();
        stateMachine.onSuccess();

        expect(stateMachine.checkTimeout(), isFalse);
      });

      test('should not timeout in failed state', () {
        stateMachine.start();
        stateMachine.onFailure();

        expect(stateMachine.checkTimeout(), isFalse);
      });

      test('should use custom timeout value', () {
        // 创建一个短超时的状态机
        final shortTimeoutMachine = InstallStateMachine(progressTimeoutSecs: 1);
        shortTimeoutMachine.start();

        // 刚启动时不应该超时
        expect(shortTimeoutMachine.checkTimeout(), isFalse);

        shortTimeoutMachine.dispose();
      });
    });

    group('message handling', () {
      test('should refresh timestamp on onMessage in waiting state', () {
        stateMachine.start();
        stateMachine.onMessage();

        // onMessage 不应该改变状态
        expect(stateMachine.state, equals(InstallStateMachineState.waiting));
      });

      test('should refresh timestamp on onMessage in installing state', () {
        stateMachine.start();
        stateMachine.onProgress(50.0);
        stateMachine.onMessage();

        // onMessage 不应该改变状态
        expect(stateMachine.state, equals(InstallStateMachineState.installing));
      });
    });

    group('touch', () {
      test('should refresh timestamp', () {
        stateMachine.start();
        stateMachine.touch();

        // touch 不应该改变状态
        expect(stateMachine.state, equals(InstallStateMachineState.waiting));
      });
    });

    group('reset', () {
      test('should reset to idle state', () {
        stateMachine.start();
        stateMachine.onProgress(50.0);
        stateMachine.reset();

        expect(stateMachine.state, equals(InstallStateMachineState.idle));
        expect(stateMachine.lastPercentage, equals(0.0));
      });
    });

    group('dispose', () {
      test('should stop timeout timer', () {
        stateMachine.start();
        stateMachine.dispose();

        // dispose 后状态机应该停止定时器，不应该抛出异常
        expect(stateMachine.state, equals(InstallStateMachineState.waiting));
      });
    });

    group('full workflow', () {
      test('should follow complete success workflow', () {
        // Idle -> Waiting -> Installing -> Succeeded
        expect(stateMachine.state, equals(InstallStateMachineState.idle));

        stateMachine.start();
        expect(stateMachine.state, equals(InstallStateMachineState.waiting));

        stateMachine.onProgress(25.0);
        expect(stateMachine.state, equals(InstallStateMachineState.installing));
        expect(stateMachine.lastPercentage, equals(25.0));

        stateMachine.onProgress(50.0);
        expect(stateMachine.lastPercentage, equals(50.0));

        stateMachine.onProgress(100.0);
        expect(stateMachine.lastPercentage, equals(100.0));

        stateMachine.onSuccess();
        expect(stateMachine.state, equals(InstallStateMachineState.succeeded));
      });

      test('should follow complete failure workflow', () {
        // Idle -> Waiting -> Installing -> Failed
        stateMachine.start();
        stateMachine.onProgress(50.0);
        stateMachine.onFailure();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });

      test('should follow early failure workflow', () {
        // Idle -> Waiting -> Failed (no progress received)
        stateMachine.start();
        stateMachine.onFailure();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });

      test('should follow error workflow', () {
        // Idle -> Waiting -> Installing -> Failed (via error)
        stateMachine.start();
        stateMachine.onProgress(30.0);
        stateMachine.onError();

        expect(stateMachine.state, equals(InstallStateMachineState.failed));
      });
    });
  });

  group('InstallStateMachineState', () {
    test('should have correct enum values', () {
      expect(InstallStateMachineState.values.length, equals(5));
      expect(
        InstallStateMachineState.values,
        contains(InstallStateMachineState.idle),
      );
      expect(
        InstallStateMachineState.values,
        contains(InstallStateMachineState.waiting),
      );
      expect(
        InstallStateMachineState.values,
        contains(InstallStateMachineState.installing),
      );
      expect(
        InstallStateMachineState.values,
        contains(InstallStateMachineState.succeeded),
      );
      expect(
        InstallStateMachineState.values,
        contains(InstallStateMachineState.failed),
      );
    });
  });
}