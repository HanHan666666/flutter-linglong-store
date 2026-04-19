# Comment Compose Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

## File Structure

- `lib/presentation/widgets/app_detail_comment_section.dart`
  - 页面内评论区改为“列表 + 发表评论按钮”
  - 新增评论弹窗承载输入表单
- `lib/presentation/pages/app_detail/app_detail_page.dart`
  - 调整 `onSubmit` 返回值，供弹窗决定是否关闭
- `test/widget/presentation/widgets/app_detail_comment_section_test.dart`
  - 更新为弹窗交互测试

## Task 1: Update tests first

- [ ] 修改评论区 widget 测试，覆盖：
  - 页面默认只显示“发表评论”入口，不显示内联输入框
  - 点击入口后弹出评论表单
  - 提交后调用现有回调并关闭弹窗
  - 未安装时隐藏评论入口但保留评论列表

- [ ] 运行：

`/home/han/flutter/bin/flutter test test/widget/presentation/widgets/app_detail_comment_section_test.dart`

预期：FAIL，因为当前实现仍是内联表单。

## Task 2: Implement the dialog

- [ ] 修改 `app_detail_comment_section.dart`
  - 抽离评论输入区到弹窗
  - 页面内改为入口按钮
  - 版本胶囊逻辑跟随弹窗移动

- [ ] 修改 `app_detail_page.dart`
  - 让评论提交回调返回成功/失败结果，供弹窗控制关闭时机

- [ ] 重新运行评论区测试，预期 PASS

## Task 3: Verify touched files

- [ ] 运行：

`/home/han/flutter/bin/flutter analyze lib/presentation/widgets/app_detail_comment_section.dart lib/presentation/pages/app_detail/app_detail_page.dart test/widget/presentation/widgets/app_detail_comment_section_test.dart`
