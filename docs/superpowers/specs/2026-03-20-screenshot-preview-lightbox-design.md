# Screenshot Preview Lightbox Design

**Date:** 2026-03-20
**Status:** Approved for implementation
**Scope:** App detail screenshot preview on Linux desktop

## Background

The separate desktop preview window based on `desktop_multi_window` fixes some interaction issues, but it still carries structural cost:

1. The first open is slow because each preview window requires a separate Flutter engine.
2. Linux desktop window lifecycle is more fragile than an in-app overlay path.
3. Theme consistency and window polish require extra coordination work that adds no product value.

The product goal is screenshot preview, not true multi-window authoring. The stable and performant design is to move preview back into the main window as a full-screen lightbox.

## Goals

- Open screenshot preview inside the main app window with near-instant response.
- Keep current core interactions: close, left/right switch, zoom, thumbnail navigation, keyboard shortcuts.
- Follow the main app locale and theme without a second app shell.
- Remove multi-engine window lifecycle risk from the screenshot path.
- Keep the preview code reusable and isolated from `AppDetailPage` business logic.

## Non-Goals

- Do not keep or emulate a separate system window.
- Do not introduce new business state providers for preview state.
- Do not change screenshot source, sorting, or locale filtering behavior.

## Chosen Approach

Use `showGeneralDialog` in the main window and render a dedicated lightbox widget tree.

Why:

- It reuses the main app `Navigator`, theme, locale, and image cache.
- It removes all Linux sub-window startup and teardown complexity.
- It keeps the interaction model close to the previous desktop-window preview.

## Architecture

### 1. Dedicated Lightbox Component

Create a focused presentation component under `lib/presentation/pages/app_detail/` for screenshot preview.

Responsibilities:

- Render the overlay shell.
- Manage `PageController`, current index, and keyboard focus.
- Support zoomable image viewing with `InteractiveViewer`.
- Expose a narrow constructor: `screenshots`, `initialIndex`.

`AppDetailPage` should only open the dialog and pass data in.

### 2. Main-Window Dialog Routing

The detail page uses `showGeneralDialog` to present the lightbox above the current route.

Behavior:

- `barrierDismissible = true`
- ESC closes the dialog
- clicking outside closes the dialog
- left/right arrows switch screenshots

This preserves the current expected “quick preview” feel while staying inside the main app process.

### 3. Theme-Adaptive Visual Design

The lightbox must follow the active Flutter theme instead of forcing dark colors.

#### Layout

- Centered preview panel
- Width: about 84% of window width, clamped for desktop usability
- Height: about 82% of window height, clamped for desktop usability
- Rounded corners and elevated shadow
- Top title bar
- Main image stage
- Bottom thumbnail rail when more than one screenshot exists

#### Dark Theme

- Overlay mask: high-opacity neutral black
- Panel background: deep neutral surface
- Title bar and thumbnail rail: slightly darker than panel body
- Text/icons: white with hierarchy by opacity

#### Light Theme

- Overlay mask: semi-transparent dark scrim to maintain focus
- Panel background: elevated light surface
- Title bar and thumbnail rail: slightly tinted light surfaces
- Text/icons: use `colorScheme.onSurface` and `onSurfaceVariant`
- Active thumbnail border: use `colorScheme.primary`

#### Interaction Details

- Close button remains top-right and gains clear hover feedback
- Navigation arrows float over image stage with translucent circular background
- Selected thumbnail uses stronger border and subtle background emphasis
- Error placeholders follow theme and remain legible in both modes

### 4. Performance Model

The lightbox stays inside the main Flutter engine.

Benefits:

- No second engine cold start
- Reuse existing network/image cache
- No cross-window message passing
- No Linux runner customization for screenshot preview

Image decoding still needs guardrails:

- Main image uses bounded `cacheWidth`
- Thumbnail images keep small fixed decode sizes

## Files To Change

- Modify: `lib/presentation/pages/app_detail/app_detail_page.dart`
- Create: `lib/presentation/pages/app_detail/screenshot_preview_lightbox.dart`
- Modify: `lib/main.dart`
- Modify: `linux/runner/my_application.cc`
- Modify: `pubspec.yaml`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_app.dart`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_window_coordinator.dart`
- Delete: `lib/presentation/pages/app_detail/screenshot_preview_window_payload.dart`
- Create: widget tests for the lightbox
- Delete: obsolete multi-window payload/coordinator tests

## Testing Strategy

Add widget coverage for:

1. localized title rendering inside the main app context
2. light and dark theme adaptation
3. close button closes only the dialog
4. left/right navigation updates current index
5. thumbnail rail appears only when multiple screenshots exist

Manual verification:

1. open app detail and click a screenshot
2. confirm the preview appears instantly in the same main window
3. press ESC and confirm only the lightbox closes
4. switch light/dark theme and confirm title bar and thumbnail rail remain readable
5. reopen another screenshot and confirm there is no extra system window

## Acceptance Criteria

- Screenshot preview no longer creates a separate desktop window.
- Preview opens inside the main app window as a full-screen lightbox.
- Preview follows current app locale and theme.
- No screenshot preview code path depends on `desktop_multi_window`.
- Widget coverage exists for core preview interactions and theme behavior.
