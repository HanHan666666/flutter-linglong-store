// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '玲珑应用商店社区版';

  @override
  String get recommend => '推 荐';

  @override
  String get allApps => '全部应用';

  @override
  String get ranking => '排行榜';

  @override
  String get myApps => '我的应用';

  @override
  String get update => '更 新';

  @override
  String get settings => '设置';

  @override
  String get category => '分 类';

  @override
  String get office => '办 公';

  @override
  String get system => '系 统';

  @override
  String get develop => '开 发';

  @override
  String get entertainment => '娱 乐';

  @override
  String get searchPlaceholder => '在这里搜索你想搜索的应用';

  @override
  String get search => '搜索';

  @override
  String get refresh => '刷新';

  @override
  String get linglongRecommend => '玲珑推荐';

  @override
  String get loading => '加载中...';

  @override
  String get installing => '安装中...';

  @override
  String get success => '成功';

  @override
  String get failed => '失败';

  @override
  String get cancel => '取消';

  @override
  String get noMoreData => '没有更多数据了';

  @override
  String get install => '安 装';

  @override
  String get uninstall => '卸 载';

  @override
  String get open => '打 开';

  @override
  String get update_action => '更 新';

  @override
  String get run => '启 动';

  @override
  String get confirm => '确认';

  @override
  String get viewDetail => '查看详情';

  @override
  String get screenShots => '屏幕截图';

  @override
  String get versionSelect => '版本选择';

  @override
  String get versionNumber => '版本号';

  @override
  String get appType => '应用类型';

  @override
  String get channel => '通道';

  @override
  String get mode => '模式';

  @override
  String get repoSource => '仓库来源';

  @override
  String get fileSize => '文件大小';

  @override
  String get downloadCount => '下载量';

  @override
  String get operation => '操作';

  @override
  String get linglongProcess => '玲珑进程';

  @override
  String get baseSetting => '基本设置';

  @override
  String get about => '关于';

  @override
  String get envMissing => '检测到当前系统缺少玲珑环境';

  @override
  String get envMissingDetail => '检测到系统中不存在或版本过低的玲珑组件，需先安装后才能使用商店。';

  @override
  String get autoInstall => '自动安装';

  @override
  String get manualInstall => '手动安装';

  @override
  String get recheck => '重新检测';

  @override
  String get exitStore => '退出商店';

  @override
  String get errorNetwork => '网络连接失败';

  @override
  String get errorNetworkDetail => '请检查网络连接后重试';

  @override
  String get errorInstallFailed => '安装失败';

  @override
  String get errorUninstallFailed => '卸载失败';

  @override
  String get errorUpdateFailed => '更新失败';

  @override
  String get errorUnknown => '未知错误';

  @override
  String get retry => '重试';

  @override
  String get downloading => '下载中...';

  @override
  String get downloadComplete => '下载完成';

  @override
  String get installComplete => '安装完成';

  @override
  String get uninstallComplete => '卸载完成';

  @override
  String get updateComplete => '更新完成';

  @override
  String get noApps => '暂无应用';

  @override
  String get noInstalledApps => '暂无已安装应用';

  @override
  String get noUpdateApps => '暂无可用更新';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get description => '简介';

  @override
  String get developer => '开发者';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get confirmDeleteMessage => '确定要删除此项吗？此操作无法撤销。';

  @override
  String get confirmUninstall => '确认卸载';

  @override
  String get confirmUninstallMessage => '确定要卸载此应用吗？';

  @override
  String get noData => '暂无数据';

  @override
  String get noDataDescription => '这里还没有任何内容';

  @override
  String get searchApps => '搜索应用...';

  @override
  String get languageSettings => '语言设置';

  @override
  String get themeSettings => '主题设置';

  @override
  String get repoConfig => '仓库配置';

  @override
  String get cacheManagement => '缓存管理';

  @override
  String get storeOptions => '商店选项';

  @override
  String get checkUpdate => '检查更新';

  @override
  String currentVersion(String version) {
    return '当前版本: $version';
  }

  @override
  String newVersionFound(String tagName, String currentVersion) {
    return '发现新版本 $tagName，当前版本 $currentVersion';
  }

  @override
  String alreadyLatest(String version) {
    return '当前已是最新版本 $version';
  }

  @override
  String get checkingUpdate => '检查更新中...';

  @override
  String get goDownload => '前往下载';

  @override
  String get editRepo => '修改仓库源';

  @override
  String repoSwitched(String repoName) {
    return '仓库已切换为: $repoName';
  }

  @override
  String get modifyBtn => '修改';

  @override
  String get cacheSize => '缓存大小';

  @override
  String get startupCheckUpdate => '启动时检查商店版本更新';

  @override
  String get startupCheckUpdateDesc => '每次启动时检测是否有新版本可用';

  @override
  String get autoUpdateInContainer => '容器内自动更新商店本体';

  @override
  String get autoUpdateInContainerDesc => '在玲珑容器内运行时自动更新商店应用';

  @override
  String get showBaseServices => '显示基础运行服务';

  @override
  String get showBaseServicesDesc => '在已安装列表中显示底层基础运行服务';

  @override
  String get cleanDeprecatedServices => '清理废弃基础服务';

  @override
  String get cleanDeprecatedServicesDesc => '移除已不再使用的基础运行服务，释放磁盘空间';

  @override
  String get checkNewVersion => '检查新版本';

  @override
  String get feedbackMenu => '意见反馈';

  @override
  String get officialWebsite => '官网';

  @override
  String get feedbackTitle => '意见反馈';

  @override
  String get uploadLog => '同时上传日志文件';

  @override
  String get noPrivacyInfo => '日志中不包含个人隐私信息';

  @override
  String get submitFeedback => '提交';

  @override
  String get feedbackHint => '请填写问题概述或描述';

  @override
  String get feedbackSuccess => '感谢您的反馈！';

  @override
  String get feedbackFailed => '反馈提交失败，请稍后重试';

  @override
  String get confirmExit => '确认退出';

  @override
  String get exitWithInstalling => '有正在进行的安装任务，确定要退出吗？';

  @override
  String get exitBtn => '退出';

  @override
  String get downloadManager => '下载管理';

  @override
  String get clearRecords => '清空记录';

  @override
  String get noDownloadTasks => '暂无下载任务';

  @override
  String cannotOpenLink(String url) {
    return '无法打开链接: $url';
  }

  @override
  String get envCheckPassed => '安装完成，环境检测通过';

  @override
  String get envCheckFailed => '安装完成，但环境仍异常，请检查';

  @override
  String launching(String appName) {
    return '正在启动 $appName...';
  }

  @override
  String launchFailed(String error) {
    return '启动失败: $error';
  }

  @override
  String copied(String value) {
    return '已复制：$value';
  }

  @override
  String get createDesktopShortcut => '创建桌面快捷方式';

  @override
  String get appNotFound => '未找到应用信息';

  @override
  String get noVersionHistory => '暂无版本历史';

  @override
  String get installedBadge => '已安装';

  @override
  String uninstallFailed(String result) {
    return '卸载失败: $result';
  }

  @override
  String uninstallSuccess(String name) {
    return '$name 已卸载';
  }

  @override
  String uninstallError(String error) {
    return '卸载异常: $error';
  }

  @override
  String get commandCopied => '命令已复制到剪贴板，请粘贴到终端中执行';
}
