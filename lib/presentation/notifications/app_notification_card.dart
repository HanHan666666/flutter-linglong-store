import 'package:flutter/material.dart';

import '../../application/notifications/app_notification.dart';

class AppNotificationCard extends StatefulWidget {
  const AppNotificationCard({
    required this.item,
    required this.onDismiss,
    required this.onAction,
    this.onHoverChanged,
    super.key,
  });

  final AppNotificationItem item;
  final VoidCallback onDismiss;
  final VoidCallback onAction;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<AppNotificationCard> createState() => _AppNotificationCardState();
}

class _AppNotificationCardState extends State<AppNotificationCard> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (backgroundColor, foregroundColor, iconData) = switch (widget.item.type) {
      AppNotificationType.success => (
        Colors.green.shade50,
        Colors.green.shade900,
        Icons.check_circle,
      ),
      AppNotificationType.warning => (
        Colors.orange.shade50,
        Colors.orange.shade900,
        Icons.warning_amber_rounded,
      ),
      AppNotificationType.error => (
        Colors.red.shade50,
        Colors.red.shade900,
        Icons.error_outline,
      ),
      AppNotificationType.info => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        Icons.info_outline,
      ),
    };

    return MouseRegion(
      onEnter: (_) => widget.onHoverChanged?.call(true),
      onExit: (_) => widget.onHoverChanged?.call(false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        offset: _isVisible ? Offset.zero : const Offset(0.08, 0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          opacity: _isVisible ? 1 : 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(iconData, size: 18, color: foregroundColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.item.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.item.actionLabel != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: widget.onAction,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: foregroundColor,
                            ),
                            child: Text(widget.item.actionLabel!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.item.dismissible)
                    IconButton(
                      onPressed: widget.onDismiss,
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: Icon(Icons.close, size: 18, color: foregroundColor),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
