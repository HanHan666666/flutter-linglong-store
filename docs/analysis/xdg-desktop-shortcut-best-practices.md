# XDG Desktop Shortcut 最佳实践

## XDG 规范要求

### 1. 桌面目录获取 (XDG Base Directory Specification)

**正确方式**:
```dart
Future<String> getDesktopDirectory() async {
  // 优先级1: XDG_DESKTOP_DIR 环境变量
  final xdgDesktop = Platform.environment['XDG_DESKTOP_DIR'];
  if (xdgDesktop != null && xdgDesktop.isNotEmpty) {
    return xdgDesktop;
  }

  // 优先级2: 通过 xdg-user-dir 命令获取
  try {
    final result = await Process.run('xdg-user-dir', ['DESKTOP']);
    if (result.exitCode == 0) {
      final path = (result.stdout as String).trim();
      if (path.isNotEmpty && await Directory(path).exists()) {
        return path;
      }
    }
  } catch (_) {}

  // 优先级3: 解析 ~/.config/user-dirs.dirs
  try {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final userDirsFile = File('$home/.config/user-dirs.dirs');
      if (await userDirsFile.exists()) {
        final content = await userDirsFile.readAsString();
        final match = RegExp(r'XDG_DESKTOP_DIR="([^"]+)"').firstMatch(content);
        if (match != null) {
          return match.group(1)!
              .replaceAll(r'\$HOME', home)
              .replaceAll(r'$HOME', home);
        }
      }
    }
  } catch (_) {}

  // Fallback: 默认 ~/Desktop
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) {
    throw Exception('无法获取 HOME 目录');
  }
  return '$home/Desktop';
}
```

### 2. .desktop 文件规范

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

### 3. 安全性要求

- **所有权**: 必须属于当前用户
- **权限**: 必须不能被其他用户写入
- **符号链接**: 应该跟随并验证目标文件

```dart
Future<void> setDesktopFilePermissions(String path) async {
  final file = File(path);

  // 设置权限为 0755 (rwxr-xr-x)
  // Owner: rwx (读/写/执行)
  // Group: r-x (读/执行)
  // Other: r-x (读/执行)
  await Process.run('chmod', ['0755', path]);

  // 确保文件属于当前用户
  // (可选,取决于安全策略)
}
```

### 4. 国际化 (I18n)

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

### 5. 文件冲突处理

**最佳实践**:
1. 检查文件是否已存在
2. 如果存在,提示用户选择:
   - 覆盖
   - 重命名 (添加后缀)
   - 取消

```dart
Future<String> resolveDesktopFilePath({
  required String desktopDir,
  required String fileName,
  bool overwrite = false,
}) async {
  var targetPath = '$desktopDir/$fileName';

  if (!overwrite && await File(targetPath).exists()) {
    // 添加时间戳后缀
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = fileName.replaceAll('.desktop', '');
    targetPath = '$desktopDir/${baseName}_$timestamp.desktop';
  }

  return targetPath;
}
```

## 错误处理最佳实践

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

4. **安全错误**:
   - .desktop 文件指向危险路径
   - Exec 包含危险命令

## 测试用例

```dart
test('应该正确获取 XDG 桌面目录', () async {
  // Mock 环境变量
  // Mock xdg-user-dir 命令
  // Mock user-dirs.dirs 文件
  // 验证优先级顺序
});

test('应该正确处理非标准桌面路径', () async {
  // 测试中文路径 ~/桌面
  // 测试自定义路径
});

test('应该正确处理文件冲突', () async {
  // 测试覆盖策略
  // 测试重命名策略
});
```

## 参考资料

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Desktop Entry Specification](https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html)
- [xdg-user-dir(1) - Linux manual](https://man7.org/linux/man-pages/man1/xdg-user-dir.1.html)
- [XDG User Directories](https://wiki.archlinux.org/title/XDG_user_directories)

## 迁移建议

### 当前问题严重程度: 🔴 **高**

**建议立即修复**:
1. 使用 `xdg-user-dir DESKTOP` 获取桌面路径
2. 实现完整的 fallback 链
3. 添加权限验证和安全检查
4. 添加单元测试和集成测试

**优先级**:
- P0: 修复桌面路径硬编码
- P1: 添加错误处理和测试
- P2: 添加 .desktop 文件验证
- P3: 支持国际化字段