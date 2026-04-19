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
  String get noInstalledAppsHint => '您还没有安装任何玲珑应用，去推荐页看看吧';

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
  String get communityExchange => '社区交流';

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
  String get shareLink => '分享';

  @override
  String shareMessage(String name) {
    return '来看看「$name」这个应用';
  }

  @override
  String get linkCopied => '链接已复制，快去分享吧';

  @override
  String get shareFailed => '分享失败';

  @override
  String get createDesktopShortcut => '创建桌面快捷方式';

  @override
  String get appDetailTitle => '应用详情';

  @override
  String get appNotFound => '未找到应用信息';

  @override
  String get noVersionHistory => '暂无版本历史';

  @override
  String get installedBadge => '已安装';

  @override
  String get versionInstallTargetMissing => '未找到对应已安装版本，请刷新后重试';

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

  @override
  String get copy => '复制';

  @override
  String get copyErrorMessage => '复制错误信息';

  @override
  String get skipCheck => '跳过检测';

  @override
  String get loadFailed => '加载失败';

  @override
  String get shortcutCreated => '快捷方式已创建';

  @override
  String get appComments => '评论区';

  @override
  String get appCommentsEmpty => '还没有评论，来写第一条吧';

  @override
  String get commentInputHint => '说说这个应用的使用体验';

  @override
  String get submitComment => '发表评论';

  @override
  String get commentVersionLabel => '关联版本';

  @override
  String get anonymousComment => '匿名访客';

  @override
  String get commentHelpful => '有帮助';

  @override
  String get commentNotHelpful => '没帮助';

  @override
  String get commentAnonymousHint => '匿名评论，按最新时间排序展示';

  @override
  String get commentSubmitSuccess => '评论已提交';

  @override
  String commentSubmitFailed(String error) {
    return '评论提交失败: $error';
  }

  @override
  String shortcutCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String get envCheckTitle => '环境检测';

  @override
  String get checkingLinglongEnv => '正在检测玲珑环境...';

  @override
  String get unknownStatus => '未知状态';

  @override
  String get llCliVersion => 'll-cli 版本';

  @override
  String get notDetected => '未检测到';

  @override
  String get errorMessage => '错误信息';

  @override
  String get installingLinglong => '正在安装...';

  @override
  String get appIntroduction => '应用介绍';

  @override
  String get collapse => '收起';

  @override
  String get expandAll => '展开全部';

  @override
  String get packageName => '包名';

  @override
  String get architecture => '架构';

  @override
  String get channelLabel => '渠道';

  @override
  String get runtime => '运行时';

  @override
  String get license => '许可证';

  @override
  String get homepage => '主页';

  @override
  String get appInfo => '应用信息';

  @override
  String get versionHistory => '版本历史';

  @override
  String get versionListLoadFailed => '版本列表加载失败，请重试';

  @override
  String get versionListUpdateFailed => '版本列表更新失败，显示最近一次结果';

  @override
  String get uninstallApp => '卸载应用';

  @override
  String uninstallConfirmMessage(String name) {
    return '确定要卸载 $name 吗？\n卸载后应用数据将被删除，此操作不可恢复。';
  }

  @override
  String get noDescription => '暂无描述';

  @override
  String get categoryLabel => '分类';

  @override
  String get searchNotFound => '未找到相关应用';

  @override
  String get searchTryOtherKeywords => '尝试使用其他关键词搜索';

  @override
  String get searchInputHint => '在顶部搜索框输入关键词';

  @override
  String get searchPressEnter => '按 Enter 开始搜索应用';

  @override
  String searchResultCount(int count) {
    return '找到 $count 个结果';
  }

  @override
  String get searchInstalledApps => '搜索已安装的应用';

  @override
  String get noMatchingApp => '未找到匹配的应用';

  @override
  String noMatchingAppHint(String query) {
    return '没有找到 \"$query\" 相关的应用';
  }

  @override
  String updateCount(int count) {
    return '共 $count 个应用可更新';
  }

  @override
  String get updating => '正在更新...';

  @override
  String get updateAll => '全部更新';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get noUpdate => '暂无更新';

  @override
  String get allAppsUpToDate => '您的所有应用都是最新版本';

  @override
  String get noMore => '没有更多了';

  @override
  String get appTitleShort => '玲珑应用商店';

  @override
  String get detectingEnv => '正在检测玲珑环境...';

  @override
  String get stepEnvCheck => '环境检测';

  @override
  String get stepAppLoad => '应用加载';

  @override
  String get stepUpdateCheck => '更新检查';

  @override
  String get stepQueueRecovery => '队列恢复';

  @override
  String get launchFailedTitle => '启动失败';

  @override
  String get skip => '跳过';

  @override
  String get cannotGetVersion => '无法获取版本信息';

  @override
  String newVersionAvailable(String version, String current) {
    return '发现新版本 $version！\n当前版本：$current';
  }

  @override
  String get languageZh => '中文';

  @override
  String get themeFollowSystem => '跟随系统';

  @override
  String get themeLight => '浅色模式';

  @override
  String get themeDark => '深色模式';

  @override
  String get clearingCache => '清除中...';

  @override
  String get clearCache => '清除缓存';

  @override
  String get clearCacheDesc => '清除缓存可以释放存储空间，但会重新下载应用图标和部分数据。';

  @override
  String get clearCacheConfirm => '确认清除缓存';

  @override
  String get clearCacheMessage => '确定要清除所有缓存吗？';

  @override
  String get cacheCleared => '缓存已清除';

  @override
  String get clearCacheFailed => '清除缓存失败';

  @override
  String get appVersion => '应用版本';

  @override
  String get appCount => '已收录应用数量';

  @override
  String get systemArch => '系统架构';

  @override
  String get linglongVersion => '玲珑版本';

  @override
  String get checkNetwork => '请检查网络连接后重试';

  @override
  String get copyContainerCommand => '复制进入容器命令';

  @override
  String get commandCopiedToClipboard => '命令已复制到剪贴板';

  @override
  String get copyAppId => '复制应用 ID';

  @override
  String stopSuccess(String name) {
    return '$name 已停止';
  }

  @override
  String get stopFailed => '停止失败';

  @override
  String get processRefreshFailed => '进程列表刷新失败...';

  @override
  String get noRunningApps => '当前没有运行中的玲珑应用';

  @override
  String get notRefreshed => '尚未刷新';

  @override
  String get lastRefresh => '上次刷新';

  @override
  String get refreshing => '刷新中';

  @override
  String get appName => '应用名称';

  @override
  String get versionNo => '版本号';

  @override
  String get source => '来源';

  @override
  String get containerId => '容器 ID';

  @override
  String get appRunningTitle => '应用正在运行';

  @override
  String get appRunningMessage => '该应用正在运行，需要先关闭才能卸载';

  @override
  String get downgradeConfirm => '确认降级';

  @override
  String get downgradeMessage => '目标版本低于当前版本，确定要降级吗？';

  @override
  String get alreadyInstalledVersion => '已安装此版本';

  @override
  String get waiting => '等待中';

  @override
  String get completed => '已完成';

  @override
  String get remove => '移除';

  @override
  String get feedbackCategories => '商店缺陷,应用更新,应用故障';

  @override
  String get feedbackCategory => '问题分类';

  @override
  String get overview => '概述';

  @override
  String get overviewHint => '请简要描述问题';

  @override
  String get detailDescription => '详细描述';

  @override
  String get none => '无';

  @override
  String get clearSearch => '清除搜索词';

  @override
  String get minimize => '最小化';

  @override
  String get restore => '还原';

  @override
  String get maximize => '最大化';

  @override
  String get close => '关闭';

  @override
  String get goRecommend => '去推荐页看看吧';

  @override
  String get processRefreshFailedHint => '进程列表刷新失败，当前显示的是上次成功获取的数据';

  @override
  String get moreActions => '更多操作';

  @override
  String appRunningUninstallMessage(String name) {
    return '$name 当前正在运行中，卸载前需要强制关闭所有运行实例。\n是否强制关闭并卸载？';
  }

  @override
  String get forceCloseAndUninstall => '强制关闭并卸载';

  @override
  String downgradeMessageWithVersion(
    String appName,
    String currentVersion,
    String targetVersion,
  ) {
    return '当前已安装 $appName v$currentVersion，您尝试安装较低的版本 v$targetVersion。\n降级安装可能导致功能异常，是否继续？';
  }

  @override
  String get confirmDowngrade => '确认降级';

  @override
  String reinstallMessage(String appName, String version) {
    return '$appName v$version 已安装。\n是否重新安装（将覆盖现有安装）？';
  }

  @override
  String get forceReinstall => '强制重装';

  @override
  String get installingLabel => '正在安装';

  @override
  String waitingCount(int count) {
    return '等待中 ($count)';
  }

  @override
  String get detailDescriptionHint => '请详细描述您遇到的问题';

  @override
  String get linglongCommunity => '玲珑社区';

  @override
  String get unknown => '未知';

  @override
  String get copyPid => '复制 PID';

  @override
  String get copyContainerId => '复制容器 ID';

  @override
  String get refreshProcessList => '刷新进程列表';

  @override
  String get stopProcess => '停止进程';

  @override
  String get checkUpdateNetworkError => '检查更新失败，请检查网络连接';

  @override
  String get pruneServiceTitle => '清理废弃基础服务';

  @override
  String get pruneServiceMessage =>
      '将执行 ll-cli prune 命令，移除所有已不再被任何应用依赖的基础运行服务。\n\n清理后可节省磁盘空间，但如进行中有其他操作可能需要重新下载。';

  @override
  String get pruneServiceSuccess => '废弃基础服务已清理';

  @override
  String get pruneServiceFailed => '清理失败，请稍后重试';

  @override
  String get clearCacheHint => '清除缓存可以释放存储空间，但可能会导致应用需要重新加载数据。';

  @override
  String get pruneBaseServiceMessage =>
      '将执行 ll-cli prune 命令，移除所有已不再被任何应用依赖的基础运行服务。\n\n清理后可节省磁盘空间，但如进行中有其他操作可能需要重新下载。';

  @override
  String get clean => '清理';

  @override
  String get baseServiceCleaned => '废弃基础服务已清理';

  @override
  String get cleanFailed => '清理失败，请稍后重试';

  @override
  String appCountValue(int count) {
    return '$count 个';
  }

  @override
  String get llCliVersionLabel => 'll-cli 版本';

  @override
  String get rankingTabDownload => '下载榜';

  @override
  String get rankingTabRising => '新秀榜';

  @override
  String get rankingTabUpdate => '更新榜';

  @override
  String get rankingTabHot => '热门榜';

  @override
  String get sidebarAllApps => '全 部';

  @override
  String get sidebarRanking => '排 行';

  @override
  String get installErrorGeneric => '安装失败: 通用错误';

  @override
  String get installErrorTimeout => '安装失败: 进度超时';

  @override
  String get installCancelled => '安装已取消';

  @override
  String get installErrorUnknown => '安装失败: 未知错误';

  @override
  String get installErrorAppNotFoundRemote => '安装失败: 远程仓库找不到应用';

  @override
  String get installErrorAppNotFoundLocal => '安装失败: 本地找不到应用';

  @override
  String get installFailed => '安装失败';

  @override
  String get installErrorAppNotInRemote => '安装失败: 远程无该应用';

  @override
  String get installErrorSameVersion => '安装失败: 已安装同版本';

  @override
  String get installErrorDowngrade => '安装失败: 需要降级安装';

  @override
  String get installErrorModuleVersionNotAllowed => '安装失败: 安装模块时不允许指定版本';

  @override
  String get installErrorModuleRequiresApp => '安装失败: 安装模块需先安装应用';

  @override
  String get installErrorModuleExists => '安装失败: 模块已存在';

  @override
  String get installErrorArchMismatch => '安装失败: 架构不匹配';

  @override
  String get installErrorModuleNotInRemote => '安装失败: 远程无该模块';

  @override
  String get installErrorMissingErofs => '安装失败: 缺少 erofs 解压命令';

  @override
  String get installErrorUnsupportedFormat => '安装失败: 不支持的文件格式';

  @override
  String get installErrorNetwork => '安装失败: 网络错误';

  @override
  String get installErrorInvalidRef => '安装失败: 无效引用';

  @override
  String get installErrorUnknownArch => '安装失败: 未知架构';

  @override
  String installErrorCode(int code) {
    return '安装失败: 错误码 $code';
  }

  @override
  String get installStatusStarting => '开始安装';

  @override
  String get installStatusInstallingApp => '正在安装应用';

  @override
  String get installStatusInstallingRuntime => '正在安装运行时';

  @override
  String get installStatusInstallingBase => '正在安装基础包';

  @override
  String get installStatusDownloadingMeta => '正在下载元数据';

  @override
  String get installStatusDownloadingFiles => '正在下载文件';

  @override
  String get installStatusPostProcessing => '安装后处理';

  @override
  String get installStatusCompleted => '安装完成';

  @override
  String get installStatusProcessing => '正在处理';

  @override
  String waitingForOperation(String operation) {
    return '等待$operation...';
  }

  @override
  String get operationInstall => '安装';

  @override
  String get operationUpdate => '更新';

  @override
  String operationPreparing(String operation, String appId) {
    return '准备$operation $appId...';
  }

  @override
  String operationCancelled(String operation) {
    return '$operation已取消';
  }

  @override
  String operationCompleted(String operation) {
    return '$operation完成';
  }

  @override
  String operationUnknown(String operation) {
    return '$operation状态未知';
  }

  @override
  String operationConfirmFailed(String operation) {
    return '无法确认$operation结果';
  }

  @override
  String operationTimeout(String operation) {
    return '$operation超时';
  }

  @override
  String operationFailed(String operation) {
    return '$operation失败';
  }

  @override
  String get taskCrashInterrupted => '应用崩溃，任务中断';

  @override
  String get taskCrashRetryHint => '应用在执行过程中崩溃，请重试';

  @override
  String uninstallFailedWithError(String error) {
    return '卸载失败: $error';
  }

  @override
  String uninstallException(String error) {
    return '卸载异常: $error';
  }

  @override
  String stopFailedWithError(String error) {
    return '终止失败: $error';
  }

  @override
  String stopException(String error) {
    return '终止异常: $error';
  }

  @override
  String shortcutCreatedWithPath(String path) {
    return '快捷方式已创建: $path';
  }

  @override
  String shortcutCreateFailedWithError(String error) {
    return '创建失败: $error';
  }

  @override
  String pruneFailedWithError(String error) {
    return '清理失败: $error';
  }

  @override
  String pruneException(String error) {
    return '清理异常: $error';
  }

  @override
  String get getVersionFailed => '获取版本失败';

  @override
  String get llCliNotInstalled => 'll-cli 未安装';

  @override
  String get appInfoUnavailable => '无法获取应用信息';

  @override
  String shortcutCreateException(String error) {
    return '创建快捷方式失败: $error';
  }

  @override
  String get waitingForInstall => '等待安装';

  @override
  String get cancelInstall => '取消安装';

  @override
  String get uninstallBlockedTitle => '暂时无法卸载';

  @override
  String uninstallBlockedMessage(String activeTaskName) {
    return '当前正在安装/更新「$activeTaskName」。玲珑暂不支持同时执行安装和卸载。请等待当前任务完成，或先取消当前任务后再卸载。';
  }

  @override
  String get iKnow => '我知道了';

  @override
  String get viewDownloadManager => '查看下载管理';

  @override
  String a11yInstallApp(Object appName) {
    return '安装 $appName';
  }

  @override
  String a11yUpdateApp(Object appName) {
    return '更新 $appName';
  }

  @override
  String a11yOpenApp(Object appName) {
    return '打开 $appName';
  }

  @override
  String a11yUninstallApp(Object appName) {
    return '卸载 $appName';
  }

  @override
  String get a11ySearchBox => '搜索应用';

  @override
  String get a11ySearchInputHint => '输入关键词搜索';

  @override
  String get a11yCommentInputHint => '输入评论内容';

  @override
  String get a11ySidebarNav => '侧边栏导航';

  @override
  String a11yAppCard(Object appName, Object version, Object status) {
    return '$appName，版本 $version，$status';
  }

  @override
  String a11yRankingItem(Object rank, Object appName) {
    return '排名第 $rank，$appName';
  }

  @override
  String a11yProcessItem(Object name, Object pid) {
    return '进程 $name，PID $pid';
  }

  @override
  String a11yDownloadItem(Object appName, Object percent) {
    return '下载 $appName，进度 $percent%';
  }

  @override
  String get a11yRecommendPage => '推荐';

  @override
  String get a11yAllAppsPage => '全部应用';

  @override
  String get a11yRankingPage => '排行榜';

  @override
  String get a11yMyAppsPage => '我的应用';

  @override
  String get a11ySettingsPage => '设置';

  @override
  String get a11yAppDetailPage => '应用详情';

  @override
  String get a11yScreenshotArea => '截图区域';

  @override
  String get a11yCommentSection => '评论区';

  @override
  String get a11yCarouselArea => '轮播区域';

  @override
  String get a11yAppListArea => '应用列表';

  @override
  String get a11ySidebarArea => '侧边栏';

  @override
  String get a11yMinimize => '最小化';

  @override
  String get a11yMaximize => '最大化';

  @override
  String get a11yRestore => '还原';

  @override
  String get a11yClose => '关闭';

  @override
  String get a11yPrevious => '上一个';

  @override
  String get a11yNext => '下一个';

  @override
  String get a11yTabSelected => '已选中';

  @override
  String get a11yTabNotSelected => '未选中';

  @override
  String get a11yStatusInstalled => '已安装';

  @override
  String get a11yStatusUpdatable => '可更新';

  @override
  String get a11yStatusNotInstalled => '未安装';

  @override
  String get noAppsInCategory => '该分类下暂无应用';

  @override
  String get noRanking => '暂无排行';

  @override
  String get noRecommend => '暂无推荐';

  @override
  String get installTimeout => '安装超时：长时间未收到进度更新';

  @override
  String get loadingInstalledApps => '正在加载已安装应用...';

  @override
  String get appDescriptionPlaceholder => '应用描述';

  @override
  String get rankingTabNewUpload => '最新上架榜';

  @override
  String get rankingTabDownloadCount => '下载量榜';

  @override
  String uploadedXHoursAgo(int count) {
    return '$count小时前上架';
  }

  @override
  String uploadedXDaysAgo(int count) {
    return '$count天前上架';
  }

  @override
  String uploadedOnDate(String date) {
    return '$date上架';
  }

  @override
  String downloadedXTimes(String count) {
    return '下载 $count次';
  }
}
