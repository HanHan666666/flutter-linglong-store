# og 协议网页安装拉起设计

## 背景

网页版商店旧实现点击安装时使用 `og://<appId>` 交给系统协议处理器拉起本地“玲珑安装程序”。Flutter 商店需要承接同一入口：用户在网页端点击安装后，系统拉起当前 Flutter 应用商店，并由 Flutter 商店开始安装。

本次只支持旧协议 `og://appId`，不新增其他协议名称或 URL 格式。`og` 本身不是 FreeDesktop 的标准协议名；Linux 桌面上的规范实现方式是按 XDG MIME/desktop entry 机制把它注册为 URL scheme handler。

## XDG 规范约束

桌面包必须在 `.desktop` 文件中声明：

```ini
Exec=linglong-store %u
MimeType=x-scheme-handler/og;
```

设计依据：

- Desktop Entry Specification：`Exec` 的 `%u` 表示单个 URL；应用声明能处理的 MIME 类型通过 `MimeType`。
- MIME Apps Specification：默认应用由 `mimeapps.list` 决定，应用 `.desktop` 只能声明支持能力，不应在运行时强行覆盖用户默认设置。
- `xdg-mime`：设置默认 handler 需要应用已安装且 `.desktop` 已列出对应 MIME 类型；请求可能受系统策略或用户确认影响。

因此本项目只在打包元数据中声明 `x-scheme-handler/og`。是否成为默认 handler 交给包管理器、桌面环境和用户配置处理，不在应用运行时写 `mimeapps.list`。

## 目标体验

1. 用户在网页商店点击安装。
2. 浏览器打开 `og://appId`。
3. 系统将 URL 交给 Flutter 商店。
4. Flutter 商店聚焦主窗口。
5. 应用启动流程已完成时，立即解析应用详情并入队安装。
6. 应用启动流程未完成时，暂存请求，启动完成后再处理。
7. 入队成功后提示用户已加入下载管理；重复、无效、环境异常和详情缺失都给明确反馈。

## 架构

协议处理分为三层：

- Platform：Linux runner / 单实例 socket 负责把命令行 URL 传给 Dart。冷启动通过 `main(List<String> args)` 接收；已有实例通过 Unix socket 转发 URL 并聚焦窗口。
- Core：`OgProtocolRequest` 负责解析和校验 `og://appId`，仅接受非空 appId，不执行 URL 中的任何命令。
- Application：`OgInstallController` 负责等待启动完成、检查玲珑环境、获取应用详情、复用 `appOperationQueueControllerProvider` 入队安装。

Presentation 只负责展示提示，不直接调用 `ll-cli`。

## URL 规则

只支持以下形式：

```text
og://org.example.App
```

解析规则：

- scheme 必须是 `og`，大小写归一为小写。
- appId 来自 `Uri.host`；若 host 为空，再允许从 `Uri.path` 去掉前导 `/` 后读取，用于兼容少数浏览器可能传入的 `og:///appId`。
- 不接受空 appId。
- query 参数暂不使用，避免扩大旧协议语义。

## 安装策略

入队前先通过 `AppRepository.getAppDetail(appId)` 获取当前系统架构下的应用详情，得到应用名称、图标、版本、仓库和模块。入队使用现有统一入口：

```dart
appOperationQueueControllerProvider.enqueueAppOperation(
  EnqueueAppOperationParams(
    kind: InstallTaskKind.install,
    appId: detail.appId,
    appName: detail.name,
    icon: detail.icon,
    version: detail.version,
  ),
)
```

安装执行仍由 `InstallQueue` 串行处理，不新增 `ll-cli` 调用。

## 边界处理

- 已有任务：`InstallQueue` 返回空 taskId 时提示该应用已在队列或正在处理。
- 环境未就绪：如果 `linglongEnvProvider.result?.isOk` 不是 true，不入队，提示用户先处理玲珑环境。
- 启动未完成：请求进入内存队列，待 `launchSequenceProvider.isCompleted` 后处理。
- 详情失败：提示应用信息获取失败，不入队。
- 多次点击：按 appId 去重，避免网页重复触发导致重复排队。

## 测试

- 单元测试覆盖 `og://appId`、`og:///appId`、错误 scheme、空 appId。
- 单元测试覆盖单实例消息序列化和 URL 转发解析。
- 单元测试覆盖 `OgInstallController` 的启动完成等待、环境拦截、详情入队、重复请求。
- 打包元数据测试覆盖 `.desktop` 包含 `%u` 和 `x-scheme-handler/og`。

