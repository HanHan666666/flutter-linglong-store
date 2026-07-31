import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/guided_repair_provider.dart';
import '../../core/i18n/l10n/app_localizations.dart';
import '../../core/security/trusted_content_signature.dart';
import '../../core/utils/app_notification_helpers.dart';
import '../../domain/models/error_solution.dart';
import '../widgets/guided_repair_execution_dialog.dart';
import '../widgets/script_review_dialog.dart';

/// 安装错误一键修复的统一展示流程。
///
/// 所有入口必须经过“首次验签 → 全文审计 → 执行服务再次验签”这一条路径，
/// 禁止页面自行弹确认框或直接调用 pkexec。
Future<void> showGuidedRepairFlow(
  BuildContext context,
  WidgetRef ref,
  ErrorSolution solution,
) async {
  final script = solution.repairScript;
  final signature = solution.repairScriptSignature;
  if (script == null || signature == null) {
    return;
  }

  final signatureValid = await ref
      .read(trustedContentSignatureVerifierProvider)
      .verify(
        purpose: TrustedContentPurpose.privilegedShellScript,
        content: script,
        signature: signature,
      );
  if (!context.mounted) {
    return;
  }
  if (!signatureValid) {
    final l10n = AppLocalizations.of(context)!;
    showAppError(context, l10n.repairInvalidSignature);
    return;
  }

  final confirmed = await showScriptReviewDialog(context, script: script);
  if (!confirmed || !context.mounted) {
    return;
  }

  await showGuidedRepairExecutionDialog(
    context,
    service: ref.read(guidedRepairServiceProvider),
    script: script,
    signature: signature,
  );
}
