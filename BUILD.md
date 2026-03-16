# 玲珑应用商店社区版 - Flutter Linux 构建指南

## 构建状态

✅ Linux Debug 构建成功
✅ Linux Release 构建成功
✅ 核心测试通过

## 构建输出位置

- **Debug 版本**: `build/linux/x64/debug/bundle/`
- **Release 版本**: `build/linux/x64/release/bundle/`

## 运行应用

### 方式一：使用 flutter run

```bash
cd /home/han/linglong-store/flutter-linglong-store
~/flutter/bin/flutter run -d linux
```

### 方式二：直接运行可执行文件

```bash
# Release 版本
cd /home/han/linglong-store/flutter-linglong-store/build/linux/x64/release/bundle
export LD_LIBRARY_PATH=./lib:$LD_LIBRARY_PATH
./linglong_store
```

## 构建命令

```bash
# Debug 构建
~/flutter/bin/flutter build linux --debug

# Release 构建
~/flutter/bin/flutter build linux --release
```

## 重新生成代码

如果修改了模型或 Provider，需要重新生成代码：

```bash
~/flutter/bin/dart run build_runner build --delete-conflicting-outputs
```

## 项目结构

```
lib/
├── app.dart                    # 应用入口
├── main.dart                   # 主函数
├── application/                # 应用层
│   └── providers/             # Riverpod Providers
├── core/                      # 核心功能
│   ├── config/               # 配置（路由、主题）
│   ├── i18n/                 # 国际化
│   ├── logging/              # 日志
│   ├── platform/             # 平台相关（CLI执行器、窗口服务）
│   └── storage/              # 存储服务
├── data/                      # 数据层
│   ├── datasources/          # 数据源
│   ├── mappers/              # 数据映射
│   └── repositories/         # 仓库实现
├── domain/                    # 领域层
│   ├── models/               # 数据模型
│   └── repositories/         # 仓库接口
└── presentation/             # 表示层
    ├── pages/                # 页面
    └── widgets/              # 组件
```

## 技术栈

- Flutter 3.41.4
- Dart 3.11.1
- flutter_riverpod ^3.3.1 (状态管理)
- go_router ^14.6.2 (路由)
- freezed ^3.2.5 (不可变数据模型)
- window_manager ^0.4.3 (窗口管理)

## 注意事项

1. **编译器问题**: 项目使用 clang++ 编译，已添加 GCC 12 标准库头文件路径

2. **依赖问题**:
   - `system_tray` 包与 Dart 3.x 不兼容，已禁用
   - 使用 `freezed` 3.x 版本需要 `sealed class` 语法

3. **桌面环境**: 应用需要在桌面环境中运行（需要 X11 或 Wayland 显示服务）

## 下一步

- [ ] 在 Deepin DDE 环境中测试应用
- [ ] 完善 UI 页面实现
- [ ] 集成 ll-cli 功能测试
- [ ] 添加更多测试覆盖