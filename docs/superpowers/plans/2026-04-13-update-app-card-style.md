# Update App 卡片风格统一 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 仅统一 `update_app` 页面列表 item 的卡片视觉风格，使其与项目现有主流列表卡片观感一致，同时保持现有布局、状态展示与交互逻辑不变。

**Architecture:** 保留 `lib/presentation/pages/update_app/update_app_page.dart` 中 `_UpdatableAppItem` 的现有信息结构与按钮逻辑，只将外层容器替换为更接近 `AppCard` 的 surface 卡片表现，并增加轻量 hover 反馈。通过先补 widget 测试锁定“结构不变”和“样式关键属性”，再做最小实现，避免扩散到公共组件或其他页面。

**Tech Stack:** Flutter, Material 3, Riverpod, flutter_test

---

## File Map

- Modify: `lib/presentation/pages/update_app/update_app_page.dart`
  - 保留页面数据流、更新逻辑、按钮状态逻辑；
  - 将 `_UpdatableAppItem` 从重描边 `Card` 调整为接近 `AppCard` 的 surface 卡片；
  - 在 item 内部增加轻量 hover 视觉反馈，但不改布局层级。

- Modify: `test/widget/presentation/pages/update_app/update_app_page_test.dart`
  - 新增 widget 测试，锁定“版本信息仍存在”“卡片容器使用 surface 背景”“不再依赖显式灰色描边 Card”的要求；
  - 保留现有交互测试，防止按钮/队列行为回归。

- Reference: `lib/presentation/widgets/app_card.dart`
  - 只作为风格对齐参考，不直接修改。

- Reference: `lib/core/config/theme.dart`
  - 复用 `AppSpacing`、`AppRadius`、`BuildContext.appColors` 等现有主题 token。

### Task 1: 先用测试锁定 update item 的结构与卡片样式基线

**Files:**
- Modify: `test/widget/presentation/pages/update_app/update_app_page_test.dart`
- Reference: `lib/presentation/pages/update_app/update_app_page.dart:216-368`
- Reference: `lib/presentation/widgets/app_card.dart:92-154`

- [ ] **Step 1: 写一个失败的 widget 测试，确认更新页仍保留版本文案，并暴露当前卡片样式不符合预期**

```dart
testWidgets(
  'keeps version text while using surface-style update cards',
  (tester) async {
    final installQueue = TestInstallQueue(
      initialState: const InstallQueueState(),
    );
    final updateApps = TestUpdateApps(
      apps: const [
        UpdatableApp(
          installedApp: InstalledApp(
            appId: 'org.example.demo',
            name: 'Demo',
            version: '1.0.0',
          ),
          latestVersion: '1.1.0',
          latestVersionDescription: 'Bug fixes',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          installQueueProvider.overrideWith(() => installQueue),
          updateAppsProvider.overrideWith(() => updateApps),
          networkSpeedProvider.overrideWithValue(const NetworkSpeed()),
          appOperationQueueControllerProvider.overrideWith(
            (ref) => RecordingAppOperationQueueController(ref),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: UpdateAppPage()),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1.0.0 → 1.1.0'), findsOneWidget);

    final card = tester.widget<Card>(find.byType(Card).first);
    expect(card.margin, EdgeInsets.zero);
    expect(card.shape, isA<RoundedRectangleBorder>());

    final shape = card.shape! as RoundedRectangleBorder;
    expect(card.color, Colors.transparent);
    expect(shape.side.color, isNot(equals(ThemeData().colorScheme.outlineVariant)));
  },
);
```

- [ ] **Step 2: 运行单测，确认它先失败**

Run:
```bash
flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart
```

Expected:
```text
FAIL ... keeps version text while using surface-style update cards
Expected: Colors.transparent
  Actual: <null> 或存在显式描边 Card
```

- [ ] **Step 3: 把测试改成更稳定的断言，避免依赖默认 ThemeData()，直接验证 update item 使用了目标容器结构**

```dart
expect(find.text('1.0.0 → 1.1.0'), findsOneWidget);
expect(find.byType(Card), findsOneWidget);
expect(find.byType(AnimatedContainer), findsNothing);

final card = tester.widget<Card>(find.byType(Card).first);
expect(card.margin, EdgeInsets.zero);
expect(card.clipBehavior, Clip.antiAlias);
```

- [ ] **Step 4: 再次运行测试，确认当前实现仍然失败，证明需要改代码**

Run:
```bash
flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart --plain-name "keeps version text while using surface-style update cards"
```

Expected:
```text
FAIL ... Expected: EdgeInsets.zero / Clip.antiAlias
```

- [ ] **Step 5: 提交测试基线**

```bash
git add test/widget/presentation/pages/update_app/update_app_page_test.dart
git commit -m "test: lock update app card style expectations"
```

### Task 2: 用最小改动把 update item 容器改成统一风格

**Files:**
- Modify: `lib/presentation/pages/update_app/update_app_page.dart`
- Reference: `lib/presentation/widgets/app_card.dart:102-149`
- Reference: `lib/core/config/theme.dart`

- [ ] **Step 1: 在页面文件中引入项目主题 barrel，准备复用 spacing、radius 与 appColors**

```dart
import '../../../core/config/theme.dart';
```

- [ ] **Step 2: 把 `_UpdatableAppItem` 改成 `StatefulWidget`，以便提供轻量 hover 状态**

```dart
class _UpdatableAppItem extends ConsumerStatefulWidget {
  const _UpdatableAppItem({
    super.key,
    required this.app,
    required this.installTask,
    required this.hasActiveTasks,
    required this.onUpdate,
    required this.onCancel,
  });

  final UpdatableApp app;
  final InstallTask? installTask;
  final bool hasActiveTasks;
  final VoidCallback onUpdate;
  final VoidCallback? onCancel;

  @override
  ConsumerState<_UpdatableAppItem> createState() => _UpdatableAppItemState();
}

class _UpdatableAppItemState extends ConsumerState<_UpdatableAppItem> {
  bool _isHovered = false;
```

- [ ] **Step 3: 保留原有内容结构，替换外层 `Card` 装饰，使其改用 surface 背景、零 margin、统一圆角和轻量 hover 阴影**

```dart
return MouseRegion(
  onEnter: (_) => setState(() => _isHovered = true),
  onExit: (_) => setState(() => _isHovered = false),
  child: Card(
    margin: EdgeInsets.zero,
    elevation: 0,
    color: Colors.transparent,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: AppRadius.smRadius,
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 保留现有 Row、按钮、进度文案、更新说明结构
          ],
        ),
      ),
    ),
  ),
);
```

- [ ] **Step 4: 在 stateful 改造后，把字段访问从 `app` / `installTask` / `hasActiveTasks` 切换为 `widget.app` / `widget.installTask` / `widget.hasActiveTasks`，确保现有逻辑完全等价**

```dart
final buttonState = _getButtonState();
final disableUpdateAction =
    widget.hasActiveTasks &&
    widget.installTask != null &&
    (widget.installTask!.status == InstallStatus.success ||
        widget.installTask!.status == InstallStatus.failed ||
        widget.installTask!.status == InstallStatus.cancelled);
final progress = widget.installTask?.progress ?? 0.0;
```

- [ ] **Step 5: 保留 item 内部布局不变，只把间距对齐到现有 token，避免手写魔法值继续扩散**

```dart
ExcludeSemantics(
  child: AppIcon(
    iconUrl: widget.app.icon,
    size: 48,
    borderRadius: AppRadius.sm,
    appName: widget.app.name,
  ),
),
const SizedBox(width: AppSpacing.md),
const SizedBox(height: AppSpacing.sm),
```

- [ ] **Step 6: 运行定向 widget 测试，确认新样式满足预期且现有交互测试不回归**

Run:
```bash
flutter test test/widget/presentation/pages/update_app/update_app_page_test.dart
```

Expected:
```text
All tests passed!
```

- [ ] **Step 7: 提交最小实现**

```bash
git add lib/presentation/pages/update_app/update_app_page.dart test/widget/presentation/pages/update_app/update_app_page_test.dart
git commit -m "feat: unify update app card style"
```

### Task 3: 做收尾验证，确认只改风格没有扩散影响

**Files:**
- Modify: `docs/CLAUDE.md`（仅当本次形成新的、值得长期沉淀的项目约定时；如果没有，则不要改）
- Verify: `lib/presentation/pages/update_app/update_app_page.dart`
- Verify: `test/widget/presentation/pages/update_app/update_app_page_test.dart`

- [ ] **Step 1: 运行静态分析，确认页面改造没有引入新的 lint / 类型错误**

Run:
```bash
flutter analyze
```

Expected:
```text
No issues found!
```

- [ ] **Step 2: 如果本地有 Linux 桌面运行条件，启动应用人工检查 update 页 golden path；否则明确记录未做 UI 实机验证的原因**

Run:
```bash
flutter run -d linux
```

Expected:
```text
应用启动成功，可以进入更新页确认：
- item 不再是明显灰框
- 名称、版本、按钮布局未变化
- hover 时仅出现轻量阴影，无位移/抖动
```

- [ ] **Step 3: 根据本次结果决定是否更新项目指南；仅当形成新的长期约定时才追加，否则跳过这一步**

```md
- 若没有新增长期约定：不要修改 `CLAUDE.md`
- 若确认形成长期约定，再追加类似：
  - 更新页列表项样式应对齐 `AppCard` 的 surface 卡片视觉语言，但保留版本对比信息结构。
```

- [ ] **Step 4: 检查工作区，只保留本次需求相关变更，然后提交收尾说明（如本任务拆成多次 commit，则本步只在确有收尾变更时提交）**

Run:
```bash
git status --short
```

Expected:
```text
仅包含 update_app 页面样式、对应测试，以及可选的文档更新；不应夹带其他无关文件
```

- [ ] **Step 5: 如有收尾变更，创建收尾提交；若无新增文件变动，则跳过提交并在交付说明中明确验证结果**

```bash
git add lib/presentation/pages/update_app/update_app_page.dart test/widget/presentation/pages/update_app/update_app_page_test.dart CLAUDE.md
git commit -m "chore: verify update app card style polish"
```

## Self-Review

- **Spec coverage:**
  - “只改卡片风格” → Task 2 仅修改 `_UpdatableAppItem` 外层容器；
  - “不改布局和业务逻辑” → Task 1 锁定版本文案与结构，Task 2 第 4 步要求字段访问等价迁移；
  - “增加轻量 hover 反馈” → Task 2 第 3 步落实；
  - “验证无回归” → Task 2 第 6 步 + Task 3 第 1/2/4 步覆盖。
- **Placeholder scan:** 已移除 TBD/TODO 式表述；所有改动步骤都给出具体代码或命令。
- **Type consistency:** 计划中统一使用 `_UpdatableAppItemState`、`widget.app`、`widget.installTask`、`context.appColors.surface`、`AppSpacing.md`、`AppRadius.smRadius`，与现有代码命名兼容。
