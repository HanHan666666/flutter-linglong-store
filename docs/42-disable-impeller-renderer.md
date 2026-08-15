# Flutter 3.47 Impeller 渲染器花屏问题与禁用方案

## 背景

2026-08 升级 Flutter SDK 到 3.47.0（commit `23b942b`，打包镜像随后跟进 `c074953`）后，
应用在启动时出现严重渲染损坏：

- 整窗黑屏，画面撕裂；
- 一块一块的白色三角形碎片叠在 UI 上，UI 内容同样撕裂；
- 同时伴随大量 `Gdk-CRITICAL **: gdk_device_get_axis: assertion 'GDK_IS_DEVICE (device)' failed`
  日志（后文说明：该日志与本问题无关）。

实测环境为 VMware 虚拟机（SVGA II 虚拟显卡，deepin/UOS 桌面）。

## 根因

**Flutter 3.47 起 Impeller 成为 Linux 桌面的默认渲染器**（此前 Linux 一直走
Skia + OpenGL 路径）。Impeller 优先尝试 Vulkan，拿不到可用 Vulkan 时回退到
OpenGL/GLES 路径，而该回退路径正是上游问题最集中的地方：

- [flutter/flutter#124040](https://github.com/flutter/flutter/issues/124040)：Vulkan 后端图形损坏，症状即「三角形 artifacts」；
- [flutter/flutter#130619](https://github.com/flutter/flutter/issues/130619)：Linux OpenGL 后端各类黑屏/崩溃问题汇总；
- 官方文档（<https://docs.flutter.dev/perf/impeller>）明确 Linux 桌面 3.47 起默认启用
  Impeller，且**未来版本将移除 opt-out 能力**。

本机（VMware SVGA II）上系统安装的 Vulkan ICD（intel/nouveau/radeon/lvp/virtio）
没有一个能真正在该虚拟显卡上运行，Impeller 只能落到不成熟的 GL 回退路径，
产生上述花屏。已通过 `flutter run -d linux --no-enable-impeller` 实测验证：
关闭 Impeller 后一切正常，确诊为 Impeller 兼容性问题，与应用代码无关。

## 关键机制事实（排障时踩过的点）

以下是排查过程中从引擎源码/二进制里确认的事实，避免后续重复踩坑：

1. `FLUTTER_LINUX_RENDERER` 环境变量只支持 `software` / `opengl` 两个取值，
   是**软件渲染回退体系**（见 `docs/19-linux-renderer-fallback-preference.md`）的开关，
   与 Impeller 无关；Impeller 关闭后走的就是 `opengl`（Skia）路径。
2. `FLUTTER_ENGINE_SWITCHES` / `FLUTTER_ENGINE_SWITCH_N` 环境变量机制在引擎
   release 构建中被 `#ifndef FLUTTER_RELEASE` 编译移除（见引擎
   `shell/platform/common/engine_switches.cc`），**发布包无法通过环境变量或命令行
   关闭 Impeller**，`--enable-impeller=false` 只在 debug/profile 生效。
3. release 包中禁用 Impeller 的唯一正规途径是 runner 调用引擎公开 API
   `fl_dart_project_set_enable_impeller(project, FALSE)`（Flutter 3.47+ 提供）。

## 修复实现

- `linux/runner/my_application.cc`：创建 `FlDartProject` 后调用
  `fl_dart_project_set_enable_impeller(project, FALSE)`，恢复 3.46 及之前的
  Skia + OpenGL 渲染路径。调用点带注释说明原因与上游 issue 编号。
- `linux/runner/CMakeLists.txt`：通过扫描引擎头文件 `fl_dart_project.h` 是否包含
  `fl_dart_project_set_enable_impeller` 生成编译宏 `FLUTTER_SDK_HAS_IMPELLER_SWITCH`，
  上面的调用由该宏保护。

### 龙芯（loong64）兼容性

龙芯构建链锁定的 SDK 是 3.46.0-1.0.pre-327（见
`build/scripts/build-loong64-in-container.sh`），其引擎头文件没有该 API、引擎本身
也没有 Impeller。若不加保护直接调用，龙芯包会编译/链接失败。因此：

- CMake 检测到 3.46 头文件时不生成宏，调用点整体跳过；
- 龙芯 3.46 引擎默认就是 Skia 路径，行为不受影响；
- 已用 3.46 头文件对 `my_application.cc` 做过 `-fsyntax-only` 编译验证。

## 为什么禁用几乎没有代价：Impeller 的收益边界

**Impeller 的核心收益是「帧时序可预测」，不是更高的 FPS 或更低的内存，**
而前者对本应用的价值很小。具体依据：

1. **官方不量化收益**：docs.flutter.dev/perf/impeller 对 Impeller 的表述全部是
   定性的（离线预编译全部 shader、提前创建管线状态对象、显式缓存控制），
   没有给出任何 FPS、卡顿率或内存的量化数字。它的目标是稳态帧率与 Skia
   持平（parity），消除的是 Skia「首次用到某效果时运行时编译 shader」造成的
   首次动画/首次滚动掉帧。
2. **内存无一致收益**：官方文档对内存只字未提。社区实测结论混合——Impeller
   预先创建管线状态对象，部分场景 GPU 内存反而略高。网传「省约 100 MB」
   出自 Avalonia（.NET 框架）接入 Impeller 的对比，**不是 Flutter 应用的数据，
   不要引用**。本应用的内存大头在 Dart 堆的图片缓存与 KeepAlive 页面缓存
   （见 `docs/memory-optimization/`），与渲染后端基本无关。
3. **本应用 shader 复杂度低**：商店 UI 以列表滚动 + 图片卡片 + 少量圆角/阴影
   为主，属于 shader 编译卡顿的低发场景；且 Skia 会把运行时编译结果写入磁盘
   SkSL 缓存，二次启动后首次卡顿也基本无感。
4. **交换是单向划算的**：用理论上「首帧动画更稳」换「所有显卡驱动栈上画面
   正确」，在 Impeller Linux GL 回退路径能画对像素之前没有讨论余地——
   渲染错误的渲染器没有性能可言。

因此该决策不视为性能取舍，而是兼容性修复。

## 风险与后续复查点

1. **Impeller opt-out 将被移除**：3.47 引擎已对显式关闭 Impeller 打印弃用警告
   （"[Action Required]: Impeller opt-out deprecated."）。上游真正移除时，
   升级 Flutter 必须重新评估：要么留在移除前的最后一个版本，要么依赖上游
   修复后的 Impeller。
2. **何时可以重新开启**：待上游 Linux Impeller（尤其 GL 回退路径与虚拟机/
   小众显卡场景）成熟后，在**正常硬件（物理机）**上把
   `FLUTTER_SDK_HAS_IMPELLER_SWITCH` 宏开/关各编一版，用 `flutter run --profile`
   对比帧时序与 jank 率，再对比 RSS / GPU 内存，得到本应用自己的量化结论后再
   考虑恢复默认。注意：VMware 等虚拟机环境开启 Impeller 即花屏，无法作为
   对比实验环境。恢复方式：删除 runner 中的禁用调用与 CMake 检测即可。
3. **性能预期**：Skia + OpenGL 是 3.46 及之前一直在用的路径，无性能回退；
   禁用 Impeller 不影响 `FLUTTER_LINUX_RENDERER=software` 软件渲染回退体系
   （软件渲染模式下引擎强制非 Impeller）。

## 附：Gdk-CRITICAL `gdk_device_get_axis` 报错

该断言来自 GTK3 处理指针/触摸事件时设备对象为空的场景，与渲染损坏无关、
基本无害，属独立问题。若后续需要处理，另行排查输入事件链路
（触摸板/触屏手势事件在 deepin 合成器下的设备信息缺失）。
