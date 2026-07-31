/// 玲珑仓库管理区域。
///
/// 该文件负责仓库配置的列表和操作菜单展示，所有修改动作通过回调交给
/// 对话框交互控制器，组件自身不读取 Provider。
library;

import 'package:flutter/material.dart';

import '../../../application/providers/linglong_environment_management_provider.dart';
import '../../../core/config/theme.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../domain/models/linglong_env_check_result.dart';
import '../app_anchored_menu.dart';
import 'environment_management_components.dart';

/// 展示仓库配置并提供仓库操作入口。
class RepositoryManagementTab extends StatelessWidget {
  /// 创建仓库管理区域。
  const RepositoryManagementTab({
    required this.state,
    required this.onAddRepository,
    required this.onUpdateRepository,
    required this.onRemoveRepository,
    required this.onSetDefaultRepository,
    required this.onSetPriority,
    required this.onSetMirror,
    super.key,
  });

  /// 当前环境管理状态。
  final LinglongEnvironmentManagementState state;

  /// 添加仓库的回调。
  final VoidCallback onAddRepository;

  /// 修改仓库地址的回调。
  final ValueChanged<LinglongRepoInfo> onUpdateRepository;

  /// 删除仓库的回调。
  final ValueChanged<LinglongRepoInfo> onRemoveRepository;

  /// 设置默认仓库的回调。
  final ValueChanged<LinglongRepoInfo> onSetDefaultRepository;

  /// 设置仓库优先级的回调。
  final ValueChanged<LinglongRepoInfo> onSetPriority;

  /// 修改仓库镜像状态的回调。
  final void Function(LinglongRepoInfo repo, {required bool enabled})
  onSetMirror;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final config = state.repositoryConfig;
    if (config == null) {
      return EnvironmentManagementEmptyState(
        icon: Icons.hub_outlined,
        title: state.errorMessage == null
            ? l10n.envRepositoryNotLoaded
            : l10n.envResultUnexpectedFailure(state.errorMessage!),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.envRepositoryDefaultValue(
                  config.defaultRepo ?? l10n.envNotSet,
                ),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: context.appFontWeight(FontWeight.w600),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: state.isBusy ? null : onAddRepository,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.envAddRepository),
            ),
          ],
        ),
        const SizedBox(height: 12),
        EnvironmentManagementInfoPanel(
          icon: Icons.info_outline,
          title: AppLocalizations.of(context)!.repoManagementHintTitle,
          message: AppLocalizations.of(context)!.repoManagementHintMessage,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: config.repos.isEmpty
              ? EnvironmentManagementEmptyState(
                  icon: Icons.hub_outlined,
                  title: l10n.envNoRepositories,
                )
              : ListView.separated(
                  itemCount: config.repos.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final repo = config.repos[index];
                    final isDefault =
                        repo.name == config.defaultRepo ||
                        repo.alias == config.defaultRepo;
                    return _RepositoryTile(
                      repo: repo,
                      isDefault: isDefault,
                      isBusy: state.isBusy,
                      onUpdateRepository: onUpdateRepository,
                      onRemoveRepository: onRemoveRepository,
                      onSetDefaultRepository: onSetDefaultRepository,
                      onSetPriority: onSetPriority,
                      onSetMirror: onSetMirror,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _RepositoryTile extends StatelessWidget {
  const _RepositoryTile({
    required this.repo,
    required this.isDefault,
    required this.isBusy,
    required this.onUpdateRepository,
    required this.onRemoveRepository,
    required this.onSetDefaultRepository,
    required this.onSetPriority,
    required this.onSetMirror,
  });

  final LinglongRepoInfo repo;
  final bool isDefault;
  final bool isBusy;
  final ValueChanged<LinglongRepoInfo> onUpdateRepository;
  final ValueChanged<LinglongRepoInfo> onRemoveRepository;
  final ValueChanged<LinglongRepoInfo> onSetDefaultRepository;
  final ValueChanged<LinglongRepoInfo> onSetPriority;
  final void Function(LinglongRepoInfo repo, {required bool enabled})
  onSetMirror;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(
            isDefault ? Icons.star_rounded : Icons.hub_outlined,
            color: isDefault
                ? AppColors.warning
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        linglongRepositoryDisplayName(repo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: context.appFontWeight(FontWeight.w600),
                        ),
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          l10n.envDefaultBadge,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.warning,
                                fontWeight: context.appFontWeight(
                                  FontWeight.w600,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  repo.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.envRepositoryDetails(
                    repo.name,
                    repo.priority ?? l10n.envNotSet,
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          AppAnchoredMenuButton<_RepositoryAction>(
            enabled: !isBusy,
            tooltip: l10n.envRepositoryActions,
            semanticsLabel: l10n.envRepositoryActions,
            onSelected: (action) {
              switch (action) {
                case _RepositoryAction.editUrl:
                  onUpdateRepository(repo);
                case _RepositoryAction.setDefault:
                  onSetDefaultRepository(repo);
                case _RepositoryAction.setPriority:
                  onSetPriority(repo);
                case _RepositoryAction.enableMirror:
                  onSetMirror(repo, enabled: true);
                case _RepositoryAction.disableMirror:
                  onSetMirror(repo, enabled: false);
                case _RepositoryAction.remove:
                  onRemoveRepository(repo);
              }
            },
            entries: [
              AppAnchoredMenuItem(
                value: _RepositoryAction.editUrl,
                label: l10n.envEditAddress,
              ),
              AppAnchoredMenuItem(
                value: _RepositoryAction.setDefault,
                label: l10n.envSetDefault,
              ),
              AppAnchoredMenuItem(
                value: _RepositoryAction.setPriority,
                label: l10n.envSetPriority,
              ),
              AppAnchoredMenuItem(
                value: _RepositoryAction.enableMirror,
                label: l10n.envEnableMirror,
              ),
              AppAnchoredMenuItem(
                value: _RepositoryAction.disableMirror,
                label: l10n.envDisableMirror,
              ),
              const AppAnchoredMenuDivider(),
              AppAnchoredMenuItem(
                value: _RepositoryAction.remove,
                label: l10n.envRemoveRepositoryTitle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _RepositoryAction {
  editUrl,
  setDefault,
  setPriority,
  enableMirror,
  disableMirror,
  remove,
}
