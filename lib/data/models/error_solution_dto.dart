/// 安装错误解决方案接口 DTO。
///
/// 该接口结构很小且稳定，使用显式 JSON 映射能让空数据语义和字段边界一目了然，
/// 同时避免把后端传输模型扩散到领域层。
class ErrorSolutionFindRequest {
  /// 创建查询请求。
  const ErrorSolutionFindRequest({
    required this.message,
    required this.language,
  });

  /// ll-cli JSON 中未经本地匹配加工的 message。
  final String message;

  /// 客户端当前语言代码。
  final String language;

  /// 转换为后端接口约定的 JSON。
  Map<String, dynamic> toJson() => <String, dynamic>{
    'message': message,
    'lang': language,
  };
}

/// 错误解决方案公共接口响应。
class ErrorSolutionResponse {
  /// 创建接口响应。
  const ErrorSolutionResponse({required this.code, this.message, this.data});

  /// 后端统一业务状态码。
  final int code;

  /// 后端统一响应说明。
  final String? message;

  /// 唯一命中的解决方案；未命中时为 `null`。
  final ErrorSolutionDto? data;

  /// 从后端 JSON 构建响应。
  factory ErrorSolutionResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return ErrorSolutionResponse(
      code: (json['code'] as num?)?.toInt() ?? -1,
      message: json['message'] as String?,
      data: rawData is Map<String, dynamic>
          ? ErrorSolutionDto.fromJson(rawData)
          : null,
    );
  }
}

/// 错误解决方案传输对象。
class ErrorSolutionDto {
  /// 创建传输对象。
  const ErrorSolutionDto({
    required this.title,
    required this.markdown,
    this.repairScript,
    this.repairScriptSignature,
  });

  /// 后端完成多语言解析后的标题。
  final String title;

  /// 后端完成多语言解析后的 Markdown。
  final String markdown;

  /// 后端验签通过后才返回的修复脚本。
  final String? repairScript;

  /// 修复脚本的 Base64 Ed25519 签名。
  final String? repairScriptSignature;

  /// 从后端 JSON 构建传输对象。
  factory ErrorSolutionDto.fromJson(Map<String, dynamic> json) {
    return ErrorSolutionDto(
      title: json['title'] as String? ?? '',
      markdown: json['markdown'] as String? ?? '',
      repairScript: json['repairScript'] as String?,
      repairScriptSignature: json['repairScriptSignature'] as String?,
    );
  }
}
