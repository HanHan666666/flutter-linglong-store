# 统一应用 ID 与数据目录开发方案

## 开发目标

统一应用标识为 `com.dongpl.linglong-store.v2`，让 Linux 运行时、打包元数据、数据目录、日志目录都指向同一套 ID。

启动时把旧 Flutter 数据目录迁移到新目录，迁移完成后删除旧目录。

## 目标目录

旧目录：

```text
~/.local/share/org.linglong-store.LinyapsManager
```

新目录：

```text
~/.local/share/com.dongpl.linglong-store.v2
```

日志目录保持：

```text
~/.local/share/com.dongpl.linglong-store.v2/logs
```

## 修改文件

- `linux/CMakeLists.txt`
- `linux/my_application.cc`
- `build/scripts/render-packaging-templates.sh`
- `lib/main.dart`
- 新增：`lib/core/storage/app_data_directory_migration.dart`
- 新增：`test/unit/core/storage/app_data_directory_migration_test.dart`
- 新增：`docs/18-application-id-and-data-directory.md`

## 实现步骤

### 1. 修改 Linux 运行时 application-id

修改 `linux/CMakeLists.txt`：

```cmake
set(APPLICATION_ID "com.dongpl.linglong-store.v2")
```

### 2. 修改旧 Linux runner 的硬编码 ID

修改 `linux/my_application.cc`：

```cpp
"application-id", "com.dongpl.linglong-store.v2"
```

### 3. 修改打包模板

修改 `build/scripts/render-packaging-templates.sh`：

```bash
wm_class="com.dongpl.linglong-store.v2"
app_id="com.dongpl.linglong-store.v2"
```

### 4. 新增启动期数据目录迁移服务

新增文件：

```text
lib/core/storage/app_data_directory_migration.dart
```

迁移逻辑要求：

- 旧目录不存在时直接返回。
- 新目录不存在时创建新目录。
- 递归迁移旧目录内容到新目录。
- 新目录已有同名文件时不覆盖。
- 可迁移内容处理完成后删除旧目录。
- 删除旧目录失败只记录 warning，不阻断启动。
- 不依赖 Flutter UI，不弹窗。

### 5. 在 main.dart 早期调用迁移

调用位置建议放在：

```dart
WidgetsFlutterBinding.ensureInitialized();
```

之后，以下初始化之前：

```dart
SharedPreferences.getInstance();
CacheService.init();
```

这样 `shared_preferences` 和 Hive 初始化时会直接读取新目录。

### 6. 补单元测试

新增测试：

```text
test/unit/core/storage/app_data_directory_migration_test.dart
```

覆盖场景：

- 旧目录不存在时不报错。
- 旧目录存在、新目录不存在时，文件迁移成功，新目录创建，旧目录删除。
- 新目录已有同名文件时不覆盖。
- 嵌套目录可以递归迁移。
- 删除旧目录失败时不抛异常。

### 7. 补文档

新增：

```text
docs/18-application-id-and-data-directory.md
```

文档内容说明：

- 应用唯一 ID 固定为 `com.dongpl.linglong-store.v2`
- 数据目录固定为 `~/.local/share/com.dongpl.linglong-store.v2`
- 日志目录固定为 `~/.local/share/com.dongpl.linglong-store.v2/logs`
- 禁止新增 `org.linglong-store.LinyapsManager`
- 禁止新增 `org.linglongstore.linglong_store`
- 旧 ID 只能作为历史迁移来源出现

## 验证命令

```bash
flutter test test/unit/core/storage/app_data_directory_migration_test.dart
flutter analyze
rg "org\\.linglong-store\\.LinyapsManager|org\\.linglongstore\\.linglong_store" linux lib build docs test
```

最后一个 `rg` 预期不能再搜到需要保留之外的旧 ID。

如果文档里提到旧 ID，只能作为“历史迁移来源”出现。
