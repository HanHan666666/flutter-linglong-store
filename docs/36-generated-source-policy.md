# Flutter 生成源码单一策略设计

## 1. 文档定位

本文记录 Flutter/Dart 生成源码的仓库策略、生成入口、CI 校验方式和维护边界。
目标是消除当前“部分生成物提交、部分生成物忽略”的混合状态，让开发、CI、
离线构建和发行打包使用同一份可追溯源码。

本设计只统一生成源码的生命周期，不修改业务模型、Provider、API 或本地化文案。

## 2. 现状与问题

仓库当前存在三类生成链：

1. `build_runner`
   - Freezed：`*.freezed.dart`
   - JSON/Retrofit/Riverpod：`*.g.dart`
   - Mockito：`*.mocks.dart`
2. Flutter l10n
   - `lib/core/i18n/l10n/app_localizations*.dart`
3. 应用身份生成器
   - `lib/core/config/generated/application_identity.g.dart`
   - `linux/generated/application_identity.cmake`

实际跟踪状态不一致：

- `.gitignore` 全局忽略 `*.g.dart` 和 `*.freezed.dart`；
- 仍有少量历史生成文件已经被 Git 跟踪；
- 大部分本地生成文件被忽略，只在运行 `build_runner` 后存在；
- CI 会执行生成命令，但没有验证生成后工作区是否发生变化。

这会产生四类风险：

- 干净检出缺少部分源码，分析、测试和 IDE 索引依赖隐式生成步骤；
- 某些打包路径可跳过 `build_runner`，结果取决于检出时恰好有哪些生成物；
- 注解源码与已跟踪生成物漂移时，CI 生成后继续执行，无法提示提交者补齐生成结果；
- 生成器升级可能一次改变大量文件，却无法在代码审查中看见完整影响。

## 3. 方案比较

### 3.1 方案 A：全部忽略生成物

删除已跟踪生成文件，并要求开发、CI 和所有打包入口先执行生成。

优点是仓库体积较小，不会产生生成文件评审噪声。缺点是干净检出不能直接分析或
离线构建，所有发行路径都必须具备完全一致的生成器环境；这与当前 Linux 多架构、
容器化和可跳过生成器的打包能力冲突。

### 3.2 方案 B：继续混合管理

按历史状态保留少量生成物，其他文件在需要时生成。

改动最小，但没有可解释的边界。开发者无法仅根据文件类型判断是否应该提交，
也无法建立可靠的 CI 漂移检查。

### 3.3 方案 C：全部提交稳定生成物

提交所有参与编译的生成源码；CI 重新执行生成器，并在生成源码相对 `HEAD`
发生修改、删除或新增时失败。

优点：

- 干净检出可直接分析和构建；
- 离线或受限架构打包可复用已提交产物；
- 注解与生成结果的差异进入正常代码审查；
- 生成器升级的影响完整可见；
- CI 可以明确阻止遗漏生成物。

代价是仓库体积和代码审查差异会增加，但生成文件本身不需要手工维护。

## 4. 决策

采用方案 C：**所有稳定生成源码都提交到 Git**。

`.gitignore` 不再忽略 `*.g.dart`、`*.freezed.dart` 或 `*.mocks.dart`。生成源码
只能由对应生成器更新，禁止手工修改。

以下文件属于同一策略：

| 生成器 | 输入 | 提交的输出 |
|---|---|---|
| `build_runner` | Dart 注解源码 | `**/*.g.dart`、`**/*.freezed.dart`、`**/*.mocks.dart` |
| `flutter gen-l10n` | `l10n.yaml`、`app_*.arb` | `lib/core/i18n/l10n/app_localizations*.dart` |
| 应用身份脚本 | `config/application_identity.conf` | Dart/CMake 应用身份文件 |

生成器依赖版本继续由 `pubspec.lock` 固定。升级 Freezed、Riverpod、Retrofit、
Mockito、Flutter SDK 或其他生成器时，必须在同一提交中包含完整生成差异。

## 5. 统一入口

新增 `build/scripts/verify-generated-sources.sh`，按固定顺序执行：

1. `dart run build_runner build --delete-conflicting-outputs`；
2. `flutter gen-l10n`；
3. `generate-application-identity.sh --check`；
4. 检查所有生成源码相对 `HEAD` 是否存在修改、删除或未跟踪新增。

脚本必须使用 Git pathspec 限定生成源码，不把调用者正在开发的普通业务文件误报为
生成漂移。失败时输出具体文件列表和重新生成命令。

该入口用于 CI 的一致性门禁；开发者修改注解、ARB 或应用身份配置后，仍直接运行
对应生成命令并把生成结果与输入一起提交。

## 6. CI 与打包边界

PR CI 在依赖安装后首先执行统一生成源码校验，再执行静态分析和测试。CI 不再保留
一条“只生成但永远成功”的步骤。

发行打包仍允许根据目标架构执行 `build_runner`，也允许已验证的特殊链路使用
`LINGLONG_RELEASE_SKIP_BUILD_RUNNER=1` 复用已提交生成物。两种路径的输入基线
相同，不再依赖维护者工作区里的被忽略文件。

应用身份生成器继续保持独立的严格解析和 `--check` 语义；统一脚本只负责编排，
不复制身份派生逻辑。

## 7. 架构文档同步

实现生成策略后，另行更新 `docs/02-flutter-architecture.md`：

- 用实际目录和职责替换迁移初期的假想目录树；
- 明确组合根、Application/Domain/Data/Platform 的真实依赖方向；
- 记录队列执行、恢复、Journal、批次与生命周期协调器的边界；
- 记录大型页面的容器、动作控制器、纯规则和展示区块约定；
- 删除过时的依赖版本快照和不存在的 CI 示例；
- 引用本文作为生成源码的唯一维护规范。

文档校准与构建策略分开提交，避免生成文件基线和大篇幅说明混在同一审查单元。

## 8. 验证范围

实现阶段执行：

- `build/scripts/verify-generated-sources.sh`；
- `flutter analyze`；
- CI YAML 和 Shell 脚本静态检查；
- Linux Debug 构建。

本阶段不新增业务单元测试，因为生成策略没有新增可独立测试的业务规则。真实风险由
生成器重放、Git 漂移检测、静态分析和平台构建直接覆盖。
