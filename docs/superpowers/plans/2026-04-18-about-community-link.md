# About Community Link Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## File Structure

- `lib/presentation/pages/setting/setting_page.dart`
  - 在关于区现有外链行新增“社区交流”按钮，复用 `_openUrl()`
- `test/widget/presentation/pages/setting_page_test.dart`
  - 增加最小 widget 测试，验证按钮渲染

## Task 1: Add the failing widget test

- [ ] **Step 1: Update `test/widget/presentation/pages/setting_page_test.dart`**

Add a new test that renders `SettingPage` and expects to find the `社区交流` button text.

- [ ] **Step 2: Run the test and verify it fails**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/setting_page_test.dart`

Expected: FAIL because `社区交流` is not rendered yet.

## Task 2: Implement the button

- [ ] **Step 1: Update `lib/presentation/pages/setting/setting_page.dart`**

In the existing project links row inside `_buildAboutSection`, append a `TextButton.icon` that opens:

`https://bbs.deepin.org.cn/module/detail/230`

- [ ] **Step 2: Run the test and verify it passes**

Run: `/home/han/flutter/bin/flutter test test/widget/presentation/pages/setting_page_test.dart`

Expected: PASS.

## Task 3: Verify the touched files

- [ ] **Step 1: Run targeted analysis**

Run:

`/home/han/flutter/bin/flutter analyze lib/presentation/pages/setting/setting_page.dart test/widget/presentation/pages/setting_page_test.dart`

Expected: PASS with no issues.
