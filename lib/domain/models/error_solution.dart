/// 安装错误解决方案领域模型。
///
/// 该模型只表达客户端真正需要展示和执行的数据，不暴露后端的匹配条件、
/// 多语言存储编码等管理细节，从而保持展示层与后端表结构解耦。
class ErrorSolution {
  /// 创建一个不可变的错误解决方案。
  const ErrorSolution({
    required this.title,
    required this.markdown,
    this.repairScript,
    this.repairScriptSignature,
  });

  /// 按当前语言解析后的标题。
  final String title;

  /// 按当前语言解析并由后端完成中文回退后的完整 Markdown。
  final String markdown;

  /// 通过后端验签后返回的一键修复脚本；为空时只能展示人工解决步骤。
  final String? repairScript;

  /// 与 [repairScript] 精确对应的 Base64 Ed25519 签名。
  final String? repairScriptSignature;

  /// 当前方案是否携带完整的一键修复载荷。
  ///
  /// 客户端执行前仍会独立验签；这里仅用于决定是否展示入口。
  bool get hasRepairScript =>
      repairScript != null &&
      repairScript!.isNotEmpty &&
      repairScriptSignature != null &&
      repairScriptSignature!.isNotEmpty;
}
