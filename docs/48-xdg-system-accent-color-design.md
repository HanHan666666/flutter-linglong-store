# XDG 系统强调色跟随设计

> 文档版本：1.0<br>
> 更新日期：2026-09-04<br>
> 状态：已实施（2026-09-04，提交 93c2fb6 / 760e540 / 8392315 / 90a6986）<br>
> 适用范围：玲珑应用商店 Linux 桌面端、Flutter 全局主题、Linux runner 平台通道<br>
> 反馈致谢：感谢 GitHub 用户 [`EvernightFedora`](https://github.com/EvernightFedora)
> 在 [issue #22 的评论](https://github.com/HanHan666666/flutter-linglong-store/issues/22#issuecomment-5453872807)
> 中提出“界面强调色跟随桌面设置并实时更新”的建议。

## 1. 背景

应用已经支持系统、浅色、深色三种主题模式：`LinglongStoreApp` 根据
`ThemeMode` 和 `MediaQuery.platformBrightness` 决定实际亮度，并在系统明暗变化时
重建根主题。但是强调色仍固定为 `AppColors.primary = #016FFD`，系统设置中的强调色
变化不会进入 Flutter 主题。

当前强调色也不只存在于 `ColorScheme`：主题组件配置、页面和通用组件仍同时读取
`AppColors.primary`、`AppColors.primaryLight` 与 `context.appColors.primary*`。
截至本文编写时，生产代码共有约 80 处此类静态或半静态引用，分布在 23 个文件中。
如果只替换 `MaterialApp.colorScheme`，按钮、侧边栏、进度、焦点边框、选中背景等区域
仍会保留品牌蓝，造成同一页面出现两套强调色。

本需求的核心不是分别适配 KDE 和 GNOME，而是接入桌面环境共同实现的 Freedesktop
接口，让支持标准的桌面自动工作，让暂不支持的环境保持现有稳定外观。

## 2. 标准依据与上游现状

### 2.1 统一接口

采用 XDG Desktop Portal 的
[`org.freedesktop.portal.Settings`](https://flatpak.github.io/xdg-desktop-portal/docs/doc-org.freedesktop.portal.Settings.html)
接口：

- 服务：`org.freedesktop.portal.Desktop`；
- 对象：`/org/freedesktop/portal/desktop`；
- 命名空间：`org.freedesktop.appearance`；
- 键：`accent-color`；
- 值类型：`(ddd)`，依次为 sRGB 的红、绿、蓝三个分量，合法范围均为 `[0, 1]`；
- 变化通知：`SettingChanged(namespace, key, value)`。

规范明确要求把超出 `[0, 1]` 的分量视为“未设置强调色”。实现还应拒绝 NaN、Infinity、
错误的 GVariant 类型和结构不完整的数据，不能把损坏的平台数据传入主题系统。

初始读取采用 `ReadAll(["org.freedesktop.appearance"])`，不采用已经废弃且存在双层
Variant 历史问题的 `Read`，也不强制依赖接口版本 2 才增加的 `ReadOne`。是否支持强调色
以返回结果中是否存在合法 `accent-color` 为准，不通过桌面名称或 portal 版本号猜测。

### 2.2 主流桌面 backend 核验

截至 2026-09-04，上游源码核验结果如下：

| 桌面环境/后端 | 标准键来源 | 实时变化来源 | 结论 |
|---|---|---|---|
| GNOME / `xdg-desktop-portal-gnome` | `org.gnome.desktop.interface` 的强调色转换为标准 `(ddd)` | GSettings 变化后发出标准 `SettingChanged` | 支持 |
| KDE Plasma / `xdg-desktop-portal-kde` | Qt 应用调色板的 highlight 色 | `QGuiApplication::paletteChanged` 后发出标准事件 | 支持 |
| DDE / `xdg-desktop-portal-dde` | Qt 应用调色板的 highlight 色 | `QEvent::ApplicationPaletteChange` 后发出标准事件 | 支持 |
| Cinnamon、MATE、Xfce / `xdg-desktop-portal-xapp` | XApp/GTK 主题中的强调或选中色 | 设置或 GTK 主题变化后发出标准事件 | 支持 |
| 其它桌面或合成器 | 由当前会话选中的 portal backend 决定 | backend 按规范发出事件 | 按能力自动支持 |

核验源码：

- [GNOME Settings backend](https://github.com/GNOME/xdg-desktop-portal-gnome/blob/759e194b83b7fb8320d4dfaa4fcee59b8f56b2b0/src/settings.c)
- [KDE Settings backend](https://github.com/KDE/xdg-desktop-portal-kde/blob/3c920bcb88d36b0786ea15c17e653e0465030a2d/src/settings.cpp)
- [DDE Settings backend](https://github.com/linuxdeepin/xdg-desktop-portal-dde/blob/95551e85084adbb68618f886f6731c8de95b6f8c/src/settings.cpp)
- [XApp Settings backend](https://github.com/linuxmint/xdg-desktop-portal-xapp/blob/4d78d6e9a1eb0c8584af3fe2b699737a4b4baa80/src/settings.c)
- [XApp backend 适用 Cinnamon/MATE/Xfce 的说明](https://github.com/linuxmint/xdg-desktop-portal-xapp)

“上游支持”不等于所有发行版中的旧包都已经支持。应用必须按运行时返回值进行能力探测；
用户系统只安装旧 backend、会话没有 Settings 接口或 portal 配置不完整时，应用回退到
现有品牌蓝，不弹错误、不阻塞启动。

## 3. 目标

1. 所有提供 XDG `accent-color` 的桌面环境自动使用系统强调色，不写 KDE、GNOME、DDE、
   Xfce、Cinnamon、MATE 等桌面名称分支。
2. 用户在系统设置修改强调色后，通过 D-Bus 事件驱动，在下一次 Flutter 渲染帧应用新
   主题；不轮询、不重启应用、不增加人为延迟或过渡动画。
3. 无 portal、无 Settings 接口、无该键、值非法或平台通道不可用时，继续使用现有
   `#016FFD` 品牌蓝，应用其它功能不受影响。
4. 强调色同时适用于浅色、深色以及用户强制指定主题模式的场景；强调色跟随与主题明暗
   选择彼此独立。
5. 所有交互强调色统一由 `ThemeData.colorScheme` 提供，消除页面绕过主题读取静态主色的
   双轨状态。
6. 对任意合法系统颜色派生可读的前景色、容器色和状态色，不能因为亮黄色、接近白色或
   接近黑色的自定义强调色破坏文字与控件对比度。
7. 不增加 Shell、`ll-cli` 或桌面私有命令调用，不增加启动阻塞 IO，不引入新的运行时
   第三方依赖。
8. 保留建议者致谢；实现和发布说明引用本设计文档与原始建议链接。

## 4. 非目标

- 本阶段不新增“跟随系统/使用品牌色/自定义颜色”设置项或持久化字段。需求只要求跟随
  系统，缺少标准值时已有品牌蓝就是确定性回退。
- 不读取 `XDG_CURRENT_DESKTOP` 来选择实现，不直接读取 `kdeglobals`、dconf、GSettings、
  DDE 私有 D-Bus 或主题文件。
- 不以 GTK CSS 的 `theme_selected_bg_color` 作为应用侧第二套兜底。它不是统一的应用
  强调色契约，主题作者也不保证其语义和热更新行为；需要这类兼容层时应先拿到目标环境
  的实测证据，再单独评审。
- 不在本需求中改造现有系统明暗模式来源、系统高对比度或 reduced-motion 支持。它们虽在
  同一 Portal Settings 命名空间中，但属于独立功能。
- 不给 Logo、错误、警告、成功、信息提示或推荐 Banner 图片调色板套用系统强调色。
  Logo 蓝和状态色具有独立语义，不能因桌面个性化设置而改变含义。
- 不强制覆盖原生 GTK 右键菜单的强调色。原生菜单继续由 GTK/当前桌面主题绘制；现有
  `NativeMenuThemeSync` 只同步应用实际明暗模式。

## 5. 方案比较

### 5.1 按桌面环境读取私有设置

分别读取 GNOME GSettings、KDE `kdeglobals`、DDE D-Bus 以及其它桌面的主题配置，可以
兼容部分旧系统，但会把桌面识别、配置格式、变化信号和版本差异永久带入应用。它还会
遗漏组合会话、用户自选 portal backend 和未来桌面环境，不符合最少知识原则。

结论：不采用。

### 5.2 Flutter 侧新增通用 D-Bus 包

纯 Dart 连接 session bus 可以直接调用同一个 XDG 接口，单元测试也较方便。但项目当前
没有 D-Bus 依赖；为一个低频系统事件增加新的运行时包、连接生命周期和 GVariant 映射层，
收益不足。Linux runner 已经链接 GTK/GLib/GIO，并已有 MethodChannel 平台边界。

结论：保留为 native runner 无法满足需求时的备选，不作为首选。

### 5.3 Linux runner 使用 GDBus，通过 EventChannel 发布（采用）

由 Linux runner 使用 GIO 自带的 GDBus 读取 Portal Settings 并订阅变化，通过一个职责
单一的 Flutter `EventChannel` 向 Dart 发布“有效 RGB”或“当前不可用”。这不引入第三方
依赖和外部进程，能够自然处理 GVariant，并与现有 Linux 平台通道结构一致。

平台代码必须放进独立的 `system_accent_color_channel.cc/.h`，`my_application.cc` 只负责
创建、持有和释放通道，禁止继续把 D-Bus 解析和状态机堆进入口文件。

## 6. 总体架构

```text
系统设置
  │
  ▼
当前桌面的 portal backend
  │  实现 org.freedesktop.appearance/accent-color
  ▼
org.freedesktop.portal.Settings
  │  ReadAll + SettingChanged（session D-Bus）
  ▼
Linux runner: SystemAccentColorChannel
  │  校验 (ddd) / 去重 / 生命周期管理
  ▼
Flutter EventChannel
  │
  ▼
Platform: LinuxSystemAccentColorGateway
  │  解析通道契约
  ▼
Application: systemAccentColorProvider
  │  有效颜色或 null
  ▼
app.dart → AppTheme
  │  可访问性友好的浅/深 ColorScheme
  ▼
Presentation 统一读取 Theme.of(context).colorScheme
```

依赖方向保持为：

```text
Presentation/app.dart → Application → Domain ← Platform ← Linux runner
```

平台返回纯 RGB 领域值，不返回 `dart:ui Color`、`ThemeData` 或桌面环境名称。主题构建仍
属于 Flutter `core/config/theme`，D-Bus 和 GVariant 细节不能越过 Platform 边界。

## 7. 分层设计

### 7.1 Domain

新增：

- `lib/domain/models/system_accent_color.dart`
- `lib/domain/repositories/system_accent_color_gateway.dart`

`SystemAccentColor` 保存归一化后的 8-bit `red/green/blue`，不依赖 Flutter。Gateway 只
暴露一个流：

```dart
Stream<SystemAccentColor?> watchAccentColor();
```

`null` 表示当前标准能力不可用或标准明确返回未设置。它不是错误页面状态，也不携带用户
文案。暂不创建泛化的“桌面环境设置仓库”，避免为尚未实施的对比度、动画和明暗模式
提前设计接口。

### 7.2 Platform

新增 `lib/platform/appearance/linux_system_accent_color_gateway.dart`，职责为：

- 使用由应用 ID 生成的 EventChannel 名称监听原生事件；
- 严格验证 Map、布尔字段和 RGB 整数范围，拒绝宽松类型转换；
- 把有效数据转换为 `SystemAccentColor`，把 unavailable 转换为 `null`；
- 对连续相同结果去重；
- 平台通道契约错误写入日志，但不能让根主题订阅永久崩溃。

生产实现由 `bootstrap/production_dependency_overrides.dart` 注入。依赖声明继续集中在
`application_dependency_providers.dart`，测试使用 Fake Gateway，不直接模拟 Linux
桌面名称。

### 7.3 Application

新增 `systemAccentColorProvider`，只维护 Gateway 流的订阅生命周期，不把颜色写进
`GlobalAppState`：

- 强调色是可丢弃的运行时系统状态，不是用户偏好；
- 不写 SharedPreferences，避免应用启动时先显示已经过期的旧系统颜色；
- 初始 loading、当前 null 或不可恢复的通道错误都由根主题解析为品牌蓝；
- 根应用是唯一长期订阅者，页面和卡片不得各自订阅。

系统强调色与 `ThemeMode` 不合并成一个枚举。用户强制浅色或深色时仍跟随强调色；用户
选择系统明暗模式时也只改变亮度来源。

### 7.4 Linux runner

新增 `linux/runner/system_accent_color_channel.cc/.h`，并在 runner CMake 中注册。通道使用
`${APPLICATION_ID}/system_accent_color`，Dart 常量由应用身份生成脚本同步生成，禁止在
Dart 和 C++ 两端分别手写完整 ID。

EventChannel 消息契约固定为：

```text
有效：   { available: true, red: 0..255, green: 0..255, blue: 0..255 }
不可用： { available: false }
```

原生生命周期：

1. Dart 开始监听后，异步连接 session bus；不得在 GTK 主线程执行同步 D-Bus 调用。
2. 先建立 `SettingChanged` 订阅，再异步调用 `ReadAll` 获取初始值，避免读取和订阅之间
   丢失变化。
3. 只处理目标 namespace 与 key，其它 Settings 事件直接忽略。
4. 校验 GVariant 为三个有限 double 且均在 `[0, 1]`，按统一舍入规则转为 8-bit RGB。
5. 对相同 RGB 或连续 unavailable 去重，只给 Flutter 发送有意义变化。
6. Dart 取消监听时取消未完成调用并解除 D-Bus 信号订阅；应用销毁时释放 EventChannel、
   connection、cancellable 和 name-owner watcher。
7. portal 进程重启时保留当前内存颜色，待服务重新出现后执行一次 `ReadAll`；成功返回
   明确缺失/非法值时再回退，避免服务瞬时重启造成界面闪蓝。

初次读取失败、接口不存在或键缺失时发送 unavailable 并保持事件流存活。此类环境能力
缺失只记录诊断日志，不使用 `fl_event_channel_send_error` 终止订阅。

### 7.5 Theme

`AppTheme.buildLightTheme` 和 `buildDarkTheme` 增加明确的强调色输入。系统 RGB 仅作为
主题种子，不直接无条件覆盖所有 ColorScheme 角色：KDE 允许任意自定义颜色，原始颜色
可能接近白色、黑色或高亮黄色，直接同时用于按钮背景和链接文字会破坏对比度。

系统颜色路径使用 `ColorScheme.fromSeed` 的 `DynamicSchemeVariant.fidelity` 派生浅色和
深色角色，在尽量保持色相与饱和度的同时让 `primary/onPrimary`、
`primaryContainer/onPrimaryContainer` 等配对保持可读。项目既有中性表面色、错误色和
边框令牌继续通过 `copyWith` 保留，不让系统强调色重染整个界面。

Portal 不可用时必须进入现有品牌基线路径，保持以下关键值和现有 Golden 外观：

- 主强调色：`#016FFD`；
- 浅色选中背景：`#E6F0FF`；
- 深色选中背景：`#0D2040`。

主题令牌语义调整：

| 类型 | 处理 |
|---|---|
| 按钮、链接、选中态、焦点、进度、活动导航 | 使用当前 `ColorScheme.primary` 系列 |
| 有色背景上的文字/图标 | 使用对应 `onPrimary`/`onPrimaryContainer`，禁止固定白色 |
| 页面、卡片、边框、中性文字 | 保持现有浅/深 `AppColorPalette` |
| error/warning/success/info | 保持固定功能色 |
| Logo 蓝、TOP 标签、Banner 图片调色板 | 保持原业务来源，不跟随系统强调色 |

`AppColors.primary` 应重命名为只表达回退用途的 `brandPrimary`，禁止继续作为组件颜色
读取。`AppColorPalette.primary/primaryLight/primaryDark` 需要移除，Presentation 中全部
迁移到当前 `ThemeData.colorScheme`。`AppTextStyles.link` 不能继续静态捕获品牌蓝，应改为
由上下文主题提供颜色或只保留无颜色的排版属性。

### 7.6 Presentation 与根应用

`LinglongStoreApp` 只新增一次根级 Provider 订阅，并把解析后的强调色传给浅/深主题构建
函数。初始异步加载不阻塞首帧，先使用现有品牌蓝；收到首个合法系统值后重建根主题。

页面迁移必须覆盖当前全部静态强调色引用，尤其注意：

- `const AlwaysStoppedAnimation(AppColors.primary)` 需要改为使用当前主题值；
- disabled/hover/focus 背景不能继续对品牌蓝做固定透明度运算；
- Overlay 内必须使用 Overlay 自己的 `BuildContext` 读取主题；
- `primary` 用作背景时同时迁移对应前景色，不能只换背景；
- 业务状态颜色不能因为当前数值也恰好为蓝色而误迁移成强调色。

系统变化只触发根 Theme 及依赖主题的 Widget 重建，不触发列表重新请求、缓存失效、安装
队列变化或页面路由重建。

## 8. 热更新与时序

```text
用户修改桌面强调色
  → 桌面配置更新
  → portal backend 发出 SettingChanged
  → Linux runner 校验并去重
  → EventChannel 推送 RGB
  → systemAccentColorProvider 发布新值
  → LinglongStoreApp 生成浅/深 ColorScheme
  → 当前可见 Theme 在下一帧生效
```

链路不增加 debounce。强调色变化频率极低，事件到达后直接安排一次正常 Flutter 重建比
定时轮询或动画更快、更省资源。验收中的“立即更新”定义为：应用收到标准 D-Bus 变化
事件后，不等待计时器、不需要用户交互，在下一次可用 Flutter 帧采用新主题。

Portal 首次读取是异步的，因此冷启动可能先绘制一帧品牌蓝，再切换到系统色。为了不把
桌面 IPC 变成启动阻塞项，本方案不在 `main()` 中等待 D-Bus；如实机 Profile 证明这一帧
切换明显可见，再以测量结果评审是否需要短时启动预取，不能预先牺牲启动性能。

## 9. 降级与恢复策略

| 场景 | 行为 |
|---|---|
| session bus 不可用 | 使用品牌蓝，记录一次诊断日志 |
| `org.freedesktop.portal.Desktop` 不可用 | 使用品牌蓝，事件流保持可恢复 |
| Settings 接口不存在 | 使用品牌蓝，不按桌面名称尝试私有接口 |
| namespace/key 缺失 | 视为未设置，使用品牌蓝 |
| 分量越界、NaN、Infinity 或类型错误 | 丢弃值，使用品牌蓝并记录诊断 |
| 初始有效读取 | 发布系统色，重建主题 |
| 连续收到相同值 | 不发布、不重建 |
| portal 瞬时退出 | 暂时保留进程内最后有效颜色，等待服务恢复 |
| portal 恢复 | 重新读取；值变化才发布 |
| Dart 通道契约异常 | Provider 回退品牌蓝；错误不得影响其它业务 |

不持久化最后系统色。进程重启后重新做标准能力探测，避免桌面、用户会话或主题已经改变
却先恢复旧值。

## 10. 性能设计

- 原生侧只执行一次初始 `ReadAll`，后续完全依赖 D-Bus 信号，不设置 Timer 和轮询。
- 不启动 `gsettings`、`dbus-send`、`kreadconfig` 等外部进程。
- RGB 校验、整数转换和去重在 native/Platform 边界完成，Widget `build` 内不解析 Map、
  GVariant 或字符串颜色。
- 仅根 Provider 订阅系统流；列表卡片继续只接收主题依赖，不新增全局 Provider 订阅。
- `ColorScheme` 只在强调色、亮度、locale 或无障碍字体输入实际变化时重建。
- 不为强调色变化添加动画，避免大树插值和连续重绘。
- Linux runner 复用已经由 GTK 带入的 GLib/GIO，不增加包体中的新共享库或 Dart 包。

## 11. 无障碍与视觉边界

系统强调色是外部不可信视觉输入。除依靠 Material 颜色算法外，测试必须覆盖代表性极端
种子（白、黑、黄色、高饱和红/绿/蓝）在浅色和深色下的角色配对。至少检查：

- `primary` 与 `onPrimary`；
- `primaryContainer` 与 `onPrimaryContainer`；
- `primary` 作为可点击文字时与当前 surface 的对比；
- disabled 状态仍可辨识但不抢占正常态；
- 焦点边框在浅色和深色表面都可见。

不得假设有色背景永远搭配白色文字。系统黄色等颜色可能需要深色 `onPrimary`；具体前景
由生成后的 ColorScheme 决定。

## 12. 测试与验证计划

### 12.1 Domain/Platform 单元测试

- 合法 RGB 事件转换为 `SystemAccentColor`；
- unavailable 转换为 null；
- 缺字段、错误类型、负数、大于 255 的整数被拒绝；
- 相同事件去重；
- 订阅取消后释放流；
- 平台异常不会传播成未处理异步错误。

### 12.2 Provider 与主题单元测试

- loading、null、错误均解析为现有品牌基线；
- Fake Gateway 推送新颜色后 Provider 只发布一次有效变化；
- 浅/深主题使用同一系统 seed 派生各自 ColorScheme；
- 品牌回退路径的关键颜色保持当前值；
- 极端颜色的前景/背景对比满足既定 WCAG 门槛；
- Logo 与功能状态色不随强调色变化。

### 12.3 Widget 测试

- 根应用收到 Fake Gateway 事件后无需重启即可改变按钮、侧边栏、进度和焦点主色；
- 强制浅色、强制深色和系统明暗模式下都能更新强调色；
- Overlay/菜单读取更新后的主题；
- 原有主题设置、字体缩放、语言切换与原生菜单明暗同步不回归；
- 现有 Golden 以品牌回退作为确定性输入，避免 CI 主机桌面设置污染基线；另增加一个
  代表性的非蓝强调色 Golden 或核心组件组合测试。

### 12.4 Native 与构建验证

- 为 `(ddd)` 解析、非法 GVariant、舍入边界和 unavailable 事件增加可独立运行的 GLib
  测试；
- `flutter build linux --release` 验证 EventChannel/GDBus 与项目最低构建环境兼容；
- DEB、RPM、AppImage 和玲珑运行身份均不增加额外系统依赖；
- `build/scripts/verify-generated-sources.sh` 校验新增应用身份通道常量未漂移；
- 执行 `flutter analyze`、全量 `flutter test` 和方向感知布局门禁。

### 12.5 实机兼容矩阵

至少验证以下会话；“backend 未提供键时正确回退”同样是通过：

| 会话 | 初始读取 | 系统设置热更新 | portal 重启恢复 | 无键回退 |
|---|---:|---:|---:|---:|
| GNOME | 必测 | 必测 | 必测 | 旧 backend 抽测 |
| KDE Plasma | 必测 | 必测 | 必测 | 旧 backend 抽测 |
| DDE | 必测 | 必测 | 抽测 | 必测 |
| Cinnamon/MATE/Xfce 中至少一个 XApp 会话 | 必测 | 必测 | 抽测 | 必测 |
| 无图形/CI session bus 环境 | 不适用 | 不适用 | 不适用 | 必测 |

实机调试可用以下只读命令确认标准能力，但生产代码禁止执行这些命令：

```bash
gdbus call --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop \
  --method org.freedesktop.portal.Settings.ReadAll \
  "['org.freedesktop.appearance']"

gdbus monitor --session \
  --dest org.freedesktop.portal.Desktop \
  --object-path /org/freedesktop/portal/desktop
```

## 13. 文档同步范围

正式实现时同步维护：

1. `docs/03a-ui-design-tokens.md`：把主色从固定品牌色改为“系统强调色派生，品牌蓝回退”，
   明确 Logo/状态色例外；
2. `docs/02-flutter-architecture.md`：补充系统强调色 Gateway、组合根和根生命周期；
3. `docs/06-testing-and-performance-spec.md`：补充动态主题对比度与热更新验证；
4. `docs/26-application-identity-single-source.md`：登记生成的 EventChannel 命名；
5. `AGENTS.md`：增加长期维护约定与变更记录；
6. 发布说明或对应 PR：引用原始 issue 评论，并致谢 `EvernightFedora`。

本设计文档顶部的致谢必须保留。后续若方案由其他社区成员补充，可在同一位置追加姓名与
对应链接，不能只写模糊的“感谢社区反馈”。

## 14. 分阶段实施与提交边界

### 阶段一：标准接口与平台边界

- 新增纯 RGB Domain 模型与 Gateway；
- 新增 Linux GDBus/EventChannel 实现及生命周期；
- 接入组合根与 Provider；
- 更新应用身份通道生成和验证；
- 添加平台契约与 native 解析测试。

建议提交：`feat: 接入 XDG Portal 系统强调色`

### 阶段二：全局主题热更新

- 根应用订阅单一 Provider；
- AppTheme 接收系统 seed 并构建浅/深 ColorScheme；
- 保留品牌回退精确外观；
- 添加 Provider、主题和根 Widget 热更新测试。

建议提交：`feat: 让全局主题实时跟随系统强调色`

### 阶段三：强调色令牌收敛

- 逐一分类并迁移全部静态主色引用；
- 移除 `AppColorPalette` 中的静态 primary 系列；
- 区分交互强调色、功能状态色、Logo 品牌色与图片内容色；
- 更新受影响的 Widget/Golden 测试。

建议提交：`refactor: 统一应用强调色主题令牌`

### 阶段四：文档与兼容验证

- 完成第 13 节文档同步；
- 记录各桌面实机结果和已知旧 backend 行为；
- 在 PR/发布说明中保留建议者致谢；
- 跑完生成、分析、测试、构建和 Profile 验证。

建议提交：`docs: 完善系统强调色兼容性说明`

每个阶段完成并通过对应验证后单独提交，禁止把平台接入、主题迁移和无关重构混成一个
大提交。

## 15. 验收标准

1. 应用代码不包含 GNOME/KDE/DDE/Xfce/Cinnamon/MATE 名称判断或私有强调色读取。
2. 支持 XDG 标准键的桌面启动后使用系统强调色；修改系统强调色后应用无需重启，在下一
   可用帧更新。
3. 不支持标准键的环境与现状像素级一致地使用品牌蓝，无错误弹窗和启动阻塞。
4. 浅色、深色、系统主题模式均正确；亮黄、近白、近黑等颜色没有不可读文字。
5. 按钮、链接、导航选中态、焦点、进度等不再残留静态品牌蓝；Logo 和功能状态色保持
   原语义。
6. 只有根应用订阅强调色，页面不执行平台 IO、不新增高频 Provider 订阅。
7. portal 消失、重启、返回非法值或通道不可用时应用稳定，资源能随订阅和进程生命周期
   释放。
8. `flutter analyze` 0 error/0 warning，相关单元、Widget、Golden、native 测试和 Linux
   release 构建通过。
9. 技术文档、维护约定、PR/发布说明均保留对 `EvernightFedora` 及原建议链接的致谢。

## 16. 待确认决策

正式编码前需要确认以下产品决策；本文推荐值已按最小功能面给出：

1. **是否默认无条件跟随标准系统强调色**：推荐“是”，不新增应用内开关；
2. **Portal 不支持时的行为**：推荐精确回退当前品牌蓝，不尝试桌面私有兼容层；
3. **系统色的使用方式**：推荐作为 `DynamicSchemeVariant.fidelity` 的 seed 派生可访问
   角色，而不是把原始 RGB 强制用于所有背景和文字；
4. **冷启动策略**：推荐不阻塞首帧，异步读到系统色后立即更新。

以上四项确认后即可按第 14 节进入测试驱动实现。
