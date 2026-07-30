# 商店 API 环境配置约定

## 1. 背景

Flutter 客户端和真实 API 集成测试统一通过 `AppConfig.apiBaseUrl` 创建 Dio。
2026-07-26 的一次提交把默认地址从正式商店 API 改成了维护者局域网地址
`192.168.11.147:8687`，但打包脚本和 GitHub Actions 并没有额外注入
`API_BASE_URL`。这会导致：

- 普通开发者无法运行真实 API 集成测试；
- 正式安装包在未额外传参时也会连接不可达的私有地址；
- 测试和正式运行环境无法代表用户实际访问的服务。

## 2. 唯一配置规则

`lib/core/config/app_config.dart` 是客户端 API 基础地址的唯一配置入口：

- 默认值固定为正式地址 `https://storeapi.linyaps.org.cn`；
- 应用运行、Repository 和真实 API 集成测试都读取
  `AppConfig.apiBaseUrl`，禁止在测试或业务模块复制正式 URL；
- 本地联调、预发布环境和私有部署必须显式使用 Dart 编译变量覆盖：

```bash
flutter run -d linux \
  --dart-define=API_BASE_URL=http://127.0.0.1:8687
```

测试其他环境时同样通过 Flutter 的 Dart define 覆盖，不能修改仓库默认值：

```bash
flutter test test/unit/data/i18n_api_integration_test.dart \
  --dart-define=API_BASE_URL=http://127.0.0.1:8687
```

## 3. 测试边界

真实网络测试必须：

- 使用 `flutter test` runner；测试依赖 `flutter_test`，不能由普通
  `dart test` 加载；
- 默认连接生产地址，以验证用户实际使用的 API 契约；
- 在明确离线的 CI 环境通过 `SKIP_NETWORK_TESTS=true` 显式跳过；
- 不把网络不可达误判为 DTO 或业务规则回归。

序列化、Mapper 和 Repository 行为仍应由无网络单元测试覆盖，不能依赖生产服务
来验证本地纯逻辑。

## 4. 安全与维护

API 地址不是凭据，可以作为公开默认配置。令牌、私钥或内部管理地址不得通过
`String.fromEnvironment` 默认值提交到仓库。未来切换正式域名时只修改
`AppConfig.apiBaseUrl` 的默认值，并同步验证应用启动请求和真实 API 集成测试，
避免出现两套地址漂移。
