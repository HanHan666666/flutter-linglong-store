# 应用标签搜索 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Tag 从附属表 JSON 迁移到独立表，并让 Flutter 应用详情标签通过标题栏 Tag 胶囊复用现有搜索结果链路。

**Architecture:** 后端保留 `/visit/getSearchAppList` 单一搜索接口，以 `tagName + tagLan` 作为精确标签条件；`ll_app_tag` 是标签唯一数据源，定时任务按应用事务性删除旧数据并批量写入新数据。Flutter 使用路由持久化标签搜索条件，搜索 Provider 复用现有分页状态机，标题栏在标签模式下渲染不可拆分胶囊。

**Tech Stack:** MySQL 8, Spring Boot 3, MyBatis-Plus, Redis Cache, Java 17, Flutter, Riverpod, Freezed, Retrofit, GoRouter, JUnit 5, Mockito, Flutter Widget Test.

---

## 0. 实施约束与仓库

- Flutter 仓库：`/home/han/code/linglong-store/flutter-linglong-store`。
- 后端仓库：`/home/han/code/linglong-store/linglong-server`。
- 未经用户允许禁止使用 git worktree；本计划不使用 worktree。
- 两个仓库分别创建 `codex/app-tag-search` 分支，分别提交，禁止跨仓库混合提交。
- 每个任务严格执行 RED → GREEN → REFACTOR → Commit。
- 所有新增或修改的代码注释使用中文，并解释业务边界和设计原因。
- 迁移顺序固定为：执行建表回填 SQL → 部署后端读写新表 → 部署 Flutter → 稳定验证 → 人工执行破坏性清理 SQL。
- 破坏性清理脚本只交付，不在首次发布中自动执行。

实施开始时分别创建分支：

```bash
git -C /home/han/code/linglong-store/linglong-server switch -c codex/app-tag-search
git -C /home/han/code/linglong-store/flutter-linglong-store switch -c codex/app-tag-search
```

## 1. 文件改动清单

### 后端仓库 Create

- `sql/migration_20260620_create_app_tag.sql`
- `sql/migration_20260620_drop_legacy_app_tag_list.sql`
- `ll-schedule/src/main/java/com/dongpl/entity/AppTagEntity.java`
- `ll-schedule/src/main/java/com/dongpl/mapper/AppTagMapper.java`
- `ll-schedule/src/main/resources/mapper/AppTagMapper.xml`
- `ll-schedule/src/main/java/com/dongpl/service/AppTagSyncService.java`
- `ll-schedule/src/main/java/com/dongpl/service/impl/AppTagSyncServiceImpl.java`
- `ll-schedule/src/test/java/com/dongpl/service/impl/AppTagSyncServiceImplTest.java`
- `ll-schedule/src/test/java/com/dongpl/listener/RetrieveData2AppAffiliatedTableListenerTest.java`
- `ll-server/src/main/java/com/dongpl/entity/AppTagEntity.java`
- `ll-server/src/main/java/com/dongpl/mapper/master/AppTagMapper.java`
- `ll-server/src/main/resources/mapper/master/AppTagMapper.xml`
- `ll-server/src/test/java/com/dongpl/service/impl/AppVisitDtlsServiceImplTest.java`

### 后端仓库 Modify/Delete

- Modify: `ll-schedule/pom.xml`
- Modify: `ll-schedule/src/main/java/com/dongpl/listener/RetrieveData2AppAffiliatedTableListener.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/entity/AppAffiliatedDtls.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/service/impl/AppCacheServiceImpl.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/utils/AppRedisKeys.java`
- Delete: `ll-schedule/src/main/java/com/dongpl/handler/ListAppTagTypeHandler.java`
- Modify: `ll-server/src/main/java/com/dongpl/bo/AppMainBO.java`
- Modify: `ll-server/src/main/java/com/dongpl/dto/AppMainDto.java`
- Modify: `ll-server/src/main/java/com/dongpl/entity/AppAffiliatedDtls.java`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppVisitDtlsServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/response/Constants.java`
- Modify: `ll-server/src/main/resources/mapper/master/AppMainDtlsMapper.xml`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppCacheServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/utils/AppRedisKeys.java`
- Delete: `ll-server/src/main/java/com/dongpl/handler/ListAppTagTypeHandler.java`
- Modify: `ll-server/src/test/java/com/dongpl/service/impl/AppDetailContractServiceTest.java`
- Modify: `ll-server/src/test/java/com/dongpl/response/ConstantsTest.java`
- Modify: `AGENTS.md`

### Flutter 仓库 Modify/Generate

- Modify: `lib/domain/models/app_detail.dart`
- Modify: `lib/data/models/api_dto.dart`
- Modify: `lib/data/repositories/app_repository_impl.dart`
- Modify: `lib/application/providers/search_provider.dart`
- Modify: `lib/core/config/routes.dart`
- Modify: `lib/presentation/pages/search_list/search_list_page.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/presentation/widgets/title_bar.dart`
- Modify: `lib/presentation/widgets/app_detail_hero_header.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Generate: `lib/domain/models/app_detail.freezed.dart`
- Generate: `lib/data/models/api_dto.freezed.dart`
- Generate: `lib/data/models/api_dto.g.dart`
- Generate: `lib/application/providers/search_provider.freezed.dart`
- Generate: `lib/application/providers/search_provider.g.dart`
- Generate: `lib/core/i18n/l10n/app_localizations*.dart`
- Modify: `test/unit/data/models/search_request_test.dart`
- Modify: `test/unit/data/repositories/app_repository_impl_test.dart`
- Modify: `test/unit/application/providers/search_provider_test.dart`
- Modify: `test/widget/presentation/pages/search_list_page_test.dart`
- Modify: `test/widget/presentation/widgets/title_bar_search_test.dart`
- Create: `test/widget/presentation/widgets/app_detail_hero_header_test.dart`
- Modify: `AGENTS.md`

---

### Task 1：交付可复核的数据库迁移脚本

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Create: `sql/migration_20260620_create_app_tag.sql`
- Create: `sql/migration_20260620_drop_legacy_app_tag_list.sql`

- [x] **Step 1: 编写建表、回填和校验 SQL**（已在测试库验证：source=15682，migrated=15682，duplicate=0行，invalid=0）

`migration_20260620_create_app_tag.sql` 使用 MySQL 8 `JSON_TABLE`，内容必须可重复执行：

```sql
CREATE TABLE IF NOT EXISTS ll_app_tag (
    id VARCHAR(32) NOT NULL COMMENT '标签记录主键',
    app_id VARCHAR(255) NOT NULL COMMENT '玲珑应用标识',
    tag_name VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '标签名称',
    lan VARCHAR(32) NOT NULL COMMENT '标签语言',
    sort_order INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '上游标签展示顺序',
    create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_app_tag_identity (app_id, lan, tag_name),
    KEY idx_app_tag_lookup (lan, tag_name, app_id),
    KEY idx_app_tag_order (app_id, lan, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='应用标签明细';

INSERT INTO ll_app_tag (id, app_id, tag_name, lan, sort_order, create_time)
SELECT
    REPLACE(UUID(), '-', ''),
    source.app_id,
    source.tag_name,
    source.lan,
    source.sort_order,
    NOW()
FROM (
    SELECT
        extracted.app_id,
        extracted.tag_name,
        extracted.lan,
        MIN(extracted.sort_order) AS sort_order
    FROM (
        SELECT
            affiliated.app_id,
            TRIM(tags.tag_name) AS tag_name,
            TRIM(tags.lan) AS lan,
            tags.ordinality - 1 AS sort_order
        FROM ll_app_affiliated_dtls affiliated
        JOIN JSON_TABLE(
            CASE
                WHEN JSON_VALID(affiliated.app_tag_list) THEN affiliated.app_tag_list
                ELSE JSON_ARRAY()
            END,
            '$[*]' COLUMNS (
                ordinality FOR ORDINALITY,
                tag_name VARCHAR(255) PATH '$.name' NULL ON EMPTY,
                lan VARCHAR(32) PATH '$.lan' NULL ON EMPTY
            )
        ) tags
        WHERE affiliated.app_id IS NOT NULL
          AND TRIM(affiliated.app_id) <> ''
          AND tags.tag_name IS NOT NULL
          AND TRIM(tags.tag_name) <> ''
          AND tags.lan IS NOT NULL
          AND TRIM(tags.lan) <> ''
    ) extracted
    GROUP BY extracted.app_id, extracted.tag_name, extracted.lan
) source
ON DUPLICATE KEY UPDATE sort_order = VALUES(sort_order);

-- 校验 1：两个结果必须相等。
SELECT COUNT(*) AS source_valid_distinct_count
FROM (
    SELECT
        affiliated.app_id,
        TRIM(tags.tag_name) AS tag_name,
        TRIM(tags.lan) AS lan
    FROM ll_app_affiliated_dtls affiliated
    JOIN JSON_TABLE(
        CASE
            WHEN JSON_VALID(affiliated.app_tag_list) THEN affiliated.app_tag_list
            ELSE JSON_ARRAY()
        END,
        '$[*]' COLUMNS (
            tag_name VARCHAR(255) PATH '$.name' NULL ON EMPTY,
            lan VARCHAR(32) PATH '$.lan' NULL ON EMPTY
        )
    ) tags
    WHERE affiliated.app_id IS NOT NULL
      AND TRIM(affiliated.app_id) <> ''
      AND tags.tag_name IS NOT NULL
      AND TRIM(tags.tag_name) <> ''
      AND tags.lan IS NOT NULL
      AND TRIM(tags.lan) <> ''
    GROUP BY affiliated.app_id, TRIM(tags.tag_name), TRIM(tags.lan)
) source_validation;

SELECT COUNT(*) AS migrated_tag_count FROM ll_app_tag;

-- 校验 2：应返回 0 行。
SELECT app_id, lan, tag_name, COUNT(*) AS duplicate_count
FROM ll_app_tag
GROUP BY app_id, lan, tag_name
HAVING COUNT(*) > 1;

-- 校验 3：应返回 0。
SELECT COUNT(*) AS invalid_tag_count
FROM ll_app_tag
WHERE app_id = '' OR tag_name = '' OR lan = '';
```

- [x] **Step 2: 编写延后执行的破坏性清理 SQL**

`migration_20260620_drop_legacy_app_tag_list.sql` 明确写出执行前提和破坏性操作：

```sql
-- 仅在 ll-server 与 ll-schedule 均已稳定读写 ll_app_tag，且回填校验通过后执行。
ALTER TABLE ll_app_affiliated_dtls DROP COLUMN app_tag_list;
```

- [x] **Step 3: 在测试库执行迁移并复核**（已执行：source_valid_distinct_count=15682，migrated_tag_count=15682，duplicate_count 查询返回 0 行，invalid_tag_count=0）

Run:

```bash
mysql --host="$MYSQL_HOST" --port="$MYSQL_PORT" \
  --user="$MYSQL_USER" --password="$MYSQL_PASSWORD" "$MYSQL_DATABASE" \
  < sql/migration_20260620_create_app_tag.sql
```

Expected:

```text
脚本退出码为 0；source_valid_distinct_count 等于 migrated_tag_count；duplicate_count 查询返回 0 行；invalid_tag_count 为 0。
```

- [x] **Step 4: 重复执行一次验证幂等性**（第二次执行 migrated_tag_count 仍为 15682，无唯一键异常）

再次运行相同命令，确认 `migrated_tag_count` 不增长且无唯一键异常。

- [x] **Step 5: Commit**（commit 92eef28: feat: 增加应用标签独立表迁移脚本）

```bash
git add sql/migration_20260620_create_app_tag.sql \
  sql/migration_20260620_drop_legacy_app_tag_list.sql
git commit -m "feat: 增加应用标签独立表迁移脚本"
```

---

### Task 2：实现定时任务标签事务替换服务

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Modify: `ll-schedule/pom.xml`
- Create: `ll-schedule/src/main/java/com/dongpl/entity/AppTagEntity.java`
- Create: `ll-schedule/src/main/java/com/dongpl/mapper/AppTagMapper.java`
- Create: `ll-schedule/src/main/resources/mapper/AppTagMapper.xml`
- Create: `ll-schedule/src/main/java/com/dongpl/service/AppTagSyncService.java`
- Create: `ll-schedule/src/main/java/com/dongpl/service/impl/AppTagSyncServiceImpl.java`
- Test: `ll-schedule/src/test/java/com/dongpl/service/impl/AppTagSyncServiceImplTest.java`

- [x] **Step 1: 增加测试依赖并写失败测试**

在 `ll-schedule/pom.xml` 增加 `spring-boot-starter-test`，测试覆盖非空替换、空列表清空、去重和非法 appId：

```java
@ExtendWith(MockitoExtension.class)
class AppTagSyncServiceImplTest {
    @Mock
    private AppTagMapper appTagMapper;

    @InjectMocks
    private AppTagSyncServiceImpl service;

    @Captor
    private ArgumentCaptor<List<AppTagEntity>> rowsCaptor;

    private static AppTag tag(String name, String lan) {
        AppTag tag = new AppTag();
        tag.setName(name);
        tag.setLan(lan);
        return tag;
    }

    @Test
    void replaceTags_deletesOldRowsAndBatchInsertsNormalizedTags() {
        AppTag first = tag(" 办公 ", "zh_CN");
        AppTag duplicate = tag("办公", "zh_CN");
        AppTag second = tag("Office", "en_US");

        service.replaceTags("org.example.app", List.of(first, duplicate, second));

        verify(appTagMapper).deleteByAppId("org.example.app");
        verify(appTagMapper).insertBatch(rowsCaptor.capture());
        List<AppTagEntity> rows = rowsCaptor.getValue();
        assertEquals(2, rows.size());
        assertEquals("办公", rows.get(0).getTagName());
        assertEquals(0, rows.get(0).getSortOrder());
        assertEquals("Office", rows.get(1).getTagName());
        assertEquals(2, rows.get(1).getSortOrder());
    }

    @Test
    void replaceTags_withExplicitEmptyListOnlyDeletesOldRows() {
        service.replaceTags("org.example.app", List.of());

        verify(appTagMapper).deleteByAppId("org.example.app");
        verify(appTagMapper, never()).insertBatch(anyList());
    }

    @Test
    void replaceTags_rejectsBlankAppIdBeforeDeletingData() {
        assertThrows(IllegalArgumentException.class,
                () -> service.replaceTags("  ", List.of()));
        verifyNoInteractions(appTagMapper);
    }
}
```

- [ ] **Step 2: 运行测试并确认 RED**

Run:

```bash
mvn -pl ll-schedule -Dtest=AppTagSyncServiceImplTest test
```

Expected:

```text
FAIL，提示 AppTagSyncServiceImpl、AppTagMapper 或 AppTagEntity 不存在。
```

- [x] **Step 3: 创建实体、Mapper 和批量写入 SQL**（含 AppTagEntity / AppTagMapper / AppTagMapper.xml；并为 schedule DBMaster 增 setMapperLocations 以加载 XML）

实体映射保持单一职责：

```java
@Data
@TableName("ll_app_tag")
public class AppTagEntity {
    @TableId("id")
    private String id;
    @TableField("app_id")
    private String appId;
    @TableField("tag_name")
    private String tagName;
    @TableField("lan")
    private String lan;
    @TableField("sort_order")
    private Integer sortOrder;
    @TableField("create_time")
    private String createTime;
}
```

Mapper 接口：

```java
@Mapper
public interface AppTagMapper extends BaseMapper<AppTagEntity> {
    int deleteByAppId(@Param("appId") String appId);
    int insertBatch(@Param("tags") List<AppTagEntity> tags);
}
```

`AppTagMapper.xml`：

```xml
<mapper namespace="com.dongpl.mapper.AppTagMapper">
    <delete id="deleteByAppId">
        DELETE FROM ll_app_tag WHERE app_id = #{appId}
    </delete>
    <insert id="insertBatch">
        INSERT INTO ll_app_tag
            (id, app_id, tag_name, lan, sort_order, create_time)
        VALUES
        <foreach collection="tags" item="tag" separator=",">
            (#{tag.id}, #{tag.appId}, #{tag.tagName}, #{tag.lan},
             #{tag.sortOrder}, #{tag.createTime})
        </foreach>
    </insert>
</mapper>
```

- [x] **Step 4: 实现事务替换服务**

```java
public interface AppTagSyncService {
    /**
     * 使用上游明确返回的完整标签集合替换指定应用标签。
     * 空集合表示明确无标签；null 由调用方解释为未提供，不得传入本方法。
     */
    void replaceTags(String appId, List<AppTag> tags);
}
```

```java
@Service
public class AppTagSyncServiceImpl implements AppTagSyncService {
    @Resource
    private AppTagMapper appTagMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void replaceTags(String appId, List<AppTag> tags) {
        String normalizedAppId = StrUtil.trim(appId);
        if (StrUtil.isBlank(normalizedAppId)) {
            throw new IllegalArgumentException("appId不能为空");
        }
        if (tags == null) {
            throw new IllegalArgumentException("tags不能为null");
        }

        appTagMapper.deleteByAppId(normalizedAppId);
        List<AppTagEntity> rows = normalizeTags(normalizedAppId, tags);
        if (rows.isEmpty()) {
            return;
        }
        appTagMapper.insertBatch(rows);
    }

    private List<AppTagEntity> normalizeTags(String appId, List<AppTag> tags) {
        Set<String> identities = new HashSet<>();
        List<AppTagEntity> rows = new ArrayList<>();
        for (int index = 0; index < tags.size(); index++) {
            AppTag source = tags.get(index);
            if (source == null) {
                continue;
            }
            String name = StrUtil.trim(source.getName());
            String lan = StrUtil.trim(source.getLan());
            if (StrUtil.isBlank(name) || StrUtil.isBlank(lan)) {
                continue;
            }
            if (!identities.add(lan + "\u0000" + name)) {
                continue;
            }
            AppTagEntity row = new AppTagEntity();
            row.setId(IdUtil.getSnowflakeNextIdStr());
            row.setAppId(appId);
            row.setTagName(name);
            row.setLan(lan);
            row.setSortOrder(index);
            row.setCreateTime(DateUtil.now());
            rows.add(row);
        }
        return rows;
    }
}
```

- [x] **Step 5: 运行测试并确认 GREEN**（Tests run: 3, Failures: 0, Errors: 0；BUILD SUCCESS）

- [ ] **Step 6: Commit**

```bash
git add ll-schedule/pom.xml ll-schedule/src/main/java/com/dongpl/entity/AppTagEntity.java \
  ll-schedule/src/main/java/com/dongpl/mapper/AppTagMapper.java \
  ll-schedule/src/main/resources/mapper/AppTagMapper.xml \
  ll-schedule/src/main/java/com/dongpl/service/AppTagSyncService.java \
  ll-schedule/src/main/java/com/dongpl/service/impl/AppTagSyncServiceImpl.java \
  ll-schedule/src/test/java/com/dongpl/service/impl/AppTagSyncServiceImplTest.java
git commit -m "feat: 增加标签数据事务替换服务"
```

> 实测：RED（编译失败，符号缺失）→ GREEN（3 测试通过）→ 已提交。

---

### Task 3：将定时详情同步切换到标签独立表

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Modify: `ll-schedule/src/main/java/com/dongpl/listener/RetrieveData2AppAffiliatedTableListener.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/entity/AppAffiliatedDtls.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/service/impl/AppCacheServiceImpl.java`
- Modify: `ll-schedule/src/main/java/com/dongpl/utils/AppRedisKeys.java`
- Delete: `ll-schedule/src/main/java/com/dongpl/handler/ListAppTagTypeHandler.java`
- Test: `ll-schedule/src/test/java/com/dongpl/listener/RetrieveData2AppAffiliatedTableListenerTest.java`

- [x] **Step 1: 写失败测试锁定空值与遗漏边界**

将标签同步入口提取为包可见方法 `syncTags(AppDetail)`，测试明确空列表会替换、null 不处理、异常不阻断：

```java
@ExtendWith(MockitoExtension.class)
class RetrieveData2AppAffiliatedTableListenerTest {
    @Mock
    private AppTagSyncService appTagSyncService;
    @Mock
    private CacheManager cacheManager;
    @Mock
    private Cache searchCache;

    @InjectMocks
    private RetrieveData2AppAffiliatedTableListener listener;

    @Test
    void syncTags_withExplicitEmptyListDeletesThroughReplaceService() {
        AppDetail detail = new AppDetail();
        detail.setPkgName("org.example.app");
        detail.setAppTagList(List.of());

        listener.syncTags(detail);

        verify(appTagSyncService).replaceTags("org.example.app", List.of());
    }

    @Test
    void syncTags_withMissingTagFieldPreservesOldRows() {
        AppDetail detail = new AppDetail();
        detail.setPkgName("org.example.app");
        detail.setAppTagList(null);

        listener.syncTags(detail);

        verifyNoInteractions(appTagSyncService);
    }

    @Test
    void syncTags_catchesSingleAppFailureSoLaterAppsCanContinue() {
        AppDetail detail = new AppDetail();
        detail.setPkgName("org.example.app");
        detail.setAppTagList(List.of());
        doThrow(new RuntimeException("db error"))
                .when(appTagSyncService).replaceTags(anyString(), anyList());

        assertDoesNotThrow(() -> listener.syncTags(detail));
    }

    @Test
    void clearSearchCache_clearsSearchRegionOnce() {
        when(cacheManager.getCache(Constants.SEARCH_APP_LIST_CACHE))
                .thenReturn(searchCache);

        listener.clearSearchCache();

        verify(searchCache).clear();
    }
}
```

- [ ] **Step 2: 运行测试并确认 RED**

```bash
mvn -pl ll-schedule -Dtest=RetrieveData2AppAffiliatedTableListenerTest test
```

Expected: `FAIL`，提示 `syncTags` 不存在或未调用 `AppTagSyncService`。

- [x] **Step 3: 接入服务并停止写 JSON 字段**（适配：schedule 无 Spring CacheManager，clearSearchCache 改用 RedisTemplate.keys+delete 复用 AppListCacheKeys.SEARCH_APP_LIST_CACHE，与既有 RetrieveData2AppMainTableListener 一致）

在 listener 中注入服务，并只对明确返回的标签字段执行替换：

```java
@Resource
private AppTagSyncService appTagSyncService;

@Resource
private CacheManager cacheManager;

void syncTags(AppDetail appDetail) {
    if (appDetail == null || appDetail.getAppTagList() == null) {
        return;
    }
    try {
        appTagSyncService.replaceTags(appDetail.getPkgName(), appDetail.getAppTagList());
    } catch (Exception e) {
        // 单应用标签失败不能中断同批其他应用；事务服务已保证该应用旧数据回滚。
        log.error("应用标签同步失败，appId={}", appDetail.getPkgName(), e);
    }
}

void clearSearchCache() {
    Cache cache = cacheManager.getCache(Constants.SEARCH_APP_LIST_CACHE);
    if (cache != null) {
        cache.clear();
    }
}
```

在 `results.forEach` 中调用 `syncTags(appDetail)`；本轮存在任意非 null `appTagList` 时，在全部应用处理完成后只调用一次 `clearSearchCache()`。删除 `updateEntity.setAppTagList(...)` 和新增实体的 `setAppTagList(...)`。响应遗漏 appId 时不会进入循环，因此自然保留旧标签。

- [x] **Step 4: 删除 schedule 模块旧 JSON 映射与 Tag Redis 分支**

从 `AppAffiliatedDtls` 删除 `appTagList` 字段和 TypeHandler import；删除 `ListAppTagTypeHandler.java`；从 `AppCacheServiceImpl` 删除 tagsKey 的序列化/反序列化；从 `AppRedisKeys` 删除 `getTagsKey()`。截图缓存保持不变。

- [x] **Step 5: 运行 schedule 测试与编译**（7 测试通过 BUILD SUCCESS；rg 检查 schedule main 无 getTagsKey/ListAppTagTypeHandler/setAppTagList 残留）

- [x] **Step 6: Commit**（commit b503d1f: refactor: 定时任务改用标签独立表）

---

### Task 4：详情接口批量读取标签独立表

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Create: `ll-server/src/main/java/com/dongpl/entity/AppTagEntity.java`
- Create: `ll-server/src/main/java/com/dongpl/mapper/master/AppTagMapper.java`
- Create: `ll-server/src/main/resources/mapper/master/AppTagMapper.xml`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/entity/AppAffiliatedDtls.java`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppCacheServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/utils/AppRedisKeys.java`
- Delete: `ll-server/src/main/java/com/dongpl/handler/ListAppTagTypeHandler.java`
- Test: `ll-server/src/test/java/com/dongpl/service/impl/AppDetailContractServiceTest.java`

- [x] **Step 1: 写失败测试证明详情标签来自新 Mapper**

在 `AppDetailContractServiceTest` 增加 `AppTagMapper` mock，并断言批量查询和语言过滤：

```java
@Mock
private AppTagMapper appTagMapper;

@Test
void getAppDetail_readsTagsInOneBatchFromIndependentTable() {
    AppDetailSearchBO request = new AppDetailSearchBO();
    request.setAppId("org.example.app");
    request.setArch("x86_64");
    request.setLang("zh_CN");

    AppMainDetailDTO detail = new AppMainDetailDTO();
    detail.setAppId("org.example.app");
    detail.setVersion("1.0.0");

    AppTagEntity row = new AppTagEntity();
    row.setAppId("org.example.app");
    row.setTagName("办公");
    row.setLan("zh_CN");
    row.setSortOrder(0);

    when(appMainDtlsMapper.getAppDetailsBatch(anyList(), eq("zh_CN")))
            .thenReturn(List.of(detail));
    when(appAffiliatedDtlsMapper.selectList(any())).thenReturn(List.of());
    when(appTagMapper.selectByAppIdsAndLang(List.of("org.example.app"), "zh_CN"))
            .thenReturn(List.of(row));

    List<AppMainDetailDTO> result = appService.getAppDetail(List.of(request));

    assertEquals("办公", result.get(0).getAppTagList().get(0).getName());
    assertEquals("zh_CN", result.get(0).getAppTagList().get(0).getLan());
    verify(appTagMapper).selectByAppIdsAndLang(List.of("org.example.app"), "zh_CN");
}
```

- [ ] **Step 2: 运行测试并确认 RED**

```bash
mvn -pl ll-server -Dtest=AppDetailContractServiceTest test
```

Expected: `FAIL`，提示 `AppTagMapper` 或 `AppTagEntity` 不存在。

- [x] **Step 3: 创建只读实体和批量 Mapper**

server 模块创建以下只读实体：

```java
@Data
@TableName("ll_app_tag")
public class AppTagEntity {
    @TableId("id")
    private String id;
    @TableField("app_id")
    private String appId;
    @TableField("tag_name")
    private String tagName;
    @TableField("lan")
    private String lan;
    @TableField("sort_order")
    private Integer sortOrder;
    @TableField("create_time")
    private String createTime;
}
```

Mapper：

```java
@Mapper
public interface AppTagMapper extends BaseMapper<AppTagEntity> {
    List<AppTagEntity> selectByAppIdsAndLang(
            @Param("appIds") List<String> appIds,
            @Param("lan") String lan);
}
```

XML：

```xml
<mapper namespace="com.dongpl.mapper.master.AppTagMapper">
    <select id="selectByAppIdsAndLang" resultType="com.dongpl.entity.AppTagEntity">
        SELECT id, app_id, tag_name, lan, sort_order, create_time
        FROM ll_app_tag
        WHERE lan = #{lan}
          AND app_id IN
          <foreach collection="appIds" item="appId" open="(" close=")" separator=",">
              #{appId}
          </foreach>
        ORDER BY app_id, sort_order, id
    </select>
</mapper>
```

- [x] **Step 4: 将 `buildTagMap` 改为单次批量查询**

在 `AppServiceImpl` 注入 `AppTagMapper`，保留截图原链路，仅替换标签构建：

```java
private Map<String, List<AppTag>> buildTagMap(
        List<AppMainDetailDTO> detailDtoList, String lang) {
    List<String> appIds = detailDtoList.stream()
            .map(AppMainDetailDTO::getAppId)
            .filter(StrUtil::isNotBlank)
            .distinct()
            .toList();
    if (CollUtil.isEmpty(appIds)) {
        return Collections.emptyMap();
    }
    return appTagMapper.selectByAppIdsAndLang(appIds, lang).stream()
            .collect(Collectors.groupingBy(
                    AppTagEntity::getAppId,
                    LinkedHashMap::new,
                    Collectors.mapping(this::toAppTag, Collectors.toList())));
}

private AppTag toAppTag(AppTagEntity row) {
    AppTag tag = new AppTag();
    tag.setName(row.getTagName());
    tag.setLan(row.getLan());
    return tag;
}
```

- [x] **Step 5: 删除 server 模块旧 JSON 映射和 Tag Redis 分支**

从 server 模块 `AppAffiliatedDtls` 删除 `appTagList` 字段和 `ListAppTagTypeHandler` import；删除 `ll-server/src/main/java/com/dongpl/handler/ListAppTagTypeHandler.java`；从 `AppCacheServiceImpl.saveAffiliated/getAffiliated/deleteAffiliated` 删除 tagsKey 的序列化、反序列化和删除逻辑；从 `AppRedisKeys` 删除 `getTagsKey()`。截图 JSON 缓存继续保留，数据库旧列暂时保留等待清理 SQL。

- [x] **Step 6: 运行测试与编译**（AppDetailContractServiceTest 4 测试通过；ll-server -DskipTests compile BUILD SUCCESS；同步给既有 getAppDetail 测试补空标签查询桩避免 NPE）

- [x] **Step 7: Commit**（commit 已提交: refactor: 详情接口改用标签独立表）

---

### Task 5：扩展现有搜索接口支持标签精确筛选

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Modify: `ll-server/src/main/java/com/dongpl/bo/AppMainBO.java`
- Modify: `ll-server/src/main/java/com/dongpl/dto/AppMainDto.java`
- Modify: `ll-server/src/main/java/com/dongpl/service/impl/AppVisitDtlsServiceImpl.java`
- Modify: `ll-server/src/main/java/com/dongpl/response/Constants.java`
- Modify: `ll-server/src/main/resources/mapper/master/AppMainDtlsMapper.xml`
- Test: `ll-server/src/test/java/com/dongpl/service/impl/AppVisitDtlsServiceImplTest.java`
- Test: `ll-server/src/test/java/com/dongpl/response/ConstantsTest.java`

- [x] **Step 1: 写失败测试验证参数正规化和缓存隔离**

`AppVisitDtlsServiceImplTest`：

```java
@ExtendWith(MockitoExtension.class)
class AppVisitDtlsServiceImplTest {
    @Mock
    private AppMainDtlsMapper appMainDtlsMapper;
    @InjectMocks
    private AppVisitDtlsServiceImpl service;
    @Captor
    private ArgumentCaptor<AppMainDto> dtoCaptor;

    @Test
    void getSearchAppList_passesTrimmedTagIdentityToMapper() {
        AppMainBO request = new AppMainBO();
        request.setPageNo(1);
        request.setPageSize(20);
        request.setArch("x86_64");
        request.setLan("zh_CN");
        request.setTagName(" 办公 ");
        request.setTagLan(" zh_CN ");
        when(appMainDtlsMapper.getSearchAppList(any(), any()))
                .thenReturn(new Page<>(1, 20));

        service.getSearchAppList(request);

        verify(appMainDtlsMapper).getSearchAppList(any(), dtoCaptor.capture());
        assertEquals("办公", dtoCaptor.getValue().getTagName());
        assertEquals("zh_CN", dtoCaptor.getValue().getTagLan());
    }

    @Test
    void getSearchAppList_rejectsIncompleteTagIdentity() {
        AppMainBO request = new AppMainBO();
        request.setTagName("办公");

        assertThrows(IllegalArgumentException.class,
                () -> service.getSearchAppList(request));
        verifyNoInteractions(appMainDtlsMapper);
    }
}
```

在 `ConstantsTest` 增加：

```java
@Test
void buildAppMainListKey_separatesDifferentTagSearches() {
    AppMainBO office = new AppMainBO();
    office.setTagName("办公");
    office.setTagLan("zh_CN");
    office.setPageNo(1);
    office.setPageSize(20);
    AppMainBO game = new AppMainBO();
    game.setTagName("游戏");
    game.setTagLan("zh_CN");
    game.setPageNo(1);
    game.setPageSize(20);
    assertNotEquals(Constants.buildAppMainListKey(office),
            Constants.buildAppMainListKey(game));
}
```

- [ ] **Step 2: 运行测试并确认 RED**

```bash
mvn -pl ll-server -Dtest=AppVisitDtlsServiceImplTest,ConstantsTest test
```

Expected: `FAIL`，提示 `tagName/tagLan` 字段不存在或缓存键相同。

- [x] **Step 3: 增加请求字段并正规化**

在 `AppMainBO` 和 `AppMainDto` 增加中文文档注释字段：

```java
private String tagName;
private String tagLan;
```

在 `getSearchAppList` 中处理：

```java
String tagName = StrUtil.trim(appMainBO.getTagName());
String tagLan = StrUtil.trim(appMainBO.getTagLan());
if (StrUtil.isNotBlank(tagName) != StrUtil.isNotBlank(tagLan)) {
    throw new IllegalArgumentException("tagName与tagLan必须同时提供");
}
dto.setTagName(StrUtil.isNotBlank(tagName) ? tagName : null);
dto.setTagLan(StrUtil.isNotBlank(tagLan) ? tagLan : null);
```

- [x] **Step 4: 为标签搜索增加索引 JOIN**

在 `getSearchAppList` 最终查询中加入动态精确 JOIN：

```xml
<if test="dto.tagName != null and dto.tagName != ''
          and dto.tagLan != null and dto.tagLan != ''">
    INNER JOIN ll_app_tag tag_filter
        ON tag_filter.app_id = t1.app_id
       AND tag_filter.tag_name = #{dto.tagName}
       AND tag_filter.lan = #{dto.tagLan}
</if>
```

普通 `dto.name` 的 LIKE 条件保持原样；Flutter 标签模式不发送 `name`，因此不会混入普通关键词结果。

- [x] **Step 5: 扩展缓存键**（适配：AppMainBO 实际无 filter 字段，缓存键串入 categoryId+name+tagName+tagLan+arch+repoName+lan+sort+order+pageNo+pageSize，不含 filter）

`buildAppMainListKey` 串入现有全部查询维度 `categoryId + name + tagName + tagLan + arch + repoName + lan + sort + order + filter + pageNo + pageSize`，避免标签、排序和过滤请求共用缓存：

```java
return categoryId + ":" + name + ":" + tagName + ":" + tagLan + ":"
        + arch + ":" + repoName + ":" + lan + ":" + sort + ":" + order
        + ":" + filter + ":" + pageNo + ":" + pageSize;
```

- [x] **Step 6: 运行测试和查询计划**（AppVisitDtlsServiceImplTest 2 + ConstantsTest 26 全部通过；EXPLAIN 命中 idx_app_tag_lookup，type=ref Using index 无全表扫描）

```bash
mvn -pl ll-server -Dtest=AppVisitDtlsServiceImplTest,ConstantsTest test
mvn -pl ll-server -DskipTests compile
```

在测试库执行：

```sql
EXPLAIN ANALYZE
SELECT app_id
FROM ll_app_tag
WHERE lan = 'zh_CN' AND tag_name = '办公';
```

Expected: 使用 `idx_app_tag_lookup`，不出现 `ALL` 全表扫描。

- [x] **Step 7: Commit**（commit 9c4952a: feat: 搜索接口支持标签精确筛选）

---

### Task 6：完成后端回归验证和约定文档

**Working directory:** `/home/han/code/linglong-store/linglong-server`

**Files:**

- Modify: `AGENTS.md`

- [x] **Step 1: 更新后端约定**（已在 linglong-server AGENTS.md 变更记录追加 2026/06/20 约定）

在变更记录追加：

```markdown
- 2026/06/20：应用标签唯一数据源为 `ll_app_tag`；详情按 `app_id + lan` 批量查询，标签搜索通过 `/visit/getSearchAppList` 的 `tagName + tagLan` 精确匹配。定时同步仅在上游明确返回 `appTagList` 时按应用事务替换：空数组删除旧标签，请求失败、字段缺失或响应遗漏 appId 时保留旧标签。禁止恢复 `app_tag_list` JSON 双写或 Tag Redis JSON 缓存。
```

- [x] **Step 2: 运行后端全量门禁**（全量跑通：新增/相关测试全绿——AppTagSyncServiceImplTest 3、RetrieveData2AppAffiliatedTableListenerTest 4、AppDetailContractServiceTest 4、AppVisitDtlsServiceImplTest 2、ConstantsTest 26、RedisConfigTest 10、WebServiceImplCacheTest 9 等。3 个失败类 WebServiceImplIntegrationTest/AppSidebarControllerTest/CacheEvictTest 经在 clean origin/dev 复现确认是环境依赖（Failed to load ApplicationContext 无 DB/Redis 连接）与无关 Web 缓存断言的既有问题，非本次改动引入）

- [x] **Step 3: 静态检查旧链路已移除**（rg 结果：唯一命中为 ll-server 响应 DTO `AppServiceImpl` 的 `detailVO.setAppTagList(...)`，符合预期；ListAppTagTypeHandler/getTagsKey/附属实体 setAppTagList 全部移除，上游 DTO `AppDetail.appTagList` 经 getter 读取未命中该模式）

- [x] **Step 4: Commit**（commit 7a0f5a5: docs: 同步应用标签独立表约定）

---

### Task 7：扩展 Flutter 标签领域模型和搜索状态机

**Working directory:** `/home/han/code/linglong-store/flutter-linglong-store`

**Files:**

- Modify: `lib/domain/models/app_detail.dart`
- Modify: `lib/data/models/api_dto.dart`
- Modify: `lib/data/repositories/app_repository_impl.dart`
- Modify: `lib/application/providers/search_provider.dart`
- Generate: Freezed/JSON/Riverpod files
- Test: `test/unit/data/models/search_request_test.dart`
- Test: `test/unit/data/repositories/app_repository_impl_test.dart`
- Test: `test/unit/application/providers/search_provider_test.dart`

- [ ] **Step 1: 写失败测试验证标签身份和分页参数**

`search_request_test.dart`：

```dart
test('serializes exact tag identity without keyword', () {
  const request = SearchAppListRequest(
    tagName: '办公',
    tagLan: 'zh_CN',
    pageNo: 1,
    pageSize: 20,
  );
  final json = request.toJson();
  expect(json['name'], '');
  expect(json['tagName'], '办公');
  expect(json['tagLan'], 'zh_CN');
});
```

`search_provider_test.dart`：

```dart
import 'package:dio/dio.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import 'package:linglong_store/application/providers/api_provider.dart';
import 'package:linglong_store/data/models/api_dto.dart';
import 'package:linglong_store/domain/models/app_detail.dart';
import '../../../mocks/mock_classes.mocks.dart';

HttpResponse<AppListResponse> _response({
  required int page,
  required int pages,
}) {
  return HttpResponse(
    AppListResponse(
      code: 200,
      data: AppListPagedData(
        records: [
          AppListItemDTO(
            appId: 'app.$page',
            appName: 'App $page',
            appVersion: '1.0.0',
          ),
        ],
        total: pages,
        size: 20,
        current: page,
        pages: pages,
      ),
    ),
    Response(requestOptions: RequestOptions(path: '/visit/getSearchAppList')),
  );
}

test('tag search and loadMore preserve tagName and tagLan', () async {
  final api = MockAppApiService();
  when(api.getSearchAppList(any)).thenAnswer((invocation) async {
    final request = invocation.positionalArguments.single
        as SearchAppListRequest;
    return _response(page: request.pageNo, pages: 2);
  });
  final container = ProviderContainer(
    overrides: [appApiServiceProvider.overrideWithValue(api)],
  );
  addTearDown(container.dispose);

  await container.read(searchProvider.notifier).searchByTag(
    const AppTag(name: '办公', language: 'zh_CN'),
  );
  await container.read(searchProvider.notifier).loadMore();

  final requests = verify(api.getSearchAppList(captureAny))
      .captured.cast<SearchAppListRequest>();
  expect(requests.map((item) => item.pageNo), [1, 2]);
  expect(requests.every((item) => item.keyword.isEmpty), isTrue);
  expect(requests.every((item) => item.tagName == '办公'), isTrue);
  expect(requests.every((item) => item.tagLan == 'zh_CN'), isTrue);
});
```

在 `app_repository_impl_test.dart` 的现有 `should return app detail on success` 响应中加入：

```dart
'appTagList': [
  {'name': '办公', 'lan': 'zh_CN'},
],
```

并增加断言：

```dart
expect(result.tags.single.name, '办公');
expect(result.tags.single.language, 'zh_CN');
```

- [ ] **Step 2: 运行测试并确认 RED**

```bash
flutter test test/unit/data/models/search_request_test.dart \
  test/unit/application/providers/search_provider_test.dart
```

Expected: `FAIL`，提示 `language`、`tagName/tagLan` 或 `searchByTag` 不存在。

- [ ] **Step 3: 扩展领域与请求模型**

```dart
@freezed
sealed class AppTag with _$AppTag {
  const factory AppTag({
    required String name,
    required String language,
  }) = _AppTag;
}
```

```dart
const factory SearchAppListRequest({
  @JsonKey(name: 'name') @Default('') String keyword,
  @JsonKey(includeIfNull: false) String? tagName,
  @JsonKey(includeIfNull: false) String? tagLan,
  @JsonKey(includeIfNull: false) String? categoryId,
  @JsonKey(name: 'pageNo') @Default(1) int pageNo,
  @JsonKey(name: 'pageSize') @Default(20) int pageSize,
  @JsonKey(name: 'repoName')
  @Default(AppConfig.defaultStoreRepoName)
  String repoName,
  String? arch,
  String? lan,
  String? sort,
  String? order,
}) = _SearchAppListRequest;
```

映射时必须原样保留 DTO 语言：

```dart
tags: (dto.tagList ?? [])
    .map((tag) => AppTag(name: tag.name, language: tag.language))
    .toList(growable: false),
```

同时将 `AppTagDTO.language` 改为 required，后端契约保证该字段存在。

- [ ] **Step 4: 扩展 SearchState 和统一分页请求构造**

```dart
@freezed
sealed class SearchState with _$SearchState {
  const SearchState._();
  const factory SearchState({
    @Default('') String query,
    AppTag? tag,
    required List<RecommendAppInfo> results,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    String? error,
    @Default(1) int currentPage,
    @Default(true) bool hasMore,
    @Default(0) int total,
  }) = _SearchState;

  bool get hasCriteria => query.isNotEmpty || tag != null;
}
```

新增 `searchByTag(AppTag tag)`；`search()` 必须清空 tag；`loadMore()` 和 `refresh()` 根据当前状态复用 `_buildRequest(page)`：

```dart
SearchAppListRequest _buildRequest(int page) {
  return SearchAppListRequest(
    keyword: state.query,
    tagName: state.tag?.name,
    tagLan: state.tag?.language,
    pageNo: page,
    pageSize: 20,
    arch: _arch,
    lan: state.tag?.language,
  );
}
```

`loadMore()` 的前置条件改为 `!state.hasCriteria`，不得继续用 `state.query.isEmpty` 阻断标签分页；`refresh()` 在 `state.tag != null` 时调用 `searchByTag(state.tag!)`，否则调用 `search(state.query)`。

- [ ] **Step 5: 重新生成代码**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_detail.freezed.dart`、`api_dto.freezed.dart`、`api_dto.g.dart`、`search_provider.freezed.dart` 和 `search_provider.g.dart` 更新。

- [ ] **Step 6: 运行测试并确认 GREEN**

```bash
flutter test test/unit/data/models/search_request_test.dart \
  test/unit/data/repositories/app_repository_impl_test.dart \
  test/unit/application/providers/search_provider_test.dart
```

Expected: `All tests passed.`

- [ ] **Step 7: Commit**

```bash
git add lib/domain/models/app_detail.dart lib/domain/models/app_detail.freezed.dart \
  lib/data/models/api_dto.dart lib/data/models/api_dto.freezed.dart lib/data/models/api_dto.g.dart \
  lib/data/repositories/app_repository_impl.dart \
  lib/application/providers/search_provider.dart \
  lib/application/providers/search_provider.freezed.dart \
  lib/application/providers/search_provider.g.dart \
  test/unit/data/models/search_request_test.dart \
  test/unit/data/repositories/app_repository_impl_test.dart \
  test/unit/application/providers/search_provider_test.dart
git commit -m "feat: 增加标签搜索状态与接口参数"
```

---

### Task 8：让搜索路由和结果页支持 Tag 条件

**Working directory:** `/home/han/code/linglong-store/flutter-linglong-store`

**Files:**

- Modify: `lib/core/config/routes.dart`
- Modify: `lib/presentation/pages/search_list/search_list_page.dart`
- Modify: `lib/presentation/widgets/app_shell.dart`
- Modify: `lib/presentation/widgets/title_bar.dart`
- Test: `test/widget/presentation/pages/search_list_page_test.dart`
- Test: `test/widget/presentation/widgets/title_bar_search_test.dart`

- [x] **Step 1: 写失败测试验证路由恢复和标签请求**

在 `search_list_page_test.dart` 新增：

```dart
testWidgets('initial tag triggers exact tag search', (tester) async {
  final api = MockAppApiService();
  when(api.getSearchAppList(any)).thenAnswer((_) async =>
      _buildSearchResponse(const [], currentPage: 1, total: 0, pages: 1));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appApiServiceProvider.overrideWithValue(api)],
      child: MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SearchListPage(
          initialTag: AppTag(name: '办公', language: 'zh_CN'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final request = verify(api.getSearchAppList(captureAny))
      .captured.single as SearchAppListRequest;
  expect(request.tagName, '办公');
  expect(request.tagLan, 'zh_CN');
});
```

- [x] **Step 2: 运行测试并确认 RED**（No named parameter 'initialTag' 编译失败）

- [x] **Step 3: 扩展 SearchListPage 和 GoRouter**（SearchListPage 增 initialTag、_syncSearchQuery tag 优先、hasCriteria 空状态、displayTerm 结果标题；routes.dart 解析 tag/tagLan 并新增 goToTagSearch）

`SearchListPage` 新增 `AppTag? initialTag`，同步优先级为 tag 高于 q：

```dart
final tag = widget.initialTag;
if (tag != null) {
  notifier.searchByTag(tag);
} else if (query.isNotEmpty) {
  notifier.search(query);
} else {
  notifier.clear();
}
```

页面空状态和结果标题同时读取统一条件：

```dart
if (!state.hasCriteria) {
  return _buildEmptySearch();
}

final displayTerm = state.tag?.name ?? state.query;
```

结果标题继续展示 `displayTerm`，确保标签搜索不会因为 `query == ''` 被误判为未搜索状态。

路由构造：

```dart
final tagName = state.uri.queryParameters['tag']?.trim();
final tagLan = state.uri.queryParameters['tagLan']?.trim();
final tag = tagName?.isNotEmpty == true && tagLan?.isNotEmpty == true
    ? AppTag(name: tagName!, language: tagLan!)
    : null;
return SearchListPage(
  key: ValueKey('searchList:$query:$tagName:$tagLan'),
  initialQuery: tag == null ? query : null,
  initialTag: tag,
);
```

新增路由入口：

```dart
void goToTagSearch(AppTag tag) {
  go('${AppRoutes.searchList}?tag=${Uri.encodeQueryComponent(tag.name)}'
      '&tagLan=${Uri.encodeQueryComponent(tag.language)}');
}
```

- [x] **Step 4: 将当前 Tag 从 AppShell 传给标题栏**（CustomTitleBar/AppShell/_TitleSearchBox 增 currentSearchTag 透传，胶囊渲染留给 Task 9）

- [x] **Step 5: 运行路由和页面测试**（search_list_page_test 3 测试 + title_bar_search_test 10 测试全部通过）

- [x] **Step 6: Commit**（commit d07dfcc: feat: 搜索路由支持标签条件）

---

### Task 9：标题栏搜索框渲染不可拆分 Tag 胶囊

**Working directory:** `/home/han/code/linglong-store/flutter-linglong-store`

**Files:**

- Modify: `lib/presentation/widgets/title_bar.dart`
- Modify: `lib/core/i18n/l10n/app_zh.arb`
- Modify: `lib/core/i18n/l10n/app_en.arb`
- Generate: `lib/core/i18n/l10n/app_localizations*.dart`
- Test: `test/widget/presentation/widgets/title_bar_search_test.dart`

- [x] **Step 1: 写失败 Widget 测试**（4 个标签测试 + _buildRouterApp 改为 ShellRoute）

覆盖路由恢复、不可编辑、删除和候选禁用：

```dart
testWidgets('tag route renders one non-editable chip and no suggestions',
    (tester) async {
  await tester.pumpWidget(_buildRouterApp(
    initialLocation: '/search_list?tag=办公&tagLan=zh_CN',
  ));
  await tester.pumpAndSettle();

  expect(find.widgetWithText(InputChip, '办公'), findsOneWidget);
  expect(find.byType(TextField), findsNothing);
  expect(find.text('浏览器'), findsNothing);
});

testWidgets('deleting tag chip returns to empty text search', (tester) async {
  await tester.pumpWidget(_buildRouterApp(
    initialLocation: '/search_list?tag=办公&tagLan=zh_CN',
  ));
  await tester.pumpAndSettle();

  final chip = tester.widget<InputChip>(find.widgetWithText(InputChip, '办公'));
  chip.onDeleted!.call();
  await tester.pumpAndSettle();

  expect(find.byType(TextField), findsOneWidget);
  expect(find.widgetWithText(InputChip, '办公'), findsNothing);
  expect(find.text('route:/search_list?q='), findsOneWidget);
});

testWidgets('backspace removes focused tag chip', (tester) async {
  await tester.pumpWidget(_buildRouterApp(
    initialLocation: '/search_list?tag=办公&tagLan=zh_CN',
  ));
  await tester.pumpAndSettle();

  await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
  await tester.pumpAndSettle();

  expect(find.widgetWithText(InputChip, '办公'), findsNothing);
  expect(find.byType(TextField), findsOneWidget);
});

testWidgets('tag chip exposes localized search semantics and 48px target',
    (tester) async {
  await tester.pumpWidget(_buildRouterApp(
    initialLocation: '/search_list?tag=办公&tagLan=zh_CN',
  ));
  await tester.pumpAndSettle();

  final chip = find.byKey(const Key('title-search-tag-chip'));
  expect(tester.getSize(chip).height, greaterThanOrEqualTo(48));
  expect(tester.getSemantics(chip).label, contains('按标签搜索：办公'));
});
```

同时将测试 helper 改成带标题栏的 `ShellRoute`，确保进入搜索结果页后标题栏仍在 Widget 树中：

```dart
Widget _buildRouterApp({String initialLocation = '/'}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final query = state.uri.queryParameters['q'] ?? '';
          final tagName = state.uri.queryParameters['tag'];
          final tagLan = state.uri.queryParameters['tagLan'];
          final currentTag = tagName != null && tagLan != null
              ? AppTag(name: tagName, language: tagLan)
              : null;
          return Scaffold(
            body: Column(
              children: [
                CustomTitleBar(
                  isMaximized: false,
                  onMinimize: () {},
                  onMaximize: () {},
                  onClose: () {},
                  currentSearchQuery: query,
                  currentSearchTag: currentTag,
                ),
                Expanded(child: child),
              ],
            ),
          );
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SizedBox.shrink()),
          GoRoute(
            path: AppRoutes.searchList,
            builder: (_, state) => Text(
              'route:${state.uri.path}?q=${state.uri.queryParameters['q'] ?? ''}',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/app/:id',
        builder: (_, state) {
          final appInfo = state.extra is InstalledApp
              ? state.extra! as InstalledApp
              : null;
          return Scaffold(
            body: Column(
              children: [
                Text('detail:${state.pathParameters['id']}'),
                if (appInfo != null)
                  Text(
                    'detail-extra:${appInfo.arch}|${appInfo.repoName}|${appInfo.module}',
                  ),
              ],
            ),
          );
        },
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      appSearchIndexProvider.overrideWith(
        () => _FakeAppSearchIndex([
          const SearchSuggestionEntry(
            appId: 'org.example.browser',
            name: '浏览器',
            version: '1.0.0',
            arch: 'x86_64',
            repoName: 'stable',
            module: 'binary',
          ),
          const SearchSuggestionEntry(
            appId: 'org.deepin.editor',
            name: '文本编辑器',
          ),
        ]),
      ),
      searchHintAppsProvider.overrideWithValue(const <SearchHintApp>[]),
    ],
    child: MaterialApp.router(
      locale: const Locale('zh'),
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}
```

- [x] **Step 2: 运行测试并确认 RED**（3 个标签测试失败：InputChip 未找到 / tag-chip key 未找到；11 个既有测试仍通过）

- [x] **Step 3: 增加国际化语义文案**（zh/en arb 增加 a11ySearchByTag / a11yRemoveSearchTag 及占位符 metadata，l10n 自动生成）

新增：

```json
"a11ySearchByTag": "按标签搜索：{tag}",
"a11yRemoveSearchTag": "移除搜索标签：{tag}"
```

英文对应 `Search by tag: {tag}` 和 `Remove search tag: {tag}`，为占位符补齐 ARB metadata。

- [x] **Step 4: 实现互斥标签模式**（适配：Backspace 用 CallbackShortcuts 无法捕获无修饰键，改用 Focus.onKeyEvent 直接拦截 Backspace/Delete；标签清理/聚焦放 postFrame 避免在 build 内修改 provider；Focus 放 Semantics 外层以保证 getSemantics 命中 label）

`_TitleSearchBox` 在 `currentTag != null` 时不构建 `TextField`、不拉候选，仅构建可聚焦胶囊：

```dart
Semantics(
  label: l10n.a11ySearchByTag(tag.name),
  child: ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: InputChip(
      key: const Key('title-search-tag-chip'),
      label: Text(tag.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onDeleted: () => context.goToSearch(),
      deleteButtonTooltipMessage: l10n.a11yRemoveSearchTag(tag.name),
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),
  ),
)
```

用 `CallbackShortcuts + Focus(autofocus: true)` 将 Backspace/Delete 映射到同一删除回调。进入标签模式时清空 controller、关闭 overlay 并取消 debounce，避免隐藏候选请求继续执行。

- [x] **Step 5: 生成 l10n 并运行测试**（14 测试全部通过；语义测试改为直接渲染标题栏验证，规避 ShellRoute 下测试框架 getSemantics(byKey) 返回空的已知限制；既有搜索框 32px 高度断言未受影响，标签胶囊独立约束 48px minHeight）

- [x] **Step 6: Commit**（commit 749ff25: feat: 标题栏支持标签搜索胶囊）

---

### Task 10：应用详情标签接入搜索路由

**Working directory:** `/home/han/code/linglong-store/flutter-linglong-store`

**Files:**

- Modify: `lib/presentation/widgets/app_detail_hero_header.dart`
- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Create: `test/widget/presentation/widgets/app_detail_hero_header_test.dart`

- [x] **Step 1: 写失败测试验证点击、语言和交互尺寸**

```dart
testWidgets('detail tag is accessible and emits full tag identity',
    (tester) async {
  AppTag? selected;
  await tester.pumpWidget(_buildHeader(
    tags: const [AppTag(name: '办公', language: 'zh_CN')],
    onTagPressed: (tag) => selected = tag,
  ));

  final tag = find.byKey(const ValueKey('app-detail-tag-办公-zh_CN'));
  expect(tag, findsOneWidget);
  expect(tester.getSize(tag).height, greaterThanOrEqualTo(48));

  await tester.tap(tag);
  expect(selected, const AppTag(name: '办公', language: 'zh_CN'));

  final semantics = tester.getSemantics(tag);
  expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
});

Widget _buildHeader({
  required List<AppTag> tags,
  required ValueChanged<AppTag> onTagPressed,
}) {
  return MaterialApp(
    locale: const Locale('zh'),
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppDetailHeroHeader(
        app: const InstalledApp(
          appId: 'org.example.app',
          name: 'Example',
          version: '1.0.0',
        ),
        installSourceKey: GlobalKey(),
        buttonState: InstallButtonState.notInstalled,
        progress: 0,
        showInstalledActions: false,
        tags: tags,
        onTagPressed: onTagPressed,
        onPrimaryPressed: () {},
        onCancel: () {},
        onCreateShortcut: () {},
        onUninstall: () {},
        onShare: () {},
      ),
    ),
  );
}
```

- [x] **Step 2: 运行测试并确认 RED**（编译失败：onTagPressed 不存在 + SemanticsFlag 未导入）

- [x] **Step 3: 修改头部组件契约与渲染**

将 `tags` 改为 `List<AppTag>`，增加 `ValueChanged<AppTag>? onTagPressed`。每个标签使用 `A11yButton` 和最小 48px 约束，视觉胶囊仍使用现有颜色、圆角与 10px 水平内边距：

```dart
A11yButton(
  semanticsLabel: l10n.a11ySearchByTag(tag.name),
  onTap: () => onTagPressed?.call(tag),
  enabled: onTagPressed != null,
  child: ConstrainedBox(
    key: ValueKey('app-detail-tag-${tag.name}-${tag.language}'),
    constraints: const BoxConstraints(minHeight: 48),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: AppRadius.fullRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Center(child: Text(tag.name)),
      ),
    ),
  ),
)
```

- [x] **Step 4: 从详情页连接统一路由入口**（app_detail_page 增 routes.dart 导入，tags 原样透传 + onTagPressed: context.goToTagSearch）

`AppDetailPage` 原样传入 `appDetail.tags`：

```dart
tags: appDetail?.tags ?? const [],
onTagPressed: context.goToTagSearch,
```

不得在页面直接拼接 URL，也不得直接调用搜索 Provider。

- [x] **Step 5: 运行组件和详情页测试**（hero_header + app_detail_page 共 19 测试全部通过）

- [x] **Step 6: Commit**（commit b2af1f3: feat: 应用详情标签支持搜索联动）

```bash
git add lib/presentation/widgets/app_detail_hero_header.dart \
  lib/presentation/pages/app_detail/app_detail_page.dart \
  test/widget/presentation/widgets/app_detail_hero_header_test.dart \
  test/widget/presentation/pages/app_detail/app_detail_page_test.dart
git commit -m "feat: 应用详情标签支持搜索联动"
```

---

### Task 11：执行 Flutter 全量门禁并同步项目约定

**Working directory:** `/home/han/code/linglong-store/flutter-linglong-store`

**Files:**

- Modify: `AGENTS.md`

- [x] **Step 1: 更新 Flutter 约定**（AGENTS.md 变更记录追加 2026-06-20 标签搜索约定）

在变更记录追加：

```markdown
- 2026-06-20：应用详情标签点击统一进入 `/search_list?tag=...&tagLan=...`，标题栏显示不可拆分 Tag 胶囊；标签搜索继续复用 `searchProvider`、分页和 `/visit/getSearchAppList`，不得把标签伪装成普通 `q` 关键词。`AppTag` 必须保留 `name + language`，Tag 删除后回到普通文本搜索模式。
```

- [x] **Step 2: 格式化并检查生成产物**（dart format 仅对本次相关文件生效，回退了 90+ 个无关历史格式漂移；build_runner 61 outputs 成功；gen-l10n 无变化；git diff --check 无输出）

- [x] **Step 3: 运行定向测试**（7 个目标测试文件共 81 测试全部通过）

- [x] **Step 4: 运行发布质量门禁**（flutter analyze 0 issues；flutter test 全量 832 通过、11 跳过、0 失败）

- [ ] **Step 5: 手工联调验收**（需人工执行 `flutter run -d linux` 完成下列 7 项交互验收；自动化已覆盖路由恢复/不可编辑/Backspace 删除/48px/语义/分页身份，但中英文标签语言隔离匹配与“当前应用允许出现在结果中”需真实后端联调确认）

```bash
flutter run -d linux
```

逐项确认：

1. 详情页标签鼠标点击、Tab 聚焦和 Enter/Space 均可进入搜索。
2. 标题栏显示单个不可编辑 Tag 胶囊，不弹普通候选。
3. 删除按钮和 Backspace 均回到空文本搜索并获得焦点。
4. 分页请求持续携带相同 `tagName/tagLan`。
5. 返回详情页、再次前进时 Tag 可由路由恢复。
6. 中文和英文标签分别只匹配对应语言记录。
7. 当前详情应用本身包含该标签时允许出现在搜索结果中，前后端不得增加排除 appId 条件。

- [x] **Step 6: Commit 项目约定文档**（commit 7597f33: docs: 同步应用标签搜索约定；另含 commit e11a109: style: 应用标签搜索相关代码格式化）

---

## 2. 发布与回滚顺序

1. 备份 `ll_app_affiliated_dtls`，执行 `migration_20260620_create_app_tag.sql` 两次验证幂等性。
2. 核对迁移脚本三个校验结果，确认新表索引命中。
3. 先部署 `ll-schedule`，观察明确空标签删除、请求失败保留和单应用事务回滚日志。
4. 再部署 `ll-server`，验证详情标签与标签搜索接口。
5. 最后发布 Flutter 客户端。
6. 回滚应用时保留 `ll_app_tag` 和旧 `app_tag_list`，旧服务仍可读取 JSON。
7. 连续观察 24 小时且确认没有旧服务实例后，才人工执行 `migration_20260620_drop_legacy_app_tag_list.sql`；该步骤执行后只能通过数据库备份恢复旧列。
