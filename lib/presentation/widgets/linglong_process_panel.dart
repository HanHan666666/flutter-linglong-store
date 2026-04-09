import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_desktop_context_menu/flutter_desktop_context_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/running_process_provider.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../domain/models/running_app.dart';
import 'app_icon.dart';
import 'empty_state.dart';

/// 玲珑进程面板
class LinglongProcessPanel extends ConsumerStatefulWidget {
  const LinglongProcessPanel({super.key});

  @override
  ConsumerState<LinglongProcessPanel> createState() =>
      _LinglongProcessPanelState();
}

class _LinglongProcessPanelState extends ConsumerState<LinglongProcessPanel> {
  String? _contextMenuRowId;

  Future<void> _showProcessContextMenu(RunningApp app, Offset position) async {
    final isKilling = ref
        .read(runningProcessProvider)
        .killLoadingIds
        .contains(app.id);

    // 获取国际化实例用于菜单项标签
    final l10n = AppLocalizations.of(context)!;
    final menu = Menu(
      items: [
        MenuItem(
          label: l10n.copyContainerCommand,
          onClick: (_) => _copyText(
            'll-cli enter ${app.appId}',
            l10n.commandCopied,
          ),
        ),
        MenuItem(
          label: l10n.copyAppId,
          onClick: (_) => _copyText(
            app.appId,
            l10n.copied(app.appId),
          ),
        ),
        MenuItem(
          label: l10n.copyPid,
          onClick: (_) => _copyText(
            app.pid.toString(),
            l10n.copied(app.pid.toString()),
          ),
        ),
        MenuItem(
          label: l10n.copyContainerId,
          onClick: (_) => _copyText(
            app.containerId,
            l10n.copied(app.containerId),
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          label: l10n.refreshProcessList,
          onClick: (_) => ref.read(runningProcessProvider.notifier).refresh(),
        ),
        MenuItem.separator(),
        MenuItem(
          label: l10n.stopProcess,
          disabled: isKilling,
          onClick: (_) => _stopProcess(app),
        ),
      ],
    );

    setState(() {
      _contextMenuRowId = app.id;
    });

    try {
      await popUpContextMenu(
        menu,
        position: position + const Offset(4, 4),
        placement: Placement.bottomRight,
      );
    } finally {
      if (mounted) {
        setState(() {
          _contextMenuRowId = null;
        });
      }
    }
  }

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _stopProcess(RunningApp app) async {
    final success = await ref
        .read(runningProcessProvider.notifier)
        .killApp(app);
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? l10n.stopSuccess(app.name)
              : l10n.stopFailed,
        ),
        backgroundColor: success ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(runningProcessProvider);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        _ProcessToolbar(state: state),
        if (state.error != null && state.apps.isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD591)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 18,
                  color: Color(0xFFD48806),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.processRefreshFailed,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8C5A00),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: _buildContent(context, state, l10n)),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    RunningProcessState state,
    AppLocalizations l10n,
  ) {
    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.apps.isEmpty) {
      return EmptyState(
        icon: Icons.layers_clear,
        title: l10n.linglongProcess,
        description: l10n.noRunningApps,
        retryText: l10n.refresh,
        onRetry: () => ref.read(runningProcessProvider.notifier).refresh(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = math.max(constraints.maxWidth, 1008.0);

        return RefreshIndicator(
          onRefresh: () => ref.read(runningProcessProvider.notifier).refresh(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _ProcessTableHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: state.apps.length,
                      itemBuilder: (context, index) {
                        final app = state.apps[index];
                        return _ProcessTableRow(
                          app: app,
                          isMenuSelected: _contextMenuRowId == app.id,
                          isKilling: state.killLoadingIds.contains(app.id),
                          onShowMenu: (position) =>
                              _showProcessContextMenu(app, position),
                          onStop: () => _stopProcess(app),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProcessToolbar extends ConsumerWidget {
  const _ProcessToolbar({required this.state});

  final RunningProcessState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final lastRefreshedText = state.lastRefreshedAt == null
        ? l10n.notRefreshed
        : '${l10n.lastRefresh} ${_formatTime(state.lastRefreshedAt!)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          Text(
            l10n.linglongProcess,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${state.apps.length}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const Spacer(),
          if (state.isRefreshing) ...[
            Text(
              l10n.refreshing,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            lastRefreshedText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () =>
                ref.read(runningProcessProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class _ProcessTableHeader extends StatelessWidget {
  const _ProcessTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _ProcessHeaderCell(
            label: l10n.appName,
            width: 240,
          ),
          _ProcessHeaderCell(
            label: l10n.versionNo,
            width: 120,
            centered: true,
          ),
          _ProcessHeaderCell(
            label: l10n.architecture,
            width: 100,
            centered: true,
          ),
          _ProcessHeaderCell(
            label: l10n.channelLabel,
            width: 90,
            centered: true,
          ),
          _ProcessHeaderCell(
            label: l10n.source,
            width: 110,
            centered: true,
          ),
          const _ProcessHeaderCell(
            label: 'PID',
            width: 90,
            centered: true,
          ),
          _ProcessHeaderCell(
            label: l10n.containerId,
            width: 210,
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _ProcessHeaderCell extends StatelessWidget {
  const _ProcessHeaderCell({
    required this.label,
    required this.width,
    this.centered = false,
  });

  final String label;
  final double width;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProcessTableRow extends StatefulWidget {
  const _ProcessTableRow({
    required this.app,
    required this.isMenuSelected,
    required this.isKilling,
    required this.onShowMenu,
    required this.onStop,
  });

  final RunningApp app;
  final bool isMenuSelected;
  final bool isKilling;
  final ValueChanged<Offset> onShowMenu;
  final VoidCallback onStop;

  @override
  State<_ProcessTableRow> createState() => _ProcessTableRowState();
}

class _ProcessTableRowState extends State<_ProcessTableRow> {
  bool _isHovered = false;
  Offset? _lastTapPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final rowColor = widget.isMenuSelected
        ? context.appColors.primaryLight
        : (_isHovered
              ? context.appColors.surfaceContainerLow
              : Colors.transparent);
    final borderColor = widget.isMenuSelected
        ? AppColors.primary
        : (_isHovered
              ? theme.colorScheme.outline
              : theme.colorScheme.outlineVariant);

    return Semantics(
      label: l10n.a11yProcessItem(
        widget.app.name,
        widget.app.pid.toString(),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // 必须等右键抬起后再弹菜单，否则 GTK 会把同一次抬起事件当成
          // 一次“点空白处关闭菜单”，表现就是菜单闪一下立即消失。
          onSecondaryTapUp: (details) =>
              widget.onShowMenu(details.globalPosition),
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: rowColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: Row(
                    children: [
                      AppIcon(
                        iconUrl: widget.app.icon,
                        size: 36,
                        borderRadius: 8,
                        appName: widget.app.name,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.app.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.app.appId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _ProcessValueCell(
                  value: widget.app.version,
                  width: 120,
                  centered: true,
                ),
                _ProcessValueCell(
                  value: widget.app.arch,
                  width: 100,
                  centered: true,
                ),
                _ProcessValueCell(
                  value: widget.app.channel,
                  width: 90,
                  centered: true,
                ),
                _ProcessValueCell(
                  value: widget.app.source,
                  width: 110,
                  centered: true,
                ),
                _ProcessValueCell(
                  value: widget.app.pid.toString(),
                  width: 90,
                  centered: true,
                  monospace: true,
                ),
                _ProcessValueCell(
                  value: widget.app.containerId,
                  width: 210,
                  monospace: true,
                ),
                SizedBox(
                  width: 48,
                  child: GestureDetector(
                    onTapDown: (details) =>
                        _lastTapPosition = details.globalPosition,
                    child: IconButton(
                      onPressed: widget.isKilling
                          ? null
                          : () {
                              final position =
                                  _lastTapPosition ?? const Offset(0, 0);
                              widget.onShowMenu(position);
                            },
                      icon: widget.isKilling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.more_horiz),
                      tooltip: AppLocalizations.of(context)?.moreActions ??
                          '更多操作',
                    ),
                  ),
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

class _ProcessValueCell extends StatelessWidget {
  const _ProcessValueCell({
    required this.value,
    required this.width,
    this.centered = false,
    this.monospace = false,
  });

  final String value;
  final double width;
  final bool centered;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? '—' : value;
    return SizedBox(
      width: width,
      child: Text(
        displayValue,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: centered ? TextAlign.center : TextAlign.start,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: monospace ? 'monospace' : null,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
