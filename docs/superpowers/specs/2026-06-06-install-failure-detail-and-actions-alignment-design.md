# 安装失败详情与下载中心操作行对齐设计

**日期:** 2026-06-06
**状态:** 已确认
**范围:** ll-cli 安装失败文案与下载管理弹窗失败项布局

## 背景

下载中心失败项当前存在两个问题：

1. `ll-cli --json` 返回 `{"code":-1,"message":"..."}` 时，UI 只展示“安装失败: 通用错误”，没有展示 `message` 中真正的失败详情，例如 DNS 解析失败。
2. 失败状态 tag 位于应用标题行内部，而“复制日志 / 重试 / 删除”位于右侧操作区，两组控件不在同一条水平线上。

## 目标

- 只要 `ll-cli` JSON 错误事件里有非空 `message`，失败提示必须展示这个详情。
- `code=-1` 不再展示“通用错误”，基础摘要只用“安装失败”。
- 当存在 `message` 详情时，最终提示形如：`安装失败：<message>`。
- 其他错误码如果同时提供 `message`，也必须把 `message` 追加到错误提示里。
- 下载中心任务卡片右侧操作行统一展示状态 tag 和操作按钮，保证“失败 / 复制日志 / 重试 / 删除”同一行居中对齐。

## 方案

### 错误文案

在 `LinglongCliRepositoryImpl` 处理 `InstallPhase.failed` 时，不再只按错误码生成最终 `errorMessage`。改为：

1. 先取错误码摘要。
2. `code=-1` 的摘要强制用当前操作的失败基础文案，例如“安装失败”或“更新失败”。
3. 如果 `rawMessage` / JSON `message` 非空，把详情追加到摘要后面。
4. 如果详情已经等于摘要，避免重复拼接。

这样 `InstallQueue._markFailed()` 仍然接收规范化后的失败文案，发行版提示追加逻辑继续集中在队列层。

### 下载中心布局

调整 `_TaskCard` 顶部结构：

- 应用名称行只显示应用名称。
- 右侧 `_buildActionButtons()` 先渲染 `_buildStatusPill()`，再渲染复制日志、重试、删除等按钮。
- 操作 Row 使用 `crossAxisAlignment: CrossAxisAlignment.center`。

这避免状态 tag 与标题文本基线绑在一起，保证 tag 与按钮视觉对齐。

## 测试

- Repository 单元测试覆盖 `code=-1 + message` 时错误文案包含“安装失败”和原始 message，且不包含“通用错误”。
- Repository 单元测试覆盖其他错误码仍追加 message。
- 下载中心 widget 测试覆盖失败项中“失败 / 复制日志 / 重试 / 删除”属于同一右侧操作行。

## 验收标准

- 截图中的 DNS 失败会显示 `安装失败：ostree_repo_pull_with_options ... Could not resolve hostname`。
- 下载中心不再出现“通用错误”作为 `code=-1` 展示文案。
- 失败 tag 与复制日志、重试、删除按钮水平对齐。
