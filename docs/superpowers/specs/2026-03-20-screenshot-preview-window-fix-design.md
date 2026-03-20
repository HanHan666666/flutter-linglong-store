# Screenshot Preview Window Fix Design

**Date:** 2026-03-20
**Status:** Draft for review
**Scope:** Linux desktop screenshot preview sub-window in app detail

## Background

Current screenshot preview behavior was introduced by `dd2375b43f88cfbfe1177d4a70bc572883bac9aa` and `61bf63a9b68406fb8c496ac636ef6c09d8a0cc0d`.

The current implementation moved preview UI into a separate Flutter desktop window, but it introduced several regressions:

1. Closing the preview window can terminate the whole app instead of only the preview window.
2. The preview window uses a standalone dark `MaterialApp`, so it no longer follows the store's locale and theme settings.
3. Clicking screenshots repeatedly creates unlimited preview windows, each with its own Flutter engine and image cache.
4. Startup argument parsing for the sub-window is unsafe and can crash on malformed payloads.
5. There is no regression test coverage for the window routing and preview behavior.

The goal is to keep the separate desktop preview window, but make it behave like a controlled sub-window owned by the main app rather than a second ad-hoc app shell.

## Constraints

- Keep the current user-facing feature: screenshot preview opens in a separate desktop window.
- Do not duplicate full app startup or business provider initialization in the preview window.
- Keep `desktop_multi_window` and `window_manager` integration on Linux.
- Avoid adding more direct window logic into `app_detail_page.dart`; orchestration should be centralized.
- The preview window must remain lightweight and predictable under repeated open/focus actions.

## Design Summary

Introduce a dedicated screenshot preview window coordinator with a strict payload model, single-window reuse, and a narrow window-method API.

The main app will no longer create anonymous preview windows directly from `AppDetailPage`. Instead, page code will call a dedicated service that:

1. serializes a typed preview payload,
2. reuses an existing preview window when possible,
3. creates a new preview window only when none exists,
4. forwards "show these screenshots at this index" messages to the preview window.

The preview window itself will:

1. parse startup arguments through a typed parser with fallback handling,
2. register a method handler for targeted commands such as `preview_update` and `window_close`,
3. expose a lightweight app shell that inherits locale/theme values from the payload instead of hardcoded values,
4. close only its own window through its own `WindowController`, not through shared main-window assumptions.

Because `window_manager` is unreliable for the preview sub-window close path in the current multi-window integration, the final implementation may use a tiny runner-owned MethodChannel for current-window hide/focus operations instead of calling the plugin close path directly from Dart.

## Architecture

### 1. Typed Payload Model

Add a dedicated model for screenshot preview window arguments and runtime updates.

Responsibilities:

- Convert main-window request data into a stable JSON payload.
- Validate required fields when parsing in the sub-window.
- Carry only the data the preview UI really needs:
  - screenshot URLs
  - initial index
  - locale code
  - theme mode / effective brightness

Behavior:

- Parsing failure must not crash `main()`.
- Invalid payload falls back to a minimal error window with a close action.
- Unknown payload `type` must not enter the preview app path.

### 2. Preview Window Coordinator

Add a coordinator/service on the main-app side to own all screenshot preview window lifecycle operations.

Responsibilities:

- Track the current preview `WindowController`.
- Query existing windows and reuse the preview window by business type instead of opening duplicates.
- Send updates to an existing preview window to switch images instead of spawning a new engine.
- Await window creation/show calls and surface failures to UI with a snack bar or logged error.

Rules:

- At most one screenshot preview window exists at a time.
- Reopening preview with a new image list updates the existing window content and focuses it.
- If the previous preview window was closed, the next open call creates a fresh one.

### 3. Narrow Cross-Window Protocol

Window-to-window communication will use a narrow method set:

- `preview_update`: replace screenshots, locale/theme data, and active index.
- `window_close`: close the preview window itself.

The preview window will register its method handler during startup. The main window will use these methods only through the coordinator; page widgets will not call `WindowController` directly.

This keeps protocol details out of UI code and avoids future drift when more preview behaviors are added.

### 4. Preview Window App Shell

Replace the current hardcoded preview `MaterialApp` configuration with a small but explicit app shell.

Responsibilities:

- Build localized preview strings using the locale passed from the main window.
- Resolve theme from the main window payload rather than always forcing dark mode.
- Render the same preview page, but under a stable shell that does not depend on the main app's Riverpod container.

Non-goals:

- Do not boot the full store router.
- Do not initialize install queue, cache service, or other unrelated app providers in the preview window.

### 5. Safe Close Behavior

The preview close button and ESC shortcut must close only the preview sub-window.

Implementation rule:

- Use the current preview window's own `WindowController` close path.
- Do not assume `windowManager.close()` is scoped correctly for this integration path without the plugin's explicit current-window binding.

This also provides a clean place to clear coordinator state when the window disappears.

## Error Handling

- If window creation fails, keep the main app alive and show a localized error message.
- If preview payload parsing fails in the sub-window, show a compact error state instead of crashing the engine.
- If a `preview_update` call fails because the tracked controller is stale, clear the cached controller and retry with one new window creation.
- If screenshot URLs are empty, preview opening is a no-op.

## Testing Strategy

### Unit / Widget Coverage

Add tests for:

1. payload serialization and parsing success,
2. payload parsing failure / invalid arguments,
3. preview window app shell locale/theme resolution,
4. preview page state updates when receiving `preview_update`,
5. coordinator behavior:
   - create on first open,
   - reuse on second open,
   - retry when stale controller update fails.

### Manual Verification

Because this feature depends on Linux multi-window runtime behavior, manual verification is still required:

1. Open app detail and click a screenshot.
2. Click close in the preview window and confirm the main app remains open.
3. Reopen another screenshot and confirm the existing preview window is reused and focused.
4. Switch app language/theme and reopen preview to confirm the preview window follows them.
5. Repeat rapid open/close cycles and confirm no duplicate preview windows accumulate.

## Files Likely To Change

- `lib/main.dart`
- `lib/presentation/pages/app_detail/app_detail_page.dart`
- `lib/presentation/pages/app_detail/screenshot_preview_app.dart`
- `lib/presentation/pages/app_detail/` new preview coordinator/model files
- `test/` new unit/widget tests for payload parsing, coordinator, and preview shell
- `docs/` implementation notes if the final protocol needs to be recorded

## Trade-offs

### Chosen

Keep the independent desktop window, but add a coordinator and typed protocol.

Why:

- Preserves the desired desktop UX.
- Fixes current regressions without copying the entire main app shell.
- Keeps future window behavior changes localized to one place.

### Rejected

1. Revert to dialog preview.
   - Simpler, but removes the new desktop-window behavior.

2. Run the full store app inside the sub-window.
   - Better consistency at first glance, but far more invasive and expensive.

## Acceptance Criteria

- Closing the preview window never closes the main app.
- Preview window follows current locale and theme.
- Only one preview window exists at a time.
- Invalid preview arguments no longer crash startup.
- Preview behavior has automated regression coverage for the new coordinator and payload logic.
