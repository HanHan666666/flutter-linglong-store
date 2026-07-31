# 40. 应用自更新（App Self-Update）设计方案

> 状态：设计中
> 分支：`feat/app-self-update`
> 涉及范围：设置页检查更新弹窗、DEB / RPM / AppImage 三种安装包的自动安装

## 1. 背景与目标

### 1.1 现状痛点

设置页「检查新版本」功能目前非常鸡肋：

1. 检测到新版本后只弹出一个 `AlertDialog`，内容是「发现新版本 X，当前版本 Y」+ 一个「前往下载」按钮；
2. 「前往下载」只打开**检测成功那一个源**（Gitee 或 GitHub）的 release 页面，没有同时给两个链接；
3. 弹窗不展示更新日志；
4. **完全没有安装能力**——用户必须手动下载 deb / rpm / AppImage 再手动安装。

### 1.2 目标

- **弹窗改进**：检测到新版本时，弹窗只提示有更新，平铺展示 **GitHub** 与 **Gitee** 两个链接按钮（不做下拉选择），另有一个「立即更新」主按钮触发自动安装；
- **自动安装**：支持 DEB（dpkg 系）、RPM（rpm 系）、AppImage 三种安装包的一键自动安装；
- **安装方式检测**：两步确认——先检测发行版，再去对应包管理器查询是否安装了本包；包管理器查不到时，若当前以 AppImage 方式运行，则直接检测当前运行的 AppImage 路径并原地替换。

## 2. 现状调研

### 2.1 检查更新链路

```
设置页「检查新版本」按钮
  └─ SettingPage._checkForUpdate()
      └─ VersionCheckService.checkForUpdate(currentVersion)
          ├─ 优先 Gitee latest release API
          └─ 失败回退 GitHub latest release API
      └─ 返回 sealed VersionCheckResult
          ├─ NoUpdate / UpdateAvailable / VersionInfoMissing / NetworkError
```

- 文件：`lib/application/services/version_check_service.dart`
- 入口：`lib/presentation/pages/setting/setting_page.dart`（`_checkForUpdate`）
- `VersionCheckResultUpdateAvailable` 目前携带 `currentVersion` / `latestVersion` / `releasePageUrl` / `releaseNotes`
- GitHub / Gitee 的 `latest release` API 返回的 JSON 中带 `assets` 数组（`name` + `browser_download_url` + `size`），**安装包直链可直接复用该接口**，无需新增接口

### 2.2 发布资产现状

从 `release.yml` + 打包脚本确认（`build/scripts/package-{deb,rpm,appimage}.sh`）：

| 架构 | DEB | RPM | AppImage |
|------|-----|-----|----------|
| amd64 | `linglong-store_${v}_amd64.deb` | `linglong-store-${v}-1.x86_64.rpm` | `linglong-store-${v}-amd64.AppImage` |
| arm64 | `linglong-store_${v}_arm64.deb` | `linglong-store-${v}-1.aarch64.rpm` | `linglong-store-${v}-arm64.AppImage` |
| loong64 | `linglong-store_${v}_loong64.deb` | ❌ 无 | ❌ 无 |

- DEB 包名：`linglong-store`（`build/packaging/linux/deb/control.in`）
- RPM 包名：`linglong-store`（`build/packaging/linux/rpm/linglong-store.spec.in`）
- 资产经 `sync-gitee-release.sh` 全量同步到 Gitee，**双源都有完整资产**
- release 附带 `hashes.sha256` 资产（`append-release-asset-hashes.sh` 生成并随 release 上传），可作为下载后校验来源

### 2.3 可复用基础设施

| 能力 | 位置 | 说明 |
|------|------|------|
| 特权执行 | `lib/core/platform/shell_command_executor.dart` + `shellCommandExecutorProvider` | `pkexec` 模式，已有 30 分钟超时、日志、流式输出 |
| 关闭应用 | `lib/core/platform/window_service.dart` 的 `WindowService.close()` | 通过 window_manager 关窗 |
| 架构检测 | `globalAppProvider.arch`（`lib/application/providers/global_provider.dart`） | 当前系统架构 |
| 发行版解析 | `lib/application/services/linux_distribution_resolver.dart` | 目前只识别 UOS，需扩展 debian / rpm 系 |
| 签名信封 | `lib/core/security/trusted_content_signature.dart` | 特权脚本签名体系（本次仅做 sha256 校验，不扩展脚本签名） |
| HTTP | Dio（已在 `pubspec.yaml`，`version_check_service` 与 `api_provider` 使用） | 下载安装包 |

## 3. 需求明细

### 3.1 弹窗（阶段一 + 阶段三共用入口）

检测到新版本时弹出：

```
┌────────────────────────────────────────────┐
│  检查更新                                   │
│  发现新版本 vX.Y.Z，当前版本 vA.B.C         │
│                                            │
│  [GitHub]  [Gitee]     （链接平铺，点击跳转）│
│                                            │
│  [立即更新]              [取消]             │
└────────────────────────────────────────────┘
```

- 不展示 changelog；
- GitHub / Gitee 两个链接按钮**平铺**，不做下拉；
- 「立即更新」为主按钮，触发自动安装流程；
- 「取消」关闭弹窗。

### 3.2 自动安装流程

点击「立即更新」后，依次执行：

```
检测安装方式 → 选择安装包 → 下载 → sha256 校验 → 安装 → 重启
```

每个阶段在进度弹窗中展示：阶段文字 + 进度条。

## 4. 总体架构

新增/修改组件：

```
┌─────────────────────────────────────────────────────────────┐
│ presentation                                                │
│  setting_page.dart            （修改）弹窗 + 进度弹窗        │
│  widgets/app_update_flow.dart （新增）进度弹窗 UI           │
├─────────────────────────────────────────────────────────────┤
│ application                                                  │
│  services/app_self_update_service.dart   （新增）编排服务    │
│  services/app_installation_probe.dart    （新增）安装方式检测│
│  services/version_check_service.dart     （修改）携带资产    │
│  services/linux_distribution_resolver.dart（修改）发行版扩展 │
│  providers/app_self_update_provider.dart（新增）Provider    │
├─────────────────────────────────────────────────────────────┤
│ domain                                                        │
│  models/linux_distribution.dart          （修改）包管理器字段│
│  models/app_self_update.dart             （新增）自更新模型  │
├─────────────────────────────────────────────────────────────┤
│ core                                                          │
│  platform/file_downloader.dart           （新增）下载服务    │
└─────────────────────────────────────────────────────────────┘
```

分层约定（遵循 `docs/02-flutter-architecture.md`）：
- domain 只放纯模型与纯函数，不依赖 IO；
- application 编排服务，可注入依赖便于测试；
- presentation 只消费 Provider，不直接执行 `pkexec` / 下载。

## 5. 详细设计

### 5.1 发行版检测扩展

`lib/domain/models/linux_distribution.dart`：

- 新增 `LinuxDistributionId.debian`、`LinuxDistributionId.rpm`（保留 `unknown` / `uos`）；
- 新增字段 `LinuxPackageManager? packageManager`（`dpkg` / `rpm` / `null`）；
- 新增枚举 `LinuxPackageManager { dpkg, rpm }`。

`lib/application/services/linux_distribution_resolver.dart`：

- 新增 matcher：
  - debian 系：`ID` / `ID_LIKE` 含 `debian` / `ubuntu` / `deepin` / `uos` / `linuxmint` / `elementary` 等 → `packageManager = dpkg`；
  - rpm 系：`ID` / `ID_LIKE` 含 `fedora` / `rhel` / `centos` / `opensuse` / `suse` / `rocky` / `almalinux` 等 → `packageManager = rpm`；
- UOS 保留原能力标签，同时归入 debian 系（`packageManager = dpkg`）。

### 5.2 安装方式检测（两步确认 + AppImage 兜底）

新文件 `lib/application/services/app_installation_probe.dart`：

```dart
enum AppInstallationKind {
  packageManagerDpkg,  // 包管理器 dpkg 已安装本包
  packageManagerRpm,   // 包管理器 rpm 已安装本包
  appImage,            // 以 AppImage 方式运行（APPIMAGE 环境变量）
  manual,              // 手动解压 tar.gz 等，无法自动更新
}
```

检测逻辑：

```
1. 读取 /etc/os-release（File('/etc/os-release')）
   └─ LinuxDistributionResolver.resolve() → packageManager
2. 按 packageManager 查包：
   ├─ dpkg：执行 dpkg -s linglong-store（退出码 0 = 已安装）
   └─ rpm： 执行 rpm -q linglong-store（退出码 0 = 已安装）
3. 若包管理器查到已安装 → AppInstallationKind.packageManagerDpkg / Rpm
4. 若未查到（或 packageManager 为 null）：
   └─ 检查 Platform.environment['APPIMAGE'] 非空 且 文件存在
       └─ 是 → AppInstallationKind.appImage（记录真实 AppImage 路径）
5. 否则 → AppInstallationKind.manual
```

依赖注入：`osReleaseReader`、`shellExecutor`、`environment` 全部可注入，便于单测。

### 5.3 发布资产解析

`lib/application/services/version_check_service.dart` 修改：

- 新增领域模型 `ReleaseAsset { name, browserDownloadUrl, size }`（domain 层）；
- `VersionCheckResultUpdateAvailable` 增加字段 `List<ReleaseAsset> assets`；
- `checkForUpdate` 从 release JSON 的 `assets` 数组解析出全部资产（含 `hashes.sha256` 本身）；
- 保留 `releasePageUrl`（GitHub 或 Gitee 中成功源对应的页面）。

新增纯函数 `lib/domain/models/app_self_update.dart`：

- `resolveAssetForPackage({required List<ReleaseAsset> assets, required String arch, required LinuxPackageManager manager})`
  - dpkg + amd64 → 匹配 `*_amd64.deb`；
  - dpkg + loong64 → 匹配 `*_loong64.deb`；
  - rpm + amd64 → 匹配 `*-1.x86_64.rpm`；
  - rpm + arm64 → 匹配 `*-1.aarch64.rpm`；
  - AppImage + amd64 → 匹配 `*-amd64.AppImage`；arm64 → `*-arm64.AppImage`；
  - 匹配规则统一用「文件名前缀 `linglong-store` + 架构段 + 后缀」，不硬编码完整文件名。

架构归一化（amd64 / arm64 / loong64）由 `linux-arch-utils` 的约定 + 现有 `globalAppProvider.arch` 提供；若 arch 无法归一化 → 视为不支持。

### 5.4 文件下载服务

新文件 `lib/core/platform/file_downloader.dart`：

```dart
class FileDownloader {
  FileDownloader({Dio? dio});
  Future<File> downloadToFile({
    required String url,
    required String destinationPath,
    void Function(int received, int total)? onProgress,
  });
}
```

- 使用 Dio 流式下载（`ResponseType.stream`），逐块写入文件；
- `onProgress` 回调（received / total），total 未知时为 -1；
- 下载到临时目录（XDG cache 或系统 tmp）；
- 超时、失败统一抛 `FileDownloadException`。

### 5.5 自更新编排服务

新文件 `lib/application/services/app_self_update_service.dart`：

```dart
enum AppSelfUpdatePhase {
  detectingInstallation,
  resolvingAsset,
  downloading,
  verifying,
  installing,
  restarting,
  done,
  failed,
}

class AppSelfUpdateProgress {
  final AppSelfUpdatePhase phase;
  final double progress;      // 0..1
  final String? message;      // 阶段描述（由 UI 用 l10n 本地化，这里传语义 key）
  final Object? error;
}
```

服务接口（全部依赖注入，可测试）：

```dart
class AppSelfUpdateService {
  AppSelfUpdateService({
    required AppInstallationProbe probe,
    required FileDownloader downloader,
    required ShellCommandExecutor shellExecutor,
    required String Function() currentArch,
    required Future<void> Function(String path) restartApp,
    required Future<void> Function() closeApp,
  });

  Future<bool> performUpdate({
    required VersionCheckResultUpdateAvailable update,
    required void Function(AppSelfUpdateProgress) onProgress,
  });
}
```

#### 5.5.1 DEB 安装路径

```
1. probe 检测 → packageManagerDpkg
2. 从 update.assets 按 arch 选 .deb（resolveAssetForPackage）
3. 下载到临时目录（进度回调）
4. 下载 hashes.sha256 资产 → 解析本文件 sha256 → 本地计算比对
5. 校验通过 → shellExecutor.run(['pkexec', 'dpkg', '-i', debPath], timeout: 30min, logOptions)
6. 安装成功 → 自动重启
```

#### 5.5.2 RPM 安装路径

与 DEB 相同，第 5 步改为 `['pkexec', 'rpm', '-Uvh', rpmPath]`。

#### 5.5.3 AppImage 路径

```
1. probe 检测 → appImage，拿到 APPIMAGE 真实路径 oldPath
2. 从 update.assets 按 arch 选 .AppImage
3. 下载到临时目录（进度回调）
4. sha256 校验（同上）
5. 替换：
   ├─ oldPath 所在目录当前用户可写 → 直接覆盖（File.rename/copy）
   └─ 不可写 → shellExecutor.run(['pkexec', 'install', '-m755', newPath, oldPath])
6. 重启：使用 oldPath（已替换为新版）重新拉起进程
```

**AppImage 替换为什么安全**：AppImage 运行时把内部 squashfs 挂载到 `/tmp/.mount_xxx`，进程从挂载点（已映射内存）运行，磁盘上的 `.AppImage` 仅是数据源；Linux 打开文件按 inode 持有，运行中覆盖磁盘文件不影响当前进程。桌面快捷方式 `Exec` 指向的路径不变，替换内容后依然有效。

#### 5.5.4 手动安装兜底

`AppInstallationKind.manual` 时：
- 弹窗提示「无法自动更新，请前往下载页手动安装」；
- 仅提供 GitHub / Gitee 链接，不提供安装按钮（或安装按钮置灰）。

#### 5.5.5 重启实现

- deb / rpm：安装完成后调用 `restartApp('/opt/linglong-store/linglong_store')`（dpkg/rpm 固定安装路径）；
- AppImage：调用 `restartApp(oldAppImagePath)`（**不能用** `/proc/self/exe` / `Platform.resolvedExecutable`，因为 AppImage 下它指向已卸载的挂载点）；
- 重启方式：`Process.start(executable, const [], mode: ProcessStartMode.detached)`，随后 `closeApp()`（`WindowService.close()`）。

### 5.6 UI 设计

#### 5.6.1 检测到更新弹窗（修改 `_checkForUpdate`）

`AlertDialog`：
- 标题：`l10n.checkUpdate`（检查更新）
- 内容：`l10n.newVersionFound(latestVersion, currentVersion)`
- 按钮行 1：`OutlinedButton` **GitHub** + **Gitee**（平铺，`_openUrl` 跳 release 页）
- 按钮行 2：`FilledButton` **立即更新**（主按钮，触发安装流程）+ `TextButton` **取消**

#### 5.6.2 安装进度弹窗（新文件 `lib/presentation/widgets/app_update_flow.dart`）

- `showDialog` 全屏/居中弹窗，内容：
  - 阶段标题（检测安装方式 / 下载中 / 校验中 / 安装中 / 完成 / 失败）
  - `LinearProgressIndicator`（进度 0..1）
  - 失败时显示错误 + 「重试」/「关闭」按钮
  - 安装完成自动进入重启流程，不需要用户确认

### 5.7 错误处理与边界情况

| 场景 | 处理 |
|------|------|
| 检测不到发行版 / 包管理器查询失败 | 回退 AppImage 检测；再失败 → manual |
| 当前架构无对应包（如 loong64 无 rpm/AppImage） | 提示「当前架构暂无安装包」，仅提供链接 |
| 下载失败 / 超时 | 进度弹窗显示失败，可重试 |
| sha256 校验失败 | 中止安装，提示「文件校验失败」，不执行安装 |
| `hashes.sha256` 资产缺失 | 跳过校验（降级为仅大小校验），或直接拒绝安装（保守策略：拒绝） |
| 用户取消 pkexec 授权 | pkexec 非零退出 → 提示安装失败/已取消 |
| 安装完成后自动重启失败 | 提示「更新已安装，请手动重启应用」 |
| AppImage 旧文件不存在 | 回退 manual 提示 |

### 5.8 安全说明

- 下载源固定为官方 GitHub / Gitee release，资产来自 `latest release` API 的官方 assets；
- deb / rpm 安装前强制 sha256 校验（来源 `hashes.sha256` 官方资产）；
- pkexec 执行时使用参数数组（`['pkexec', 'dpkg', '-i', filePath]`），不拼接 shell 字符串，避免注入；
- 安装包文件路径来自临时目录且由本服务生成，不信任任何用户输入路径。

## 6. i18n 文案

新增（`app_zh.arb` / `app_en.arb` / `app_es.arb` / `app_ru.arb` + `l10n.yaml` 生成）：

| key | zh |
|-----|-----|
| `updateNow` | 立即更新 |
| `updateDownloading` | 正在下载更新包… |
| `updateVerifying` | 正在校验更新包… |
| `updateInstalling` | 正在安装更新… |
| `updateDetectingInstallation` | 正在检测安装方式… |
| `updateRestarting` | 更新完成，正在重启… |
| `updateSucceeded` | 更新完成 |
| `updateFailed` | 更新失败 |
| `updateRetry` | 重试 |
| `updateUnsupportedArch` | 当前架构暂不支持自动安装 |
| `updateManualInstallHint` | 无法自动更新，请手动下载安装 |
| `updateChecksumFailed` | 更新包校验失败，已中止安装 |
| `updateRestartFailed` | 更新已安装，请手动重启应用 |
| `updateCancelled` | 已取消更新 |
| `noInstallationDetected` | 未检测到可更新的安装方式 |

## 7. 测试方案

### 7.1 单元测试

- `test/unit/domain/models/app_self_update_test.dart`：`resolveAssetForPackage` 按架构/包类型匹配（含 loong64 无 rpm 的边界）；
- `test/unit/application/services/app_installation_probe_test.dart`：模拟 os-release + shell 输出 + APPIMAGE 环境变量，覆盖 dpkg/rpm/appImage/manual 四种结果；
- `test/unit/application/services/version_check_service_test.dart`：扩展测试资产解析（携带 assets / hashes.sha256 / 无 assets）；
- `test/unit/application/services/app_self_update_service_test.dart`：注入 fake 依赖，覆盖 deb / rpm / appimage / manual / 校验失败 / 下载失败 / pkexec 失败 / 重启失败 各路径；
- `test/unit/core/platform/file_downloader_test.dart`：下载成功 / 进度回调 / 失败。

### 7.2 Widget 测试

- `test/widget/presentation/pages/setting_page_test.dart`：扩展检测到更新弹窗（GitHub / Gitee 链接存在、「立即更新」按钮存在）；
- `test/widget/presentation/widgets/app_update_flow_test.dart`：进度弹窗各阶段渲染。

### 7.3 验证命令

```
flutter analyze
flutter test test/unit/application/services/version_check_service_test.dart
flutter test test/unit/application/services/app_installation_probe_test.dart
flutter test test/unit/application/services/app_self_update_service_test.dart
flutter test test/unit/domain/models/app_self_update_test.dart
flutter test test/unit/core/platform/file_downloader_test.dart
flutter test test/widget/presentation/pages/setting_page_test.dart
flutter test test/widget/presentation/widgets/app_update_flow_test.dart
```

## 8. 风险与取舍

| 项 | 说明 |
|----|------|
| 自动重启体验 | deb/rpm 安装后自动重启应用；若重启失败，回退提示手动重启 |
| AppImage 无系统集成 | AppImage 场景只替换文件，不重建 .desktop；替换后快捷方式仍指向原路径，有效 |
| 发行版识别覆盖度 | debian / rpm 两大系覆盖绝大多数桌面发行版；Arch 系（AUR 安装）归入 manual，提示手动更新 |
| sha256 校验依赖官方资产 | 若 `hashes.sha256` 缺失则拒绝自动安装（保守策略），仅保留链接引导 |
| pkexec 交互 | 依赖桌面 polkit 弹窗，用户取消 → 提示失败/取消，不破坏现有状态 |
