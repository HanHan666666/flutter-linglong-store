import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'玲珑应用商店社区版'**
  String get appTitle;

  /// No description provided for @recommend.
  ///
  /// In zh, this message translates to:
  /// **'推 荐'**
  String get recommend;

  /// No description provided for @allApps.
  ///
  /// In zh, this message translates to:
  /// **'全部应用'**
  String get allApps;

  /// No description provided for @ranking.
  ///
  /// In zh, this message translates to:
  /// **'排行榜'**
  String get ranking;

  /// No description provided for @myApps.
  ///
  /// In zh, this message translates to:
  /// **'我的应用'**
  String get myApps;

  /// No description provided for @update.
  ///
  /// In zh, this message translates to:
  /// **'更 新'**
  String get update;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @category.
  ///
  /// In zh, this message translates to:
  /// **'分 类'**
  String get category;

  /// No description provided for @office.
  ///
  /// In zh, this message translates to:
  /// **'办 公'**
  String get office;

  /// No description provided for @system.
  ///
  /// In zh, this message translates to:
  /// **'系 统'**
  String get system;

  /// No description provided for @develop.
  ///
  /// In zh, this message translates to:
  /// **'开 发'**
  String get develop;

  /// No description provided for @entertainment.
  ///
  /// In zh, this message translates to:
  /// **'娱 乐'**
  String get entertainment;

  /// No description provided for @searchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'在这里搜索你想搜索的应用'**
  String get searchPlaceholder;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @linglongRecommend.
  ///
  /// In zh, this message translates to:
  /// **'玲珑推荐'**
  String get linglongRecommend;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loading;

  /// No description provided for @installing.
  ///
  /// In zh, this message translates to:
  /// **'安装中...'**
  String get installing;

  /// No description provided for @success.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get success;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @noMoreData.
  ///
  /// In zh, this message translates to:
  /// **'没有更多数据了'**
  String get noMoreData;

  /// No description provided for @install.
  ///
  /// In zh, this message translates to:
  /// **'安 装'**
  String get install;

  /// No description provided for @uninstall.
  ///
  /// In zh, this message translates to:
  /// **'卸 载'**
  String get uninstall;

  /// No description provided for @open.
  ///
  /// In zh, this message translates to:
  /// **'打 开'**
  String get open;

  /// No description provided for @update_action.
  ///
  /// In zh, this message translates to:
  /// **'更 新'**
  String get update_action;

  /// No description provided for @run.
  ///
  /// In zh, this message translates to:
  /// **'启 动'**
  String get run;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @viewDetail.
  ///
  /// In zh, this message translates to:
  /// **'查看详情'**
  String get viewDetail;

  /// No description provided for @screenShots.
  ///
  /// In zh, this message translates to:
  /// **'屏幕截图'**
  String get screenShots;

  /// No description provided for @versionSelect.
  ///
  /// In zh, this message translates to:
  /// **'版本选择'**
  String get versionSelect;

  /// No description provided for @versionNumber.
  ///
  /// In zh, this message translates to:
  /// **'版本号'**
  String get versionNumber;

  /// No description provided for @appType.
  ///
  /// In zh, this message translates to:
  /// **'应用类型'**
  String get appType;

  /// No description provided for @channel.
  ///
  /// In zh, this message translates to:
  /// **'通道'**
  String get channel;

  /// No description provided for @mode.
  ///
  /// In zh, this message translates to:
  /// **'模式'**
  String get mode;

  /// No description provided for @repoSource.
  ///
  /// In zh, this message translates to:
  /// **'仓库来源'**
  String get repoSource;

  /// No description provided for @fileSize.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get fileSize;

  /// No description provided for @downloadCount.
  ///
  /// In zh, this message translates to:
  /// **'下载量'**
  String get downloadCount;

  /// No description provided for @operation.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get operation;

  /// No description provided for @linglongProcess.
  ///
  /// In zh, this message translates to:
  /// **'玲珑进程'**
  String get linglongProcess;

  /// No description provided for @baseSetting.
  ///
  /// In zh, this message translates to:
  /// **'基本设置'**
  String get baseSetting;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @envMissing.
  ///
  /// In zh, this message translates to:
  /// **'检测到当前系统缺少玲珑环境'**
  String get envMissing;

  /// No description provided for @envMissingDetail.
  ///
  /// In zh, this message translates to:
  /// **'检测到系统中不存在或版本过低的玲珑组件，需先安装后才能使用商店。'**
  String get envMissingDetail;

  /// No description provided for @autoInstall.
  ///
  /// In zh, this message translates to:
  /// **'自动安装'**
  String get autoInstall;

  /// No description provided for @manualInstall.
  ///
  /// In zh, this message translates to:
  /// **'手动安装'**
  String get manualInstall;

  /// No description provided for @recheck.
  ///
  /// In zh, this message translates to:
  /// **'重新检测'**
  String get recheck;

  /// No description provided for @exitStore.
  ///
  /// In zh, this message translates to:
  /// **'退出商店'**
  String get exitStore;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败'**
  String get errorNetwork;

  /// No description provided for @errorNetworkDetail.
  ///
  /// In zh, this message translates to:
  /// **'请检查网络连接后重试'**
  String get errorNetworkDetail;

  /// No description provided for @errorInstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败'**
  String get errorInstallFailed;

  /// No description provided for @errorUninstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'卸载失败'**
  String get errorUninstallFailed;

  /// No description provided for @errorUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败'**
  String get errorUpdateFailed;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知错误'**
  String get errorUnknown;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @downloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中...'**
  String get downloading;

  /// No description provided for @downloadComplete.
  ///
  /// In zh, this message translates to:
  /// **'下载完成'**
  String get downloadComplete;

  /// No description provided for @installComplete.
  ///
  /// In zh, this message translates to:
  /// **'安装完成'**
  String get installComplete;

  /// No description provided for @uninstallComplete.
  ///
  /// In zh, this message translates to:
  /// **'卸载完成'**
  String get uninstallComplete;

  /// No description provided for @updateComplete.
  ///
  /// In zh, this message translates to:
  /// **'更新完成'**
  String get updateComplete;

  /// No description provided for @noApps.
  ///
  /// In zh, this message translates to:
  /// **'暂无应用'**
  String get noApps;

  /// No description provided for @noInstalledApps.
  ///
  /// In zh, this message translates to:
  /// **'暂无已安装应用'**
  String get noInstalledApps;

  /// No description provided for @noInstalledAppsHint.
  ///
  /// In zh, this message translates to:
  /// **'您还没有安装任何玲珑应用，去推荐页看看吧'**
  String get noInstalledAppsHint;

  /// No description provided for @noUpdateApps.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用更新'**
  String get noUpdateApps;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @size.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get size;

  /// No description provided for @description.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get description;

  /// No description provided for @developer.
  ///
  /// In zh, this message translates to:
  /// **'开发者'**
  String get developer;

  /// No description provided for @confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除此项吗？此操作无法撤销。'**
  String get confirmDeleteMessage;

  /// No description provided for @confirmUninstall.
  ///
  /// In zh, this message translates to:
  /// **'确认卸载'**
  String get confirmUninstall;

  /// No description provided for @confirmUninstallMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要卸载此应用吗？'**
  String get confirmUninstallMessage;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @noDataDescription.
  ///
  /// In zh, this message translates to:
  /// **'这里还没有任何内容'**
  String get noDataDescription;

  /// No description provided for @searchApps.
  ///
  /// In zh, this message translates to:
  /// **'搜索应用...'**
  String get searchApps;

  /// No description provided for @languageSettings.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get languageSettings;

  /// No description provided for @themeSettings.
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get themeSettings;

  /// No description provided for @cacheManagement.
  ///
  /// In zh, this message translates to:
  /// **'缓存管理'**
  String get cacheManagement;

  /// No description provided for @storeOptions.
  ///
  /// In zh, this message translates to:
  /// **'商店选项'**
  String get storeOptions;

  /// No description provided for @checkUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkUpdate;

  /// No description provided for @currentVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前版本: {version}'**
  String currentVersion(String version);

  /// No description provided for @newVersionFound.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {tagName}，当前版本 {currentVersion}'**
  String newVersionFound(String tagName, String currentVersion);

  /// No description provided for @alreadyLatest.
  ///
  /// In zh, this message translates to:
  /// **'当前已是最新版本 {version}'**
  String alreadyLatest(String version);

  /// No description provided for @checkingUpdate.
  ///
  /// In zh, this message translates to:
  /// **'检查更新中...'**
  String get checkingUpdate;

  /// No description provided for @goDownload.
  ///
  /// In zh, this message translates to:
  /// **'前往下载'**
  String get goDownload;

  /// No description provided for @cacheSize.
  ///
  /// In zh, this message translates to:
  /// **'缓存大小'**
  String get cacheSize;

  /// No description provided for @startupCheckUpdate.
  ///
  /// In zh, this message translates to:
  /// **'启动时检查商店版本更新'**
  String get startupCheckUpdate;

  /// No description provided for @startupCheckUpdateDesc.
  ///
  /// In zh, this message translates to:
  /// **'每次启动时检测是否有新版本可用'**
  String get startupCheckUpdateDesc;

  /// No description provided for @autoUpdateInContainer.
  ///
  /// In zh, this message translates to:
  /// **'容器内自动更新商店本体'**
  String get autoUpdateInContainer;

  /// No description provided for @autoUpdateInContainerDesc.
  ///
  /// In zh, this message translates to:
  /// **'在玲珑容器内运行时自动更新商店应用'**
  String get autoUpdateInContainerDesc;

  /// No description provided for @showBaseServices.
  ///
  /// In zh, this message translates to:
  /// **'显示基础运行服务'**
  String get showBaseServices;

  /// No description provided for @showBaseServicesDesc.
  ///
  /// In zh, this message translates to:
  /// **'在已安装列表中显示底层基础运行服务'**
  String get showBaseServicesDesc;

  /// No description provided for @cleanDeprecatedServices.
  ///
  /// In zh, this message translates to:
  /// **'清理废弃基础服务'**
  String get cleanDeprecatedServices;

  /// No description provided for @cleanDeprecatedServicesDesc.
  ///
  /// In zh, this message translates to:
  /// **'移除已不再使用的基础运行服务，释放磁盘空间'**
  String get cleanDeprecatedServicesDesc;

  /// No description provided for @checkNewVersion.
  ///
  /// In zh, this message translates to:
  /// **'检查新版本'**
  String get checkNewVersion;

  /// No description provided for @feedbackMenu.
  ///
  /// In zh, this message translates to:
  /// **'意见反馈'**
  String get feedbackMenu;

  /// No description provided for @officialWebsite.
  ///
  /// In zh, this message translates to:
  /// **'官网'**
  String get officialWebsite;

  /// No description provided for @feedbackTitle.
  ///
  /// In zh, this message translates to:
  /// **'意见反馈'**
  String get feedbackTitle;

  /// No description provided for @uploadLog.
  ///
  /// In zh, this message translates to:
  /// **'同时上传日志文件'**
  String get uploadLog;

  /// No description provided for @noPrivacyInfo.
  ///
  /// In zh, this message translates to:
  /// **'日志中不包含个人隐私信息'**
  String get noPrivacyInfo;

  /// No description provided for @submitFeedback.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get submitFeedback;

  /// No description provided for @feedbackHint.
  ///
  /// In zh, this message translates to:
  /// **'请填写问题概述或描述'**
  String get feedbackHint;

  /// No description provided for @feedbackSuccess.
  ///
  /// In zh, this message translates to:
  /// **'感谢您的反馈！'**
  String get feedbackSuccess;

  /// No description provided for @feedbackFailed.
  ///
  /// In zh, this message translates to:
  /// **'反馈提交失败，请稍后重试'**
  String get feedbackFailed;

  /// No description provided for @confirmExit.
  ///
  /// In zh, this message translates to:
  /// **'确认退出'**
  String get confirmExit;

  /// No description provided for @exitWithInstalling.
  ///
  /// In zh, this message translates to:
  /// **'有正在进行的安装任务，确定要退出吗？'**
  String get exitWithInstalling;

  /// No description provided for @exitBtn.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get exitBtn;

  /// No description provided for @downloadManager.
  ///
  /// In zh, this message translates to:
  /// **'下载管理'**
  String get downloadManager;

  /// No description provided for @clearRecords.
  ///
  /// In zh, this message translates to:
  /// **'清空记录'**
  String get clearRecords;

  /// No description provided for @noDownloadTasks.
  ///
  /// In zh, this message translates to:
  /// **'暂无下载任务'**
  String get noDownloadTasks;

  /// No description provided for @cannotOpenLink.
  ///
  /// In zh, this message translates to:
  /// **'无法打开链接: {url}'**
  String cannotOpenLink(String url);

  /// No description provided for @envCheckPassed.
  ///
  /// In zh, this message translates to:
  /// **'安装完成，环境检测通过'**
  String get envCheckPassed;

  /// No description provided for @envCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装完成，但环境仍异常，请检查'**
  String get envCheckFailed;

  /// No description provided for @launching.
  ///
  /// In zh, this message translates to:
  /// **'正在启动 {appName}...'**
  String launching(String appName);

  /// No description provided for @launchFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动失败: {error}'**
  String launchFailed(String error);

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制：{value}'**
  String copied(String value);

  /// No description provided for @shareLink.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get shareLink;

  /// No description provided for @shareMessage.
  ///
  /// In zh, this message translates to:
  /// **'来看看「{name}」这个应用'**
  String shareMessage(String name);

  /// No description provided for @linkCopied.
  ///
  /// In zh, this message translates to:
  /// **'链接已复制，快去分享吧'**
  String get linkCopied;

  /// No description provided for @shareFailed.
  ///
  /// In zh, this message translates to:
  /// **'分享失败'**
  String get shareFailed;

  /// No description provided for @createDesktopShortcut.
  ///
  /// In zh, this message translates to:
  /// **'创建桌面快捷方式'**
  String get createDesktopShortcut;

  /// No description provided for @appDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用详情'**
  String get appDetailTitle;

  /// No description provided for @appNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到应用信息'**
  String get appNotFound;

  /// No description provided for @noVersionHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无版本历史'**
  String get noVersionHistory;

  /// No description provided for @installedBadge.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get installedBadge;

  /// No description provided for @uninstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'卸载失败: {result}'**
  String uninstallFailed(String result);

  /// No description provided for @uninstallSuccess.
  ///
  /// In zh, this message translates to:
  /// **'{name} 已卸载'**
  String uninstallSuccess(String name);

  /// No description provided for @uninstallError.
  ///
  /// In zh, this message translates to:
  /// **'卸载异常: {error}'**
  String uninstallError(String error);

  /// No description provided for @commandCopied.
  ///
  /// In zh, this message translates to:
  /// **'命令已复制到剪贴板，请粘贴到终端中执行'**
  String get commandCopied;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copyErrorMessage.
  ///
  /// In zh, this message translates to:
  /// **'复制错误信息'**
  String get copyErrorMessage;

  /// No description provided for @skipCheck.
  ///
  /// In zh, this message translates to:
  /// **'跳过检测'**
  String get skipCheck;

  /// No description provided for @loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get loadFailed;

  /// No description provided for @shortcutCreated.
  ///
  /// In zh, this message translates to:
  /// **'快捷方式已创建'**
  String get shortcutCreated;

  /// No description provided for @appComments.
  ///
  /// In zh, this message translates to:
  /// **'评论区'**
  String get appComments;

  /// No description provided for @appCommentsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有评论，来写第一条吧'**
  String get appCommentsEmpty;

  /// No description provided for @commentInputHint.
  ///
  /// In zh, this message translates to:
  /// **'说说这个应用的使用体验'**
  String get commentInputHint;

  /// No description provided for @submitComment.
  ///
  /// In zh, this message translates to:
  /// **'发表评论'**
  String get submitComment;

  /// No description provided for @commentVersionLabel.
  ///
  /// In zh, this message translates to:
  /// **'关联版本'**
  String get commentVersionLabel;

  /// No description provided for @anonymousComment.
  ///
  /// In zh, this message translates to:
  /// **'匿名访客'**
  String get anonymousComment;

  /// No description provided for @commentHelpful.
  ///
  /// In zh, this message translates to:
  /// **'有帮助'**
  String get commentHelpful;

  /// No description provided for @commentNotHelpful.
  ///
  /// In zh, this message translates to:
  /// **'没帮助'**
  String get commentNotHelpful;

  /// No description provided for @commentAnonymousHint.
  ///
  /// In zh, this message translates to:
  /// **'匿名评论，按最新时间排序展示'**
  String get commentAnonymousHint;

  /// No description provided for @commentSubmitSuccess.
  ///
  /// In zh, this message translates to:
  /// **'评论已提交'**
  String get commentSubmitSuccess;

  /// No description provided for @commentSubmitFailed.
  ///
  /// In zh, this message translates to:
  /// **'评论提交失败: {error}'**
  String commentSubmitFailed(String error);

  /// No description provided for @shortcutCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String shortcutCreateFailed(String error);

  /// No description provided for @envCheckTitle.
  ///
  /// In zh, this message translates to:
  /// **'环境检测'**
  String get envCheckTitle;

  /// No description provided for @checkingLinglongEnv.
  ///
  /// In zh, this message translates to:
  /// **'正在检测玲珑环境...'**
  String get checkingLinglongEnv;

  /// No description provided for @unknownStatus.
  ///
  /// In zh, this message translates to:
  /// **'未知状态'**
  String get unknownStatus;

  /// No description provided for @llCliVersion.
  ///
  /// In zh, this message translates to:
  /// **'ll-cli 版本'**
  String get llCliVersion;

  /// No description provided for @notDetected.
  ///
  /// In zh, this message translates to:
  /// **'未检测到'**
  String get notDetected;

  /// No description provided for @errorMessage.
  ///
  /// In zh, this message translates to:
  /// **'错误信息'**
  String get errorMessage;

  /// No description provided for @installingLinglong.
  ///
  /// In zh, this message translates to:
  /// **'正在安装...'**
  String get installingLinglong;

  /// No description provided for @appIntroduction.
  ///
  /// In zh, this message translates to:
  /// **'应用介绍'**
  String get appIntroduction;

  /// No description provided for @collapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @expandAll.
  ///
  /// In zh, this message translates to:
  /// **'展开全部'**
  String get expandAll;

  /// No description provided for @packageName.
  ///
  /// In zh, this message translates to:
  /// **'包名'**
  String get packageName;

  /// No description provided for @architecture.
  ///
  /// In zh, this message translates to:
  /// **'架构'**
  String get architecture;

  /// No description provided for @channelLabel.
  ///
  /// In zh, this message translates to:
  /// **'渠道'**
  String get channelLabel;

  /// No description provided for @runtime.
  ///
  /// In zh, this message translates to:
  /// **'运行时'**
  String get runtime;

  /// No description provided for @license.
  ///
  /// In zh, this message translates to:
  /// **'许可证'**
  String get license;

  /// No description provided for @homepage.
  ///
  /// In zh, this message translates to:
  /// **'主页'**
  String get homepage;

  /// No description provided for @appInfo.
  ///
  /// In zh, this message translates to:
  /// **'应用信息'**
  String get appInfo;

  /// No description provided for @versionHistory.
  ///
  /// In zh, this message translates to:
  /// **'版本历史'**
  String get versionHistory;

  /// No description provided for @versionListLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'版本列表加载失败，请重试'**
  String get versionListLoadFailed;

  /// No description provided for @versionListUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'版本列表更新失败，显示最近一次结果'**
  String get versionListUpdateFailed;

  /// No description provided for @uninstallApp.
  ///
  /// In zh, this message translates to:
  /// **'卸载应用'**
  String get uninstallApp;

  /// No description provided for @uninstallConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要卸载 {name} 吗？\n卸载后应用数据将被删除，此操作不可恢复。'**
  String uninstallConfirmMessage(String name);

  /// No description provided for @noDescription.
  ///
  /// In zh, this message translates to:
  /// **'暂无描述'**
  String get noDescription;

  /// No description provided for @categoryLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类'**
  String get categoryLabel;

  /// No description provided for @searchNotFound.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关应用'**
  String get searchNotFound;

  /// No description provided for @searchTryOtherKeywords.
  ///
  /// In zh, this message translates to:
  /// **'尝试使用其他关键词搜索'**
  String get searchTryOtherKeywords;

  /// No description provided for @searchInputHint.
  ///
  /// In zh, this message translates to:
  /// **'在顶部搜索框输入关键词'**
  String get searchInputHint;

  /// No description provided for @searchPressEnter.
  ///
  /// In zh, this message translates to:
  /// **'按 Enter 开始搜索应用'**
  String get searchPressEnter;

  /// No description provided for @searchResultCount.
  ///
  /// In zh, this message translates to:
  /// **'找到 {count} 个结果'**
  String searchResultCount(int count);

  /// No description provided for @searchInstalledApps.
  ///
  /// In zh, this message translates to:
  /// **'搜索已安装的应用'**
  String get searchInstalledApps;

  /// No description provided for @noMatchingApp.
  ///
  /// In zh, this message translates to:
  /// **'未找到匹配的应用'**
  String get noMatchingApp;

  /// No description provided for @noMatchingAppHint.
  ///
  /// In zh, this message translates to:
  /// **'没有找到 \"{query}\" 相关的应用'**
  String noMatchingAppHint(String query);

  /// No description provided for @updateCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 个应用可更新'**
  String updateCount(int count);

  /// No description provided for @updating.
  ///
  /// In zh, this message translates to:
  /// **'正在更新...'**
  String get updating;

  /// No description provided for @updateAll.
  ///
  /// In zh, this message translates to:
  /// **'全部更新'**
  String get updateAll;

  /// No description provided for @updateCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败'**
  String get updateCheckFailed;

  /// No description provided for @noUpdate.
  ///
  /// In zh, this message translates to:
  /// **'暂无更新'**
  String get noUpdate;

  /// No description provided for @allAppsUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'您的所有应用都是最新版本'**
  String get allAppsUpToDate;

  /// No description provided for @noMore.
  ///
  /// In zh, this message translates to:
  /// **'没有更多了'**
  String get noMore;

  /// No description provided for @appTitleShort.
  ///
  /// In zh, this message translates to:
  /// **'玲珑应用商店'**
  String get appTitleShort;

  /// No description provided for @detectingEnv.
  ///
  /// In zh, this message translates to:
  /// **'正在检测玲珑环境...'**
  String get detectingEnv;

  /// No description provided for @stepEnvCheck.
  ///
  /// In zh, this message translates to:
  /// **'环境检测'**
  String get stepEnvCheck;

  /// No description provided for @stepAppLoad.
  ///
  /// In zh, this message translates to:
  /// **'应用加载'**
  String get stepAppLoad;

  /// No description provided for @stepUpdateCheck.
  ///
  /// In zh, this message translates to:
  /// **'更新检查'**
  String get stepUpdateCheck;

  /// No description provided for @stepQueueRecovery.
  ///
  /// In zh, this message translates to:
  /// **'队列恢复'**
  String get stepQueueRecovery;

  /// No description provided for @launchFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'启动失败'**
  String get launchFailedTitle;

  /// No description provided for @skip.
  ///
  /// In zh, this message translates to:
  /// **'跳过'**
  String get skip;

  /// No description provided for @cannotGetVersion.
  ///
  /// In zh, this message translates to:
  /// **'无法获取版本信息'**
  String get cannotGetVersion;

  /// No description provided for @newVersionAvailable.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本 {version}！\n当前版本：{current}'**
  String newVersionAvailable(String version, String current);

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get languageZh;

  /// No description provided for @themeFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeFollowSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get themeDark;

  /// No description provided for @clearingCache.
  ///
  /// In zh, this message translates to:
  /// **'清除中...'**
  String get clearingCache;

  /// No description provided for @clearCache.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存'**
  String get clearCache;

  /// No description provided for @clearCacheDesc.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存可以释放存储空间，但会重新下载应用图标和部分数据。'**
  String get clearCacheDesc;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认清除缓存'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要清除所有缓存吗？'**
  String get clearCacheMessage;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清除'**
  String get cacheCleared;

  /// No description provided for @clearCacheFailed.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存失败'**
  String get clearCacheFailed;

  /// No description provided for @appVersion.
  ///
  /// In zh, this message translates to:
  /// **'应用版本'**
  String get appVersion;

  /// No description provided for @appCount.
  ///
  /// In zh, this message translates to:
  /// **'已收录应用数量'**
  String get appCount;

  /// No description provided for @systemArch.
  ///
  /// In zh, this message translates to:
  /// **'系统架构'**
  String get systemArch;

  /// No description provided for @linglongVersion.
  ///
  /// In zh, this message translates to:
  /// **'玲珑版本'**
  String get linglongVersion;

  /// No description provided for @checkNetwork.
  ///
  /// In zh, this message translates to:
  /// **'请检查网络连接后重试'**
  String get checkNetwork;

  /// No description provided for @copyContainerCommand.
  ///
  /// In zh, this message translates to:
  /// **'复制进入容器命令'**
  String get copyContainerCommand;

  /// No description provided for @commandCopiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'命令已复制到剪贴板'**
  String get commandCopiedToClipboard;

  /// No description provided for @copyAppId.
  ///
  /// In zh, this message translates to:
  /// **'复制应用 ID'**
  String get copyAppId;

  /// No description provided for @stopSuccess.
  ///
  /// In zh, this message translates to:
  /// **'{name} 已停止'**
  String stopSuccess(String name);

  /// No description provided for @stopFailed.
  ///
  /// In zh, this message translates to:
  /// **'停止失败'**
  String get stopFailed;

  /// No description provided for @processRefreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'进程列表刷新失败...'**
  String get processRefreshFailed;

  /// No description provided for @noRunningApps.
  ///
  /// In zh, this message translates to:
  /// **'当前没有运行中的玲珑应用'**
  String get noRunningApps;

  /// No description provided for @notRefreshed.
  ///
  /// In zh, this message translates to:
  /// **'尚未刷新'**
  String get notRefreshed;

  /// No description provided for @lastRefresh.
  ///
  /// In zh, this message translates to:
  /// **'上次刷新'**
  String get lastRefresh;

  /// No description provided for @refreshing.
  ///
  /// In zh, this message translates to:
  /// **'刷新中'**
  String get refreshing;

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'应用名称'**
  String get appName;

  /// No description provided for @versionNo.
  ///
  /// In zh, this message translates to:
  /// **'版本号'**
  String get versionNo;

  /// No description provided for @source.
  ///
  /// In zh, this message translates to:
  /// **'来源'**
  String get source;

  /// No description provided for @containerId.
  ///
  /// In zh, this message translates to:
  /// **'容器 ID'**
  String get containerId;

  /// No description provided for @appRunningTitle.
  ///
  /// In zh, this message translates to:
  /// **'应用正在运行'**
  String get appRunningTitle;

  /// No description provided for @appRunningMessage.
  ///
  /// In zh, this message translates to:
  /// **'该应用正在运行，需要先关闭才能卸载'**
  String get appRunningMessage;

  /// No description provided for @downgradeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认降级'**
  String get downgradeConfirm;

  /// No description provided for @downgradeMessage.
  ///
  /// In zh, this message translates to:
  /// **'目标版本低于当前版本，确定要降级吗？'**
  String get downgradeMessage;

  /// No description provided for @alreadyInstalledVersion.
  ///
  /// In zh, this message translates to:
  /// **'已安装此版本'**
  String get alreadyInstalledVersion;

  /// No description provided for @waiting.
  ///
  /// In zh, this message translates to:
  /// **'等待中'**
  String get waiting;

  /// No description provided for @completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get completed;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @feedbackCategories.
  ///
  /// In zh, this message translates to:
  /// **'商店缺陷,应用更新,应用故障'**
  String get feedbackCategories;

  /// No description provided for @feedbackCategory.
  ///
  /// In zh, this message translates to:
  /// **'问题分类'**
  String get feedbackCategory;

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'概述'**
  String get overview;

  /// No description provided for @overviewHint.
  ///
  /// In zh, this message translates to:
  /// **'请简要描述问题'**
  String get overviewHint;

  /// No description provided for @detailDescription.
  ///
  /// In zh, this message translates to:
  /// **'详细描述'**
  String get detailDescription;

  /// No description provided for @none.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get none;

  /// No description provided for @clearSearch.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索词'**
  String get clearSearch;

  /// No description provided for @minimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get minimize;

  /// No description provided for @restore.
  ///
  /// In zh, this message translates to:
  /// **'还原'**
  String get restore;

  /// No description provided for @maximize.
  ///
  /// In zh, this message translates to:
  /// **'最大化'**
  String get maximize;

  /// No description provided for @close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @goRecommend.
  ///
  /// In zh, this message translates to:
  /// **'去推荐页看看吧'**
  String get goRecommend;

  /// No description provided for @processRefreshFailedHint.
  ///
  /// In zh, this message translates to:
  /// **'进程列表刷新失败，当前显示的是上次成功获取的数据'**
  String get processRefreshFailedHint;

  /// No description provided for @moreActions.
  ///
  /// In zh, this message translates to:
  /// **'更多操作'**
  String get moreActions;

  /// No description provided for @appRunningUninstallMessage.
  ///
  /// In zh, this message translates to:
  /// **'{name} 当前正在运行中，卸载前需要强制关闭所有运行实例。\n是否强制关闭并卸载？'**
  String appRunningUninstallMessage(String name);

  /// No description provided for @forceCloseAndUninstall.
  ///
  /// In zh, this message translates to:
  /// **'强制关闭并卸载'**
  String get forceCloseAndUninstall;

  /// No description provided for @downgradeMessageWithVersion.
  ///
  /// In zh, this message translates to:
  /// **'当前已安装 {appName} v{currentVersion}，您尝试安装较低的版本 v{targetVersion}。\n降级安装可能导致功能异常，是否继续？'**
  String downgradeMessageWithVersion(
    String appName,
    String currentVersion,
    String targetVersion,
  );

  /// No description provided for @confirmDowngrade.
  ///
  /// In zh, this message translates to:
  /// **'确认降级'**
  String get confirmDowngrade;

  /// No description provided for @reinstallMessage.
  ///
  /// In zh, this message translates to:
  /// **'{appName} v{version} 已安装。\n是否重新安装（将覆盖现有安装）？'**
  String reinstallMessage(String appName, String version);

  /// No description provided for @forceReinstall.
  ///
  /// In zh, this message translates to:
  /// **'强制重装'**
  String get forceReinstall;

  /// No description provided for @installingLabel.
  ///
  /// In zh, this message translates to:
  /// **'正在安装'**
  String get installingLabel;

  /// No description provided for @waitingCount.
  ///
  /// In zh, this message translates to:
  /// **'等待中 ({count})'**
  String waitingCount(int count);

  /// No description provided for @detailDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'请详细描述您遇到的问题'**
  String get detailDescriptionHint;

  /// No description provided for @linglongCommunity.
  ///
  /// In zh, this message translates to:
  /// **'玲珑社区'**
  String get linglongCommunity;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @copyPid.
  ///
  /// In zh, this message translates to:
  /// **'复制 PID'**
  String get copyPid;

  /// No description provided for @copyContainerId.
  ///
  /// In zh, this message translates to:
  /// **'复制容器 ID'**
  String get copyContainerId;

  /// No description provided for @refreshProcessList.
  ///
  /// In zh, this message translates to:
  /// **'刷新进程列表'**
  String get refreshProcessList;

  /// No description provided for @stopProcess.
  ///
  /// In zh, this message translates to:
  /// **'停止进程'**
  String get stopProcess;

  /// No description provided for @checkUpdateNetworkError.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请检查网络连接'**
  String get checkUpdateNetworkError;

  /// No description provided for @pruneServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'清理废弃基础服务'**
  String get pruneServiceTitle;

  /// No description provided for @pruneServiceMessage.
  ///
  /// In zh, this message translates to:
  /// **'将执行 ll-cli prune 命令，移除所有已不再被任何应用依赖的基础运行服务。\n\n清理后可节省磁盘空间，但如进行中有其他操作可能需要重新下载。'**
  String get pruneServiceMessage;

  /// No description provided for @pruneServiceSuccess.
  ///
  /// In zh, this message translates to:
  /// **'废弃基础服务已清理'**
  String get pruneServiceSuccess;

  /// No description provided for @pruneServiceFailed.
  ///
  /// In zh, this message translates to:
  /// **'清理失败，请稍后重试'**
  String get pruneServiceFailed;

  /// No description provided for @clearCacheHint.
  ///
  /// In zh, this message translates to:
  /// **'清除缓存可以释放存储空间，但可能会导致应用需要重新加载数据。'**
  String get clearCacheHint;

  /// No description provided for @pruneBaseServiceMessage.
  ///
  /// In zh, this message translates to:
  /// **'将执行 ll-cli prune 命令，移除所有已不再被任何应用依赖的基础运行服务。\n\n清理后可节省磁盘空间，但如进行中有其他操作可能需要重新下载。'**
  String get pruneBaseServiceMessage;

  /// No description provided for @clean.
  ///
  /// In zh, this message translates to:
  /// **'清理'**
  String get clean;

  /// No description provided for @baseServiceCleaned.
  ///
  /// In zh, this message translates to:
  /// **'废弃基础服务已清理'**
  String get baseServiceCleaned;

  /// No description provided for @cleanFailed.
  ///
  /// In zh, this message translates to:
  /// **'清理失败，请稍后重试'**
  String get cleanFailed;

  /// No description provided for @appCountValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个'**
  String appCountValue(int count);

  /// No description provided for @llCliVersionLabel.
  ///
  /// In zh, this message translates to:
  /// **'ll-cli 版本'**
  String get llCliVersionLabel;

  /// No description provided for @rankingTabDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载榜'**
  String get rankingTabDownload;

  /// No description provided for @rankingTabRising.
  ///
  /// In zh, this message translates to:
  /// **'新秀榜'**
  String get rankingTabRising;

  /// No description provided for @rankingTabUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新榜'**
  String get rankingTabUpdate;

  /// No description provided for @rankingTabHot.
  ///
  /// In zh, this message translates to:
  /// **'热门榜'**
  String get rankingTabHot;

  /// No description provided for @sidebarAllApps.
  ///
  /// In zh, this message translates to:
  /// **'全 部'**
  String get sidebarAllApps;

  /// No description provided for @sidebarRanking.
  ///
  /// In zh, this message translates to:
  /// **'排 行'**
  String get sidebarRanking;

  /// No description provided for @installErrorGeneric.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 通用错误'**
  String get installErrorGeneric;

  /// No description provided for @installErrorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 进度超时'**
  String get installErrorTimeout;

  /// No description provided for @installCancelled.
  ///
  /// In zh, this message translates to:
  /// **'安装已取消'**
  String get installCancelled;

  /// No description provided for @installErrorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 未知错误'**
  String get installErrorUnknown;

  /// No description provided for @installErrorAppNotFoundRemote.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 远程仓库找不到应用'**
  String get installErrorAppNotFoundRemote;

  /// No description provided for @installErrorAppNotFoundLocal.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 本地找不到应用'**
  String get installErrorAppNotFoundLocal;

  /// No description provided for @installFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败'**
  String get installFailed;

  /// No description provided for @installErrorAppNotInRemote.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 远程无该应用'**
  String get installErrorAppNotInRemote;

  /// No description provided for @installErrorSameVersion.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 已安装同版本'**
  String get installErrorSameVersion;

  /// No description provided for @installErrorDowngrade.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 需要降级安装'**
  String get installErrorDowngrade;

  /// No description provided for @installErrorModuleVersionNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 安装模块时不允许指定版本'**
  String get installErrorModuleVersionNotAllowed;

  /// No description provided for @installErrorModuleRequiresApp.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 安装模块需先安装应用'**
  String get installErrorModuleRequiresApp;

  /// No description provided for @installErrorModuleExists.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 模块已存在'**
  String get installErrorModuleExists;

  /// No description provided for @installErrorArchMismatch.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 架构不匹配'**
  String get installErrorArchMismatch;

  /// No description provided for @installErrorModuleNotInRemote.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 远程无该模块'**
  String get installErrorModuleNotInRemote;

  /// No description provided for @installErrorMissingErofs.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 缺少 erofs 解压命令'**
  String get installErrorMissingErofs;

  /// No description provided for @installErrorUnsupportedFormat.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 不支持的文件格式'**
  String get installErrorUnsupportedFormat;

  /// No description provided for @installErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 网络错误'**
  String get installErrorNetwork;

  /// No description provided for @installErrorInvalidRef.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 无效引用'**
  String get installErrorInvalidRef;

  /// No description provided for @installErrorUnknownArch.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 未知架构'**
  String get installErrorUnknownArch;

  /// No description provided for @installErrorCode.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: 错误码 {code}'**
  String installErrorCode(int code);

  /// No description provided for @installStatusStarting.
  ///
  /// In zh, this message translates to:
  /// **'开始安装'**
  String get installStatusStarting;

  /// No description provided for @installStatusInstallingApp.
  ///
  /// In zh, this message translates to:
  /// **'正在安装应用'**
  String get installStatusInstallingApp;

  /// No description provided for @installStatusInstallingRuntime.
  ///
  /// In zh, this message translates to:
  /// **'正在安装运行时'**
  String get installStatusInstallingRuntime;

  /// No description provided for @installStatusInstallingBase.
  ///
  /// In zh, this message translates to:
  /// **'正在安装基础包'**
  String get installStatusInstallingBase;

  /// No description provided for @installStatusDownloadingMeta.
  ///
  /// In zh, this message translates to:
  /// **'正在下载元数据'**
  String get installStatusDownloadingMeta;

  /// No description provided for @installStatusDownloadingFiles.
  ///
  /// In zh, this message translates to:
  /// **'正在下载文件'**
  String get installStatusDownloadingFiles;

  /// No description provided for @installStatusPostProcessing.
  ///
  /// In zh, this message translates to:
  /// **'安装后处理'**
  String get installStatusPostProcessing;

  /// No description provided for @installStatusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'安装完成'**
  String get installStatusCompleted;

  /// No description provided for @installStatusProcessing.
  ///
  /// In zh, this message translates to:
  /// **'正在处理'**
  String get installStatusProcessing;

  /// No description provided for @waitingForOperation.
  ///
  /// In zh, this message translates to:
  /// **'等待{operation}...'**
  String waitingForOperation(String operation);

  /// No description provided for @operationInstall.
  ///
  /// In zh, this message translates to:
  /// **'安装'**
  String get operationInstall;

  /// No description provided for @operationUpdate.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get operationUpdate;

  /// No description provided for @operationPreparing.
  ///
  /// In zh, this message translates to:
  /// **'准备{operation} {appId}...'**
  String operationPreparing(String operation, String appId);

  /// No description provided for @operationCancelled.
  ///
  /// In zh, this message translates to:
  /// **'{operation}已取消'**
  String operationCancelled(String operation);

  /// No description provided for @operationCompleted.
  ///
  /// In zh, this message translates to:
  /// **'{operation}完成'**
  String operationCompleted(String operation);

  /// No description provided for @operationUnknown.
  ///
  /// In zh, this message translates to:
  /// **'{operation}状态未知'**
  String operationUnknown(String operation);

  /// No description provided for @operationConfirmFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法确认{operation}结果'**
  String operationConfirmFailed(String operation);

  /// No description provided for @operationTimeout.
  ///
  /// In zh, this message translates to:
  /// **'{operation}超时'**
  String operationTimeout(String operation);

  /// No description provided for @operationFailed.
  ///
  /// In zh, this message translates to:
  /// **'{operation}失败'**
  String operationFailed(String operation);

  /// No description provided for @taskCrashInterrupted.
  ///
  /// In zh, this message translates to:
  /// **'应用崩溃，任务中断'**
  String get taskCrashInterrupted;

  /// No description provided for @taskCrashRetryHint.
  ///
  /// In zh, this message translates to:
  /// **'应用在执行过程中崩溃，请重试'**
  String get taskCrashRetryHint;

  /// No description provided for @uninstallFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'卸载失败: {error}'**
  String uninstallFailedWithError(String error);

  /// No description provided for @uninstallException.
  ///
  /// In zh, this message translates to:
  /// **'卸载异常: {error}'**
  String uninstallException(String error);

  /// No description provided for @stopFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'终止失败: {error}'**
  String stopFailedWithError(String error);

  /// No description provided for @stopException.
  ///
  /// In zh, this message translates to:
  /// **'终止异常: {error}'**
  String stopException(String error);

  /// No description provided for @shortcutCreatedWithPath.
  ///
  /// In zh, this message translates to:
  /// **'快捷方式已创建: {path}'**
  String shortcutCreatedWithPath(String path);

  /// No description provided for @shortcutCreateFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String shortcutCreateFailedWithError(String error);

  /// No description provided for @pruneFailedWithError.
  ///
  /// In zh, this message translates to:
  /// **'清理失败: {error}'**
  String pruneFailedWithError(String error);

  /// No description provided for @pruneException.
  ///
  /// In zh, this message translates to:
  /// **'清理异常: {error}'**
  String pruneException(String error);

  /// No description provided for @getVersionFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取版本失败'**
  String get getVersionFailed;

  /// No description provided for @llCliNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'ll-cli 未安装'**
  String get llCliNotInstalled;

  /// No description provided for @appInfoUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法获取应用信息'**
  String get appInfoUnavailable;

  /// No description provided for @shortcutCreateException.
  ///
  /// In zh, this message translates to:
  /// **'创建快捷方式失败: {error}'**
  String shortcutCreateException(String error);

  /// No description provided for @waitingForInstall.
  ///
  /// In zh, this message translates to:
  /// **'等待安装'**
  String get waitingForInstall;

  /// No description provided for @cancelInstall.
  ///
  /// In zh, this message translates to:
  /// **'取消安装'**
  String get cancelInstall;

  /// No description provided for @uninstallBlockedTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法卸载'**
  String get uninstallBlockedTitle;

  /// No description provided for @uninstallBlockedMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前正在安装/更新「{activeTaskName}」。玲珑暂不支持同时执行安装和卸载。请等待当前任务完成，或先取消当前任务后再卸载。'**
  String uninstallBlockedMessage(String activeTaskName);

  /// No description provided for @iKnow.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get iKnow;

  /// No description provided for @viewDownloadManager.
  ///
  /// In zh, this message translates to:
  /// **'查看下载管理'**
  String get viewDownloadManager;

  /// No description provided for @a11yInstallApp.
  ///
  /// In zh, this message translates to:
  /// **'安装 {appName}'**
  String a11yInstallApp(Object appName);

  /// No description provided for @a11yUpdateApp.
  ///
  /// In zh, this message translates to:
  /// **'更新 {appName}'**
  String a11yUpdateApp(Object appName);

  /// No description provided for @a11yOpenApp.
  ///
  /// In zh, this message translates to:
  /// **'打开 {appName}'**
  String a11yOpenApp(Object appName);

  /// No description provided for @a11yUninstallApp.
  ///
  /// In zh, this message translates to:
  /// **'卸载 {appName}'**
  String a11yUninstallApp(Object appName);

  /// No description provided for @a11ySearchBox.
  ///
  /// In zh, this message translates to:
  /// **'搜索应用'**
  String get a11ySearchBox;

  /// No description provided for @a11ySearchInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词搜索'**
  String get a11ySearchInputHint;

  /// No description provided for @a11yCommentInputHint.
  ///
  /// In zh, this message translates to:
  /// **'输入评论内容'**
  String get a11yCommentInputHint;

  /// No description provided for @a11ySidebarNav.
  ///
  /// In zh, this message translates to:
  /// **'侧边栏导航'**
  String get a11ySidebarNav;

  /// No description provided for @a11yAppCard.
  ///
  /// In zh, this message translates to:
  /// **'{appName}，版本 {version}，{status}'**
  String a11yAppCard(Object appName, Object version, Object status);

  /// No description provided for @a11yRankingItem.
  ///
  /// In zh, this message translates to:
  /// **'排名第 {rank}，{appName}'**
  String a11yRankingItem(Object rank, Object appName);

  /// No description provided for @a11yProcessItem.
  ///
  /// In zh, this message translates to:
  /// **'进程 {name}，PID {pid}'**
  String a11yProcessItem(Object name, Object pid);

  /// No description provided for @a11yDownloadItem.
  ///
  /// In zh, this message translates to:
  /// **'下载 {appName}，进度 {percent}%'**
  String a11yDownloadItem(Object appName, Object percent);

  /// No description provided for @a11yRecommendPage.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get a11yRecommendPage;

  /// No description provided for @a11yAllAppsPage.
  ///
  /// In zh, this message translates to:
  /// **'全部应用'**
  String get a11yAllAppsPage;

  /// No description provided for @a11yRankingPage.
  ///
  /// In zh, this message translates to:
  /// **'排行榜'**
  String get a11yRankingPage;

  /// No description provided for @a11yMyAppsPage.
  ///
  /// In zh, this message translates to:
  /// **'我的应用'**
  String get a11yMyAppsPage;

  /// No description provided for @a11ySettingsPage.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get a11ySettingsPage;

  /// No description provided for @a11yAppDetailPage.
  ///
  /// In zh, this message translates to:
  /// **'应用详情'**
  String get a11yAppDetailPage;

  /// No description provided for @a11yScreenshotArea.
  ///
  /// In zh, this message translates to:
  /// **'截图区域'**
  String get a11yScreenshotArea;

  /// No description provided for @a11yCommentSection.
  ///
  /// In zh, this message translates to:
  /// **'评论区'**
  String get a11yCommentSection;

  /// No description provided for @a11yCarouselArea.
  ///
  /// In zh, this message translates to:
  /// **'轮播区域'**
  String get a11yCarouselArea;

  /// No description provided for @a11yAppListArea.
  ///
  /// In zh, this message translates to:
  /// **'应用列表'**
  String get a11yAppListArea;

  /// No description provided for @a11ySidebarArea.
  ///
  /// In zh, this message translates to:
  /// **'侧边栏'**
  String get a11ySidebarArea;

  /// No description provided for @a11yMinimize.
  ///
  /// In zh, this message translates to:
  /// **'最小化'**
  String get a11yMinimize;

  /// No description provided for @a11yMaximize.
  ///
  /// In zh, this message translates to:
  /// **'最大化'**
  String get a11yMaximize;

  /// No description provided for @a11yRestore.
  ///
  /// In zh, this message translates to:
  /// **'还原'**
  String get a11yRestore;

  /// No description provided for @a11yClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get a11yClose;

  /// No description provided for @a11yPrevious.
  ///
  /// In zh, this message translates to:
  /// **'上一个'**
  String get a11yPrevious;

  /// No description provided for @a11yNext.
  ///
  /// In zh, this message translates to:
  /// **'下一个'**
  String get a11yNext;

  /// No description provided for @a11yTabSelected.
  ///
  /// In zh, this message translates to:
  /// **'已选中'**
  String get a11yTabSelected;

  /// No description provided for @a11yTabNotSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选中'**
  String get a11yTabNotSelected;

  /// No description provided for @a11yStatusInstalled.
  ///
  /// In zh, this message translates to:
  /// **'已安装'**
  String get a11yStatusInstalled;

  /// No description provided for @a11yStatusUpdatable.
  ///
  /// In zh, this message translates to:
  /// **'可更新'**
  String get a11yStatusUpdatable;

  /// No description provided for @a11yStatusNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get a11yStatusNotInstalled;

  /// No description provided for @noAppsInCategory.
  ///
  /// In zh, this message translates to:
  /// **'该分类下暂无应用'**
  String get noAppsInCategory;

  /// No description provided for @noRanking.
  ///
  /// In zh, this message translates to:
  /// **'暂无排行'**
  String get noRanking;

  /// No description provided for @noRecommend.
  ///
  /// In zh, this message translates to:
  /// **'暂无推荐'**
  String get noRecommend;

  /// No description provided for @installTimeout.
  ///
  /// In zh, this message translates to:
  /// **'安装超时：长时间未收到进度更新'**
  String get installTimeout;

  /// No description provided for @loadingInstalledApps.
  ///
  /// In zh, this message translates to:
  /// **'正在加载已安装应用...'**
  String get loadingInstalledApps;

  /// No description provided for @appDescriptionPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'应用描述'**
  String get appDescriptionPlaceholder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
