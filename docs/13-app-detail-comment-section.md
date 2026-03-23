# 应用详情页评论区说明

## 目标
- 在应用详情页增加与 Java 后端对接的评论区能力。
- 保持当前 Flutter 商店的详情页信息层级稳定：应用信息之后展示评论区，版本历史继续保留在评论区下方。
- 严格按现有后端能力实现，不在前端臆造评分、头像、点赞提交等不存在的业务。

## 后端接口
- 评论列表：`POST /app/getAppCommentList`
- 提交评论：`POST /app/saveAppComment`

后端代码参考：
- [AppController.java](/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/controller/app/AppController.java)
- [AppServiceImpl.java](/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java)
- [AppCommentVO.java](/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/vo/AppCommentVO.java)
- [AppCommentSaveBO.java](/home/han/linglong-store/linglong-server/ll-common/src/main/java/com/dongpl/bo/AppCommentSaveBO.java)

## 明确业务边界
- 当前后端仅支持匿名文本评论，不支持登录用户身份、头像、昵称、星级评分。
- 评论列表会返回 `agreeNum / disagreeNum`，但当前后端没有独立的点赞/点踩提交接口，Flutter 端只做只读展示。
- 版本号是评论的可选附加信息，提交评论时允许带版本，也允许不带。
- 提交成功后必须重新请求最新评论列表，不能在前端本地伪造一条“刚提交”的评论卡片。

## UI 布局
- 页面位置：应用信息区之后，版本历史之前。
- 结构分为两块：
  - 评论输入面板：多行输入框、版本下拉框、提交按钮、匿名提示文案。
  - 评论列表：按卡片样式展示已有评论。
- 评论卡片包含：
  - 匿名标识
  - 关联版本（有则显示）
  - 创建时间（有则显示）
  - 评论正文
  - `有帮助 / 没帮助` 统计

## 数据流
### 1. 加载详情
- [app_detail_page.dart](/home/han/linglong-store/flutter-linglong-store/.worktrees/app-detail-comments/lib/presentation/pages/app_detail/app_detail_page.dart) 中的 `AppDetail.loadDetail()` 在详情主体成功后，先等待评论列表完成，再异步加载版本历史。
- 这样可以保证评论区在页面中部出现时，不会长时间停留在空白态。

### 2. 评论列表
- 页面只能通过 [app_repository.dart](/home/han/linglong-store/flutter-linglong-store/.worktrees/app-detail-comments/lib/domain/repositories/app_repository.dart) 的 `getAppComments()` 读取评论。
- 仓储实现集中在 [app_repository_impl.dart](/home/han/linglong-store/flutter-linglong-store/.worktrees/app-detail-comments/lib/data/repositories/app_repository_impl.dart)，禁止在页面层直接新增 Dio/Retrofit 调用。

### 3. 评论提交
- 页面只能通过 `saveAppComment()` 提交评论。
- 仓储层会先对评论文本做 `trim()`，空评论直接拦截，不向后端发送无效请求。
- 提交成功后立即重新请求评论列表，统一以后端返回结果为准。

## 版本选择规则
- 评论输入区的关联版本使用横向胶囊按钮，不再使用承载大量选项的桌面下拉框。
- 默认展示前 `8` 个候选版本；超过 `8` 个时通过“展开全部 / 收起”切换剩余版本。
- 候选值，优先取详情页当前版本，再合并版本历史接口返回的标准化版本列表。
- 候选值需要去重，避免同一版本重复出现。
- 评论区只消费“字符串版本号”，不在组件内自行推导仓库、架构或版本排序。

## 状态约束
- `isLoadingComments` 仅控制评论列表首屏加载态，不影响详情页头部和描述区域交互。
- `isSubmittingComment` 仅控制提交按钮 loading，不阻塞浏览已有评论。
- 评论列表失败时只能显示轻量错误态与重试入口，不能伪装成空列表。

## 性能约束
- 评论列表使用现有详情页滚动容器中的 `ListView.separated(shrinkWrap)`，自身不再创建独立滚动上下文。
- 评论区组件只接收页面层整理后的轻量数据，不在 `build()` 中发起网络请求或做重型计算。
- 版本候选在页面层整理后传入，避免评论组件内部重复扫描详情与版本列表状态。
- 关联版本选择禁止继续回退到一次性展开所有版本的 `DropdownButton`/原生下拉 overlay。

## 测试覆盖
- Widget 测试：
  - 评论列表展示
  - 错误态与重试按钮
  - 评论提交时传出修剪后的文本和选中版本
  - 关联版本胶囊默认展示前 `8` 个并支持展开
- Provider/Repository 单测：
  - `loadDetail()` 会拉取评论
  - `submitComment()` 成功后会刷新最新评论
  - 仓储层能正确调用评论列表与评论提交接口
