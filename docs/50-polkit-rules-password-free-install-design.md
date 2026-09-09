# 50 - polkit rules 免密安装设计

> 日期：2026-09-09
> 关联：`docs/47-pkexec-auth-popup-analysis.md`（根因分析与特权 helper 设计）
> 状态：设计完成，未实施

---

## 1. 背景与定位

### 1.1 问题回顾

见 `docs/47` §3：上游 linyaps 自 `9937c545` 起由 root daemon 对每个特权 D-Bus
方法做 polkit 校验，policy 为 `auth_admin_keep`，但缓存按「调用方进程身份」计算，
CLI/商店每次操作都 spawn 新进程，缓存永不命中，导致每次安装/更新都弹出授权框。

### 1.2 现状

安装/更新授权现由独立 C++ root helper 承载（`docs/47` §9，已落地
`lib/core/platform/privileged_helper/` 与 `linux/privileged_helper/`）：
会话内首次拉起 helper 弹 1 次 pkexec，之后任务免密。

### 1.3 本方案定位

- 效果：**0 弹窗**（连 helper 首次授权也不需要，终端 `ll-cli` 同样免密）。
- 手段：写入系统级 polkit rules + 设置页开关（默认关闭、开启需风险确认）。
- 与 helper 链路的关系：**相互独立、互不依赖**。规则只作用于
  `org.deepin.linglong.PackageManager1.*` 前缀的 action，不覆盖
  `org.freedesktop.policykit.exec`，因此 helper 拉起路径行为不变；
  helper 未可用的回退场景（直连 D-Bus / 终端 ll-cli）由本规则覆盖免密。

## 2. 目标与非目标

### 2.1 目标

1. 开启后，安装、更新、本地文件安装全程 0 授权弹窗（含终端 `ll-cli`）。
2. 用户可通过设置页开关随时开启/关闭；默认关闭。
3. 开启前展示小白可读的风险说明，用户明确确认后才执行。
4. 授权被取消、pkexec 不可用等异常路径有明确反馈，不产生中间态。

### 2.2 非目标（明确排除）

1. **卸载、清理缓存、修改 daemon 配置不免密**——破坏性/敏感操作保留系统授权防线。
2. 不覆盖远程会话（SSH）、cron、systemd 服务等非活动本机会话。
3. 不修改 linyaps 上游 policy 文件，不新增自定义 polkit action。

## 3. 规则设计

### 3.1 规则文件

- 路径：`/etc/polkit-1/rules.d/60-linglong-store.rules`
- 权限：`0644 root:root`
- 优先级取 `60`：位于发行版默认规则（`10-`~`50-`）之后、用户自定义（`90-`+）之前；
  polkitd 按字典序加载，后加载者优先，`60` 不覆盖发行版规则之外的合理默认。

### 3.2 规则内容（固定，不可由用户配置）

```js
// 由玲珑商店写入；开启「安装时免密码确认」后生效，关闭即删除本文件。
polkit.addRule(function(action, subject) {
    // 仅限本机活动会话：SSH、cron、系统服务不受影响。
    if (!subject.local || !subject.active) {
        return;
    }
    // 精确列出安装类 action，禁止使用前缀匹配扩大范围。
    if (action.id === "org.deepin.linglong.PackageManager1.install" ||
        action.id === "org.deepin.linglong.PackageManager1.update" ||
        action.id === "org.deepin.linglong.PackageManager1.install-from-file") {
        return polkit.Result.yes;
    }
});
```

### 3.3 六个 action 的免密划分

| action | 免密 | 理由 |
|--------|------|------|
| `install` | ✅ | 高频，痛点场景 |
| `update` | ✅ | 高频（批量更新） |
| `install-from-file` | ✅ | 同为安装心智 |
| `uninstall` | ❌ | 破坏性操作，防恶意静默卸载与误删 |
| `prune` | ❌ | 低频，保留防线 |
| `set-configuration` | ❌ | 敏感操作，保留防线 |

### 3.4 生效机制

polkitd 通过 inotify 监听 `rules.d` 目录，文件写入/删除后**自动重新加载**，
无需重启服务、无需注销。

## 4. 安全分析与影响面

### 4.1 系统级全局降级（必须向用户明示）

polkit 校验的是调用方**身份属性**（uid、会话），无法按「发起程序是谁」收窄。
规则生效后：

- 终端手动 `ll-cli install/update` 同样免密；
- **任何本机活动会话程序（含恶意程序）均可静默安装软件**——这是本方案固有的
  安全让渡，也是默认关闭、开启前强制风险确认的原因。

### 4.2 边界兜底

- `subject.local && subject.active` 限定：SSH 远程、cron、系统服务不受影响；
- 卸载/清理/配置三个 action 始终要求授权，恶意程序无法静默**删除**软件；
- 撤销即恢复：删除规则文件后立刻回到系统默认行为。

### 4.3 残留与生命周期

规则文件位于系统目录，**商店卸载不会自动清理**（不引入卸载钩子）。需在
应用内关闭入口与文档中说明手动清理路径：

```bash
sudo rm -f /etc/polkit-1/rules.d/60-linglong-store.rules
```

## 5. UI 设计

### 5.1 设置页开关

- 位置：「商店选项」区（`setting_page.dart` 的 `_buildStoreOptionsSection`），
  复用现有 `SwitchListTile + _buildDivider` 模式。
- 文案：

| 键 | zh 文案 |
|----|---------|
| 标题 | 安装时免密码确认 |
| 副标题 | 开启后，安装和更新应用不再弹出系统密码确认，卸载等操作仍需确认 |

### 5.2 开启流程（强制风险确认）

点击开启**不直接生效**，先弹 `ConfirmDialog`：

- 标题：`开启免密码确认？`
- 正文（风险说明，小白可读）：
  > 开启后，玲珑商店安装、更新应用将直接执行，不再要求输入密码。这意味着电脑
  > 少了一道保护——某些来路不明的程序也可能利用这条规则，在您不知情时悄悄安装
  > 软件。如果这台电脑有多人使用，或您经常安装来源不确定的软件，建议保持关闭。
  > 卸载和系统清理不受影响，仍需密码确认。
- 确认按钮：`我已了解风险，开启`；取消按钮：`保持关闭`。
- 用户确认后执行 `pkexec bash <临时脚本>`（此时弹**一次**系统授权框——用户
  主动开启行为，合理）。
- 授权被取消（pkexec 退出码 126）：开关回弹，提示「未完成授权，保持关闭」。

### 5.3 关闭流程

点击关闭同样经 `pkexec` 删除规则文件（弹一次授权框），成功后开关落为关。
取消授权则开关保持开启并提示。

### 5.4 状态模型（关键约束）

- **开关状态以规则文件存在性为唯一事实来源**，不做 SharedPreferences 持久化，
  避免「配置说开、文件不存在」的状态漂移（如用户手动删文件）。
- 进入设置页异步探测 `File(rulesPath).existsSync()`（该目录普通用户可读，
  探测无需提权），探测期间开关禁用。
- 执行中（开启/关闭进行时）显示 loading 并禁用开关，禁止连点
  （参照现有 `isPruningBaseService` 模式）。

## 6. 技术实现

### 6.1 模块划分（遵循分层与统一入口约定）

```
lib/application/services/polkit_rule_service.dart   # 唯一 pkexec 入口：常量、探测、脚本生成、执行
lib/application/providers/polkit_rule_provider.dart # 状态机与 UI 桥接
```

- **全项目禁止其他位置散写该规则文件或 `pkexec` 调用**（与
  `GuidedRepairService` 同等收敛要求）。
- pkexec 执行复用现有流式执行器模式：临时脚本落盘（`0700`）→
  `pkexec bash <脚本>` → 实时收集输出 → 执行后删除脚本。

### 6.2 脚本内容

开启（写规则）：

```bash
install -m 0644 /dev/null /etc/polkit-1/rules.d/60-linglong-store.rules
cat > /etc/polkit-1/rules.d/60-linglong-store.rules <<'RULE_EOF'
<§3.2 规则内容>
RULE_EOF
```

关闭：

```bash
rm -f /etc/polkit-1/rules.d/60-linglong-store.rules
```

规则内容以常量内嵌于 service（单一事实来源），脚本生成时原样嵌入；
执行后重新探测文件存在性作为成功判定（不轻信退出码）。

### 6.3 状态机

```
idle ──探测──> checked(enabled|disabled)
checked ──确认开启──> toggling ──成功──> checked(enabled)
                          └─126/失败─> checked(原状态) + 错误提示
checked ──确认关闭──> toggling ──成功──> checked(disabled)
```

- 状态：`{phase: idle|checking|toggling, enabled: bool?, lastError: ...}`。
- `toggling` 期间 UI 禁点；完成/失败均回到 `checked`。

### 6.4 错误处理矩阵

| 场景 | 表现 |
|------|------|
| pkexec 126（取消授权） | 开关回弹 + 「未完成授权」提示 |
| pkexec 不存在/启动失败 | 错误提示（含原始 stderr 摘要），状态不变 |
| 脚本执行非 0 | 同上，并记录完整输出到 XDG 日志 |
| 执行后探测与预期不符 | 视为失败并提示，下次进设置页重新探测纠正 |

## 7. i18n

新增键（10 个 arb 文件同步：zh/en/zh_Hant/ja/ko/de/fr/es/ru/ar）：

| 键 | 说明 |
|----|------|
| `passwordFreeInstallTitle` | 开关标题 |
| `passwordFreeInstallSubtitle` | 开关副标题 |
| `passwordFreeInstallConfirmTitle` | 确认框标题 |
| `passwordFreeInstallRiskDescription` | 风险说明正文 |
| `passwordFreeInstallConfirmAction` | 我已了解风险，开启 |
| `passwordFreeInstallCancelAction` | 保持关闭 |
| `passwordFreeInstallEnabled` | 已开启提示 |
| `passwordFreeInstallDisabled` | 已关闭提示 |
| `passwordFreeInstallAuthCancelled` | 未完成授权，保持原状态 |
| `passwordFreeInstallFailed` | 操作失败（附错误摘要） |

开关走 `SwitchListTile` 自带语义（title 即可读标签），无需额外 `a11y` 键。

## 8. 测试计划

| 层 | 内容 |
|----|------|
| 单元 | `polkit_rule_service_test`：规则内容快照（防篡改）、开启/关闭脚本内容校验、探测逻辑、执行器三态 mock（成功/126/异常）、执行后探测判定 |
| 单元 | `polkit_rule_provider_test`：状态机迁移矩阵、toggling 防重入、失败回弹 |
| Widget | 设置页开关渲染、点击弹确认框、取消不执行、确认后 loading、126 回弹提示 |
| 真机 | ①开启→弹 1 次授权→终端 `ll-cli install` 免密；②`ll-cli uninstall` 仍弹窗；③关闭→恢复弹窗；④取消授权→开关回弹；⑤SSH 会话（可测则测）仍要求授权 |

## 9. 提交拆分

1. `feat: 新增 polkit 免密规则服务与状态管理`
2. `feat: 设置页新增安装免密码确认开关与风险确认`
3. `feat: 补充免密开关多语言文案`
4. `test: 补充 polkit 免密开关单元与 Widget 测试`
5. `docs: 本设计文档`

## 10. 实施前检查单

- [ ] 确认目标环境 polkit 版本支持 JS rules（polkit ≥ 106，Deepin 25 满足）
- [ ] 确认 `/etc/polkit-1/rules.d/` 存在且 polkitd 监听（真机验证 §8）
- [ ] 风险文案终稿过产品确认
- [ ] 与 helper 链路叠加行为真机回归（§1.3）
