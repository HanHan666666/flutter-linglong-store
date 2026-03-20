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
  String get repoConfig => 'Repository Config';

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
  String get editRepo => 'Edit Repository';

  @override
  String repoSwitched(String repoName) {
    return 'Repository switched to: $repoName';
  }

  @override
  String get modifyBtn => 'Modify';

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
}
