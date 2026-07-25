import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/security/trusted_content_signature.dart';

/// Flutter 与后端共享的 Ed25519 固定向量测试。
///
/// 该测试锁定信封格式、用途、UTF-8 和末尾换行，防止跨语言实现出现“同一脚本
/// 后端验签通过、客户端验签失败”的协议漂移。
void main() {
  const publicKeyBase64 = 'UZnaLPXj7z7IRpeeUJNxwRaBzzVpQD8HGz4f+dtaPLY=';
  const signatureBase64 =
      '/a35krb5rpB2DFhvrJh7fZ0VGW9/toDoz+lFM/ABDSC1+Qf5sXBJGLaqO8Nk/9Bsu3pJfMs9dY6Hlk471PNkCA==';
  const script = '#!/usr/bin/env bash\necho ok\n';

  test('固定跨端向量验签通过', () async {
    final verifier = Ed25519TrustedContentSignatureVerifier.withPublicKeyBase64(
      publicKeyBase64,
    );

    final valid = await verifier.verify(
      purpose: TrustedContentPurpose.privilegedShellScript,
      content: script,
      signature: signatureBase64,
    );

    expect(valid, isTrue);
  });

  test('正文末尾换行变化后验签失败', () async {
    final verifier = Ed25519TrustedContentSignatureVerifier.withPublicKeyBase64(
      publicKeyBase64,
    );

    final valid = await verifier.verify(
      purpose: TrustedContentPurpose.privilegedShellScript,
      content: script.trim(),
      signature: signatureBase64,
    );

    expect(valid, isFalse);
  });

  test('非法 Base64 或非 64 字节签名返回 false', () async {
    final verifier = Ed25519TrustedContentSignatureVerifier.withPublicKeyBase64(
      publicKeyBase64,
    );

    expect(
      await verifier.verify(
        purpose: TrustedContentPurpose.privilegedShellScript,
        content: script,
        signature: 'not-base64',
      ),
      isFalse,
    );
    expect(
      await verifier.verify(
        purpose: TrustedContentPurpose.privilegedShellScript,
        content: script,
        signature: 'YWJj',
      ),
      isFalse,
    );
  });
}
