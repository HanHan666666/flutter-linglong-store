# Detail Contract Alignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make app detail requests honor the same app identity that list results expose, so any app returned by a list can be opened in detail without module/repoName drift or extra app_level filtering.

**Architecture:** Extend the shared detail request contract to carry `module` and `repoName`, then pass those fields from Flutter list items into `/app/getAppDetail`. On the backend, both `/visit/getAppDetails` and `/app/getAppDetail` will use exact matching when those fields are present and only fall back to the existing runtime/binary candidate set when they are missing. The detail SQL will stop applying its own `app_level` visibility filter so visibility stays owned by list APIs.

**Tech Stack:** Flutter + Riverpod + Dio + Freezed/Retrofit + Mockito, Spring Boot + MyBatis XML mapper + MockMvc integration tests

---

### Task 1: Lock the backend request contract and detail query behavior

**Files:**
- Modify: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/bo/AppDetailSearchBO.java`
- Modify: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/service/impl/AppVisitDtlsServiceImpl.java`
- Modify: `/home/han/linglong-store/linglong-server/ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java`
- Modify: `/home/han/linglong-store/linglong-server/ll-server/src/main/resources/mapper/master/AppMainDtlsMapper.xml`
- Test: `/home/han/linglong-store/linglong-server/ll-server/src/test/java/com/dongpl/controller/app/AppDetailControllerTest.java`

- [ ] **Step 1: Write the failing backend integration test**

```java
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AppDetailControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    @Qualifier("masterJdbcTemplate")
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldReturnRuntimeDetailWhenModuleAndRepoNameAreProvided() throws Exception {
        String body = """
                [{
                  "appId":"io.github.fingerboard",
                  "arch":"x86_64",
                  "module":"runtime",
                  "repoName":"stable",
                  "lang":"zh_CN"
                }]
                """;

        mockMvc.perform(post("/app/getAppDetail")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(200))
                .andExpect(jsonPath("$.data.io.github.fingerboard[0].module").value("runtime"))
                .andExpect(jsonPath("$.data.io.github.fingerboard[0].repoName").value("stable"));
    }
}
```

- [ ] **Step 2: Run the backend test and verify it fails for the current contract**

Run: `mvn -pl ll-server -Dtest=AppDetailControllerTest test`
Expected: FAIL because `module` / `repoName` are ignored and `data.io.github.fingerboard` is missing or empty.

- [ ] **Step 3: Extend the request BO and remove the hard-coded binary default**

```java
@Data
public class AppDetailSearchBO {
    private String appId;
    private String arch;
    private String lang;
    private String module;
    private String repoName;
}
```

```java
appMainDto.setModule(StrUtil.emptyToDefault(appDetailsBO.getModule(), null));
appMainDto.setRepoName(StrUtil.emptyToDefault(appDetailsBO.getRepoName(), null));
```

- [ ] **Step 4: Make mapper queries honor exact identity when known**

```xml
<if test="repoName != null and repoName != ''">
    and md.repo_name = #{repoName}
</if>
<if test="module != null and module != ''">
    and md.module = #{module}
</if>
<if test="module == null or module == ''">
    and md.module in ('runtime', 'binary')
</if>
```

```xml
<if test="item.repoName != null and item.repoName != ''">
    and md.repo_name = #{item.repoName}
</if>
<if test="item.module != null and item.module != ''">
    and md.module = #{item.module}
</if>
<if test="item.module == null or item.module == ''">
    and md.module in ('runtime', 'binary')
</if>
```

Also delete the detail-only visibility clause:

```xml
AND ad.app_level > 1
```

- [ ] **Step 5: Run the backend test again and verify it passes**

Run: `mvn -pl ll-server -Dtest=AppDetailControllerTest test`
Expected: PASS with a populated `io.github.fingerboard` detail payload.

- [ ] **Step 6: Commit the backend contract fix**

```bash
cd /home/han/linglong-store/linglong-server
git add ll-server/src/main/java/com/dongpl/bo/AppDetailSearchBO.java \
        ll-server/src/main/java/com/dongpl/service/impl/AppVisitDtlsServiceImpl.java \
        ll-server/src/main/java/com/dongpl/service/impl/AppServiceImpl.java \
        ll-server/src/main/resources/mapper/master/AppMainDtlsMapper.xml \
        ll-server/src/test/java/com/dongpl/controller/app/AppDetailControllerTest.java
git commit -m "fix: 对齐应用列表与详情请求契约"
```

### Task 2: Pass module and repoName from Flutter list items into detail requests

**Files:**
- Modify: `/home/han/linglong-store/flutter-linglong-store/lib/data/models/api_dto.dart`
- Modify: `/home/han/linglong-store/flutter-linglong-store/lib/domain/repositories/app_repository.dart`
- Modify: `/home/han/linglong-store/flutter-linglong-store/lib/data/repositories/app_repository_impl.dart`
- Modify: `/home/han/linglong-store/flutter-linglong-store/lib/application/providers/app_detail_provider.dart`
- Test: `/home/han/linglong-store/flutter-linglong-store/test/unit/data/repositories/app_repository_impl_test.dart`
- Test: `/home/han/linglong-store/flutter-linglong-store/test/unit/presentation/pages/app_detail/app_detail_comment_provider_test.dart`

- [ ] **Step 1: Write the failing Flutter repository test**

```dart
test('should pass repoName and module through detail request when provided', () async {
  when(mockApiService.getAppDetail(any)).thenAnswer((_) async => mockResponse);

  await repository.getAppDetail(
    'com.example.app',
    arch: 'x86_64',
    repoName: 'stable',
    module: 'runtime',
  );

  final captured =
      verify(mockApiService.getAppDetail(captureAny)).captured.single
          as List<AppDetailSearchBO>;
  expect(captured.single.repoName, equals('stable'));
  expect(captured.single.module, equals('runtime'));
});
```

- [ ] **Step 2: Write the failing provider test for list-to-detail propagation**

```dart
await container.read(appDetailProvider('org.deepin.album').notifier).loadDetail(
  const InstalledApp(
    appId: 'org.deepin.album',
    name: '相册',
    version: '6.0.49.1',
    arch: 'aarch64',
    module: 'runtime',
    repoName: 'stable',
  ),
);

expect(captured.single.module, equals('runtime'));
expect(captured.single.repoName, equals('stable'));
```

- [ ] **Step 3: Run the targeted Flutter tests and verify they fail**

Run: `flutter test test/unit/data/repositories/app_repository_impl_test.dart`
Expected: FAIL because `AppDetailSearchBO` and `AppRepository.getAppDetail()` do not expose `module` / `repoName`.

Run: `flutter test test/unit/presentation/pages/app_detail/app_detail_comment_provider_test.dart`
Expected: FAIL because the provider does not pass the list item identity through.

- [ ] **Step 4: Implement the minimal Flutter contract changes**

```dart
const factory AppDetailSearchBO({
  required String appId,
  required String arch,
  String? lang,
  String? module,
  String? repoName,
}) = _AppDetailSearchBO;
```

```dart
Future<AppDetail> getAppDetail(
  String appId, {
  String? arch,
  String? repoName,
  String? module,
});
```

```dart
final appDetail = await repository.getAppDetail(
  appId,
  arch: detailArch,
  repoName: initialApp?.repoName ?? state.appDetail?.repoName ?? state.app?.repoName,
  module: initialApp?.module ?? state.appDetail?.module ?? state.app?.module,
);
```

- [ ] **Step 5: Regenerate Dart artifacts**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: updated `*.g.dart` and any mock/type artifacts that depend on the request signature.

- [ ] **Step 6: Re-run the targeted Flutter tests and verify they pass**

Run: `flutter test test/unit/data/repositories/app_repository_impl_test.dart`
Expected: PASS

Run: `flutter test test/unit/presentation/pages/app_detail/app_detail_comment_provider_test.dart`
Expected: PASS

- [ ] **Step 7: Commit the Flutter propagation fix**

```bash
git add lib/data/models/api_dto.dart \
        lib/domain/repositories/app_repository.dart \
        lib/data/repositories/app_repository_impl.dart \
        lib/application/providers/app_detail_provider.dart \
        test/unit/data/repositories/app_repository_impl_test.dart \
        test/unit/presentation/pages/app_detail/app_detail_comment_provider_test.dart \
        lib/data/models/api_dto.g.dart \
        test/mocks/mock_classes.mocks.dart
git commit -m "fix: 详情页透传列表应用身份"
```

### Task 3: Verify the aligned contract end to end and document the rule

**Files:**
- Modify: `/home/han/linglong-store/flutter-linglong-store/AGENTS.md`

- [ ] **Step 1: Add the repository rule to project guidance**

```md
- 2026-05-10：应用详情契约必须与列表项身份对齐；列表页进入详情时必须原样透传 `appId + arch + repoName + module`，后端 `/visit/getAppDetails` 与 `/app/getAppDetail` 已知这些字段时必须精确匹配，未知时才允许回退到 `runtime/binary` 候选；详情接口禁止再额外施加列表之外的 `app_level` 可见性过滤。
```

- [ ] **Step 2: Run the focused verification commands**

Run: `flutter test test/unit/data/repositories/app_repository_impl_test.dart test/unit/presentation/pages/app_detail/app_detail_comment_provider_test.dart`
Expected: all passing

Run: `flutter analyze`
Expected: 0 errors, 0 warnings

Run: `cd /home/han/linglong-store/linglong-server && mvn -pl ll-server -Dtest=AppDetailControllerTest test`
Expected: PASS against the test profile database

- [ ] **Step 3: Report any residual risk explicitly**

```text
- If the shared MySQL test database is unavailable, backend MockMvc verification will be blocked even when the code compiles.
- Existing clients that omit `module` and `repoName` continue to use the fallback branch and must still return a stable candidate.
```
