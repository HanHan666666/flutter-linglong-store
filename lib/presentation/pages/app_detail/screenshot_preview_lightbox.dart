import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';

Future<void> showScreenshotPreviewLightbox(
  BuildContext context, {
  required List<String> screenshots,
  required int initialIndex,
}) {
  if (screenshots.isEmpty) {
    return Future<void>.value();
  }

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'screenshot_preview',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (ctx, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) {
      return ScreenshotPreviewLightbox(
        screenshots: screenshots,
        initialIndex: initialIndex,
      );
    },
  );
}

class ScreenshotPreviewLightbox extends StatefulWidget {
  const ScreenshotPreviewLightbox({
    super.key,
    required this.screenshots,
    required this.initialIndex,
  });

  final List<String> screenshots;
  final int initialIndex;

  @override
  State<ScreenshotPreviewLightbox> createState() =>
      _ScreenshotPreviewLightboxState();
}

class _ScreenshotPreviewLightboxState extends State<ScreenshotPreviewLightbox> {
  late final PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.screenshots.length) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
    );
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? const Color(0xFF1C1C28) : colors.surface;

    return Material(
      color: Colors.transparent,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is! KeyDownEvent) {
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _close();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goTo(_currentIndex - 1);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goTo(_currentIndex + 1);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                key: const Key('screenshotPreviewBackdrop'),
                behavior: HitTestBehavior.opaque,
                onTap: _close,
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: Container(
                width: (size.width * 0.84).clamp(560.0, 1200.0),
                height: (size.height * 0.82).clamp(400.0, 900.0),
                decoration: BoxDecoration(
                  color: panelColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.52 : 0.22,
                      ),
                      blurRadius: 48,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      _TitleBar(
                        containerKey: const Key('screenshotPreviewTitleBar'),
                        currentIndex: _currentIndex,
                        totalCount: widget.screenshots.length,
                        onClose: _close,
                      ),
                      Expanded(
                        child: _ImageStage(
                          screenshots: widget.screenshots,
                          currentIndex: _currentIndex,
                          pageController: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          onGoTo: _goTo,
                        ),
                      ),
                      if (widget.screenshots.length > 1)
                        _ThumbnailBar(
                          containerKey: const Key(
                            'screenshotPreviewThumbnailBar',
                          ),
                          screenshots: widget.screenshots,
                          currentIndex: _currentIndex,
                          onTapThumbnail: _goTo,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.containerKey,
    required this.currentIndex,
    required this.totalCount,
    required this.onClose,
  });

  final Key containerKey;
  final int currentIndex;
  final int totalCount;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final titleBarColor = isDark ? const Color(0xFF15151F) : const Color(0xFFF6F7FA);
    final borderColor = isDark ? Colors.white10 : AppColors.borderSecondary;
    final primaryText = colors.onSurface.withValues(alpha: isDark ? 0.70 : 0.86);
    final secondaryText = colors.onSurface.withValues(alpha: isDark ? 0.60 : 0.64);
    final hintBackground = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : colors.onSurface.withValues(alpha: 0.04);
    final counterBackground = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colors.primary.withValues(alpha: 0.10);
    final l10n = AppLocalizations.of(context);

    return Container(
      key: containerKey,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: titleBarColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: secondaryText,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            l10n?.screenShots ?? '屏幕截图',
            style: TextStyle(
              color: primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _KeyHintBadge(label: 'ESC', backgroundColor: hintBackground),
          const SizedBox(width: 4),
          _KeyHintBadge(label: '←  →', backgroundColor: hintBackground),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: counterBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentIndex + 1} / $totalCount',
              style: TextStyle(color: secondaryText, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: l10n?.close ?? '关闭',
            child: _CloseButton(onTap: onClose),
          ),
        ],
      ),
    );
  }
}

class _ImageStage extends StatelessWidget {
  const _ImageStage({
    required this.screenshots,
    required this.currentIndex,
    required this.pageController,
    required this.onPageChanged,
    required this.onGoTo,
  });

  final List<String> screenshots;
  final int currentIndex;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoTo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.24 : 0.32,
    );

    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          itemCount: screenshots.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.network(
                  screenshots[index],
                  fit: BoxFit.contain,
                  cacheWidth:
                      (MediaQuery.sizeOf(context).width *
                              MediaQuery.devicePixelRatioOf(context) *
                              0.84)
                          .toInt(),
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: iconColor,
                      size: 64,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (currentIndex > 0)
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrowButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Previous screenshot',
                onTap: () => onGoTo(currentIndex - 1),
              ),
            ),
          ),
        if (currentIndex < screenshots.length - 1)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _NavArrowButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Next screenshot',
                onTap: () => onGoTo(currentIndex + 1),
              ),
            ),
          ),
      ],
    );
  }
}

class _ThumbnailBar extends StatelessWidget {
  const _ThumbnailBar({
    required this.containerKey,
    required this.screenshots,
    required this.currentIndex,
    required this.onTapThumbnail,
  });

  final Key containerKey;
  final List<String> screenshots;
  final int currentIndex;
  final ValueChanged<int> onTapThumbnail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF15151F) : const Color(0xFFF6F7FA);
    final borderColor = isDark ? Colors.white10 : AppColors.borderSecondary;
    final placeholderColor = colors.onSurface.withValues(alpha: isDark ? 0.10 : 0.08);
    final placeholderIconColor = colors.onSurface.withValues(alpha: isDark ? 0.24 : 0.32);

    return Container(
      key: containerKey,
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: barColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: screenshots.length,
        itemBuilder: (context, index) {
          final selected = index == currentIndex;
          return GestureDetector(
            onTap: () => onTapThumbnail(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: selected
                      ? colors.primary.withValues(alpha: isDark ? 0.88 : 0.72)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.network(
                  screenshots[index],
                  width: 82,
                  height: 60,
                  fit: BoxFit.cover,
                  cacheWidth: 164,
                  cacheHeight: 120,
                  errorBuilder: (_, __, ___) => Container(
                    width: 82,
                    height: 60,
                    color: placeholderColor,
                    child: Icon(
                      Icons.image_outlined,
                      color: placeholderIconColor,
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
  const _NavArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_NavArrowButton> createState() => _NavArrowButtonState();
}

class _NavArrowButtonState extends State<_NavArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? Colors.white.withValues(alpha: _hovered ? 0.22 : 0.10)
        : Colors.black.withValues(alpha: _hovered ? 0.16 : 0.08);
    final iconColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
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
              color: backgroundColor,
            ),
            child: Icon(widget.icon, color: iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}

class _KeyHintBadge extends StatelessWidget {
  const _KeyHintBadge({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.12 : 0.10,
    );
    final textColor = theme.colorScheme.onSurface.withValues(
      alpha: isDark ? 0.38 : 0.48,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final idleColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.onSurface.withValues(alpha: 0.06);
    final iconColor = isDark
        ? Colors.white54
        : theme.colorScheme.onSurface.withValues(alpha: 0.60);

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
                : idleColor,
          ),
          child: Icon(
            Icons.close_rounded,
            color: _hovered ? Colors.white : iconColor,
            size: 16,
          ),
        ),
      ),
    );
  }
}
