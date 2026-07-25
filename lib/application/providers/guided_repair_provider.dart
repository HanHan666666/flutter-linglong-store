import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/security/trusted_content_signature.dart';
import '../services/guided_repair_service.dart';
import 'linglong_env_provider.dart';

/// 通用受信内容验签器 Provider。
final trustedContentSignatureVerifierProvider =
    Provider<TrustedContentSignatureVerifier>((ref) {
      return Ed25519TrustedContentSignatureVerifier();
    });

/// 安装错误一键修复服务 Provider。
final guidedRepairServiceProvider = Provider<GuidedRepairService>((ref) {
  return GuidedRepairService(
    executor: ref.watch(shellCommandExecutorProvider),
    signatureVerifier: ref.watch(trustedContentSignatureVerifierProvider),
  );
});
