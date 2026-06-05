# 2026-05-24 Loong64 GitHub Actions 交接报告

## 任务目标

本次任务的目标是为仓库补齐 **Loong64（龙芯）GitHub Actions 构建与发布链路**，要求如下：

1. **Nightly**：Loong64 不与现有 `Nightly` 主链串行绑定，而是走 **独立 workflow 异步补传**，在当前 nightly prerelease 成功后把 `loong64` 资产追加进去。
2. **Release**：正式发版可以并入现有 `release.yml`，但只要求 Loong64 产出 **`bundle + deb`**。
3. Loong64 构建使用 **QEMU + `linux/loong64` 容器**。
4. Flutter SDK 使用仓库外部提供的 Loong64 SDK：
   - 仓库：`Flutter-Dart-loong64/flutter-loong64-releases`
   - 当前默认 pin：`v2026.05.20.1`
5. 要把整套链路 **开发、提交、触发、远端验证** 到可交付状态。

---

## 当前结论（先看这个）

- `Nightly` 主链（`amd64 + arm64`）已经稳定，最近一次 **成功**：`26352939277`
- `Nightly Loong64` 的自动触发机制已经跑通过，历史上有 **成功样本**：`26352685221`
- `Release` 已经并入 Loong64 `bundle + deb` 构建逻辑
- **当前唯一核心 blocker**：Loong64 Flutter SDK 在补本地 `.git` 后，Flutter 启动脚本会误判 `flutter_tools.stamp` 失效，继而尝试下载一个**并不存在的 upstream `linux loong64 Dart SDK zip`**，最终拿到 259-byte 错误页，`unzip` 失败
- 我已经在本地补了一个**未提交修复**：在 synthetic git bootstrap 后，重写 `bin/cache/flutter_tools.stamp`，让 SDK 继续使用自带 snapshot / dart-sdk，而不是走那条错误下载路径
- **这个最新修复还没有 push，也还没有远端重新验证**

一句话版：**功能主体已做完，验证已逼近终点，但最后卡在 Loong64 Flutter SDK bootstrap/cache 行为；最新本地修复已写好，下一位 AI 需要继续提交、推送、重跑 workflow。**

---

## 本次已经完成了什么

### 1. 设计与文档

已落地：

- `docs/superpowers/specs/2026-05-24-loong64-release-workflow-design.md`
- `docs/superpowers/plans/2026-05-24-loong64-release-workflow.md`
- `docs/12-github-workflow-maintenance.md`
- `AGENTS.md`
- `CLAUDE.md`
- `/memories/repo/loong64-actions.md`

文档里已经记录了：

- Loong64 nightly 采用“主 Nightly 成功后异步补传”的策略
- Release 中 Loong64 只并入 `bundle + deb`
- `AUR / UOS Store` 仍然只消费 `amd64 + arm64`
- Loong64 Flutter SDK 当前必须 pin 到 `v2026.05.20.1`
- `v3.45.0-1.0.pre-198` 虽然是较新的 preview，但会在 `native.git` 缺 `pkgs/data_assets` 时失败，不适合当前链路

### 2. Workflow 与脚本实现

已完成的关键新增/修改：

- 新增 `.github/workflows/nightly-loong64.yml`
  - 触发源：`workflow_run`（Nightly completed）+ `workflow_dispatch`
  - 作用：从当前 nightly prerelease 读取 notes / assets，补传 Loong64 资产并刷新 hash / notes

- 修改 `.github/workflows/release.yml`
  - 新增 `build-loong64` job
  - 并入 Loong64 `bundle + deb`
  - 保持 `publish-aur` 与 `update-uos-store` 只处理 `amd64 + arm64`

- 新增 / 修改构建脚本：
  - `build/scripts/build-loong64-in-container.sh`
  - `build/scripts/install-loong64-build-deps.sh`
  - `build/scripts/augment-nightly-release-notes-loong64.sh`
  - `build/scripts/append-release-asset-hashes.sh`
  - `build/scripts/validate-release-workflow.sh`
  - `build/scripts/nightly-cli-smoke-test.sh`
  - `build/scripts/release-cli-smoke-test.sh`

- 修复正式发版版本解析问题：
  - `tool/release/release_version.dart`
  - `test/unit/tool/release/release_version_test.dart`

### 3. 多轮真实 GitHub Actions 验证

已经做过多轮真实远端验证，不是纸上谈兵。

#### 已成功的关键运行

- `Nightly 26351835770`：success
- `Nightly 26352196197`：success
- `Nightly 26352757924`：success
- `Nightly 26352939277`：success
- `Nightly Loong64 26352685221`（head `e932a34`）：success

#### 已明确失败并定位根因的关键运行

- `Release 26352940074`
  - 失败 job：`77574311085`
  - 根因：Flutter 在 packaged SDK bootstrap 后尝试下载 `Linux loong64 Dart SDK`，拿到 `259-byte` 非 zip 文件，`unzip` 失败

- `Nightly Loong64 26353095846`
  - 失败 job：`77574692209`
  - 根因与上面一致：同样卡在下载不存在的 `dart-sdk-linux-loong64.zip`

---

## 已经排掉的坑

这个任务不是第一次失败，前面已经连续解决过多轮 blocker：

1. **`dubious ownership` / `safe.directory` 问题**
   - 已修复：为 workspace 和 Loong64 Flutter SDK 都加了 `git safe.directory`

2. **Loong64 SDK 选型错误**
   - `v3.45.0-1.0.pre-198` 会在 `flutter pub get` 阶段因 `native.git` 缺 `pkgs/data_assets/pubspec.yaml` 失败
   - 已切回并 pin 到上游明确验证过 `linglong-store` 的 `v2026.05.20.1`

3. **packaged SDK 无 `.git`**
   - Flutter wrapper 会报：`The Flutter directory is not a clone of the GitHub project`
   - 已修复：在容器中为解压后的 SDK 补一个最小本地 git repo

4. **SDK 路径位于主仓库内部，误命中父仓库 `.git`**
   - 仅用 `git rev-parse HEAD` 不可靠
   - 已修复：要求 `git rev-parse --show-toplevel == FLUTTER_ROOT`

5. **当前最新坑：bootstrap 后触发错误的 Dart SDK 下载**
   - 这是现在剩下的最后一个主 blocker

---

## 当前未提交改动（很重要）

当前 `HEAD` 还停在：`87a8a78`  
提交信息：`fix(ci): detect loong64 sdk git root correctly`

但工作树里已经有**新的本地未提交修复**：

```text
M build/scripts/build-loong64-in-container.sh
M build/scripts/validate-release-workflow.sh
M docs/12-github-workflow-maintenance.md
```

这些改动的核心内容是：

### `build/scripts/build-loong64-in-container.sh`

在补完本地 git repo 后，新增：

- 读取 `git -C "$FLUTTER_ROOT" rev-parse HEAD`
- 若 `bin/cache/flutter_tools.snapshot` 存在，则把
  `bin/cache/flutter_tools.stamp`
  重写成：

```text
<local_revision>:<FLUTTER_TOOL_ARGS>
```

当前在默认无 `FLUTTER_TOOL_ARGS` 时，就是：

```text
<local_revision>:
```

这一步的目的：

- synthetic git commit 会改变 Flutter 看到的 revision
- Flutter bootstrap 会用 revision + `FLUTTER_TOOL_ARGS` 校验 `flutter_tools.stamp`
- 如果 stamp 不匹配，它就会认为 snapshot 过期，继而去下载 upstream `linux loong64 Dart SDK zip`
- 这个 zip 当前并不存在，所以会拿到 259-byte 错误页并解压失败

### `build/scripts/validate-release-workflow.sh`

新增静态断言，确保上述 stamp 修复不会被后续删掉。

### `docs/12-github-workflow-maintenance.md`

补充记录：给 packaged SDK 补本地 git repo 后，还需要同步重写 `flutter_tools.stamp`。

---

## 本地已做的验证

下面这些验证已经在本地跑过，结果通过：

1. `bash -n build/scripts/build-loong64-in-container.sh`
2. `bash -n build/scripts/validate-release-workflow.sh`
3. `bash build/scripts/validate-release-workflow.sh`
4. 一个最小 smoke：
   - 构造“父仓库里嵌套 SDK 目录”的场景
   - 模拟 packaged SDK 的 `flutter_tools.snapshot`
   - 确认 `flutter_tools.stamp` 会写成 `<revision>:` 格式

> 注意：这只是本地静态 / 逻辑 smoke，不是远端完整构建验证。

---

## 仍然没干完的事情

### 1. 提交并推送最新本地修复

当前关于 `flutter_tools.stamp` 的修复**还没有 commit / push**。

建议提交信息：

```text
fix(ci): keep loong64 flutter tools cache warm
```

### 2. 重跑远端 workflow

建议至少重跑：

- `Release`
- `Nightly`
  - 因为 `Nightly Loong64` 是由 `Nightly` 成功后自动触发的 `workflow_run`

也可以直接手动触发：

- `nightly-loong64.yml`

### 3. 如果这次仍失败，优先检查这些点

如果重写 `flutter_tools.stamp` 还不够，下一层最可能的问题是：

1. `packages/flutter_tools/pubspec.yaml` 的时间戳晚于 `pubspec.lock`
   - Flutter bootstrap 也可能因此重建工具链
2. `flutter/bin/internal/shared.sh` 内对 compile key / snapshot 的其他校验逻辑
3. `bin/cache/flutter.version.json` / `bin/internal/engine.version` / `bin/cache/dart-sdk` 是否仍被 wrapper 判定不一致
4. 必要时考虑绕过 `flutter` wrapper 的自升级路径，直接调用 SDK 内现成的 `dart` / `flutter_tools.snapshot`

但**第一优先级**仍然是先验证这次 `flutter_tools.stamp` 修复，因为它和当前日志根因是直接对应的。

---

## 关键运行记录（便于下一个 AI 直接查）

### 成功

- `Nightly 26352939277`
- `Nightly Loong64 26352685221`

### 失败

- `Release 26352940074`
  - 失败 job：`77574311085`
- `Nightly Loong64 26353095846`
  - 失败 job：`77574692209`

### 最近成功 Nightly 对应 head

- head: `87a8a78b359025a7cd5243f099d91a034da301f4`

---

## 关键文件清单

下一个 AI 如果要接着干，优先看这些文件：

### Workflow

- `.github/workflows/nightly-loong64.yml`
- `.github/workflows/release.yml`

### 脚本

- `build/scripts/build-loong64-in-container.sh`
- `build/scripts/install-loong64-build-deps.sh`
- `build/scripts/augment-nightly-release-notes-loong64.sh`
- `build/scripts/append-release-asset-hashes.sh`
- `build/scripts/validate-release-workflow.sh`
- `build/scripts/nightly-cli-smoke-test.sh`
- `build/scripts/release-cli-smoke-test.sh`

### 文档

- `docs/12-github-workflow-maintenance.md`
- `docs/superpowers/plans/2026-05-24-loong64-release-workflow.md`
- `docs/superpowers/specs/2026-05-24-loong64-release-workflow-design.md`

---

## 建议的接手顺序

1. 先看当前未提交 diff
2. 提交 `flutter_tools.stamp` 修复
3. 推送到 `master`
4. 触发 `Release`
5. 触发 `Nightly` 或直接观察自动触发的 `Nightly Loong64`
6. 如果成功：
   - 核对 nightly prerelease 是否已有 `loong64 tar.gz + deb`
   - 核对正式 release 是否已有 `loong64 bundle + deb`
   - 核对 release body / `hashes.sha256` 是否包含 Loong64
   - 核对 `AUR / UOS` job 仍只处理 `amd64 + arm64`
7. 如果失败：沿着上面的“仍失败时优先检查点”继续追

---

## 额外提醒

- **不要用 git worktree**，仓库规则明确禁止
- 回复和文档都应使用**简体中文**
- 完成功能后要继续同步文档
- 当前工作树里还有一个未跟踪文件：`loongarch_world_detect.py`
  - **这不是本轮最新修复的一部分**
  - 提交时不要顺手把它混进去，先确认它是不是用户本来就有的文件 / 无关文件

---

## 最后一句

这活现在不是“从零开始”，而是已经打到 **最后 5% 的远端收尾** 了。  
下一个 AI 最应该做的事情不是重写方案，而是：**接着当前这 3 个未提交改动，提交、推送、重跑、看日志。**
