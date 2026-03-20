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

  /// No description provided for @createDesktopShortcut.
  ///
  /// In zh, this message translates to:
  /// **'创建桌面快捷方式'**
  String get createDesktopShortcut;

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
