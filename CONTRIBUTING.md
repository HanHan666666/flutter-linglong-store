# 贡献指南

感谢您对玲珑应用商店（Flutter 版本）的关注！我们欢迎任何形式的贡献。

## 🌟 贡献类型

我们欢迎以下类型的贡献：

- 🐛 **报告 Bug** - 帮助我们发现和修复问题
- 💡 **提出新功能建议** - 改进用户体验和功能
- 📖 **改进文档** - 完善 README、代码注释或技术文档
- 🔧 **提交代码修复** - 修复 Bug 或改进性能
- 🎨 **UI/UX 改进** - 提升视觉体验和交互流畅度
- 🌍 **国际化翻译** - 改进多语言支持

## 🚀 快速开始

### 1. Fork & Clone

```bash
# 1. 在 GitHub 上 Fork 本仓库
# 2. Clone 你的 Fork 仓库
git clone https://github.com/YOUR_USERNAME/flutter-linglong-store.git
cd flutter-linglong-store

# 3. 添加上游仓库（保持同步）
git remote add upstream https://github.com/HanHan666666/flutter-linglong-store.git
```

### 2. 开发环境搭建

详细步骤请参考 [README.md](README.md) 的「快速开始」章节：

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成代码文件（Freezed/Riverpod 等）
dart run build_runner build --delete-conflicting-outputs

# 3. 运行应用（开发模式）
flutter run -d linux
```

### 3. 创建功能分支

```bash
# 从最新的 upstream/master 创建分支
git fetch upstream
git checkout upstream/master
git checkout -b your-feature-name

# 分支命名建议：
# - feat/new-feature  （新功能）
# - fix/bug-description（Bug 修复）
# - docs/improve-docs  （文档改进）
# - refactor/code-refactor（重构）
```

### 4. 开发与测试

在开发过程中：

- **遵循代码规范** - 参考 [CLAUDE.md](CLAUDE.md) 的开发原则
- **保持代码整洁** - 使用 `flutter analyze` 检查代码质量
- **添加必要注释** - 关键逻辑和复杂算法需注释说明
- **运行测试验证** - 使用 `flutter test` 确保改动不会破坏现有功能

### 5. 提交代码

#### Conventional Commits 提交规范

本项目遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范：

```
<type>: <简短描述>

<可选的详细说明>
```

**常用类型：**
- `feat`: 新功能（feature）
- `fix`: Bug 修复
- `docs`: 文档改进
- `refactor`: 重构（不影响功能的代码改进）
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具/依赖等杂项

**示例：**
```bash
# 新功能
git commit -m "feat: 添加应用详情页评论区功能"

# Bug 修复
git commit -m "fix: 修复排行榜页面初始化问题"

# 文档改进
git commit -m "docs: 更新 README 环境要求说明"
```

### 6. 推送并创建 Pull Request

```bash
# 1. 推送到你的 Fork 仓库
git push origin your-feature-name

# 2. 在 GitHub 上创建 Pull Request
#    - 标题遵循 Conventional Commits 格式
#    - 在描述中说明改动内容和原因
#    - 关联相关 Issue（如有）
```

## 📝 代码规范

### 设计原则

请遵循 [CLAUDE.md](CLAUDE.md) 中强调的核心原则：

- **开闭原则（OCP）** - 对扩展开放，对修改关闭
- **单一职责原则（SRP）** - 一个类/函数只做一件事
- **依赖倒转原则（DIP）** - 依赖抽象而非具体实现
- **最少知识原则（LOD）** - 减少不必要的依赖关系

### Flutter/Dart 最佳实践

- **不可变数据** - 优先使用 Freezed 生成不可变模型
- **组件化设计** - 小而专注的组件，高复用性
- **性能优先** - 列表使用 builder，避免 build 方法中的重计算
- **清晰的命名** - 变量、函数、类名应自解释

### 文件组织

- **高内聚低耦合** - 文件组织按功能/领域而非类型
- **合理的文件大小** - 单文件不超过 800 行
- **提取工具类** - 大文件拆分为多个小模块

## 🧪 测试验证

提交 PR 前请运行以下验证：

```bash
# 1. 静态分析（确保无 error/warning）
flutter analyze

# 2. 运行测试（验证功能正常）
flutter test

# 3. Profile 模式测试性能（可选）
flutter run -d linux --profile
```

## 💬 Pull Request 审核流程

### PR 描述建议

```markdown
## 📝 改动说明
简要说明本次 PR 的目的和内容。

## 🎯 改动范围
- 涉及的模块/文件
- 影响的功能点

## 🔍 实现思路
关键逻辑的设计思路和取舍理由。

## ✅ 自测结果
已运行的测试和验证结果。

## 🔗 关联 Issue
如有关联的 Issue，请在此标注（如 Fixes #123）。
```

### 审核标准

我们会关注以下方面：

- **代码质量** - 清晰、简洁、符合规范
- **功能正确** - 改动不影响现有功能
- **性能影响** - 无明显性能下降
- **文档完善** - 关键改动有注释说明
- **架构合理** - 不破坏现有架构设计

## 🙋 新手提示

### 如何开始？

1. **寻找适合的任务**：
   - 查看 Issues 中标有 `good first issue` 的任务
   - 选择文档改进、小 Bug 修复等入门任务

2. **阅读项目文档**：
   - [README.md](README.md) - 快速上手
   - [docs/02-flutter-architecture.md](docs/02-flutter-architecture.md) - 架构理解
   - [CLAUDE.md](CLAUDE.md) - 开发规范

3. **询问问题**：
   - 不确定的地方主动提问，不要猜测
   - 在 Issue 或 Discussion 中讨论方案后再动手

### 避免常见错误

- ❌ **不要猜测** - 不确定的接口或逻辑请先查阅代码或询问
- ❌ **不要破坏架构** - 遵循现有的设计模式和目录结构
- ❌ **不要过度设计** - 实现当前需求即可，不要引入不必要的复杂性
- ❌ **不要跳过验证** - 提交前必须运行 `flutter analyze` 和 `flutter test`

## 📚 参考文档

### 项目文档

- [架构设计](docs/02-flutter-architecture.md)
- [UI 规范](docs/03a-ui-design-tokens.md)
- [测试规范](docs/06-testing-and-performance-spec.md)
- [迁移计划](docs/01-migration-plan.md)

### Flutter 官方文档

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

## 🙏 感谢贡献

每一位贡献者都是项目的重要组成部分。无论贡献大小，我们都诚挚感谢您的付出！

如有任何问题或建议，欢迎通过以下方式联系：
- 💬 **社区讨论**: [bbs.deepin.org.cn](https://bbs.deepin.org.cn)
- 🐛 **Issue**: [GitHub Issues](https://github.com/HanHan666666/flutter-linglong-store/issues)