# 玲珑环境管理服务拆分设计

## 1. 文档定位

本文定义 `LinglongEnvironmentManagementService` 的职责拆分方案。目标是在不改变
设置页行为、不改变系统命令和脚本语义、不改变 Provider 公共调用协议的前提下，
把当前集中在单个文件中的多条变化轴拆成可独立维护的协作者。

本次只处理 Application 服务层。环境管理对话框、下载管理弹窗和应用详情页的
展示层拆分将在后续独立设计、独立提交，避免一次提交同时改变业务编排和 UI 结构。

## 2. 现状与问题

`lib/application/services/linglong_environment_management_service.dart`
当前约 1250 行，同时承担以下职责：

1. 调用 `LinglongEnvironmentService` 汇总基础环境；
2. 读取运行中应用、磁盘、挂载、目录权限和本地数据状态；
3. 把探测结果归类为设置页可消费的问题；
4. 执行 OSTree 本地数据修复及旧版本参数降级；
5. 执行 fsck partial commit 重新拉取与复验；
6. 执行玲珑数据目录权限修复；
7. 校验保存位置迁移前置条件并执行迁移；
8. 生成三类特权脚本；
9. 管理 XDG 日志路径、临时脚本和输出截断；
10. 解析 `df`、`findmnt`、`stat` 和 `ll-cli` 输出。

这些职责具有不同的变化原因：

- linyaps 命令输出变化只应影响只读探测；
- OSTree 版本兼容变化只应影响本地数据修复；
- systemd bind mount 方案变化只应影响保存位置迁移；
- 服务用户或目录规则变化只应影响权限检查和修复；
- UI 只需要稳定的分析与操作结果，不应感知上述实现组合。

当前所有变化都修改同一个类，导致审查时难以判断改动是否越界，也容易在处理一种
系统能力时误触另一种能力。测试虽然覆盖了关键行为，但仍只能通过一个大服务入口
构造所有依赖。

## 3. 保持不变的业务契约

本次属于结构迁移，以下行为必须保持：

- Provider 继续只依赖 `LinglongEnvironmentManagementService`；
- `analyzeEnvironment()` 返回的模型、问题代码和文案保持不变；
- 默认健康检查只走 linyaps 运行路径，不执行底层完整性审计；
- 权限异常继续与本地数据损坏分开表达；
- 本地数据修复继续优先使用 `ostree fsck --all --delete`，仅在明确不支持
  `--all` 时降级；
- 不支持 `--delete` 时必须返回失败，不能把只检查包装为修复成功；
- 只有 fsck 明确标记的 partial commit 才进入重新拉取和复验；
- 保存位置迁移继续采用 systemd bind mount，不创造“自定义安装目录”语义；
- 迁移继续阻断运行中的玲珑应用、已 bind mount 和空间不足场景；
- 特权操作继续由上层显式确认后触发；
- 完整输出写入 XDG 日志，UI 只接收截断结果；
- 现有公开的三个脚本构建方法暂时保留在门面上，兼容已有测试和诊断调用；
- 不增加发行版、桌面环境或 DDE 特判。

## 4. 方案比较

### 4.1 方案 A：只按代码段拆成多个 mixin 或 `part`

该方案能缩短单个文件，但所有实现仍共享门面的私有字段和状态，依赖关系没有显式
表达。后续维护者仍需把多个文件当成一个 God Class 理解，只是物理位置发生变化。

### 4.2 方案 B：让 Provider 分别依赖多个细粒度服务

该方案能彻底移除门面，但会把组合复杂度泄漏到 Provider，并改变测试替身和上层
调用协议。环境管理页面本质上仍是一个完整用例入口，直接暴露四五个系统服务会让
Presentation 知道不必要的实现细节。

### 4.3 方案 C：稳定门面加单职责协作者

保留 `LinglongEnvironmentManagementService` 作为 Application 用例门面，内部
组合只读探测、健康分析、三类变更服务和命令工作区。门面只转发公开用例，不再包含
命令、脚本或解析细节。

**选择方案 C。** 它既能保持上层稳定，又能通过构造关系明确每种能力的依赖，
符合“门面稳定、实现可替换”的维护目标。

## 5. 目标结构

```text
LinglongEnvironmentManagementService
  ├─ LinglongEnvironmentHealthAnalyzer
  │    ├─ LinglongEnvironmentService
  │    └─ LinglongEnvironmentProbe
  ├─ LinglongOstreeRepairService
  │    └─ LinglongManagementCommandWorkspace
  ├─ LinglongDataPermissionRepairService
  │    └─ LinglongManagementCommandWorkspace
  └─ LinglongStorageMigrationService
       ├─ LinglongEnvironmentProbe
       └─ LinglongManagementCommandWorkspace
```

### 5.1 `LinglongEnvironmentManagementService`

定位为面向 Provider 的稳定门面：

- 保留现有构造参数和公开方法；
- 在默认构造路径创建内部协作者；
- `analyzeEnvironment()` 委托健康分析器；
- 三类变更操作分别委托对应服务；
- 脚本构建方法只做兼容转发；
- 不再直接执行 Shell 命令或解析输出。

保留当前可继承的类形态，避免现有 Provider/Widget 测试替身必须同时重写。若未来
需要收紧为接口，应作为独立变更处理。

### 5.2 `LinglongEnvironmentProbe`

定位为无副作用的系统状态探测器：

- 读取运行中应用数量；
- 读取源路径和指定路径所在文件系统信息；
- 读取 bind mount 状态；
- 检查关键路径属主和 owner 写权限；
- 使用 `ll-cli --json list` 检查运行期本地数据可用性；
- 解析 `df`、`findmnt`、`stat` 和 JSON 输出；
- 对缺失命令返回稳定的探测结果，不执行修复。

健康分析和保存位置迁移共同依赖这些事实，因此提取为一个共享只读能力是实际复用，
不是为单一调用点创建抽象。

### 5.3 `LinglongEnvironmentHealthAnalyzer`

定位为健康状态聚合和问题分类：

- 并行或顺序获取基础环境与探测事实；
- 生成 `LinglongEnvironmentAnalysis`；
- 把事实映射为 `LinglongEnvironmentIssue`；
- 维护问题严重级别、修复动作和业务说明。

它不关心命令行输出格式，也不执行任何改变系统状态的动作。

### 5.4 `LinglongOstreeRepairService`

定位为玲珑本地数据修复：

- 生成和执行 fsck 命令；
- 识别旧版本参数兼容情况；
- 识别 checksum 损坏和 fsck partial 状态；
- 生成、执行 partial ref 重拉脚本并复验；
- 把多次命令结果归类为一个修复结果。

OSTree 的兼容判断与脚本保留在同一服务中，避免把紧密关联的规则拆成没有业务语义
的工具函数。

### 5.5 `LinglongDataPermissionRepairService`

定位为目录权限修复：

- 生成受控权限修复脚本；
- 执行脚本并管理日志；
- 返回权限修复结果。

服务用户、服务组、systemd unit 和需要修复的目录规则由该服务拥有。

### 5.6 `LinglongStorageMigrationService`

定位为保存位置迁移：

- 规范化并校验目标路径；
- 检查运行中应用、现有 bind mount 和目标磁盘空间；
- 生成 systemd bind mount 迁移脚本；
- 执行迁移并返回结果。

迁移服务只读取 `LinglongEnvironmentProbe` 暴露的事实，不复制 `df`、`findmnt`
解析逻辑。

### 5.7 `LinglongManagementCommandWorkspace`

这是三类变更服务真正共享的资源生命周期组件，只负责：

- 按 XDG 规则创建日志路径；
- 创建和删除临时脚本；
- 提供稳定的英文命令环境；
- 合并或截断用于 UI 的命令输出。

它不包含健康判断、修复判断或迁移规则，避免演变成新的通用工具 God Class。

## 6. 依赖和可见性约束

- 新协作者位于 `lib/application/services/linglong_environment_management/`；
- Provider 只导入门面文件，不直接依赖内部协作者；
- 协作者可以使用公开类型进行文件间通信，但不从应用组合根单独注册；
- Domain 模型保持不变；
- UI 和 Provider 禁止直接调用 `ShellCommandExecutor`；
- 门面负责默认装配，使测试和生产使用相同的组合关系；
- 不使用全局单例，不在协作者内部读取 Riverpod。

## 7. 迁移步骤

1. 提取命令工作区，保持日志、临时脚本和输出处理字节级语义一致；
2. 提取只读探测器及解析器；
3. 提取健康分析器和问题分类；
4. 依次提取 OSTree、权限和迁移服务；
5. 把原服务收敛为委托门面；
6. 保留公开方法签名和现有测试入口；
7. 更新开发指南，禁止继续把新系统操作堆回门面；
8. 运行服务、Provider、Widget 相关测试及静态分析和 Linux 构建。

每一步先迁移原实现，不顺手改变文案、命令参数、超时或脚本行为。发现现有缺陷时
单独记录并在后续修复提交处理。

## 8. 验证范围

不为了拆文件新增无业务价值的测试。现有测试已经覆盖真实高风险边界，必须全部继续
通过：

- 健康分析不执行 fsck；
- 本地数据不可用、探测失败和权限异常正确分类；
- OSTree 新旧参数、partial 重拉和 checksum 失败分支；
- 权限修复脚本及日志；
- 保存位置危险路径、运行中应用和空间不足阻断；
- Provider 修复后刷新；
- Widget 仍通过同一门面触发操作。

完成标准：

- 环境管理服务相关测试全部通过；
- `flutter analyze` 无错误和警告；
- Linux debug 构建通过；
- 门面不再包含 Shell 命令、脚本正文和输出解析；
- 工作区不存在意外生成物或无关改动。
