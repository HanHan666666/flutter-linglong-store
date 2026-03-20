import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

/// 截图预览独立窗口 App
///
/// 仅由 main.dart 在检测到 `screenshot_preview` 参数时运行，
/// 作为独立的 Flutter Desktop 子窗口。
class ScreenshotPreviewApp extends StatelessWidget {
  const ScreenshotPreviewApp({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  final List<String> screenshots;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C28),
        colorScheme: const ColorScheme.dark(surface: Color(0xFF1C1C28)),
      ),
      home: _ScreenshotPreviewPage(
        screenshots: screenshots,
        initialIndex: initialIndex,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 页面
// ---------------------------------------------------------------------------

class _ScreenshotPreviewPage extends StatefulWidget {
  const _ScreenshotPreviewPage({
    required this.screenshots,
    required this.initialIndex,
  });

  final List<String> screenshots;
  final int initialIndex;

  @override
  State<_ScreenshotPreviewPage> createState() => _ScreenshotPreviewPageState();
}

class _ScreenshotPreviewPageState extends State<_ScreenshotPreviewPage> {
  late final PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.screenshots.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.escape) {
          windowManager.close();
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _goTo(_currentIndex - 1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _goTo(_currentIndex + 1);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1C28),
        body: Column(
          children: [
            _buildTitleBar(),
            Expanded(child: _buildImageArea(context)),
            if (widget.screenshots.length > 1) _buildThumbnailBar(),
          ],
        ),
      ),
    );
  }

  /// 自定义标题栏：可拖动 + 页码 + 快捷键提示 + 关闭按钮
  Widget _buildTitleBar() {
    return GestureDetector(
      // 拖动标题栏区域移动窗口
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF15151F),
          border: Border(bottom: BorderSide(color: Colors.white10)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: Colors.white54,
              size: 17,
            ),
            const SizedBox(width: 8),
            const Text(
              '截图预览',
              style: TextStyle(
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
            // 页码指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.screenshots.length}',
                style:
                    const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            _WindowCloseButton(onTap: () => windowManager.close()),
          ],
        ),
      ),
    );
  }

  /// 图片查看区：PageView + InteractiveViewer + 左右导航箭头
  Widget _buildImageArea(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.screenshots.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  widget.screenshots[index],
                  fit: BoxFit.contain,
                  cacheWidth: (MediaQuery.sizeOf(context).width *
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
        if (_currentIndex < widget.screenshots.length - 1)
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

  /// 底部缩略图导航栏（多张截图时显示）
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
        itemCount: widget.screenshots.length,
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
                  widget.screenshots[index],
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

// ---------------------------------------------------------------------------
// 辅助 Widgets
// ---------------------------------------------------------------------------

/// 左右翻页导航箭头（悬停高亮）
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

/// 键盘快捷键提示标签
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

/// 关闭按钮（悬停时高亮为红色）
class _WindowCloseButton extends StatefulWidget {
  const _WindowCloseButton({required this.onTap});

  final VoidCallback onTap;

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
