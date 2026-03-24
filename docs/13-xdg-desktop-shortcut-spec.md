# XDG 桌面快捷方式规范

> **状态**: ✅ 已修复 (2026-03-24)
> **相关代码**: `lib/data/repositories/linglong_cli_repository_impl.dart:482-543`
> **相关测试**: `test/unit/data/repositories/linglong_cli_repository_impl_test.dart`

## 背景

创建桌面快捷方式功能需要严格遵守 XDG Base Directory Specification，以确保：
- 支持国际化桌面路径（如中文系统的 `~/桌面`）
- 支持用户自定义桌面路径
- 符合 Linux 桌面标准规范

## 实现方案

### 桌面目录获取（XDG Base Directory Specification）

**优先级顺序**:

```dart
Future<String> _getDesktopDirectory() async {
  // 优先级1: XDG_DESKTOP_DIR 环境变量（最高优先级）
  final xdgDesktop = Platform.environment['XDG_DESKTOP_DIR'];
  if (xdgDesktop != null && xdgDesktop.isNotEmpty) {
    final dir = Directory(xdgDesktop);
    if (await dir.exists()) {
      AppLogger.debug('[LinglongCli] 使用 XDG_DESKTOP_DIR: $xdgDesktop');
      return xdgDesktop;
    }
  }

  // 优先级2: xdg-user-dir DESKTOP 命令（推荐方式）
  try {
    final result = await Process.run('xdg-user-dir', ['DESKTOP']);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty && path != '/') {
        final dir = Directory(path);
        if (await dir.exists()) {
          AppLogger.debug('[LinglongCli] 使用 xdg-user-dir: $path');
          return path;
        }
      }
    }
  } catch (e) {
    AppLogger.debug('[LinglongCli] xdg-user-dir 命令不可用: $e');
  }

  // 优先级3: ~/.config/user-dirs.dirs 配置文件
  try {
    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      final userDirsFile = File('$home/.config/user-dirs.dirs');
      if (await userDirsFile.exists()) {
        final content = await userDirsFile.readAsString();
        final match = RegExp(r'XDG_DESKTOP_DIR="([^"]+)"').firstMatch(content);
        if (match != null) {
          final rawPath = match.group(1)!;
          final path = rawPath
              .replaceAll(r'\$HOME', home)
              .replaceAll(r'$HOME', home);
          final dir = Directory(path);
          if (await dir.exists()) {
            AppLogger.debug('[LinglongCli] 使用 user-dirs.dirs: $path');
            return path;
          }
        }
      }
    }
  } catch (e) {
    AppLogger.debug('[LinglongCli] 解析 user-dirs.dirs 失败: $e');
  }

  // 优先级4: 默认 ~/Desktop（标准 fallback）
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw Exception('无法获取 HOME 目录');
  }
  final fallbackPath = '$home/Desktop';
  AppLogger.debug('[LinglongCli] 使用 fallback 路径: $fallbackPath');
  return fallbackPath;
}
```

### 为什么 ~/Desktop 是标准 fallback？

根据 [xdg-user-dirs 规范](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/):

1. **配置文件存在时**: 从 `~/.config/user-dirs.dirs` 读取 `XDG_DESKTOP_DIR`
2. **配置文件不存在时**: 默认值为 `$HOME/Desktop`（这是规范定义的）
3. **如果配置文件被删除**: 会在下次登录时由 `xdg-user-dirs-update` 自动重建

**实际行为**:
- 中文系统: `xdg-user-dir DESKTOP` → `~/桌面`
- 英文系统: `xdg-user-dir DESKTOP` → `~/Desktop`
- 自定义路径: `xdg-user-dir DESKTOP` → 用户配置的路径

**只有在极端情况下才使用 fallback**:
- xdg-user-dirs 包未安装
- 配置文件被删除
- xdg-user-dir 命令失败

## .desktop 文件规范

**Desktop Entry Specification 要点**:
- 文件名: `org.example.AppName.desktop` (reverse DNS 命名)
- 编码: UTF-8
- 必需字段: `Type`, `Name`, `Exec`
- 推荐字段: `Comment`, `Icon`, `Categories`, `StartupNotify`
- 权限: `0755` (owner 可执行)

**示例**:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Example App
Comment=示例应用
Exec=/usr/bin/example-app %F
Icon=example-app
Terminal=false
Categories=Utility;Application;
StartupNotify=true
```

## 创建桌面快捷方式流程

```dart
Future<String> createDesktopShortcut(String appId) async {
  // 1. 检查应用是否已安装
  final installedApps = await getInstalledApps();
  final isInstalled = installedApps.any((app) => app.appId == appId);
  if (!isInstalled) {
    return '应用未安装，无法创建快捷方式: $appId';
  }

  // 2. 使用 ll-cli content 获取应用导出的 .desktop 文件
  final output = await CliExecutor.execute(['content', appId]);
  if (!output.success) {
    return _messages.shortcutCreateFailed(output.stderr);
  }

  // 3. 从输出中找到 .desktop 文件路径
  final lines = output.stdout.split('\n');
  String? desktopSource;
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty && trimmed.endsWith('.desktop')) {
      desktopSource = trimmed;
      break;
    }
  }

  if (desktopSource == null) {
    return '未找到应用导出的 desktop 文件: $appId';
  }

  // 4. 根据 XDG 规范获取桌面目录路径 ✅
  final desktopDir = await _getDesktopDirectory();

  // 5. 确保桌面目录存在
  final desktopDirFile = Directory(desktopDir);
  if (!await desktopDirFile.exists()) {
    await desktopDirFile.create(recursive: true);
  }

  // 6. 构建目标路径
  final desktopFileName = desktopSource.split('/').last;
  final targetPath = '$desktopDir/$desktopFileName';

  // 7. 检查是否已存在（不覆盖）
  final targetFile = File(targetPath);
  if (await targetFile.exists()) {
    return '快捷方式已存在，不会覆盖: $targetPath';
  }

  // 8. 复制 .desktop 文件到桌面
  final sourceFile = File(desktopSource);
  if (!await sourceFile.exists()) {
    return '源 desktop 文件不存在: $desktopSource';
  }
  await sourceFile.copy(targetPath);

  // 9. 设置可执行权限 (0755)
  await Process.run('chmod', ['755', targetPath]);

  AppLogger.info('[LinglongCli] 桌面快捷方式创建成功: $appId -> $targetPath');

  return '已创建桌面快捷方式: $targetPath';
}
```

**Desktop Entry Specification 要点**:
- 文件名: `org.example.AppName.desktop` (reverse DNS 命名)
- 编码: UTF-8
- 必需字段: `Type`, `Name`, `Exec`
- 推荐字段: `Comment`, `Icon`, `Categories`, `StartupNotify`
- 权限: `0755` 或 `0700` (owner 可执行)

**示例**:
```ini
[Desktop Entry]
Version=1.0
Type=Application
Name=Example App
Comment=示例应用
Exec=/usr/bin/example-app %F
Icon=example-app
Terminal=false
Categories=Utility;Application;
StartupNotify=true
```

## 安全性要求

- **所有权**: 必须属于当前用户
- **权限**: `0755` (rwxr-xr-x) - owner 可执行
- **符号链接**: 应该跟随并验证目标文件

## 国际化支持 (I18n)

**XDG 多语言支持**:
- 默认 `Name`, `Comment` 字段为英文
- 通过 `Name[zh_CN]`, `Comment[zh_CN]` 提供本地化

```ini
[Desktop Entry]
Name=Example App
Name[zh_CN]=示例应用
Comment=An example application
Comment[zh_CN]=这是一个示例应用
```

## 错误处理

### 应该捕获的错误:

1. **环境错误**:
   - HOME 目录不存在
   - 桌面目录不存在或无权限
   - xdg-user-dir 命令不可用

2. **应用错误**:
   - 应用未安装
   - ll-cli content 失败
   - .desktop 文件不存在

3. **文件系统错误**:
   - 磁盘空间不足
   - 权限不足
   - 符号链接循环

## 测试验证

已添加测试用例验证规范遵循：
- ✅ 应该使用 XDG 规范获取桌面目录
- ✅ 应该支持中文桌面路径
- ✅ 应该支持用户自定义桌面路径

测试文件: `test/unit/data/repositories/linglong_cli_repository_impl_test.dart`

## 修复历史

### 修复前问题 (🔴 严重)

```dart
// ❌ 硬编码桌面路径，不符合 XDG 规范
final home = Platform.environment['HOME'];
final desktopDir = '$home/Desktop';  // 不支持国际化路径
```

**问题**:
- 硬编码 `$HOME/Desktop`
- 不支持非英文系统（如中文的 `~/桌面`）
- 不支持用户自定义桌面路径
- 违反 XDG Base Directory Specification

### 修复后方案 (✅ 已修复)

```dart
// ✅ 按 XDG 规范优先级获取桌面目录
final desktopDir = await _getDesktopDirectory();
```

**优势**:
- 支持国际化桌面路径
- 支持用户自定义配置
- 符合 Linux 桌面标准规范
- 完整的 fallback 链

## 参考资料

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)
- [xdg-user-dir(1) - Linux manual](https://man7.org/linux/man-pages/man1/xdg-user-dir.1.html)
- [XDG User Directories](https://wiki.archlinux.org/title/XDG_user_directories)
- [xdg-user-dirs 项目](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/)

## 相关文件

- 实现代码: `lib/data/repositories/linglong_cli_repository_impl.dart`
- 测试代码: `test/unit/data/repositories/linglong_cli_repository_impl_test.dart`
- UI 组件: `lib/presentation/widgets/app_detail_secondary_actions.dart`
- 页面逻辑: `lib/presentation/pages/app_detail/app_detail_page.dart`