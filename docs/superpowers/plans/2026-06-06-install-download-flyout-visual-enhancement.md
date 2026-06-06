# 安装飞入下载中心动画视觉增强实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 增强安装/更新成功入队后的图标飞入下载中心反馈，并继续遵循 Linux/Flutter 暴露的系统动画禁用偏好。

**Architecture:** 继续复用 `InstallToDownloadFlyoutLayer` 作为唯一动画入口，不修改安装队列、详情页业务入队逻辑或下载中心弹窗。系统动画开关以 `MediaQuery.disableAnimations` 为主，避免新增发行版分支判断。

**Tech Stack:** Flutter Widget、`AnimationController`、`AnimatedBuilder`、Widget Test、Markdown 文档。

---

### Task 1: 系统禁用动画回归测试

**Files:**
- Modify: `test/widget/presentation/widgets/install_to_download_flyout_test.dart`

- [x] **Step 1: 写入失败测试**

新增一个 Widget 测试：外层 `MediaQuery` 设置 `disableAnimations: true`，点击触发 `launch()` 后应返回 `false`，并且不出现 `install-download-flyout` 或 `install-download-target-pulse`。

- [x] **Step 2: 运行目标测试确认行为**

Run: `flutter test test/widget/presentation/widgets/install_to_download_flyout_test.dart`

Expected: 当前实现已经支持该行为，若测试直接通过，说明系统动画开关链路已有覆盖；继续保留测试作为回归约束。

### Task 2: 增强统一飞行动画层

**Files:**
- Modify: `lib/presentation/widgets/install_to_download_flyout.dart`

- [x] **Step 1: 调整飞行动画节奏**

将飞行时长调整到约 `920ms`，脉冲时长调整到约 `520ms`，让用户有足够时间感知源点、轨迹和落点。

- [x] **Step 2: 强化飞行图标视觉**

在飞行图标外增加主题主色描边、柔和光晕和更稳定的尺寸过渡；末段不再过早淡出，避免落点前视觉消失。

- [x] **Step 3: 强化下载中心落点反馈**

下载中心脉冲改为主题主色双层圆环，并增加短暂中心高亮；使用主题色和暗色阴影，保证明暗主题都可见。

### Task 3: 文档同步

**Files:**
- Modify: `docs/20-install-download-center-flyout.md`

- [x] **Step 1: 记录系统动画开关策略**

明确当前策略：依赖 Flutter `MediaQuery.disableAnimations`，该值由 Flutter Linux 对系统减少/禁用动画偏好做平台适配；暂不新增发行版专有读取逻辑。

- [x] **Step 2: 记录视觉约束**

记录飞行动画应包含可辨识轨迹、图标光晕、落点双层脉冲，并保持不参与业务逻辑。

### Task 4: 验证与提交

**Files:**
- Test: `test/widget/presentation/widgets/install_to_download_flyout_test.dart`
- Test: `test/widget/presentation/pages/app_detail/app_detail_page_test.dart`
- Analyze: `flutter analyze`

- [x] **Step 1: 运行目标测试**

Run: `flutter test test/widget/presentation/widgets/install_to_download_flyout_test.dart`

- [x] **Step 2: 运行详情页相关测试**

Run: `flutter test test/widget/presentation/pages/app_detail/app_detail_page_test.dart`

- [x] **Step 3: 运行静态分析**

Run: `flutter analyze`

Actual: 全量分析报告 51 个既有 warning/info，未命中本次修改文件；随后运行 `flutter analyze lib/presentation/widgets/install_to_download_flyout.dart test/widget/presentation/widgets/install_to_download_flyout_test.dart`，本次改动文件无 analyzer 问题。

- [x] **Step 4: 提交**

Run:

```bash
git add lib/presentation/widgets/install_to_download_flyout.dart test/widget/presentation/widgets/install_to_download_flyout_test.dart docs/20-install-download-center-flyout.md docs/superpowers/plans/2026-06-06-install-download-flyout-visual-enhancement.md
git commit -m "feat: 增强安装飞入下载中心动画"
```
