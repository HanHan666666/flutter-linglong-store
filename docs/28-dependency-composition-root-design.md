# 依赖注入组合根治理设计

## 1. 背景

当前 `core/di/providers.dart` 同时承担三种互相冲突的职责：

- 重新导出 Application 状态 Provider；
- 重新导出 Repository Provider；
- 间接暴露由 Application 文件内部创建的 Data、Platform 实现。

结果是 Application 为了读取一个仓储接口，需要导入会反向导出其他 Application
Provider 的聚合文件；Presentation 也无法从 import 判断自己真正依赖哪些状态。
`core/di/repository_provider.dart` 虽然名称是 DI，但实际直接创建 Data 实现，
而多个 Application Provider 又直接创建 `LinglongCliRepositoryImpl`、
`FileAppOperationJournalRepository` 和 `LinuxSystemNotificationGateway`。

这不是单纯的目录问题，而是“依赖端口”和“生产装配”没有分开。

## 2. 目标与非目标

### 2.1 本阶段目标

1. Application 只看到 Repository/Gateway 接口及其 Provider 端口；
2. Data、Platform 具体实现只在顶层 `bootstrap` 组合根创建；
3. `main.dart` 在唯一根 `ProviderScope` 注入全部生产依赖；
4. 测试直接覆盖同一组端口，不需要构建生产文件、XDG 路径或系统通知；
5. 删除 `core/di/providers.dart` 和 `core/di/repository_provider.dart`；
6. Presentation 改为显式导入实际使用的 Application Provider，不再使用聚合出口；
7. 移除 `AppDetail` 对 `AppRepositoryImpl` 的向下转型。

### 2.2 本阶段非目标

以下问题与组合根相关，但需要改变 API/领域模型或拆分平台服务，因此不夹带处理：

- 列表 Provider 直接消费 `AppApiService`、DTO 和 Data Mapper；
- 环境管理服务直接依赖 Shell 执行器具体类型；
- Linux renderer、签名验证和忽略更新存储的进一步端口化；
- Repository 返回值和结构化错误改造。

这些内容分别进入“结构化结果边界”和“环境管理拆分”阶段。本阶段先消除具体
Repository/Gateway 的分散构造和反向聚合依赖。

## 3. 方案比较

### 3.1 把现有文件移动到 bootstrap

Application 改为导入 `bootstrap/providers.dart`。文件位置更准确，但 Application
仍依赖最外层装配，依赖方向依然倒置。

### 3.2 Application Provider 保留生产默认实现

测试使用方便，但端口声明仍需导入 Data/Platform，无法通过 import 规则阻止以后
继续在业务层创建具体实现。

### 3.3 Application 声明端口，bootstrap 覆盖生产实现

Application 文件只声明 `Provider<DomainInterface>`，默认构造函数明确抛出
“依赖未注入”；`bootstrap` 返回生产 `Override` 列表，`main.dart` 在根
`ProviderScope` 注入。测试可以只覆盖自己触达的端口。

**选择方案 3。** 它让依赖方向可以由静态 import 检查，而不是依靠维护者记忆。

## 4. 目录和职责

```text
lib/
├── application/
│   ├── mappers/
│   │   └── app_detail_mapper.dart
│   └── providers/
│       └── application_dependency_providers.dart
├── bootstrap/
│   └── production_dependency_overrides.dart
├── data/
├── domain/
├── platform/
└── main.dart
```

### 4.1 application_dependency_providers.dart

只允许：

- 引用 Domain Repository/Gateway 接口；
- 声明运行时外部依赖端口；
- 为未注入状态提供统一、可诊断的错误。

本阶段包含：

- `SharedPreferences`；
- `AppRepository`；
- `AnalyticsRepository`；
- `ErrorSolutionRepository`；
- `LinglongCliRepository`；
- `LinglongRepositoryManagementRepository`；
- `AppOperationJournalRepository`；
- `SystemNotificationGateway`。

该文件禁止导入 `data/`、`platform/` 和 `core/di/`。

### 4.2 production_dependency_overrides.dart

这是生产环境唯一组合根，允许同时依赖 Application 端口、Data 实现、Platform
实现和 XDG 路径解析。它负责：

- 创建 API/统计/错误解决方案仓储；
- 根据当前 locale 创建 `LinglongCliRepositoryImpl`；
- 创建 XDG State Journal 文件仓储；
- 创建玲珑仓库管理实现；
- 创建 Linux 系统通知网关；
- 注入 `main.dart` 已完成初始化的 SharedPreferences。

实现保持懒加载；只有对应 Provider 被读取时才创建实例。

### 4.3 main.dart

`main.dart` 仍负责启动顺序和外部资源初始化，但不逐项知道 Repository 具体类型。
它只调用生产组合根生成 Override 列表，再追加冷启动 og URL 这类本次进程输入。

## 5. AppDetail 向下转型治理

`AppDetail` 当前从 `AppRepository` 取得领域模型后，又把同一个 Provider 强转为
`AppRepositoryImpl`，只为调用一个纯字段映射方法。这破坏可替换性，并使任何 Fake
Repository 都必须继承具体实现。

映射逻辑改为 Application 纯函数：

```text
AppDetail domain model -> InstalledApp domain model
```

默认架构由调用方传入当前已知值，最终仍回退为 `x86_64`，不再访问 Data 实现内部
的系统架构缓存。Repository 因此可以被任意符合接口的实现替换。

## 6. 测试和失败语义

依赖端口没有生产默认值是有意设计：

- 正式应用漏装配时在首次读取处抛出包含 Provider 名称的 `StateError`；
- 单元/Widget 测试只需覆盖实际触达的依赖；
- 测试若无意中开始触达新的外部依赖，会明确失败，而不是访问开发机网络或 XDG
  文件后产生偶发结果。

生产组合根至少验证：

- 返回完整的端口 Override 集合；
- XDG Journal 路径无法解析时给出明确错误；
- `main.dart` 只使用组合根，不再散装具体 Repository。

本阶段不为简单 re-export 或 import 改名编写测试；现有 Provider 测试和全量静态
分析负责验证迁移完整性。

## 7. 迁移顺序

1. 新增 Application 依赖端口；
2. 新增生产组合根；
3. `main.dart` 接入生产 Override；
4. 逐个迁移 Application、Presentation 和测试 import；
5. 提取 AppDetail 纯映射并删除具体实现转型；
6. 删除旧 `core/di` 两个聚合文件；
7. 重新生成 Riverpod 文件；
8. 使用 `rg` 确认 Application 不再导入 `core/di`，并确认生产具体实现只有组合根
   负责创建；
9. 执行相关测试和 `flutter analyze`。

## 8. 后续约束

- 新增 Domain Repository/Gateway 时，端口放在
  `application_dependency_providers.dart`，生产实现只在组合根覆盖；
- 禁止从 Application 或 Presentation 新增 `core/di` 式聚合导入；
- Application 内部服务和状态 Provider 直接导入相邻模块，不通过组合根转发；
- 组合根只负责构造对象，不承载业务规则、状态转换或 UI 行为。

