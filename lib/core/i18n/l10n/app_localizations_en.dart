// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Linglong Store Community Edition';

  @override
  String get recommend => 'Recommend';

  @override
  String get allApps => 'All Apps';

  @override
  String get ranking => 'Ranking';

  @override
  String get myApps => 'My Apps';

  @override
  String get update => 'Update';

  @override
  String get settings => 'Settings';

  @override
  String get category => 'Category';

  @override
  String get office => 'Office';

  @override
  String get system => 'System';

  @override
  String get develop => 'Development';

  @override
  String get entertainment => 'Entertainment';

  @override
  String get searchPlaceholder => 'Search for apps here';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get linglongRecommend => 'Linglong Recommend';

  @override
  String get loading => 'Loading...';

  @override
  String get installing => 'Installing...';

  @override
  String get success => 'Success';

  @override
  String get failed => 'Failed';

  @override
  String get cancel => 'Cancel';

  @override
  String get noMoreData => 'No more data';

  @override
  String get install => 'Install';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get open => 'Open';

  @override
  String get update_action => 'Update';

  @override
  String get run => 'Run';

  @override
  String get confirm => 'Confirm';

  @override
  String get viewDetail => 'View Details';

  @override
  String get screenShots => 'Screenshots';

  @override
  String get versionSelect => 'Version Select';

  @override
  String get versionNumber => 'Version';

  @override
  String get appType => 'App Type';

  @override
  String get channel => 'Channel';

  @override
  String get mode => 'Mode';

  @override
  String get repoSource => 'Repo Source';

  @override
  String get fileSize => 'File Size';

  @override
  String get downloadCount => 'Downloads';

  @override
  String get operation => 'Operation';

  @override
  String get linglongProcess => 'Linglong Process';

  @override
  String get baseSetting => 'Settings';

  @override
  String get about => 'About';

  @override
  String get envMissing => 'Linglong environment missing';

  @override
  String get envMissingDetail =>
      'Linglong components are missing or outdated. Please install them first.';

  @override
  String get autoInstall => 'Auto Install';

  @override
  String get manualInstall => 'Manual Install';

  @override
  String get recheck => 'Recheck';

  @override
  String get exitStore => 'Exit';

  @override
  String get errorNetwork => 'Network Error';

  @override
  String get errorNetworkDetail =>
      'Please check your network connection and try again';

  @override
  String get errorInstallFailed => 'Installation failed';

  @override
  String get errorUninstallFailed => 'Uninstallation failed';

  @override
  String get errorUpdateFailed => 'Update failed';

  @override
  String get errorUnknown => 'Unknown error';

  @override
  String get retry => 'Retry';

  @override
  String get downloading => 'Downloading...';

  @override
  String get downloadComplete => 'Download complete';

  @override
  String get installComplete => 'Installation complete';

  @override
  String get uninstallComplete => 'Uninstallation complete';

  @override
  String get updateComplete => 'Update complete';

  @override
  String get noApps => 'No apps available';

  @override
  String get noInstalledApps => 'No installed apps';

  @override
  String get noInstalledAppsHint =>
      'You haven\'t installed any Linglong apps yet, check the recommendations';

  @override
  String get noUpdateApps => 'No updates available';

  @override
  String get version => 'Version';

  @override
  String get size => 'Size';

  @override
  String get description => 'Description';

  @override
  String get developer => 'Developer';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmDeleteMessage =>
      'Are you sure you want to delete this item? This action cannot be undone.';

  @override
  String get confirmUninstall => 'Confirm Uninstall';

  @override
  String get confirmUninstallMessage =>
      'Are you sure you want to uninstall this app?';

  @override
  String get noData => 'No Data';

  @override
  String get noDataDescription => 'There is no content here yet';

  @override
  String get searchApps => 'Search apps...';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get cacheManagement => 'Cache Management';

  @override
  String get storeOptions => 'Store Options';

  @override
  String get checkUpdate => 'Check for Updates';

  @override
  String currentVersion(String version) {
    return 'Current version: $version';
  }

  @override
  String newVersionFound(String tagName, String currentVersion) {
    return 'New version $tagName found, current version $currentVersion';
  }

  @override
  String alreadyLatest(String version) {
    return 'Already the latest version $version';
  }

  @override
  String get checkingUpdate => 'Checking for updates...';

  @override
  String get goDownload => 'Go to Download';

  @override
  String get cacheSize => 'Cache Size';

  @override
  String get startupCheckUpdate => 'Check for store updates at launch';

  @override
  String get startupCheckUpdateDesc =>
      'Check if a new version is available on each startup';

  @override
  String get autoUpdateInContainer => 'Auto-update store in container';

  @override
  String get autoUpdateInContainerDesc =>
      'Automatically update the store app when running in Linglong container';

  @override
  String get showBaseServices => 'Show base runtime services';

  @override
  String get showBaseServicesDesc =>
      'Show underlying base runtime services in the installed list';

  @override
  String get cleanDeprecatedServices => 'Clean up deprecated base services';

  @override
  String get cleanDeprecatedServicesDesc =>
      'Remove unused base runtime services to free up disk space';

  @override
  String get checkNewVersion => 'Check New Version';

  @override
  String get feedbackMenu => 'Feedback';

  @override
  String get officialWebsite => 'Official Website';

  @override
  String get feedbackTitle => 'Feedback';

  @override
  String get uploadLog => 'Also upload log file';

  @override
  String get noPrivacyInfo => 'Logs contain no personal privacy information';

  @override
  String get submitFeedback => 'Submit';

  @override
  String get feedbackHint => 'Please describe the issue';

  @override
  String get feedbackSuccess => 'Thank you for your feedback!';

  @override
  String get feedbackFailed =>
      'Feedback submission failed, please try again later';

  @override
  String get confirmExit => 'Confirm Exit';

  @override
  String get exitWithInstalling =>
      'There are ongoing installation tasks. Are you sure you want to exit?';

  @override
  String get exitBtn => 'Exit';

  @override
  String get downloadManager => 'Download Manager';

  @override
  String get clearRecords => 'Clear Records';

  @override
  String get noDownloadTasks => 'No download tasks';

  @override
  String cannotOpenLink(String url) {
    return 'Cannot open link: $url';
  }

  @override
  String get envCheckPassed =>
      'Installation complete, environment check passed';

  @override
  String get envCheckFailed =>
      'Installation complete, but environment is still abnormal, please check';

  @override
  String launching(String appName) {
    return 'Launching $appName...';
  }

  @override
  String launchFailed(String error) {
    return 'Launch failed: $error';
  }

  @override
  String copied(String value) {
    return 'Copied: $value';
  }

  @override
  String get createDesktopShortcut => 'Create Desktop Shortcut';

  @override
  String get appNotFound => 'App information not found';

  @override
  String get noVersionHistory => 'No version history';

  @override
  String get installedBadge => 'Installed';

  @override
  String uninstallFailed(String result) {
    return 'Uninstall failed: $result';
  }

  @override
  String uninstallSuccess(String name) {
    return '$name has been uninstalled';
  }

  @override
  String uninstallError(String error) {
    return 'Uninstall error: $error';
  }

  @override
  String get commandCopied =>
      'Command copied to clipboard, paste and run in terminal';

  @override
  String get skipCheck => 'Skip Check';

  @override
  String get loadFailed => 'Load Failed';

  @override
  String get shortcutCreated => 'Shortcut Created';

  @override
  String shortcutCreateFailed(String error) {
    return 'Creation Failed: $error';
  }

  @override
  String get envCheckTitle => 'Environment Check';

  @override
  String get checkingLinglongEnv => 'Checking Linglong environment...';

  @override
  String get unknownStatus => 'Unknown Status';

  @override
  String get llCliVersion => 'll-cli Version';

  @override
  String get notDetected => 'Not Detected';

  @override
  String get errorMessage => 'Error Message';

  @override
  String get installingLinglong => 'Installing...';

  @override
  String get appIntroduction => 'App Introduction';

  @override
  String get collapse => 'Collapse';

  @override
  String get expandAll => 'Expand All';

  @override
  String get packageName => 'Package Name';

  @override
  String get architecture => 'Architecture';

  @override
  String get channelLabel => 'Channel';

  @override
  String get runtime => 'Runtime';

  @override
  String get license => 'License';

  @override
  String get homepage => 'Homepage';

  @override
  String get appInfo => 'App Information';

  @override
  String get versionHistory => 'Version History';

  @override
  String get versionListLoadFailed =>
      'Version list failed to load, please retry';

  @override
  String get versionListUpdateFailed =>
      'Version list update failed, showing last results';

  @override
  String get uninstallApp => 'Uninstall App';

  @override
  String uninstallConfirmMessage(String name) {
    return 'Are you sure you want to uninstall $name?\nApp data will be deleted and cannot be recovered.';
  }

  @override
  String get noDescription => 'No description available';

  @override
  String get categoryLabel => 'Category';

  @override
  String get searchNotFound => 'No related apps found';

  @override
  String get searchTryOtherKeywords => 'Try other keywords';

  @override
  String get searchInputHint => 'Enter keywords in the search box above';

  @override
  String get searchPressEnter => 'Press Enter to search';

  @override
  String searchResultCount(int count) {
    return 'Found $count results';
  }

  @override
  String get searchInstalledApps => 'Search installed apps';

  @override
  String get noMatchingApp => 'No matching app found';

  @override
  String noMatchingAppHint(String query) {
    return 'No app found for \"$query\"';
  }

  @override
  String updateCount(int count) {
    return '$count apps available for update';
  }

  @override
  String get updating => 'Updating...';

  @override
  String get updateAll => 'Update All';

  @override
  String get updateCheckFailed => 'Update check failed';

  @override
  String get noUpdate => 'No updates';

  @override
  String get allAppsUpToDate => 'All your apps are up to date';

  @override
  String get noMore => 'No more';

  @override
  String get appTitleShort => 'Linglong Store';

  @override
  String get detectingEnv => 'Detecting Linglong environment...';

  @override
  String get stepEnvCheck => 'Environment Check';

  @override
  String get stepAppLoad => 'Loading Apps';

  @override
  String get stepUpdateCheck => 'Checking Updates';

  @override
  String get stepQueueRecovery => 'Recovering Queue';

  @override
  String get launchFailedTitle => 'Launch failed';

  @override
  String get skip => 'Skip';

  @override
  String get cannotGetVersion => 'Cannot get version info';

  @override
  String newVersionAvailable(String version, String current) {
    return 'New version $version available!\nCurrent: $current';
  }

  @override
  String get languageZh => 'Chinese';

  @override
  String get themeFollowSystem => 'Follow System';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get clearingCache => 'Clearing...';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get clearCacheDesc =>
      'Clearing cache can free up storage space, but will re-download app icons and some data.';

  @override
  String get clearCacheConfirm => 'Confirm Clear Cache';

  @override
  String get clearCacheMessage => 'Clear all cache?';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get clearCacheFailed => 'Failed to clear cache';

  @override
  String get appVersion => 'App Version';

  @override
  String get appCount => 'Total Apps';

  @override
  String get systemArch => 'System Architecture';

  @override
  String get linglongVersion => 'Linglong Version';

  @override
  String get checkNetwork => 'Please check network and retry';

  @override
  String get copyContainerCommand => 'Copy container command';

  @override
  String get commandCopiedToClipboard => 'Command copied to clipboard';

  @override
  String get copyAppId => 'Copy App ID';

  @override
  String stopSuccess(String name) {
    return '$name stopped';
  }

  @override
  String get stopFailed => 'Stop failed';

  @override
  String get processRefreshFailed => 'Process list refresh failed...';

  @override
  String get noRunningApps => 'No running apps';

  @override
  String get notRefreshed => 'Not refreshed';

  @override
  String get lastRefresh => 'Last refresh';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get appName => 'App Name';

  @override
  String get versionNo => 'Version';

  @override
  String get source => 'Source';

  @override
  String get containerId => 'Container ID';

  @override
  String get appRunningTitle => 'App is running';

  @override
  String get appRunningMessage => 'App is running, close it first';

  @override
  String get downgradeConfirm => 'Confirm Downgrade';

  @override
  String get downgradeMessage => 'Target version is lower, confirm downgrade?';

  @override
  String get alreadyInstalledVersion => 'This version is installed';

  @override
  String get waiting => 'Waiting';

  @override
  String get completed => 'Completed';

  @override
  String get remove => 'Remove';

  @override
  String get feedbackCategories => 'Store Bug,App Update,App Issue';

  @override
  String get feedbackCategory => 'Category';

  @override
  String get overview => 'Overview';

  @override
  String get overviewHint => 'Briefly describe the issue';

  @override
  String get detailDescription => 'Detailed Description';

  @override
  String get none => 'None';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get minimize => 'Minimize';

  @override
  String get restore => 'Restore';

  @override
  String get maximize => 'Maximize';

  @override
  String get close => 'Close';

  @override
  String get goRecommend => 'Check recommendations';

  @override
  String get processRefreshFailedHint =>
      'Process list refresh failed, showing last successful data';

  @override
  String get moreActions => 'More Actions';

  @override
  String appRunningUninstallMessage(String name) {
    return '$name is currently running. All instances must be closed before uninstalling.\nForce close and uninstall?';
  }

  @override
  String get forceCloseAndUninstall => 'Force Close & Uninstall';

  @override
  String downgradeMessageWithVersion(
    String appName,
    String currentVersion,
    String targetVersion,
  ) {
    return '$appName v$currentVersion is installed, you\'re trying to install lower version v$targetVersion.\nDowngrade may cause issues, continue?';
  }

  @override
  String get confirmDowngrade => 'Confirm Downgrade';

  @override
  String reinstallMessage(String appName, String version) {
    return '$appName v$version is already installed.\nReinstall (will overwrite existing installation)?';
  }

  @override
  String get forceReinstall => 'Force Reinstall';

  @override
  String get installingLabel => 'Installing';

  @override
  String waitingCount(int count) {
    return 'Waiting ($count)';
  }

  @override
  String get detailDescriptionHint => 'Describe the issue in detail';

  @override
  String get linglongCommunity => 'Linglong Community';

  @override
  String get unknown => 'Unknown';

  @override
  String get copyPid => 'Copy PID';

  @override
  String get copyContainerId => 'Copy Container ID';

  @override
  String get refreshProcessList => 'Refresh Process List';

  @override
  String get stopProcess => 'Stop Process';

  @override
  String get checkUpdateNetworkError =>
      'Update check failed, please check network connection';

  @override
  String get pruneServiceTitle => 'Clean Deprecated Base Services';

  @override
  String get pruneServiceMessage =>
      'Will execute ll-cli prune to remove all unused base runtime services.\n\nThis frees up disk space, but ongoing operations may need to re-download.';

  @override
  String get pruneServiceSuccess => 'Deprecated base services cleaned';

  @override
  String get pruneServiceFailed => 'Cleanup failed, please retry later';

  @override
  String get clearCacheHint =>
      'Clearing cache can free up storage space, but may require reloading app data.';

  @override
  String get pruneBaseServiceMessage =>
      'Will execute ll-cli prune to remove all unused base runtime services.\n\nThis frees up disk space, but ongoing operations may need to re-download.';

  @override
  String get clean => 'Clean';

  @override
  String get baseServiceCleaned => 'Deprecated base services cleaned';

  @override
  String get cleanFailed => 'Cleanup failed, please retry later';

  @override
  String appCountValue(int count) {
    return '$count apps';
  }

  @override
  String get llCliVersionLabel => 'll-cli Version';
}
