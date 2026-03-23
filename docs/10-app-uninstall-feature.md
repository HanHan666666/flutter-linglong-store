# 应用卸载功能文档

## 概述

本文档记录玲珑应用商店 Flutter 版本的**应用卸载功能**的完整设计、实现细节和 Bug 修复历史。

---

## 1. 功能流程

### 1.1 完整卸载流程图

```
用户点击卸载按钮
    │
    ▼
┌─────────────────────────────────┐
│  AppUninstallService.uninstall() │
└─────────────────────────────────┘
    │
    ├── 1. 检查应用是否正在运行
    │       │
    │       ├── 运行中 → 显示「强制关闭并卸载」确认弹窗
    │       │           │
    │       │           └── 用户确认 → 依次 kill 所有运行实例
    │       │
    │       └── 未运行 → 显示常规卸载确认弹窗
    │
    ├── 2. 用户确认？
    │       │
    │       ├── 否/取消 → 返回 false，流程结束
    │       │
    │       └── 是 → 继续执行
    │
    ├── 3. 执行卸载命令
    │       │
    │       ▼
    │   ┌─────────────────────────────┐
    │   │  PKExec 弹出授权窗口          │
    │   │  (需要管理员权限)             │
    │   └─────────────────────────────┘
    │       │
    │       ├── 用户输入密码 → 授权成功 → ll-cli 执行卸载
    │       │
    │       └── 用户点击「取消」→ 授权失败 → exitCode=126
    │
    ├── 4. 处理结果
    │       │
    │       ├── 成功 (exitCode=0)
    │       │       │
    │       │       ├── 从已安装列表移除
    │       │       ├── 刷新更新列表
    │       │       ├── 上报卸载统计
    │       │       └── 显示成功提示
    │       │
    │       └── 失败 (exitCode≠0)
    │               │
    │               └── 抛出 UninstallException
    │                       │
    │                       └── 显示失败提示
    │
    ▼
返回结果 (true/false)
```

### 1.2 关键状态检查

| 检查项 | 条件 | 处理方式 |
|--------|------|----------|
| 应用是否运行 | `runningApps.any((r) => r.appId == app.appId)` | 显示「强制关闭并卸载」弹窗 |
| kill 是否成功 | `runningProcessProvider.killApp(running)` | 失败时中止卸载 |
| 卸载命令结果 | `exitCode == 0` | 成功刷新状态，失败抛异常 |

---

## 2. 架构设计

### 2.1 分层架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌────────────────────┐    ┌────────────────────┐           │
│  │   my_apps_page     │    │  app_detail_page   │           │
│  │   (我的应用页)      │    │   (应用详情页)      │           │
│  └─────────┬──────────┘    └─────────┬──────────┘           │
│            │                         │                       │
│            └──────────┬──────────────┘                       │
│                       │                                      │
│                       ▼                                      │
│            ┌────────────────────┐                            │
│            │ AppUninstallService │ ← 统一入口                 │
│            │    (卸载服务)        │                           │
│            └─────────┬──────────┘                            │
└──────────────────────┼───────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────┐
│                Application Layer                              │
│                       ▼                                       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   Providers                             │  │
│  │  • runningProcessProvider (运行中进程)                   │  │
│  │  • installedAppsProvider (已安装列表)                    │  │
│  │  • updateAppsProvider (更新列表)                         │  │
│  │  • analyticsRepositoryProvider (统计上报)                │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────┐
│                    Domain Layer                               │
│                       ▼                                       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              LinglongCliRepository                      │  │
│  │              (Repository 接口)                           │  │
│  │  uninstallApp(appId, version) → Future<String>          │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
                       │
┌──────────────────────┼───────────────────────────────────────┐
│                     Data Layer                                │
│                       ▼                                       │
│  ┌────────────────────────────────────────────────────────┐  │
│  │         LinglongCliRepositoryImpl                       │  │
│  │              (Repository 实现)                           │  │
│  │  失败时抛出 UninstallException                           │  │
│  └─────────────────┬──────────────────────────────────────┘  │
│                    │                                          │
│                    ▼                                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              CliExecutor                                │  │
│  │           (ll-cli 命令执行器)                            │  │
│  │  execute(['uninstall', appId]) → CliOutput              │  │
│  └────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### 2.2 核心组件

#### 2.2.1 AppUninstallService

**位置**: `lib/application/services/app_uninstall_service.dart`

**职责**:
- 统一封装卸载逻辑，确保所有入口行为一致
- 处理运行中检测、确认弹窗、kill 进程、执行卸载、刷新状态、上报统计

**接口**:
```dart
class AppUninstallService {
  /// 执行卸载流程
  ///
  /// [context] BuildContext，用于显示弹窗和 SnackBar
  /// [app] 要卸载的应用信息
  ///
  /// 返回：
  /// - `true` - 卸载成功
  /// - `false` - 用户取消或卸载失败
  Future<bool> uninstall(BuildContext context, InstalledApp app);
}
```

#### 2.2.2 UninstallException

**位置**: `lib/core/network/api_exceptions.dart`

**用途**: 当卸载操作失败时抛出，确保调用方必须处理错误

```dart
class UninstallException extends AppException {
  const UninstallException(this.message, {this.appId, this.exitCode});

  final String? appId;      // 应用 ID
  final int? exitCode;      // 退出码
  final String message;     // 错误信息

  @override
  String get userMessage => '卸载失败：$message';
}
```

#### 2.2.3 LinglongCliRepository.uninstallApp

**位置**: `lib/data/repositories/linglong_cli_repository_impl.dart`

**关键修改**:
```dart
// 修复前（错误）- 返回错误字符串
if (!output.success) {
  return _messages.uninstallFailed(output.stderr);
}

// 修复后（正确）- 抛出异常
if (!output.success) {
  throw UninstallException(
    output.stderr.isNotEmpty ? output.stderr : '卸载命令执行失败',
    appId: appId,
    exitCode: output.exitCode,
  );
}
```

---

## 3. Bug 修复历史

### 3.1 Bug 描述

**症状**: 点击卸载按钮后，PKExec 弹出授权窗口；若用户未输入密码直接点击「取消」，系统仍提示"卸载成功"。

**影响版本**: 2026-03-23 之前的版本

### 3.2 根因分析

#### 数据流分析

```
用户点击卸载按钮
    ↓
ConfirmDialog.showUninstall() → 用户确认
    ↓
repo.uninstallApp() → ll-cli uninstall
    ↓
PKExec 弹出授权窗口
    ↓
用户点击「取消」→ ll-cli 返回非零退出码
    ↓
output.success = false
    ↓
uninstallApp() 返回 "卸载失败: xxx" 字符串  ← 问题点
    ↓
app_detail_page.dart 忽略返回值，直接显示"卸载成功"  ← 问题点
```

#### 问题代码

**问题 1: Repository 返回错误字符串而非抛异常**

```dart
// lib/data/repositories/linglong_cli_repository_impl.dart
Future<String> uninstallApp(String appId, String version) async {
  if (output.success) {
    return output.stdout;
  } else {
    return _messages.uninstallFailed(output.stderr);  // 返回错误字符串
  }
}
```

**问题 2: app_detail_page.dart 未检查返回值**

```dart
// lib/presentation/pages/app_detail/app_detail_page.dart
Future<void> _uninstallApp(InstalledApp app) async {
  try {
    final cliRepo = ref.read(linglongCliRepositoryProvider);
    await cliRepo.uninstallApp(app.appId, app.version);  // 返回值被忽略

    // 直接执行成功逻辑，不检查结果
    ref.read(installedAppsProvider.notifier).removeApp(app.appId, app.version);
    // 显示"卸载成功"提示
  } catch (e) {
    // 永远不会执行，因为 uninstallApp 不抛异常
  }
}
```

### 3.3 修复方案

#### 方案原则

参考 Rust 版本的 `useAppUninstall` hook 设计，遵循「统一入口」原则：

> 能收敛的业务逻辑要集中封装（如卸载流程用 `useAppUninstall`），避免在多个页面/组件里写重复弹窗或副作用。

#### 修复内容

| 步骤 | 修改内容 | 文件 |
|------|----------|------|
| 1 | 新增 `UninstallException` 异常类 | `lib/core/network/api_exceptions.dart` |
| 2 | Repository 失败时抛出异常 | `lib/data/repositories/linglong_cli_repository_impl.dart` |
| 3 | 创建 `AppUninstallService` 统一服务 | `lib/application/services/app_uninstall_service.dart` |
| 4 | 创建 Provider | `lib/application/providers/app_uninstall_provider.dart` |
| 5 | 修改 my_apps_page.dart 使用新服务 | `lib/presentation/pages/my_apps/my_apps_page.dart` |
| 6 | 修改 app_detail_page.dart 使用新服务 | `lib/presentation/pages/app_detail/app_detail_page.dart` |

### 3.4 修复后行为

```
用户点击卸载按钮
    ↓
PKExec 弹出授权窗口
    ↓
用户点击「取消」→ ll-cli 返回 exitCode=126
    ↓
CliOutput.success = false
    ↓
Repository 抛出 UninstallException  ← 修复点
    ↓
AppUninstallService 捕获异常  ← 修复点
    ↓
显示"卸载失败: Request dismissed"  ← 正确行为
```

---

## 4. PKExec 退出码参考

| 退出码 | 含义 | 处理方式 |
|--------|------|----------|
| 0 | 成功 | 正常完成 |
| 1 | 一般错误 | 显示错误信息 |
| 126 | 命令无法执行（授权取消） | 显示"授权已取消" |
| 127 | 命令未找到 | 显示"ll-cli 未安装" |

---

## 5. 测试覆盖

### 5.1 单元测试

**文件**: `test/unit/data/repositories/linglong_cli_repository_impl_test.dart`

**覆盖场景**:
- ✅ PKExec 授权取消场景
- ✅ 卸载命令执行失败场景
- ✅ 异常继承关系验证
- ✅ userMessage 格式验证
- ✅ 可序列化为用户友好信息

### 5.2 集成测试

**文件**: `integration_test/flows/uninstall_flow_test.dart`

**覆盖场景**:
- 卸载确认弹窗显示
- 取消确认对话框不执行卸载
- 卸载成功后应用从列表移除
- 卸载成功后显示成功提示
- 卸载失败时显示错误信息

---

## 6. 参考

### 6.1 Rust 版本实现

**文件**: `rust-linglong-store/src/hooks/useAppUninstall.ts`

**设计要点**:
- 统一封装卸载逻辑
- 检查运行中状态
- 失败时抛出异常
- 上报卸载统计

### 6.2 相关文档

- [Flutter 架构文档](./02-flutter-architecture.md)
- [测试规范文档](./06-testing-and-performance-spec.md)
- [运行时序图](./07-runtime-sequence-and-state-diagrams.md)

---

## 变更记录

| 日期 | 内容 |
|------|------|
| 2026-03-23 | 初始文档，记录卸载功能设计和 Bug 修复 |