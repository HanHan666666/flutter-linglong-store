# 统一应用 ID 与数据目录说明

## 固定 application-id

当前项目的唯一 application-id 固定为：

```text
com.dongpl.linglong-store.v2
```

该 ID 同时用于：

- Linux runtime application-id
- 桌面启动元数据的 `StartupWMClass`
- AppStream / metainfo 的应用 `id`
- Flutter 运行时的数据目录根路径

## 固定数据目录

应用数据目录默认位于：

```text
~/.local/share/com.dongpl.linglong-store.v2
```

当系统设置了 `XDG_DATA_HOME` 时，运行时数据目录会跟随该目录解析为：

```text
$XDG_DATA_HOME/com.dongpl.linglong-store.v2
```

日志目录与运行时数据目录共享同一数据根目录，默认位于：

```text
~/.local/share/com.dongpl.linglong-store.v2/logs
```

当系统设置了 `XDG_DATA_HOME` 时，日志目录会随之解析为：

```text
$XDG_DATA_HOME/com.dongpl.linglong-store.v2/logs
```

日志文件默认写入：

```text
~/.local/share/com.dongpl.linglong-store.v2/logs/linglong-store.log
```

## 启动期迁移约定

启动后、初始化日志与本地存储前，应用会执行一次历史数据目录迁移：

- 默认迁移来源：`~/.local/share/org.linglong-store.LinyapsManager`
- 默认迁移目标：`~/.local/share/com.dongpl.linglong-store.v2`
- 当系统设置了 `XDG_DATA_HOME` 时，迁移来源和目标会切换到同一数据根目录下对应的旧 / 新 application-id 路径
- 旧目录不存在时直接跳过
- 目标目录不存在时自动创建
- 递归迁移旧目录内容
- 目标目录已有同名文件时保留目标目录现有文件，不覆盖
- 迁移结束后尝试删除旧目录
- 删除旧目录失败只记录 warning，不阻断启动

## 历史 ID 约束

以下旧 ID 只允许作为历史迁移或兼容来源出现：

- `org.linglong-store.LinyapsManager`：旧数据目录迁移来源
- `org.linglongstore.linglong_store`：旧运行时 / 打包标识，仅用于历史兼容说明

禁止将它们重新写回新的运行时、打包或数据目录配置。
