# 08 - 实施计划与验收标准

---

## 8.1 三阶段实施计划

### Phase 1：图片内存优化（P0 高收益低风险）

| 序号 | 任务 | 改动文件 | 预估节省 | 验证点 |
|------|------|----------|----------|--------|
| 1.1 | ImageCache 限额生效 | `main.dart` | ~36 MB | DevTools 查看 ImageCache maxBytes=64MB |
| 1.2 | 截图缩略图加 cacheWidth | `app_detail_page.dart` | ~37 MB | 打开详情页前后内存对比 |
| 1.3 | Banner 加 cacheWidth | `recommend_page.dart` | ~19 MB | 推荐页加载前后内存对比 |
| 1.4 | 截图预览限制解码尺寸 | `app_detail_page.dart` | ~14 MB | 滑动截图预览内存不飙升 |
| 1.5 | 内存监控工具 | 新增 `memory_monitor.dart` | — | 控制台可见内存报告 |

**Phase 1 目标：稳态内存从 ~700MB 降至 ~550MB**

**完成标志：**
- `flutter run --profile` 模式下 DevTools Memory 面板确认 ImageCache 不超过 64MB
- 打开 3 个应用详情页后内存不超过 600MB

---

### Phase 2：KeepAlive + Provider 优化（P1 中等收益）

| 序号 | 任务 | 改动文件 | 预估节省 | 验证点 |
|------|------|----------|----------|--------|
| 2.1 | 全部应用页补 VisibilityAwareMixin | `all_apps_page.dart` | ~10 MB | 切走后不再触发 loadMore |
| 2.2 | 排行榜补 VisibilityAwareMixin | `ranking_page.dart` | ~10 MB | 切走后 Tab 不活跃 |
| 2.3 | 自定义分类补 VisibilityAwareMixin | `custom_category_page.dart` | ~10 MB | 切走后停止滚动监听 |
| 2.4 | 搜索列表移除 KeepAlive | `search_list_page.dart` | ~10 MB | 离开搜索页后内存释放 |
| 2.5 | 排行榜 pageSize 100→30 | `ranking_provider.dart` + `ranking_page.dart` | ~15 MB | 初始加载数据量减少 |
| 2.6 | installedApps 数据精简 | `installed_apps_provider.dart` | ~10 MB | 精简后数据量对比 |

**Phase 2 目标：稳态内存从 ~550MB 降至 ~480MB**

**完成标志：**
- 底部导航来回切换 10 次后内存不持续增长
- 排行榜列表滚动到底部后内存增量 < 20MB

---

### Phase 3：Hive + 收尾（P2 加固）

| 序号 | 任务 | 改动文件 | 预估节省 | 验证点 |
|------|------|----------|----------|--------|
| 3.1 | Hive Box → LazyBox | `cache_service.dart` + 调用方 | ~15 MB | Hive 不全量加载 |
| 3.2 | 启动时清理过期缓存 | `cache_service.dart` | ~5 MB | 启动日志可见清理条数 |
| 3.3 | setting_provider 统一缓存入口 | `setting_provider.dart` | 间接 | 不直接操作 Hive Box |
| 3.4 | 列表 RepaintBoundary 优化 | 各列表页面 | ~10 MB | Profile 模式 FPS 无下降 |
| 3.5 | 全量回归测试 | — | — | 所有功能正常 |

**Phase 3 目标：稳态内存 ≤ 450MB，峰值 ≤ 500MB**

**完成标志：**
- 启动后 30 秒静置内存 ≤ 350MB
- 浏览推荐页 → 全部应用 → 排行榜 → 打开 5 个详情页后内存 ≤ 500MB
- 长时间运行（30 分钟）内存无持续增长

---

## 8.2 验收指标

### 硬性指标

| 指标 | 阈值 | 测量方法 |
|------|------|----------|
| 启动 30s 静置 RSS | ≤ 350 MB | `ps aux | grep linglong_store` |
| 常规浏览稳态 RSS | ≤ 500 MB | 执行标准浏览路径后测量 |
| 高压峰值 RSS | ≤ 550 MB | 连续打开 10 个详情页 |
| ImageCache 实际占用 | ≤ 64 MB | DevTools Memory / MemoryMonitor |
| 30 分钟内存增长 | ≤ 20 MB | 持续使用 30 分钟后对比初始值 |

### 标准浏览路径（用于一致测量）

```
1. 冷启动应用
2. 等待推荐页加载完成
3. 滚动推荐页到底
4. 切换至「全部应用」，滚动 3 页
5. 切换至「排行榜」，浏览 4 个 Tab
6. 搜索 "deepin"，浏览搜索结果
7. 打开 3 个应用详情页，查看截图
8. 返回推荐页
9. 静置 10 秒，记录内存
```

### 测量命令

```bash
# 获取进程 RSS（常驻内存集）
ps -o rss,vsz,comm -p $(pgrep -f linglong_store) | awk 'NR>1{print "RSS: " $1/1024 "MB, VSZ: " $2/1024 "MB"}'

# 持续监控（每 5 秒一次）
watch -n 5 "ps -o rss -p \$(pgrep -f linglong_store) | awk 'NR>1{print \$1/1024 \" MB\"}'"
```

---

## 8.3 回滚方案

所有优化均可独立回滚：

| Phase | 回滚方式 | 影响 |
|-------|----------|------|
| Phase 1 | 删除 ImageCache 配置 + 移除 cacheWidth 参数 | 回到原始状态 |
| Phase 2 | 移除 VisibilityAwareMixin + 恢复 pageSize | 回到原始状态 |
| Phase 3 | LazyBox 改回 openBox | 回到原始状态 |

建议每个 Phase 完成后做一次 Git tag，方便快速回滚。

---

## 8.4 风险与注意事项

| 风险 | 概率 | 影响 | 缓解措施 |
|------|------|------|----------|
| cacheWidth 导致图片模糊 | 低 | 体验 | 乘以 DPR 确保清晰度 |
| VisibilityAwareMixin 导致数据不刷新 | 中 | 功能 | 页面恢复可见时轻量刷新 |
| LazyBox 性能比 openBox 慢 | 低 | 性能 | 缓存热数据到内存变量中 |
| 排行榜分页导致体验变化 | 中 | 体验 | 与旧版对齐，加载更多交互一致 |
| RepaintBoundary 影响帧率 | 中 | 性能 | Profile 模式对比测量 |

---

## 8.5 优化效果预期总表

| 阶段 | 优化内容 | 预估节省 | 累计 RSS |
|------|----------|----------|----------|
| 基线 | — | — | ~700 MB |
| Phase 1 | 图片优化 | 100~150 MB | ~550 MB |
| Phase 2 | KeepAlive + Provider | 40~65 MB | ~480 MB |
| Phase 3 | Hive + 杂项 | 20~40 MB | ~440 MB |
| **最终** | | **160~255 MB** | **≤ 500 MB ✅** |
