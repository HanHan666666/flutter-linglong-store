# 玲珑商店 Flutter 版内存优化方案

> 目标：将运行内存从 ~700MB 降至 500MB 以内

## 文档目录

| 章节 | 文件 | 内容 |
|------|------|------|
| 01 | [总览与目标](01-overview.md) | 优化目标、预期收益、优先级总表 |
| 02 | [内存现状分析](02-memory-analysis.md) | 当前内存构成拆解、热点定位 |
| 03 | [图片内存优化](03-image-optimization.md) | Image.network 裸用修复、ImageCache 配置生效、截图预览优化 |
| 04 | [KeepAlive 与页面缓存优化](04-keepalive-optimization.md) | 可见性感知补全、LRU 淘汰实现、搜索页 KeepAlive 移除 |
| 05 | [状态管理与 Provider 优化](05-provider-optimization.md) | keepAlive Provider 瘦身、排行榜分页、数据按需加载 |
| 06 | [Hive 缓存优化](06-hive-optimization.md) | LazyBox 改造、过期清理、容量上限 |
| 07 | [其他优化与内存监控](07-misc-and-monitoring.md) | 定时器管控、依赖瘦身、内存监控工具集成 |
| 08 | [实施计划与验收标准](08-implementation-plan.md) | 分阶段里程碑、验收指标、回滚方案 |

## 预期收益汇总

| 优化项 | 预估节省 |
|--------|----------|
| 图片内存优化 | 80~150 MB |
| KeepAlive 页面缓存优化 | 30~60 MB |
| Provider/状态管理优化 | 20~40 MB |
| Hive 缓存优化 | 10~30 MB |
| 其他优化 | 10~20 MB |
| **合计** | **150~300 MB** |

**当前 ~700MB → 优化后预计 400~550MB，满足 500MB 目标。**
