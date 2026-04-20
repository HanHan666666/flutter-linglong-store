# 玲珑环境检测与自动安装 Rust 语义对齐设计

> 文档版本: 1.0 | 创建日期: 2026-04-20
> 适用范围：Flutter 版启动页环境门禁、环境弹窗、自动安装链路、相关测试

## 一、背景

当前 Flutter 版“检查玲珑环境 / 自动安装环境”与旧版 Rust 商店存在明显语义漂移：

1. 环境检测只检查 `ll-cli --version` 和 `ll-cli ps`，没有对齐 Rust 的 repo 检测与最低版本语义。
2. 自动安装改成了“下载固定 URL 脚本 + 通过 `CliExecutor` 执行”，既偏离了后端脚本真相源，也错误复用了只适用于 `ll-cli` 的执行器。
3. 环境结果模型缺失 Rust 侧已有的系统信息、repo 信息、版本警告等字段，导致 UI 与埋点只能看到残缺结果。
4. 当前自动安装流程存在功能性错误：实际会尝试执行 `ll-cli sh -c ...`，在环境缺失场景下天然无法工作。

本次目标不是把 Rust 代码翻译成 Dart，而是在 Flutter 侧以 Flutter 原生实现方式，把功能语义与 Rust 商店收敛一致。

## 二、目标与非目标

### 2.1 目标

- Flutter 环境检测语义与 Rust 对齐：
  - 缺失 `ll-cli` 时阻断启动
  - repo 缺失时阻断启动
  - `ll-cli` 版本低于 `1.9.0` 时仅警告，不阻断启动
- 自动安装脚本来源恢复为后端 `/app/findShellString`
- 自动安装执行链路改成真正的 `pkexec bash <temp-script>`，不再走 `ll-cli`
- Provider 只负责状态编排，平台命令执行与脚本获取下沉到独立 service
- 补齐缺失/低版本/repo 缺失/安装失败等核心测试
- 将本次对齐约束写入文档，作为后续维护基线

### 2.2 非目标

- 不移除 Flutter 当前新增的“跳过检测”能力
- 不把该功能重新迁回 Rust/FFI 桥接层
- 不重写启动页视觉样式
- 不改动与本次需求无关的安装队列、进程管理等链路
- 不恢复 worktree 约束。本次按用户明确要求直接在当前工作区开发

## 三、对齐后的业务语义

### 3.1 环境检测结果分类

环境检测统一产出三类结果：

1. **通过**
   - `ll-cli` 可用
   - repo 配置存在且可解析
   - 版本可解析
   - 若版本低于最低要求，仅附带 warning，不改为失败

2. **警告通过**
   - 满足“通过”全部条件
   - 版本号低于最低要求 `1.9.0`
   - 启动链路继续执行
   - 启动页不弹阻断弹窗
   - UI 可显示非阻断 warning

3. **失败**
   - `ll-cli --help` 无法启动或返回非零
   - `ll-cli` 版本无法解析
   - `repo show` 无法解析出有效 repo 列表
   - 其他系统命令采集失败仅记录为空，不直接造成失败

### 3.2 与 Rust 的对应关系

Flutter 目标语义对齐以下 Rust 行为：

- `check_linglong_env_cmd()` 的最低版本固定为 `1.9.0`
- `ll-cli --help` 用于确认基础环境是否存在
- `ll-cli --json repo show` 优先，失败时回退 `ll-cli repo show`
- repo 列表为空时视为环境异常
- 版本过低只提示，不阻断
- 系统信息采集包括：
  - `uname -m`
  - `/etc/os-release`
  - `ldd --version`
  - `uname -a`
  - `apt-cache policy linglong-bin`（若可用）
  - `LINYAPS_CONTAINER=yes` 判断容器环境

### 3.3 Flutter 保留差异

以下行为明确保留 Flutter 差异，不回退到 Rust：

- **跳过检测**
  - 仅在失败但 `ll-cli` 已存在的场景显示
  - 仍允许用户继续进入应用
  - 缺失 `ll-cli` 的“致命失败”场景不允许跳过

## 四、架构方案

### 4.1 分层原则

采用“service 负责外部交互，provider 负责状态编排”的方案：

- **Service**
  - 负责系统命令执行
  - 负责环境信息采集与解析
  - 负责后端脚本获取
  - 负责脚本执行与结果返回
- **Provider**
  - 负责 UI 状态
  - 负责启动页与弹窗之间的状态流转
  - 不直接持有复杂平台命令实现

### 4.2 组件划分

#### A. `LinglongEnvironmentService`

职责：

- 执行完整环境检测
- 统一最低版本比较
- 聚合系统信息、repo 信息、版本信息
- 输出 Flutter 侧规范化的 `LinglongEnvCheckResult`

不负责：

- UI 状态
- 弹窗逻辑
- 启动流程推进

#### B. `ShellCommandExecutor`

职责：

- 执行非 `ll-cli` 命令
- 提供同步与流式执行能力
- 返回 stdout/stderr/exitCode
- 支持 timeout

存在原因：

- 现有 `CliExecutor` 被设计为“固定执行 `ll-cli`”
- 自动安装必须真正执行 `pkexec bash <temp-script>`
- 强行复用 `CliExecutor` 会再次把“环境缺失时无法安装”的错误引回系统

#### C. `LinglongInstallScriptService`

职责：

- 从后端 `/app/findShellString` 获取安装脚本正文
- 对空脚本、非 200、字段缺失统一转成明确异常

不负责：

- 下载脚本 URL
- 本地脚本维护

#### D. `LinglongEnvProvider`

职责：

- `checkEnvironment()` 调用 `LinglongEnvironmentService`
- `performAutoInstall()` 调用脚本 service 与 shell executor
- 更新 `isInstalling/installProgress/installMessage/result` 等状态
- 保持 `skipCheck()` 语义

不再负责：

- 自己拼接 `curl/wget`
- 自己执行 `Process.run('pkexec'...)`
- 自己解析 repo 文本

## 五、数据模型调整

### 5.1 `LinglongEnvCheckResult`

现有模型字段过少，需要扩充为足以承载 Rust 语义：

- `isOk`
- `warningMessage`
- `errorMessage`
- `errorDetail`
- `checkedAt`
- `arch`
- `osVersion`
- `glibcVersion`
- `kernelInfo`
- `detailMsg`
- `llCliVersion`
- `llBinVersion`
- `repoName`
- `repos`
- `isContainer`
- `repoStatus`

说明：

- `warningMessage` 明确表达“通过但有警告”，避免继续用 `errorMessage` 承载非阻断提示
- `repoStatus` 由检测 service 统一给出，供 UI 与测试断言使用

### 5.2 `RepoStatus`

保留并真正启用：

- `unknown`
- `ok`
- `notConfigured`
- `misconfigured`
- `unavailable`

其中：

- repo 为空时使用 `notConfigured`
- 命令调用成功但输出无法解析时使用 `misconfigured`
- 命令启动失败或超时时使用 `unavailable`

## 六、环境检测实现细节

### 6.1 执行顺序

1. 采集 `arch`
2. 采集 `osVersion`
3. 采集 `glibcVersion`
4. 采集 `kernelInfo`
5. 采集 `detailMsg`
6. 执行 `ll-cli --help`
7. 执行 repo 检测
8. 执行版本检测
9. 执行 `apt-cache policy linglong-bin` 检测
10. 判断容器环境
11. 产出最终结果

### 6.2 repo 检测

规则：

- 先执行 `ll-cli --json repo show`
- 若成功则优先按 JSON 解析
- JSON 解析失败时回退文本解析
- 若 `--json` 命令本身失败，再回退 `ll-cli repo show`
- 最终 repo 列表为空则直接失败

### 6.3 版本检测

规则：

- 从 `ll-cli --json --version` 优先解析
- 若 JSON 不可用，可回退从纯文本中提取语义版本号
- 无法解析版本时判失败
- 若 `< 1.9.0`：
  - `isOk = true`
  - `warningMessage = 当前玲珑基础环境版本过低...`
  - 不显示阻断弹窗

## 七、自动安装实现细节

### 7.1 脚本来源

自动安装脚本统一来自后端 `/app/findShellString`。

禁止继续使用：

- `AppConfig.installScriptUrl`
- 本地硬编码下载地址
- `curl/wget` 直接下载远端脚本

原因：

- Rust 已将后端配置作为脚本真相源
- Flutter 必须与该脚本来源保持一致，避免后端更新脚本后两端行为漂移

### 7.2 执行链路

自动安装流程：

1. 调用后端获取脚本正文
2. 将脚本写入临时文件
3. `chmod 755`
4. 使用 `pkexec bash <temp-script>` 执行
5. 采集 stdout/stderr/exitCode
6. 清理临时文件
7. 完成后再次执行环境检测

### 7.3 成功判定

必须同时满足：

- `pkexec bash` 退出码为 `0`
- recheck 后 `result.isOk == true`

任一不满足都视为安装失败。

### 7.4 失败判定

以下任一场景视为失败：

- 后端返回空脚本
- 脚本临时文件写入失败
- `chmod` 失败
- `pkexec` 启动失败
- `pkexec bash` 非零退出
- 安装后 recheck 仍失败

失败文案优先级：

1. `stderr`
2. `stdout`
3. 本地兜底错误

### 7.5 进度策略

Rust 旧版安装结果是一次性返回，不是真正的协议化进度流。
因此 Flutter 本次不引入伪精确进度协议，只保留阶段性进度：

- `0.05` 准备脚本
- `0.15` 获取脚本
- `0.25` 写入与授权
- `0.50` 执行安装
- `0.90` 安装后校验
- `1.00` 完成

如果后续脚本协议稳定，再单独设计真实流式进度，不在本次范围内解决。

## 八、UI 与启动链路行为

### 8.1 `LaunchSequence`

对齐后的行为：

- `isOk == false`：阻断启动，等待环境弹窗处理
- `isOk == true && warningMessage != null`：继续启动，同时记录 warning
- `isOk == true && warningMessage == null`：正常继续

### 8.2 `LinglongEnvDialog`

保持按钮结构：

- 退出商店
- 手动安装
- 自动安装
- 重新检测
- 跳过检测（仅部分失败场景）

对齐后的规则：

- 低版本 warning 不弹阻断对话框
- 缺失 repo / 缺失 ll-cli / 版本不可解析时弹阻断对话框
- 自动安装失败时必须展示真实失败原因
- 自动安装成功后若 recheck 通过，则关闭对话框并继续启动

## 九、测试方案

### 9.1 单元测试

新增或补充以下覆盖：

1. **缺失环境**
   - `ll-cli --help` 启动失败
   - 期望：`isOk = false`，`repoStatus = unknown or unavailable`

2. **低版本 warning**
   - `llCliVersion = 1.8.x`
   - 期望：`isOk = true`，`warningMessage != null`

3. **repo 缺失**
   - `repo show` 成功但解析结果为空
   - 期望：`isOk = false`，`repoStatus = notConfigured`

4. **自动安装失败**
   - `pkexec bash` 非零退出
   - 期望：`performAutoInstall() == false`
   - `installMessage` 或结果详情保留真实错误

5. **脚本获取失败**
   - 后端返回空字符串
   - 期望：安装失败

### 9.2 Provider / 启动测试

补充：

- `launch_provider_test.dart`
  - 低版本 warning 时继续进入后续步骤
  - repo 缺失时停在环境门禁

- `launch_page_test.dart`
  - 低版本 warning 不显示环境阻断弹窗
  - 失败场景显示环境弹窗

### 9.3 执行器测试

新增：

- 非 `ll-cli` 命令执行成功
- 非 `ll-cli` 命令执行失败
- timeout 行为
- stdout/stderr 优先级

## 十、文档与约束同步

实现完成后需要同步以下文档约束：

- 环境检测必须对齐 Rust 语义：
  - 缺失环境失败
  - repo 缺失失败
  - 低版本仅警告
- 自动安装脚本来源必须是后端 `/app/findShellString`
- 自动安装执行链路必须是 `pkexec bash <temp-script>`
- Flutter 允许保留 `skip`，但只限非致命失败场景

## 十一、实施边界

本次只处理：

- 环境检测 service 化
- 脚本来源恢复
- 自动安装执行链路修正
- 测试补齐
- 文档对齐

本次不处理：

- 弹窗视觉重设计
- 安装脚本内容本身
- 后端 `/app/findShellString` 接口定义变更
- Rust 侧代码重构
