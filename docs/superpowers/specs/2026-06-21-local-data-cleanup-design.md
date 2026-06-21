# 本地残留数据清理脚本整改设计

## 背景

`build/scripts/clear-local-data.sh` 用于开发联调、首启动验证和用户主动重置本地状态。脚本创建时只覆盖了当时的 SharedPreferences、Documents 下 Hive、图片缓存、日志和 `/tmp` 单实例文件；后续项目已经迁移到统一的 XDG data/config/cache/runtime 路径，现有脚本未同步更新。

本次只整改本地残留清理，不实现应用自我卸载，不调用系统包管理器，也不删除通过商店安装的玲珑应用。

## 目标

1. 清理当前版本真实使用的 XDG 数据、配置、缓存和运行时目录。
2. 清理已有历史版本确认产生的兼容目录和临时残留。
3. 让 `--keep-preferences` 真正保留 SharedPreferences，同时删除其他本地状态。
4. 精确删除本应用的 `flutter_cache_manager` 文件，禁止直接删除其他 Flutter 应用可能共用的缓存目录。
5. 保持默认 dry-run、运行中拒绝清理和明确汇总输出。
6. 用隔离的 HOME/XDG 测试覆盖清理边界，禁止测试触碰开发机真实数据。

## 非目标

- 不实现 deb、rpm、AUR 或 AppImage 的自我卸载。
- 不删除 `/opt/linglong-store`、`/usr/bin/linglong-store`、desktop entry、图标或 AppStream 元数据；这些文件归系统包管理器或 AppImage 管理。
- 不删除 `~/.linglong`、`~/.config/linglong`、`~/.cache/linglong` 和 `/var/lib/linglong`，这些目录归 linyaps/ll-cli 管理。
- 不卸载用户通过商店安装的应用，也不删除应用快捷方式。
- 不在本次整改中修改 Stable/Nightly 共用 application-id 的现状。

## 路径清单

### 当前版本路径

| 类型 | 路径 | 清理策略 |
|------|------|----------|
| 数据 | `$XDG_DATA_HOME/com.dongpl.linglong-store.v2/` | 默认整目录删除；保留偏好模式下仅保留 `shared_preferences.json` |
| 配置 | `$XDG_CONFIG_HOME/com.dongpl.linglong-store.v2/` | 整目录删除，包含渲染器配置 |
| Hive 缓存 | `$XDG_CACHE_HOME/com.dongpl.linglong-store.v2/` | 整目录删除，包含 `cache.hive` 和 `cache.lock` |
| 运行时 | `$XDG_RUNTIME_DIR/com.dongpl.linglong-store.v2/` | 应用退出后整目录删除，包含 lock/socket |
| 图片缓存元数据 | 应用数据目录下 `libCachedImageData.json` | 在删除数据目录前读取，用于识别本应用图片文件 |
| 图片缓存文件 | `${TMPDIR:-/tmp}/libCachedImageData/<relativePath>` | 只删除本应用元数据引用的文件 |

XDG 环境变量未设置时分别回退到 `$HOME/.local/share`、`$HOME/.config` 和 `$HOME/.cache`。`XDG_RUNTIME_DIR` 没有 HOME 回退；缺失时单实例文件按现有业务实现回退到 `${TMPDIR:-/tmp}`。

### 历史兼容路径

| 类型 | 路径 | 原因 |
|------|------|------|
| 可执行文件名数据目录 | `$XDG_DATA_HOME/linglong_store/` | `path_provider_linux` 历史 executable-name 回退路径 |
| 旧 application-id 数据目录 | `$XDG_DATA_HOME/org.linglong-store.LinyapsManager/` | V001 迁移来源，异常中断时可能残留 |
| 旧 Hive 文件 | XDG Documents 下 `cache.hive`、`cache.lock` | 早期 `Hive.initFlutter()` 落盘位置 |
| Hive 临时回退 | `${TMPDIR:-/tmp}/linglong-store-cache/` | HOME/XDG cache 无法解析时的兜底路径 |
| 日志临时回退 | `${TMPDIR:-/tmp}/linglong-store/logs/` | HOME/XDG data 无法解析时的兜底路径 |
| 单实例临时回退 | `${TMPDIR:-/tmp}/linglong-store.lock`、`linglong-store.sock` | `XDG_RUNTIME_DIR` 缺失时的兜底路径 |
| 临时脚本 | `${TMPDIR:-/tmp}` 下项目已知前缀的 `*.sh` | 进程崩溃或强杀可能绕过 `finally` 清理 |

XDG Documents 优先使用显式 `XDG_DOCUMENTS_DIR`，其次调用 `xdg-user-dir DOCUMENTS`，最后回退到 `$HOME/Documents`，以兼容本地化目录。

## 清理流程

1. 解析参数和所有路径，但不创建目标目录。
2. 使用 `pgrep -x linglong_store` 检查应用是否运行；运行中直接拒绝，避免 Hive、日志和 socket 正在写入时被删除。
3. 从当前、可执行文件名和旧 application-id 三个数据目录中收集 `libCachedImageData.json` 的 `relativePath`。
4. 对每个 `relativePath` 执行严格校验：只接受不含目录分隔符、由字母、数字、点、下划线和连字符组成的单文件名。校验失败只警告，不拼接为删除路径。
5. 只删除 `${TMPDIR:-/tmp}/libCachedImageData/` 下经校验且被本应用元数据引用的文件；完成后仅在目录为空时删除目录。
6. 清理当前 XDG config/cache/runtime 目录、历史 Hive 文件和应用专属临时回退目录。
7. 清理当前及历史数据目录：
   - 默认模式整目录删除，自动覆盖未知但属于应用目录的后续文件；
   - `--keep-preferences` 模式保留每个候选数据目录顶层的 `shared_preferences.json`，删除其他文件、隐藏文件和子目录；没有偏好文件的空目录一并删除。
8. 清理当前用户拥有的已知临时脚本残留。不得删除不属于当前用户的同名文件。
9. 输出删除、跳过、保留和警告计数。dry-run 必须执行相同的路径判断，但不得改变文件系统。

图片缓存文件必须先于元数据和数据目录处理，否则脚本无法再确定共享临时目录中哪些文件属于本应用。

## 安全约束

- 所有删除目标必须由固定 XDG 根目录、固定 application-id 或固定文件名组合得到，不接受用户传入任意路径。
- 所有路径参数使用数组或双引号传递，并在 `rm` 前使用 `--` 终止选项解析。
- 路径存在判断同时支持普通文件和符号链接，确保断链符号链接不会被错误计为“不存在”。
- `flutter_cache_manager` 的 `libCachedImageData` 是通用 key；禁止再对整个共享目录执行 `rm -rf`。
- 临时脚本只处理当前用户拥有的普通文件或符号链接，不跟随目录、不扩大 glob 范围。
- `--keep-preferences` 只保留准确命名的 `shared_preferences.json`；日志、迁移状态、缓存元数据和渲染器配置仍应清理。
- 脚本不提升权限。调用者必须以需要清理数据的目标用户身份运行。

## 测试设计

新增独立 shell smoke test，在 `mktemp -d` 下构造隔离的 HOME、XDG data/config/cache/runtime、Documents 和 TMPDIR：

1. 默认 dry-run：输出包含全部目标，但文件系统保持不变。
2. 默认 apply：当前 XDG 目录、历史目录、旧 Hive、运行时文件、临时回退和当前用户临时脚本全部删除。
3. 保留偏好 apply：三个候选数据目录中的 `shared_preferences.json` 保留，其他条目删除；config/cache/runtime 仍删除。
4. 图片缓存归属：删除元数据引用文件，保留共享目录中未引用文件。
5. 非法图片相对路径：`../`、绝对路径和带目录分隔符的值不得影响缓存目录外文件。
6. 运行中保护：通过隔离 PATH 提供可控 `pgrep`，返回运行中时脚本退出非零且不删除任何目标。
7. 断链符号链接：应被识别并删除，不得作为不存在跳过。
8. 语法检查：`bash -n build/scripts/clear-local-data.sh` 和 smoke test 均必须通过。

测试结束时使用 trap 删除测试临时根目录；测试代码不得读取或写入真实 `$HOME`。

## 文档与提交

- 新增面向维护者的本地数据清理说明，记录路径所有权、参数语义、图片缓存边界和验证命令。
- 将“XDG 路径变更必须同步清理脚本和测试”的约定加入项目指南。
- 设计文档、测试与脚本整改、维护文档按独立主目的分别使用 Conventional Commits 提交。

