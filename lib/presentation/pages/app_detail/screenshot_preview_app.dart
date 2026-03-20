import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import 'screenshot_preview_window_payload.dart';

/// 截图预览独立窗口 App。
///
/// 子窗口只承载截图预览 UI，不启动主应用的路由和业务 Provider。
class ScreenshotPreviewApp extends StatefulWidget {
  const ScreenshotPreviewApp({
    super.key,
    required this.initialPayload,
    required this.windowBinding,
  });

  final ScreenshotPreviewWindowPayload initialPayload;
  final ScreenshotPreviewWindowBinding windowBinding;

  @override
  State<ScreenshotPreviewApp> createState() => _ScreenshotPreviewAppState();
}

class _ScreenshotPreviewAppState extends State<ScreenshotPreviewApp> {
  late ScreenshotPreviewWindowPayload _payload;

  @override
  void initState() {
    super.initState();
    _payload = widget.initialPayload;
    widget.windowBinding.registerMethodHandler(_handleMethodCall);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case kScreenshotPreviewUpdateMethod:
        final nextPayload = _parsePayload(call.arguments);
        if (nextPayload == null) {
          return false;
        }
        if (mounted) {
          setState(() => _payload = nextPayload);
        }
        return true;
      case kScreenshotPreviewActivateMethod:
        await widget.windowBinding.focusWindow();
        return true;
      case kScreenshotPreviewCloseMethod:
        await widget.windowBinding.closeWindow();
        return true;
      default:
        throw MissingPluginException('Unsupported method: ${call.method}');
    }
  }

  ScreenshotPreviewWindowPayload? _parsePayload(dynamic arguments) {
    if (arguments is Map) {
      return ScreenshotPreviewWindowPayload.tryParseJson(
        Map<String, dynamic>.from(arguments),
      );
    }
    if (arguments is String) {
      return ScreenshotPreviewWindowPayload.tryParseArguments(arguments);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: _payload.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _payload.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _ScreenshotPreviewPage(
        payload: _payload,
        windowBinding: widget.windowBinding,
      ),
    );
  }
}

/// 参数损坏时的轻量错误壳，避免子窗口在启动时直接崩溃。
class ScreenshotPreviewLaunchErrorApp extends StatelessWidget {
  const ScreenshotPreviewLaunchErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        '截图预览加载失败',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '子窗口参数无效，请关闭后重试。',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final controller =
                              await WindowController.fromCurrentEngine();
                          await controller.hide();
                        },
                        child: Text(l10n?.close ?? '关闭'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

abstract class ScreenshotPreviewWindowBinding {
  Future<void> registerMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  );

  Future<void> closeWindow();

  Future<void> focusWindow();

  Future<void> startDragging();
}

class DesktopScreenshotPreviewWindowBinding
    implements ScreenshotPreviewWindowBinding {
  DesktopScreenshotPreviewWindowBinding({required WindowController controller})
    : _controller = controller;

  final WindowController _controller;

  @override
  Future<void> closeWindow() async {
    await _controller.hide();
  }

  @override
  Future<void> focusWindow() async {
    await windowManager.focus();
  }

  @override
  Future<void> registerMethodHandler(
    Future<dynamic> Function(MethodCall call)? handler,
  ) {
    return _controller.setWindowMethodHandler(handler);
  }

  @override
  Future<void> startDragging() async {
    await windowManager.startDragging();
  }
}

class _ScreenshotPreviewPage extends StatefulWidget {
  const _ScreenshotPreviewPage({
    required this.payload,
    required this.windowBinding,
  });

  final ScreenshotPreviewWindowPayload payload;
  final ScreenshotPreviewWindowBinding windowBinding;

  @override
  State<_ScreenshotPreviewPage> createState() => _ScreenshotPreviewPageState();
}

class _ScreenshotPreviewPageState extends State<_ScreenshotPreviewPage> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncWithPayload(widget.payload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ScreenshotPreviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.payload != widget.payload) {
      _pageController.dispose();
      _syncWithPayload(widget.payload);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncWithPayload(ScreenshotPreviewWindowPayload payload) {
    _currentIndex = payload.initialIndex;
    _pageController = PageController(initialPage: payload.initialIndex);
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.payload.screenshots.length) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _closeWindow() => widget.windowBinding.closeWindow();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) {
          return;
        }
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          _closeWindow();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _goTo(_currentIndex - 1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _goTo(_currentIndex + 1);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildTitleBar(context),
            Expanded(child: _buildImageArea(context)),
            if (widget.payload.screenshots.length > 1) _buildThumbnailBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onPanStart: (_) => widget.windowBinding.startDragging(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: const Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.white54,
              size: 17,
            ),
            const SizedBox(width: 8),
            Text(
              l10n?.screenShots ?? '屏幕截图',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const _KeyHintBadge(label: 'ESC'),
            const SizedBox(width: 4),
            const _KeyHintBadge(label: '←  →'),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.payload.screenshots.length}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: l10n?.close ?? '关闭',
              child: _WindowCloseButton(onTap: _closeWindow),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.payload.screenshots.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  widget.payload.screenshots[index],
                  fit: BoxFit.contain,
                  cacheWidth:
                      (MediaQuery.sizeOf(context).width *
                              MediaQuery.devicePixelRatioOf(context))
                          .toInt(),
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white24,
                      size: 64,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (_currentIndex > 0)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _goTo(_currentIndex - 1),
              ),
            ),
          ),
        if (_currentIndex < widget.payload.screenshots.length - 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _goTo(_currentIndex + 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF15151F),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.payload.screenshots.length,
        itemBuilder: (context, index) {
          final selected = index == _currentIndex;
          return GestureDetector(
            onTap: () => _goTo(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.75)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  widget.payload.screenshots[index],
                  width: 82,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 164,
                  cacheHeight: 120,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82,
                    height: 60,
                    color: Colors.white10,
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavArrowButton extends StatefulWidget {
  const _NavArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_NavArrowButton> createState() => _NavArrowButtonState();
}

class _NavArrowButtonState extends State<_NavArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: _hovered ? 0.22 : 0.10),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _KeyHintBadge extends StatelessWidget {
  const _KeyHintBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _WindowCloseButton extends StatefulWidget {
  const _WindowCloseButton({required this.onTap});

  final Future<void> Function() onTap;

  @override
  State<_WindowCloseButton> createState() => _WindowCloseButtonState();
}

class _WindowCloseButtonState extends State<_WindowCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hovered
                ? const Color(0xFFE5534B).withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.08),
          ),
          child: Icon(
            Icons.close_rounded,
            color: _hovered ? Colors.white : Colors.white54,
            size: 16,
          ),
        ),
      ),
    );
  }
}
