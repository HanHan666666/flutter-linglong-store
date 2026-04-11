# 玲珑应用商店 (Flutter 版本)

本仓库是玲珑应用商店从旧版 Tauri/React 迁移到 Flutter 的实现，目标是 **UI 像素级一致** 与 **业务逻辑等价**。

## 环境要求

- Flutter SDK (最新稳定版)
- Dart SDK
- Linux 桌面环境

## 快速开始

### 1. 安装依赖

```bash
flutter pub get
```

### 2. 生成代码文件

本项目使用 Freezed 和 Riverpod 等代码生成工具，**运行前必须先生成代码文件**：

```bash
dart run build_runner build --delete-conflicting-outputs
```

> **重要提示**：如果缺少 `.freezed.dart` 或 `.g.dart` 文件，会导致编译错误。
> 每次修改带有 `@freezed` 或 `@riverpod` 注解的文件后，都需要重新执行此命令。

### 3. 运行应用 (开发模式)

```bash
flutter run -d linux
```

### 4. 构建发布版本

```bash
flutter build linux --release
```

## 常用命令

```bash
# 代码生成（Freezed/Retrofit/Riverpod）
dart run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 运行测试
flutter test

# 运行单个测试文件
flutter test test/unit/core/format_utils_test.dart

# Profile 性能验证
flutter run -d linux --profile
```

## 打包构建

```bash
# DEB 包
time ./build/package-deb.sh

# RPM 包
./build/package-rpm.sh

# AppImage 包
./build/package-appimage.sh
```

## 项目架构

整体为分层架构（依赖方向：Presentation → Application → Domain ← Data ← Platform）：

- **Presentation**：页面与通用组件
- **Application**：业务编排（Controllers/Services/Providers）
- **Domain**：纯模型与 Repository 接口
- **Data**：Repository 实现、API/CLI 数据源
- **Platform**：`ll-cli` 执行器、进程管理、窗口管理等

## 文档

详细的架构和开发指南请查看 [AGENTS.md](AGENTS.md)。
