# 玲珑应用商店 (Flutter 版本)

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Build](https://github.com/HanHan666666/flutter-linglong-store/workflows/CI/badge.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B.svg?logo=flutter)
![Platform](https://img.shields.io/badge/platform-Linux-FCC624.svg?logo=linux)
![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)

本仓库是玲珑应用商店从旧版 Tauri/React 迁移到 Flutter 的实现，目标是 **UI 像素级一致** 与 **业务逻辑等价**。

**[English Version](README_EN.md) | 中文文档**

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

完整的技术文档位于 `docs/` 目录：
- **[架构设计](docs/02-flutter-architecture.md)** - 详细架构和目录结构
- **[UI 规范](docs/03a-ui-design-tokens.md)** - 设计系统基础
- **[测试规范](docs/06-testing-and-performance-spec.md)** - 测试覆盖和性能要求
- **[迁移计划](docs/01-migration-plan.md)** - 与 Tauri/React 版本的对照

## 🤝 贡献指南

我们欢迎社区贡献！无论是 Bug 报告、功能建议、文档改进还是代码提交，我们都诚挚感谢。

详细贡献指南请查看 **[CONTRIBUTING.md](CONTRIBUTING.md)**，包括：
- 如何提交 Issue 和 Pull Request
- 开发环境搭建步骤
- 代码规范和提交规范（Conventional Commits）
- PR 审核流程
- 新手入门提示

### 快速贡献步骤

1. Fork & Clone 本仓库
2. 创建功能分支（`feat/your-feature`）
3. 遵循代码规范进行开发
4. 运行 `flutter analyze` 和 `flutter test` 验证
5. 提交 Pull Request 并清晰描述改动

## 💬 社区与支持

- **💬 社区讨论**: [bbs.deepin.org.cn](https://bbs.deepin.org.cn) - 深度社区论坛
- **🐛 问题反馈**: [GitHub Issues](https://github.com/HanHan666666/flutter-linglong-store/issues)
- **📧 邮件联系**: 通过 GitHub 联系项目维护者

## 📄 许可证

本项目基于 **MIT 许可证** 开源 - 详细内容请查看 [LICENSE](LICENSE)。

