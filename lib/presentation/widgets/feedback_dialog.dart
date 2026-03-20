import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/global_provider.dart';
import '../../application/providers/setting_provider.dart';
import '../../core/config/app_config.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/api_client.dart';

/// 反馈问题类型选项
const _kFeedbackCategories = ['商店缺陷', '应用更新', '应用故障'];

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
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.feedbackTitle ?? '意见反馈'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 问题分类多选
              Text(
                '问题分类',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _kFeedbackCategories.map((cat) {
                  final selected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: selected,
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
                decoration: const InputDecoration(
                  labelText: '概述',
                  hintText: '请简要描述问题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // 详细描述
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '详细描述',
                  hintText: '请详细描述您遇到的问题',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // 上传日志复选框
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n?.uploadLog ?? '同时上传日志文件'),
                subtitle: Text(l10n?.noPrivacyInfo ?? '日志中不包含个人隐私信息'),
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
          child: Text(l10n?.cancel ?? '取消'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n?.submitFeedback ?? '提交'),
        ),
      ],
    );
  }

  /// 提交反馈
  Future<void> _submit() async {
    final overview = _overviewController.text.trim();
    final description = _descriptionController.text.trim();

    if (overview.isEmpty && description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.feedbackHint ?? '请填写问题概述或描述')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? logFileUrl;

      // 可选：上传日志文件
      if (_uploadLogFile) {
        logFileUrl = await _uploadLog();
      }

      // 构建消息体（与旧版格式保持一致）
      final categories = _selectedCategories.isEmpty
          ? '无'
          : _selectedCategories.join(', ');
      final message =
          '分类: $categories\n'
          '概述: ${overview.isEmpty ? "无" : overview}\n'
          '描述: ${description.isEmpty ? "无" : description}';

      final globalState = ref.read(globalAppProvider);
      final settingState = ref.read(settingProvider);

      final body = <String, dynamic>{
        'message': message,
        'llVersion': globalState.llVersion ?? '',
        'llBinVersion': globalState.llBinVersion ?? '',
        'appVersion': settingState.appVersion ?? AppConfig.appVersion,
        'arch': globalState.arch ?? '',
        if (logFileUrl != null) 'logFileUrl': logFileUrl,
      };

      await ApiClient.instance.post('/visit/suggest', data: body);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.feedbackSuccess ?? '感谢您的反馈！')));
      }
    } catch (e, s) {
      AppLogger.error('提交反馈失败', e, s);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)?.feedbackFailed ?? '反馈提交失败，请稍后重试')));
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
