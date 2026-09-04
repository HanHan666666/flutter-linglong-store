// 特权 helper 定位、mountinfo FUSE 检测与暂存 preparer 单测（docs/47 §13.2）。
//
// 覆盖：mountinfo 的最长前缀/路径分量边界/八进制转义/fuse 家族/保守回退；
// 非 FUSE 直启不产生暂存；FUSE 暂存的目录权限、复制、ready 后删除与幂等
// 清理；清扫遗留目录；helper 缺失与 XDG 运行时目录缺失的失败路径。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_binary.dart';
import 'package:linglong_store/core/platform/privileged_helper/privileged_helper_exception.dart';

/// 构造一段 mountinfo：默认给出覆盖根的 ext4 挂载。
String mountinfo({
  String rootFstype = 'ext4',
  List<(String, String)> extraMounts = const [],
}) {
  final buffer = StringBuffer(
    '36 35 98:0 /mnt1 / rw,noatime master:1 - $rootFstype /dev/root '
    'rw,errors=continue\n',
  );
  for (final (mountPoint, fstype) in extraMounts) {
    buffer.writeln(
      '37 36 0:42 / $mountPoint rw,nosuid,nodev,relatime - $fstype fusectl x',
    );
  }
  return buffer.toString();
}

void main() {
  setUpAll(() async {
    await AppLogger.init();
  });

  group('isPathOnFuseFileSystem', () {
    test('detects fuse family on covering mount', () {
      final content = mountinfo(extraMounts: [('/tmp/app', 'fuse.appimage')]);
      expect(isPathOnFuseFileSystem('/tmp/app/squashfs/usr/bin/tool', content),
          isTrue);
    });

    test('detects fuse and fuseblk', () {
      expect(isFuseFileSystemType('fuse'), isTrue);
      expect(isFuseFileSystemType('fuseblk'), isTrue);
      expect(isFuseFileSystemType('fuse.sshfs'), isTrue);
      expect(isFuseFileSystemType('ext4'), isFalse);
      expect(isFuseFileSystemType('overlay'), isFalse);
      expect(isFuseFileSystemType('fusetoo'), isFalse,
          reason: 'fuse. 前缀才属于 FUSE 家族');
    });

    test('regular filesystem is direct-exec', () {
      expect(isPathOnFuseFileSystem('/opt/linglong-store/linglong_store',
          mountinfo()), isFalse);
    });

    test('longest covering mountpoint wins', () {
      final content = mountinfo(extraMounts: [
        ('/home', 'ext4'),
        ('/home/han/Downloads', 'fuse'),
      ]);
      expect(
        isPathOnFuseFileSystem(
          '/home/han/Downloads/appimage', content),
        isTrue,
      );
      expect(
        isPathOnFuseFileSystem('/home/han/Documents/file', content),
        isFalse,
      );
    });

    test('component boundary prevents partial segment match', () {
      final content = mountinfo(extraMounts: [('/tmp/app', 'fuse')]);
      // /tmp/appimage 不是 /tmp/app 挂载点下的路径（无路径分量边界）。
      expect(isPathOnFuseFileSystem('/tmp/appimage', content), isFalse);
      // 目标等于挂载点本身按覆盖处理。
      expect(isPathOnFuseFileSystem('/tmp/app', content), isTrue);
    });

    test('unescapes octal escapes in mountpoint', () {
      final content = mountinfo(extraMounts: [('/tmp/my\\040app', 'fuse')]);
      expect(
        isPathOnFuseFileSystem('/tmp/my app/bin/tool', content),
        isTrue,
      );
    });

    test('falls back to conservative staging', () {
      // 无匹配挂载点、空内容与异常输入都保守视为 FUSE（§5.2.1 第 2 步）；
      // 无根条目的 mountinfo 下任意路径都无覆盖。
      const noRoot = '37 36 0:42 / /home rw - ext4 /dev/sda2 rw\n';
      expect(isPathOnFuseFileSystem('/unknown/path', noRoot), isTrue);
      expect(isPathOnFuseFileSystem('/any', ''), isTrue);
    });
  });

  group('PrivilegedHelperBinary.prepare', () {
    late Directory tempDir;
    late File bundleHelper;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ll-helper-test');
      final bundleDir =
          Directory('${tempDir.path}/bundle')..createSync(recursive: true);
      bundleHelper = File('${bundleDir.path}/linglong_store_helper');
      bundleHelper.writeAsStringSync('#!/bin/sh\nexit 0\n');
      Process.runSync('chmod', ['755', bundleHelper.path]);
    });

    tearDown(() async {
      Process.runSync('chmod', ['-R', 'u+rwX', tempDir.path]);
      await tempDir.delete(recursive: true);
    });

    test('non-FUSE form returns bundle path and stages nothing', () async {
      final stagingRoot = Directory('${tempDir.path}/runtime/helper-staging')
        ..createSync(recursive: true);
      final binary = PrivilegedHelperBinary(
        mountinfoReader: () =>
            '1 0 0:1 / / rw - fuse.appimage x\n', // 根挂载为 FUSE 时必然暂存
        appRuntimeDirResolver: () => '${tempDir.path}/runtime',
        bundleHelperPathOverride: bundleHelper.path,
      );
      // 先验证非 FUSE：根挂载为 ext4。
      final direct = PrivilegedHelperBinary(
        mountinfoReader: () => mountinfo(),
        appRuntimeDirResolver: () => '${tempDir.path}/runtime',
        bundleHelperPathOverride: bundleHelper.path,
      );
      final prepared = await direct.prepare();
      expect(prepared.staged, isFalse);
      expect(prepared.path, bundleHelper.path);
      expect(stagingRoot.listSync(), isEmpty,
          reason: '直启形态不得产生暂存文件');
      await prepared.release();

      // FUSE：根挂载为 fuse.appimage，所有路径都被覆盖。
      final staged = await binary.prepare();
      expect(staged.staged, isTrue);
      expect(staged.path, isNot(bundleHelper.path));
      expect(File(staged.path).existsSync(), isTrue);
      expect(staged.path, contains('${tempDir.path}/runtime/helper-staging'));

      // 权限断言：暂存目录 0700、副本 0500（§5.2.1 第 4 步）。
      final dirMode = await _modeOf(staged.stagingDir!);
      final fileMode = await _modeOf(staged.path);
      expect(dirMode, '700');
      expect(fileMode, '500');

      // ready 后删除暂存文件与父目录；重复 release 幂等。
      await staged.release();
      expect(File(staged.path).existsSync(), isFalse);
      expect(Directory(staged.stagingDir!).existsSync(), isFalse);
      await staged.release();
    });

    test('sweeps stale staging directories before every launch', () async {
      final runtimeRoot = '${tempDir.path}/runtime';
      final binary = PrivilegedHelperBinary(
        mountinfoReader: () => mountinfo(),
        appRuntimeDirResolver: () => runtimeRoot,
        bundleHelperPathOverride: bundleHelper.path,
      );
      // 模拟上次 GUI 被 SIGKILL 遗留的目录。
      final stale = Directory(
        '$runtimeRoot/helper-staging/deadbeef',
      )..createSync(recursive: true);
      File('${stale.path}/linglong_store_helper').writeAsStringSync('stale');

      await binary.prepare();
      expect(stale.existsSync(), isFalse,
          reason: '无论本次是否走暂存分支都要清扫遗留（§5.2.1 第 5 步）');
    });

    test('missing bundle helper fails as unavailable', () async {
      final binary = PrivilegedHelperBinary(
        mountinfoReader: () => mountinfo(),
        appRuntimeDirResolver: () => '${tempDir.path}/runtime',
        bundleHelperPathOverride: '${tempDir.path}/bundle/missing_helper',
      );
      expect(
        () => binary.prepare(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
    });

    test('FUSE form without runtime dir fails as unavailable', () async {
      final binary = PrivilegedHelperBinary(
        mountinfoReader: () => '1 0 0:1 / / rw - fuse x\n',
        appRuntimeDirResolver: () => null,
        bundleHelperPathOverride: bundleHelper.path,
      );
      expect(
        () => binary.prepare(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
    });

    test('copy failure cleans up and reports unavailable', () async {
      // 收回属主读权限模拟复制中断（FUSE 挂载消失等场景）。
      Process.runSync('chmod', ['000', bundleHelper.path]);
      addTearDown(() => Process.runSync('chmod', ['755', bundleHelper.path]));
      final runtimeRoot = '${tempDir.path}/runtime';
      final binary = PrivilegedHelperBinary(
        mountinfoReader: () => '1 0 0:1 / / rw - fuse x\n',
        appRuntimeDirResolver: () => runtimeRoot,
        bundleHelperPathOverride: bundleHelper.path,
      );
      await expectLater(
        binary.prepare(),
        throwsA(isA<PrivilegedHelperUnavailableException>()),
      );
      final stagingRoot = Directory('$runtimeRoot/helper-staging');
      if (stagingRoot.existsSync()) {
        expect(
          stagingRoot.listSync().whereType<Directory>().where(
                (dir) => dir.listSync().isNotEmpty,
              ),
          isEmpty,
          reason: '复制失败的半成品目录必须被清理（§11 第 14 条）',
        );
      }
    });
  });
}

/// 读取文件系统对象权限（八进制三位）。
Future<String> _modeOf(String path) async {
  final result = await Process.run('stat', ['-c', '%a', path]);
  return (result.stdout as String).trim();
}
