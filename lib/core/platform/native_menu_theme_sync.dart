import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

const MethodChannel _nativeThemeChannel = MethodChannel(
  'org.linglong_store/native_theme',
);

/// 将 Flutter 当前实际主题亮度同步到 Linux 原生菜单。
///
/// 右键菜单由 GTK 原生组件绘制，不能直接使用 Flutter ThemeData，
/// 因此这里接收上层已解析好的「当前实际是否深色」并同步给 Linux runner。
class NativeMenuThemeSync extends StatefulWidget {
  const NativeMenuThemeSync({
    required this.child,
    required this.isDark,
    super.key,
  });

  final Widget child;
  final bool isDark;

  @override
  State<NativeMenuThemeSync> createState() => _NativeMenuThemeSyncState();
}

class _NativeMenuThemeSyncState extends State<NativeMenuThemeSync> {
  bool? _lastSyncedIsDark;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scheduleThemeSync();
  }

  @override
  void didUpdateWidget(covariant NativeMenuThemeSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDark != widget.isDark) {
      _scheduleThemeSync();
    }
  }

  void _scheduleThemeSync() {
    if (!Platform.isLinux || _syncScheduled) {
      return;
    }

    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      _syncCurrentTheme();
    });
  }

  Future<void> _syncCurrentTheme() async {
    final isDark = widget.isDark;
    if (_lastSyncedIsDark == isDark) {
      return;
    }

    _lastSyncedIsDark = isDark;

    try {
      await _nativeThemeChannel.invokeMethod<void>('setContextMenuDarkTheme', {
        'isDark': isDark,
      });
    } catch (error, stackTrace) {
      AppLogger.warning(
        'Failed to sync native context menu theme',
        error,
        stackTrace,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
