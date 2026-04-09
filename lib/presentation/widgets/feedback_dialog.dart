import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/global_provider.dart';
import '../../application/providers/setting_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/config/theme.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';

/// 日志文件相对路径（相对于 $HOME）
const _kLogFileRelative =
    '.local/share/com.dongpl.linglong-store.v2/logs/linglong-store.log';

/// 意见反馈对话框
///
/// 包含问题分类（多选）、概述、详细描述、上传日志（可选）。
/// 提交时向 POST /visit/suggest 发送反馈数据，
/// 若勾选日志，先 POST /app/uploadLog 上传文件后附带 URL。
class FeedbackDialog extends ConsumerStatefulWidget {
  const FeedbackDialog({super.key});

  @override
  ConsumerState<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends ConsumerState<FeedbackDialog> {
  final _overviewController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedCategories = {};
  bool _uploadLogFile = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _overviewController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 从国际化获取分类列表
    final categories = l10n.feedbackCategories.split(',');

    return AlertDialog(
      title: Text(l10n.feedbackTitle),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问题分类多选
              Text(
                l10n.feedbackCategory,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: categories.map((cat) {
                  final selected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: selected,
                    // 显式指定文字颜色，确保浅灰背景上文字清晰可读
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    // 选中态使用主色浅底，未选中态使用卡片灰色底
                    backgroundColor: AppColors.cardBackground,
                    selectedColor: AppColors.primaryLight,
                    // 未选中态边框
                    side: const BorderSide(color: AppColors.border),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 概述输入框
              TextField(
                controller: _overviewController,
                decoration: InputDecoration(
                  labelText: l10n.overview,
                  hintText: l10n.overviewHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // 详细描述
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.detailDescription,
                  hintText: l10n.detailDescriptionHint,
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // 上传日志复选框
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.uploadLog),
                subtitle: Text(l10n.noPrivacyInfo),
                value: _uploadLogFile,
                onChanged: (value) =>
                    setState(() => _uploadLogFile = value ?? false),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.submitFeedback),
        ),
      ],
    );
  }

  /// 提交反馈
  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final overview = _overviewController.text.trim();
    final description = _descriptionController.text.trim();

    if (overview.isEmpty && description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.feedbackHint),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final noneText = l10n.none;

    try {
      String? logFileUrl;

      // 可选：上传日志文件
      if (_uploadLogFile) {
        logFileUrl = await _uploadLog();
      }

      // 构建消息体（与旧版格式保持一致）
      final categories = _selectedCategories.isEmpty
          ? noneText
          : _selectedCategories.join(', ');
      final message =
          '分类: $categories\n'
          '概述: ${overview.isEmpty ? noneText : overview}\n'
          '描述: ${description.isEmpty ? noneText : description}';

      final globalState = ref.read(globalAppProvider);
      final settingState = ref.read(settingProvider);

      final body = <String, dynamic>{
        'message': message,
        'llVersion': globalState.llVersion ?? '',
        'appVersion': settingState.appVersion ?? AppConfig.appVersion,
        'arch': globalState.arch ?? '',
        if (logFileUrl != null) 'logFileUrl': logFileUrl,
      };

      await ApiClient.instance.post('/visit/suggest', data: body);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackSuccess),
          ),
        );
      }
    } catch (e, s) {
      AppLogger.error('提交反馈失败', e, s);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 上传日志文件，返回服务端存储 URL；失败返回 null
  Future<String?> _uploadLog() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return null;

      final logFile = File('$home/$_kLogFileRelative');
      if (!logFile.existsSync()) {
        AppLogger.warning('[FeedbackDialog] 日志文件不存在: ${logFile.path}');
        return null;
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          logFile.path,
          filename: 'linglong-store.log',
        ),
      });

      final resp = await ApiClient.instance.post(
        '/app/uploadLog',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // 后端返回 { code: 200, data: "url" }
      final data = resp.data;
      if (data is Map && data['code'] == 200) {
        return data['data'] as String?;
      }
    } catch (e, s) {
      AppLogger.error('[FeedbackDialog] 上传日志失败', e, s);
    }
    return null;
  }
}
