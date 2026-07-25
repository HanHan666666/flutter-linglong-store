# 安装失败诊断与引导修复实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成后端可维护的安装错误解决方案、管理后台离线 Ed25519 签名流程，以及 Flutter Markdown 说明、可交互无方案浮窗、脚本审计和实时修复输出。

**Architecture:** 后端是解决方案和多语言内容的唯一数据源，只按原始 `message` 做区分大小写子串匹配；管理写接口认证并在启用脚本前验签。Flutter 每次点击感叹号时查询，不缓存；Presentation 只渲染 Provider 状态，通用验签器和统一 Shell 执行器负责安全边界。

**Tech Stack:** Spring Boot 3 / Java 17 / MyBatis-Plus / MySQL、Vue 3 / TypeScript / Element Plus / Web Crypto、Flutter / Riverpod / Retrofit / Freezed / flutter_markdown / cryptography。

---

## 文件边界

### linglong-server

- `sql/migration_20260725_create_error_solution.sql`：业务表、`i18n.value` 容量和首条停用数据。
- `ll-server/src/main/java/com/dongpl/entity/ErrorSolution.java`：数据库实体。
- `ll-server/src/main/java/com/dongpl/bo/ErrorSolutionFindBO.java`：公共查询参数和 8 KiB UTF-8 校验入口。
- `ll-server/src/main/java/com/dongpl/bo/ErrorSolutionSaveBO.java`：管理保存参数和多语言内容。
- `ll-server/src/main/java/com/dongpl/bo/ErrorSolutionPageBO.java`：管理分页参数。
- `ll-server/src/main/java/com/dongpl/vo/ErrorSolutionVO.java`：公共与管理展示模型。
- `ll-server/src/main/java/com/dongpl/mapper/master/ErrorSolutionMapper.java`：主库访问。
- `ll-server/src/main/java/com/dongpl/service/ErrorSolutionService.java`：匹配和管理用例接口。
- `ll-server/src/main/java/com/dongpl/service/impl/ErrorSolutionServiceImpl.java`：匹配、多语言、事务和签名启用约束。
- `ll-server/src/main/java/com/dongpl/security/ContentSignatureVerifier.java`：通用签名接口。
- `ll-server/src/main/java/com/dongpl/security/Ed25519ContentSignatureVerifier.java`：Java Ed25519 实现。
- `ll-server/src/main/java/com/dongpl/config/TrustedContentSignatureProperties.java`：公钥配置。
- `ll-server/src/main/java/com/dongpl/controller/app/ErrorSolutionController.java`：公开只读查询。
- `ll-server/src/main/java/com/dongpl/controller/admin/ErrorSolutionAdminController.java`：认证管理接口。
- `ll-server/src/test/java/com/dongpl/security/Ed25519ContentSignatureVerifierTest.java`：固定测试向量。
- `ll-server/src/test/java/com/dongpl/service/impl/ErrorSolutionServiceImplTest.java`：匹配和启用规则。

### linglong-admin

- `src/api/errorSolution.ts`：管理 API。
- `src/types/constants.ts`：解决方案和翻译类型。
- `src/views/errorSolution/index.vue`：列表、编辑、Markdown 预览、脚本导出、签名上传和启停。
- `src/router/index.ts`、`src/views/index.vue`：页面路由和菜单。
- `tools/offline-content-signer/index.html`：不联网的 Ed25519 PKCS#8 签名页。

### flutter-linglong-store

- `pubspec.yaml`：增加 `flutter_markdown` 和 `cryptography`。
- `lib/domain/models/error_solution.dart`：查询响应模型。
- `lib/domain/models/guided_repair_execution.dart`：输出通道、执行状态和结果。
- `lib/domain/repositories/error_solution_repository.dart`：无缓存查询接口。
- `lib/data/models/api_dto.dart`：Retrofit JSON DTO。
- `lib/data/datasources/remote/app_api_service.dart`：`POST /app/error-solution/find`。
- `lib/data/repositories/error_solution_repository_impl.dart`：DTO 到领域模型。
- `lib/core/security/content_signature_verifier.dart`：通用 Ed25519 验签。
- `lib/core/platform/shell_command_executor.dart`：兼容现有调用的可选流式输出。
- `lib/application/services/guided_repair_service.dart`：二次验签、临时文件、XDG 日志和 30 分钟执行。
- `lib/application/providers/error_solution_provider.dart`：单次查询状态。
- `lib/application/providers/guided_repair_provider.dart`：100 ms 批量输出和 512 KiB UI 缓冲。
- `lib/presentation/widgets/error_help_popover.dart`：无方案和查询失败小型浮窗。
- `lib/presentation/widgets/error_solution_dialog.dart`：Markdown 方案弹窗。
- `lib/presentation/widgets/script_review_dialog.dart`：脚本全文审计。
- `lib/presentation/widgets/guided_repair_execution_dialog.dart`：实时输出和结果。
- `lib/presentation/widgets/download_manager_dialog.dart`：红字右侧感叹号入口。
- `lib/core/i18n/l10n/app_zh.arb`、`app_en.arb`：全部 UI 和 Semantics 文案。

## Task 1：后端通用签名器

- [ ] 新增失败测试，固定签名原文为：

```text
LINGLONG_STORE_SIGNED_CONTENT_V1
purpose=privileged-shell-script

#!/usr/bin/env bash
echo ok
```

- [ ] 使用 JDK `KeyFactory.getInstance("Ed25519")` 和 `Signature.getInstance("Ed25519")` 实现：

```java
boolean verify(String purpose, String content, String signatureBase64);
```

- [ ] 公钥配置接收 Base64 原始 32 字节，并转换为 RFC 8410 SubjectPublicKeyInfo 后导入 JDK。
- [ ] 覆盖有效签名、内容变化、purpose 变化、非法 Base64、错误长度和空公钥。
- [ ] 运行：

```bash
mvn -pl ll-server -Dtest=Ed25519ContentSignatureVerifierTest test
```

- [ ] 提交：

```bash
git commit -m "feat: 增加通用Ed25519内容验签"
```

## Task 2：后端解决方案数据与匹配

- [ ] 编写 Service 失败测试，覆盖 0 条、1 条、多条、禁用、大小写、语言回退和 8 KiB UTF-8 字节边界。
- [ ] 新增 `ll_error_solution` 迁移；字段严格限定为设计文档中的七个业务字段。
- [ ] 给 `I18nService` 增加：

```java
String resolveValue(String code, String lang);
```

请求语言缺失时只回退 `zh`，中文也缺失时返回空字符串。

- [ ] 实现公共查询：

```java
ErrorSolutionVO findByMessage(String message, String lang);
```

服务使用 Java `String.contains()` 区分大小写匹配；多条命中抛出配置异常。

- [ ] 公共响应仅在脚本签名有效时携带 `repairScript` 和 `repairScriptSignature`。
- [ ] 运行：

```bash
mvn -pl ll-server -Dtest=ErrorSolutionServiceImplTest test
```

- [ ] 提交：

```bash
git commit -m "feat: 增加安装错误解决方案查询"
```

## Task 3：后端管理接口

- [ ] 增加保存、更新、删除、启停和分页测试。
- [ ] 管理请求使用以下核心结构：

```java
class ErrorSolutionSaveBO {
    Long id;
    String matchMessage;
    List<I18nUpdateOrCreateBO> titles;
    List<I18nUpdateOrCreateBO> markdowns;
    String repairScript;
    String repairScriptSignature;
    Boolean enabled;
}
```

- [ ] 一个事务内保存业务记录和两组 i18n；删除时同时删除翻译。
- [ ] 人工方案允许无签名启用；脚本方案只有签名有效时允许启用。
- [ ] 脚本变化且新签名无效时保存为停用、清空签名。
- [ ] 管理接口全部使用 `/admin/error-solution/**`，公共接口只提供 `/app/error-solution/find`。
- [ ] 使用 MockMvc 验证公共读取匿名可用、管理写入匿名返回未认证。
- [ ] 运行：

```bash
mvn -pl ll-server test
mvn -pl ll-server compile -DskipTests
```

- [ ] 提交：

```bash
git commit -m "feat: 增加错误解决方案管理接口"
```

## Task 4：管理后台和离线签名页

- [ ] 新增 TypeScript API 和类型，所有写操作指向 `/admin/error-solution/**`。
- [ ] 新增 Element Plus 管理页面，支持分页、编辑、语言条目、Markdown 预览、脚本导出、签名粘贴/上传、启停和删除。
- [ ] 导出脚本使用：

```ts
new Blob([repairScript], { type: 'text/x-shellscript;charset=utf-8' })
```

不得 `trim()` 或格式化。

- [ ] 新增单文件离线签名页；CSP 包含 `connect-src 'none'`，不使用任何外部资源和持久化存储。
- [ ] 离线页只导入 PKCS#8 Ed25519 私钥，按通用 envelope 签名，输出 Base64 和 `.sig`。
- [ ] 增加路由和菜单。
- [ ] 运行：

```bash
npm run type-check
npm run build
```

- [ ] 提交：

```bash
git commit -m "feat: 增加错误解决方案管理页面"
git commit -m "feat: 增加离线Ed25519签名页面"
```

## Task 5：Flutter 查询和验签

- [ ] 添加 Repository 和 verifier 单元测试。
- [ ] DTO 请求只序列化：

```json
{"message":"原始错误消息","lang":"zh"}
```

- [ ] Repository 每次直接调用 Retrofit，不保存内存或磁盘状态。
- [ ] 通用验证器构造与后端完全相同的 envelope，并使用内置 Base64 原始 32 字节公钥验签。
- [ ] 增加跨端固定测试向量，覆盖内容、换行和 purpose 变化。
- [ ] 运行代码生成：

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] 运行定向测试：

```bash
flutter test test/unit/data/repositories/error_solution_repository_impl_test.dart
flutter test test/unit/core/security/content_signature_verifier_test.dart
```

- [ ] 提交：

```bash
git commit -m "feat: 增加错误解决方案查询与验签"
```

## Task 6：Flutter 感叹号、Popover 和 Markdown

- [ ] 编写 Widget 测试，先验证失败任务红字右侧出现感叹号。
- [ ] 验证点击时才请求、关闭后再次点击会重新请求。
- [ ] `data=null` 时不打开方案弹窗，而在锚点上方显示：

```text
暂无解决方案
[社区发帖]
```

- [ ] 网络失败在同一浮窗显示“查询失败，请重试”和“重试”按钮。
- [ ] 命中方案时关闭浮窗并打开 Markdown 弹窗。
- [ ] Markdown 支持远程 HTTP/HTTPS 图片；链接交给系统浏览器；拒绝本地文件协议。
- [ ] 完成 Semantics、Tooltip、焦点隔离、Escape 和焦点恢复测试。
- [ ] 运行：

```bash
flutter test test/widget/presentation/widgets/error_solution_flow_test.dart
```

- [ ] 提交：

```bash
git commit -m "feat: 增加安装错误解决方案交互"
```

## Task 7：Flutter 脚本审计和实时执行

- [ ] 扩展 `ShellCommandExecutor` 测试，验证流事件分别标识 stdout/stderr 且旧调用不受影响。
- [ ] 增加脚本审计测试：脚本全文可选择复制，未确认不执行，确认后执行同一字符串。
- [ ] `GuidedRepairService` 在写临时文件前再次验签，调用：

```text
pkexec bash <temporary-script-path>
```

超时固定 30 分钟，日志写入 XDG logs，finally 删除临时脚本。

- [ ] Provider 每 100 ms 批量提交输出，UI 只保留最近 512 KiB，完整日志不截断。
- [ ] 执行弹窗合并显示 `[stdout]`、`[stderr]`，支持自动滚动、复制输出和打开日志目录。
- [ ] 退出码 0 只显示“修复完成，请重新尝试安装”；非 0、超时、授权取消和启动失败显示对应错误。
- [ ] 运行：

```bash
flutter test test/unit/core/platform/shell_command_executor_test.dart
flutter test test/unit/application/services/guided_repair_service_test.dart
flutter test test/widget/presentation/widgets/guided_repair_flow_test.dart
```

- [ ] 提交：

```bash
git commit -m "feat: 增加修复脚本审计与实时执行"
```

## Task 8：首条方案、私钥交付和质量门禁

- [ ] 实施阶段生成正式 Ed25519 PKCS#8 私钥到仓库外临时目录，派生公钥并配置后端和 Flutter。
- [ ] 明确记录私钥绝对路径交给用户；不 `git add` 私钥。
- [ ] 使用离线页签署首条 `RequestInteraction` 修复脚本。
- [ ] 初始化或管理接口写入首条方案，中文 Markdown 完整说明问题。
- [ ] 运行后端：

```bash
mvn -pl ll-server test
mvn -pl ll-server compile -DskipTests
```

- [ ] 运行管理后台：

```bash
npm run type-check
npm run build
```

- [ ] 运行 Flutter：

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

- [ ] 更新三个仓库 `AGENTS.md` 中与本功能有关的长期约定。
- [ ] 确认三个仓库没有混入用户原有修改或私钥。
- [ ] 分别提交首条数据、测试修复和项目约定，提交信息遵循 `type: 描述`。
