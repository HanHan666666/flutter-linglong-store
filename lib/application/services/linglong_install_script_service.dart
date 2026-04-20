/// 安装脚本获取服务。
///
/// 统一从后端读取自动安装脚本正文，不在本地维护固定脚本 URL。
class LinglongInstallScriptService {
  LinglongInstallScriptService({required Future<String?> Function() loadScript})
    : _loadScript = loadScript;

  final Future<String?> Function() _loadScript;

  Future<String> fetchInstallScript() async {
    final script = (await _loadScript())?.trim() ?? '';
    if (script.isEmpty) {
      throw StateError('获取安装脚本失败，请稍后重试');
    }
    return script;
  }
}
