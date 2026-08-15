/// 列表场景简要描述截断工具。
///
/// 后端列表接口返回的 `description` 是简要描述（完整描述 `descInfo` 仅在
/// 详情接口提供），正常为一句话；但个别应用会填写超长简介。列表模型
/// （RecommendAppInfo / InstalledApp / RankingAppInfo）会被多个常驻页面
/// 长期持有，这里在数据转换边界统一封顶，超长文本不再整串驻留内存。
/// 卡片 UI 仅展示单行摘要，截断不影响展示效果；详情页走独立接口拿全文。
library;

/// 截断列表场景的简要描述。
///
/// 超过 [maxChars] 时保留前缀并追加省略号；null 与短文本原样返回，
/// 不改变空值语义（调用方对 null/'' 已有既定处理）。
String? truncateBriefDescription(String? text, {int maxChars = 200}) {
  if (text == null || text.length <= maxChars) {
    return text;
  }
  return '${text.substring(0, maxChars)}…';
}
