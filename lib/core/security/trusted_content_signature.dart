import 'dart:convert';

import 'package:cryptography/cryptography.dart';

/// 受信内容签名用途。
///
/// 签名信封显式携带用途，防止同一把通用内容签名密钥产生的签名被跨业务重放。
enum TrustedContentPurpose {
  /// 允许客户端通过 pkexec 执行的特权 Shell 脚本。
  privilegedShellScript('privileged-shell-script');

  /// 写入签名信封的稳定文本值。
  const TrustedContentPurpose(this.value);

  /// 稳定用途值。
  final String value;
}

/// 通用受信内容签名信封。
class TrustedContentEnvelope {
  TrustedContentEnvelope._();

  /// 信封格式标识。
  static const String format = 'LINGLONG_STORE_SIGNED_CONTENT_V1';

  /// 按稳定字节协议构建待签名原文。
  ///
  /// [content] 会原样拼接，不允许 trim、换行转换或 Unicode 归一化。
  static String build({
    required TrustedContentPurpose purpose,
    required String content,
  }) {
    return '$format\npurpose=${purpose.value}\n\n$content';
  }
}

/// 通用受信内容验签接口。
abstract interface class TrustedContentSignatureVerifier {
  /// 验证 [content] 与 Base64 [signature] 是否完全对应。
  Future<bool> verify({
    required TrustedContentPurpose purpose,
    required String content,
    required String signature,
  });
}

/// Ed25519 受信内容验签器。
///
/// 客户端只内置 32 字节原始公钥；私钥始终保存在代码库和运行客户端之外。
class Ed25519TrustedContentSignatureVerifier
    implements TrustedContentSignatureVerifier {
  /// 使用生产公钥创建验签器。
  Ed25519TrustedContentSignatureVerifier()
    : this.withPublicKeyBase64(productionPublicKeyBase64);

  /// 使用指定原始公钥创建可测试验签器。
  Ed25519TrustedContentSignatureVerifier.withPublicKeyBase64(
    String publicKeyBase64,
  ) : _publicKey = SimplePublicKey(
        base64Decode(publicKeyBase64),
        type: KeyPairType.ed25519,
      );

  /// 当前生产签名公钥的 32 字节原始 Base64。
  static const String productionPublicKeyBase64 =
      'iUvAAZQEo+so/TvBKqKq95LxGTYqEHTzLeHReR9bPv4=';

  /// Ed25519 原始公钥。
  final SimplePublicKey _publicKey;

  /// Ed25519 算法实现。
  final Ed25519 _algorithm = Ed25519();

  @override
  Future<bool> verify({
    required TrustedContentPurpose purpose,
    required String content,
    required String signature,
  }) async {
    try {
      final signatureBytes = base64Decode(signature);
      if (signatureBytes.length != 64) {
        return false;
      }
      final envelope = TrustedContentEnvelope.build(
        purpose: purpose,
        content: content,
      );
      return _algorithm.verify(
        utf8.encode(envelope),
        signature: Signature(signatureBytes, publicKey: _publicKey),
      );
    } on FormatException {
      return false;
    }
  }
}
