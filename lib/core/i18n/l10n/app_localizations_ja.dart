// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Linyaps ストアコミュニティ版';

  @override
  String get linuxDesktopNameNightly => 'Linyaps ストアコミュニティ版 Nightly';

  @override
  String get linuxDesktopGenericName => 'アプリストア';

  @override
  String get linuxDesktopComment => 'Linyaps アプリの閲覧・インストール・管理';

  @override
  String get linuxDesktopCommentNightly =>
      'Linyaps アプリの閲覧・インストール・管理を行う Nightly ビルド';

  @override
  String get linuxDesktopKeywords => 'linyaps;ストア;アプリ;パッケージ;';

  @override
  String get linuxAppStreamDescription =>
      'Linyaps アプリを閲覧・インストール・管理するためのデスクトップアプリストア。';

  @override
  String get recommend => 'おすすめ';

  @override
  String get allApps => 'すべてのアプリ';

  @override
  String get ranking => 'ランキング';

  @override
  String get myApps => 'マイアプリ';

  @override
  String get update => '更新';

  @override
  String get settings => '設定';

  @override
  String get category => 'カテゴリ';

  @override
  String get office => 'オフィス';

  @override
  String get system => 'システム';

  @override
  String get develop => '開発';

  @override
  String get entertainment => 'エンターテイメント';

  @override
  String get searchPlaceholder => 'ここにアプリ名を入力して検索';

  @override
  String get search => '検索';

  @override
  String get refresh => '更新';

  @override
  String get linglongRecommend => 'Linyaps おすすめ';

  @override
  String get loading => '読み込み中...';

  @override
  String get installing => 'インストール中...';

  @override
  String get success => '成功';

  @override
  String get failed => '失敗';

  @override
  String get cancel => 'キャンセル';

  @override
  String get noMoreData => 'これ以上のデータはありません';

  @override
  String get install => 'インストール';

  @override
  String get uninstall => 'アンインストール';

  @override
  String get open => '開く';

  @override
  String get update_action => '更新';

  @override
  String get run => '起動';

  @override
  String get confirm => '確認';

  @override
  String get viewDetail => '詳細を見る';

  @override
  String get screenShots => 'スクリーンショット';

  @override
  String get versionSelect => 'バージョン選択';

  @override
  String get versionNumber => 'バージョン番号';

  @override
  String get appType => 'アプリ種別';

  @override
  String get channel => 'チャンネル';

  @override
  String get mode => 'モード';

  @override
  String get repoSource => 'リポジトリソース';

  @override
  String get fileSize => 'ファイルサイズ';

  @override
  String get downloadCount => 'ダウンロード数';

  @override
  String get operation => '操作';

  @override
  String get linglongProcess => 'Linyaps プロセス';

  @override
  String get baseSetting => '基本設定';

  @override
  String get about => '情報';

  @override
  String get envMissing => 'Linyaps 環境がこのシステムに見つかりません';

  @override
  String get envMissingDetail =>
      'システムに Linyaps コンポーネントが存在しないかバージョンが低いため、先にインストールする必要があります。';

  @override
  String get autoInstall => '自動インストール';

  @override
  String get manualInstall => '手動インストール';

  @override
  String get recheck => '再チェック';

  @override
  String get exitStore => 'ストアを終了';

  @override
  String get errorNetwork => 'ネットワーク接続に失敗しました';

  @override
  String get errorNetworkDetail => 'ネットワーク接続を確認してから再試行してください';

  @override
  String get errorInstallFailed => 'インストールに失敗しました';

  @override
  String get errorUninstallFailed => 'アンインストールに失敗しました';

  @override
  String get errorUpdateFailed => '更新に失敗しました';

  @override
  String get errorUnknown => '不明なエラー';

  @override
  String get retry => '再試行';

  @override
  String get downloading => 'ダウンロード中...';

  @override
  String get downloadComplete => 'ダウンロード完了';

  @override
  String get installComplete => 'インストール完了';

  @override
  String get uninstallComplete => 'アンインストール完了';

  @override
  String get updateComplete => '更新完了';

  @override
  String get noApps => 'アプリがありません';

  @override
  String get noInstalledApps => 'インストール済みのアプリはありません';

  @override
  String get noInstalledAppsHint =>
      'まだ Linyaps アプリをインストールしていません。おすすめページを見てみましょう';

  @override
  String get noUpdateApps => '利用可能な更新はありません';

  @override
  String get version => 'バージョン';

  @override
  String get size => 'サイズ';

  @override
  String get description => '概要';

  @override
  String get developer => '開発元';

  @override
  String get confirmDelete => '削除の確認';

  @override
  String get confirmDeleteMessage => 'この項目を削除しますか？この操作は取り消せません。';

  @override
  String get confirmUninstall => 'アンインストールの確認';

  @override
  String get confirmUninstallMessage => 'このアプリをアンインストールしますか？';

  @override
  String get noData => 'データがありません';

  @override
  String get noDataDescription => 'まだ何も表示する内容がありません';

  @override
  String get pageNotFound => 'ページが見つかりません';

  @override
  String get pageNotFoundDescription => '申し訳ありません。ページが見つかりません';

  @override
  String get backToHome => 'ホームに戻る';

  @override
  String get searchApps => 'アプリを検索...';

  @override
  String get languageSettings => '言語設定';

  @override
  String get themeSettings => 'テーマ設定';

  @override
  String get fontSettings => 'フォント設定';

  @override
  String get cacheManagement => 'キャッシュ管理';

  @override
  String get storeOptions => 'ストア設定';

  @override
  String get fontSettingsHint => 'システムのフォント設定が基本値となり、以下の調整はその上に加算されます。';

  @override
  String get fontSizeAdjustment => 'フォントサイズ';

  @override
  String get fontWeightAdjustmentLabel => 'フォントの太さ';

  @override
  String get fontWeightLighter => '細め';

  @override
  String get fontWeightNormal => '標準';

  @override
  String get fontWeightBolder => '太め';

  @override
  String fontScalePercent(int percent) {
    return '$percent%';
  }

  @override
  String get checkUpdate => '更新をチェック';

  @override
  String currentVersion(String version) {
    return '現在のバージョン: $version';
  }

  @override
  String newVersionFound(String tagName, String currentVersion) {
    return '新バージョン $tagName が見つかりました。現在のバージョンは $currentVersion';
  }

  @override
  String alreadyLatest(String version) {
    return '現在 $version は最新です';
  }

  @override
  String get checkingUpdate => '更新をチェック中...';

  @override
  String get goDownload => 'ダウンロードへ';

  @override
  String get updateNow => '今すぐ更新';

  @override
  String get updateDetectingInstallation => 'インストール方式を検出中...';

  @override
  String get updateResolvingAsset => 'インストールパッケージを選択中...';

  @override
  String get updateDownloading => '更新パッケージをダウンロード中...';

  @override
  String get updateVerifying => '更新パッケージを検証中...';

  @override
  String get updateInstalling => '更新をインストール中...';

  @override
  String get updateSucceeded =>
      '更新をインストールしました。新しいバージョンを使うにはアプリを一度閉じてから再度開いてください';

  @override
  String get updateFailed => '更新に失敗しました';

  @override
  String get updateCancelled => '更新をキャンセルしました';

  @override
  String get updateRetry => '再試行';

  @override
  String get updateManualInstallHint => '自動更新できません。ダウンロードページから手動でインストールしてください';

  @override
  String get updateUnsupportedArch => '現在のアーキテクチャは自動インストールに対応していません';

  @override
  String get updateChecksumMissing => '更新パッケージのチェックサム情報がないため、インストールを中止しました';

  @override
  String get updateChecksumFailed => '更新パッケージの検証に失敗したため、インストールを中止しました';

  @override
  String get cacheSize => 'キャッシュサイズ';

  @override
  String get startupCheckUpdate => '起動時にストアの更新をチェック';

  @override
  String get startupCheckUpdateDesc => '起動のたびに新しいバージョンの有無を確認します';

  @override
  String get systemNotifications => 'システム通知';

  @override
  String get systemNotificationsDescription => '一括更新の完了後、デスクトップ通知で結果を表示します';

  @override
  String get userExperienceProgram => 'ユーザーエクスペリエンス向上プログラム';

  @override
  String get userExperienceProgramDesc => '匿名の利用統計を送信し、ストア改善にご協力ください';

  @override
  String get userExperienceProgramDialogIntro =>
      'ユーザーエクスペリエンス向上プログラムに参加することで、Linyaps ストアの改善にご協力いただけます。収集するのは少量の匿名情報のみで、アプリのおすすめとダウンロード体験の改善に使われます：';

  @override
  String get userExperienceProgramDialogItemIdentity =>
      '匿名デバイス識別子（ランダムな文字列で、個人を特定できません）';

  @override
  String get userExperienceProgramDialogItemSystem =>
      'システムアーキテクチャ、システムバージョンとカーネル情報、ホスト名、Linyaps 環境のバージョン';

  @override
  String get userExperienceProgramDialogItemApps =>
      'インストール済みの Linyaps アプリ一覧と、アプリのインストール・更新・アンインストール記録';

  @override
  String get userExperienceProgramDialogItemNetwork => 'ネットワークアドレス（地域統計のみに使用）';

  @override
  String get userExperienceProgramDialogFooter =>
      'これらの情報は実際の身元と紐付けられず、個人を特定するためにも使われません。スイッチはいつでもオフにでき、オフ後は一切データを送信しません。';

  @override
  String get a11yUserExperienceProgramInfo => 'ユーザーエクスペリエンス向上プログラムの収集情報の説明を見る';

  @override
  String updateBatchAllSucceededTitle(int count) {
    return '$count 件のアプリを更新しました';
  }

  @override
  String get updateBatchFinishedTitle => '一括更新が終了しました';

  @override
  String get updateBatchNoSuccessTitle => 'アプリの更新が完了していません';

  @override
  String updateBatchResultSummary(String summary) {
    return '結果: $summary';
  }

  @override
  String get updateBatchResultSeparator => '、';

  @override
  String updateBatchSucceededCount(int count) {
    return '成功 $count 件';
  }

  @override
  String updateBatchFailedCount(int count) {
    return '失敗 $count 件';
  }

  @override
  String updateBatchCancelledCount(int count) {
    return 'キャンセル $count 件';
  }

  @override
  String updateBatchInterruptedCount(int count) {
    return '中断 $count 件';
  }

  @override
  String get updateBatchAppNameSeparator => '、';

  @override
  String updateBatchUpdatedApps(String names) {
    return '更新済み: $names';
  }

  @override
  String updateBatchUpdatedAppsOverflow(String names, int remainingCount) {
    return '更新済み: $names ほか $remainingCount 件';
  }

  @override
  String get softwareRendering => 'ソフトウェアレンダリング';

  @override
  String get softwareRenderingEnabled => 'ソフトウェアレンダリング';

  @override
  String get hardwareRenderingEnabled => 'ハードウェアレンダリング';

  @override
  String get rendererModeDetecting => '現在のレンダリング状態を検出中…';

  @override
  String get rendererModeDetectFailed =>
      '現在のレンダリング状態を取得できませんでしたが、次回起動時に使う描画方式は保存できます。';

  @override
  String rendererModeCurrentStatus(Object mode, Object reason) {
    return '現在は$modeを使用しています。$reason';
  }

  @override
  String rendererModeReasonEnvironment(Object value) {
    return '現在のレンダリングモードは環境変数 $value によって制御されています。';
  }

  @override
  String get rendererModeReasonUserPreference => '保存された設定に従って有効になっています。';

  @override
  String get rendererModeReasonCpuFallback =>
      '互換性を高めるため、このデバイスでは既定でソフトウェアレンダリングを使用します。';

  @override
  String get rendererModeReasonDefault => 'このデバイスでは既定でハードウェアレンダリングを使用します。';

  @override
  String rendererModeEnvLocked(Object value) {
    return '環境変数 $value が検出されました。現在のレンダリングモードはシステム環境によって制御されているため、ここでは変更できません。';
  }

  @override
  String rendererModeNextLaunchStatus(Object mode) {
    return '次回起動時は$modeを使用します。';
  }

  @override
  String get rendererModeWhitelistHint =>
      'より安定した表示のため、このデバイスではソフトウェアレンダリングを維持することをおすすめします。';

  @override
  String get rendererModeHardwareRiskHint =>
      '次回起動時はハードウェアレンダリングを使用します。画面が正常に表示されない場合は、以下のコマンドで復旧できます。';

  @override
  String get rendererModeDisableWarningTitle => 'ソフトウェアレンダリングを無効にする確認';

  @override
  String get rendererModeDisableWarningMessage =>
      'このデバイスでソフトウェアレンダリングを無効にすると、アプリが正常に表示されなくなる可能性があります。より安定した表示のためソフトウェアレンダリングを維持することをおすすめします。';

  @override
  String rendererModeDetectedCpu(Object cpu) {
    return 'このデバイスのプロセッサー: $cpu';
  }

  @override
  String get rendererModeDisableBlackScreenHint =>
      '次回の起動後にアプリが正常に表示されない場合は、ターミナルで以下のコマンドを実行してからアプリを再度開いてください。';

  @override
  String get rendererModeDataDirectoryLabel => 'データディレクトリ';

  @override
  String get rendererModeDeleteCommandLabel => '削除コマンド';

  @override
  String get rendererModeSaveCommandHint =>
      'アプリが正常に表示されなくなった場合に備えて、このコマンドをコピーして保管しておくことをおすすめします。';

  @override
  String get rendererModeDisableConfirm => '無効にする';

  @override
  String get rendererModeSavedSoftware =>
      'ソフトウェアレンダリングに切り替えました。次回の起動時に有効になります。';

  @override
  String get rendererModeSavedHardware =>
      'ハードウェアレンダリングに切り替えました。次回の起動時に有効になります。';

  @override
  String get rendererModeSaveFailed => 'レンダリング設定の保存に失敗しました。しばらくしてから再試行してください。';

  @override
  String get showBaseServices => '基盤ランタイムサービスを表示';

  @override
  String get showBaseServicesDesc => 'インストール済みリストに基盤ランタイムサービスを表示します';

  @override
  String get cleanDeprecatedServices => '廃止された基盤サービスを整理';

  @override
  String get cleanDeprecatedServicesDesc =>
      '使用されなくなった基盤ランタイムサービスを削除し、ディスク領域を解放します';

  @override
  String get checkNewVersion => '新バージョンをチェック';

  @override
  String get feedbackMenu => 'フィードバック';

  @override
  String get officialWebsite => '公式サイト';

  @override
  String get communityExchange => 'コミュニティ';

  @override
  String get aboutDevelopers => '開発者について';

  @override
  String get feedbackTitle => 'フィードバック';

  @override
  String get uploadLog => 'ログファイルも一緒に送信';

  @override
  String get noPrivacyInfo => 'ログに個人のプライバシー情報は含まれません';

  @override
  String get submitFeedback => '送信';

  @override
  String get feedbackHint => '問題の概要や説明をご記入ください';

  @override
  String get feedbackSuccess => 'フィードバックありがとうございます！';

  @override
  String get feedbackFailed => 'フィードバックの送信に失敗しました。しばらくしてから再試行してください';

  @override
  String get confirmExit => '終了の確認';

  @override
  String get exitWithInstalling => '進行中のインストールタスクがあります。終了しますか？';

  @override
  String get exitBtn => '終了';

  @override
  String get downloadManager => 'ダウンロード管理';

  @override
  String get downloadWaitingForTask => 'ダウンロードタスクの開始を待っています';

  @override
  String downloadRealtimeSpeed(String speed) {
    return 'リアルタイム速度 $speed';
  }

  @override
  String downloadHistoryCount(int count) {
    return '$count 件の記録';
  }

  @override
  String ogInstallRequestReceived(String appName) {
    return 'ウェブからのインストール要求を受信しました: $appName';
  }

  @override
  String ogInstallEnqueued(String appName) {
    return 'ダウンロード管理に追加しました: $appName';
  }

  @override
  String get ogInstallInvalidLink =>
      'ウェブのインストールリンクを認識できません。og://appId のみ対応しています';

  @override
  String get ogInstallEnvironmentUnavailable =>
      'Linyaps 実行環境が利用できないため、ウェブからの自動インストールは現在中断されています';

  @override
  String ogInstallDuplicate(String appName) {
    return '$appName は既にダウンロード管理にあります';
  }

  @override
  String get ogInstallDetailFailed => 'アプリ情報を取得できないため、インストールを開始しませんでした';

  @override
  String ogInstallDetailFailedWithError(String error) {
    return 'アプリ情報を取得できないため、インストールを開始しませんでした: $error';
  }

  @override
  String get clearRecords => '記録を消去';

  @override
  String get noDownloadTasks => 'ダウンロードタスクはありません';

  @override
  String cannotOpenLink(String url) {
    return 'リンクを開けません: $url';
  }

  @override
  String get envCheckPassed => 'インストールが完了し、環境チェックに合格しました';

  @override
  String get envCheckFailed => 'インストールは完了しましたが、環境にまだ問題があります。確認してください';

  @override
  String launching(String appName) {
    return '$appName を起動中...';
  }

  @override
  String launchFailed(String error) {
    return '起動に失敗しました: $error';
  }

  @override
  String copied(String value) {
    return 'コピーしました: $value';
  }

  @override
  String get shareLink => '共有';

  @override
  String shareMessage(String name) {
    return '「$name」というアプリを見てみて';
  }

  @override
  String get linkCopied => 'リンクをコピーしました。ぜひ共有してください';

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String get createDesktopShortcut => 'デスクトップショートカットを作成';

  @override
  String get appDetailTitle => 'アプリ詳細';

  @override
  String get appNotFound => 'アプリ情報が見つかりません';

  @override
  String get noVersionHistory => 'バージョン履歴はありません';

  @override
  String get installedBadge => 'インストール済み';

  @override
  String get versionInstallTargetMissing =>
      '対応するインストール済みバージョンが見つかりません。更新してから再試行してください';

  @override
  String uninstallFailed(String result) {
    return 'アンインストールに失敗しました: $result';
  }

  @override
  String uninstallSuccess(String name) {
    return '$name をアンインストールしました';
  }

  @override
  String uninstallError(String error) {
    return 'アンインストール中に異常が発生しました: $error';
  }

  @override
  String get commandCopied => 'コマンドをクリップボードにコピーしました。ターミナルに貼り付けて実行してください';

  @override
  String get copy => 'コピー';

  @override
  String get copyLog => 'ログをコピー';

  @override
  String get copySucceeded => 'コピーに成功しました';

  @override
  String get copyErrorMessage => 'エラーメッセージをコピー';

  @override
  String get skipCheck => 'チェックをスキップ';

  @override
  String get loadFailed => '読み込みに失敗しました';

  @override
  String get shortcutCreated => 'ショートカットを作成しました';

  @override
  String get appComments => 'コメント欄';

  @override
  String get appCommentsEmpty => 'まだコメントがありません。最初のコメントを書いてみましょう';

  @override
  String get commentInputHint => 'このアプリの使用感想を書いてみましょう';

  @override
  String get submitComment => 'コメントを投稿';

  @override
  String get commentVersionLabel => '関連バージョン';

  @override
  String get anonymousComment => '匿名ゲスト';

  @override
  String get commentHelpful => '役に立った';

  @override
  String get commentNotHelpful => '役に立たなかった';

  @override
  String get commentAnonymousHint => '匿名コメント。新しい順に表示されます';

  @override
  String get commentSubmitSuccess => 'コメントを送信しました';

  @override
  String commentSubmitFailed(String error) {
    return 'コメントの送信に失敗しました: $error';
  }

  @override
  String shortcutCreateFailed(String error) {
    return '作成に失敗しました: $error';
  }

  @override
  String get envCheckTitle => '環境チェック';

  @override
  String get checkingLinglongEnv => 'Linyaps 環境をチェック中...';

  @override
  String get unknownStatus => '不明な状態';

  @override
  String get llCliVersion => 'll-cli バージョン';

  @override
  String get notDetected => '未検出';

  @override
  String get errorMessage => 'エラーメッセージ';

  @override
  String get repoShowFailureTitle => 'リポジトリ読み取りコマンドの実行に失敗しました';

  @override
  String repoShowFailureCommand(String command) {
    return '$command を実行して Linyaps リポジトリ設定を読み取るのに失敗しました。';
  }

  @override
  String get repoShowFailureReason =>
      'このコマンドはシステムサービス org.deepin.linglong.PackageManager.service を通じてリポジトリ設定を読み取ります。サービスが起動していない場合は失敗を返します。';

  @override
  String get repoShowFailureInstalledQuestion => 'アプリ環境はもうインストール済みですか？';

  @override
  String get repoShowFailureRestartHint =>
      'll-cli とアプリ環境がインストール済みの場合は、このシステムサービスを再起動してから再度チェックしてみてください。';

  @override
  String get restartPackageManagerService =>
      'org.deepin.linglong.PackageManager.service の再起動を試す';

  @override
  String get restartingPackageManagerService =>
      'org.deepin.linglong.PackageManager.service を再起動中...';

  @override
  String get packageManagerServiceRestartPassed => 'サービスを再起動しました。環境チェックに合格しました';

  @override
  String get packageManagerServiceRestartStillFailed =>
      'サービスは再起動しましたが、環境にまだ問題があります。エラーメッセージを確認してください';

  @override
  String packageManagerServiceRestartFailed(String error) {
    return 'サービスの再起動に失敗しました: $error';
  }

  @override
  String get installingLinglong => 'インストール中...';

  @override
  String get openInstallLogDirectory => 'ログディレクトリを開く';

  @override
  String cannotOpenDirectory(String path) {
    return 'ディレクトリを開けません: $path';
  }

  @override
  String get appIntroduction => 'アプリ紹介';

  @override
  String get collapse => '折りたたむ';

  @override
  String get expandAll => 'すべて展開';

  @override
  String get collapseCategories => 'カテゴリを折りたたむ';

  @override
  String get expandCategories => 'カテゴリを展開';

  @override
  String get packageName => 'パッケージ名';

  @override
  String get architecture => 'アーキテクチャ';

  @override
  String get channelLabel => 'チャネル';

  @override
  String get runtime => 'ランタイム';

  @override
  String get license => 'ライセンス';

  @override
  String get homepage => 'ホームページ';

  @override
  String get appInfo => 'アプリ情報';

  @override
  String get versionHistory => 'バージョン履歴';

  @override
  String get versionListLoadFailed => 'バージョンリストの読み込みに失敗しました。再試行してください';

  @override
  String get versionListUpdateFailed => 'バージョンリストの更新に失敗しました。前回の結果を表示しています';

  @override
  String get uninstallApp => 'アプリをアンインストール';

  @override
  String uninstallConfirmMessage(String name) {
    return '$name をアンインストールしますか？\nアンインストール後はアプリデータが削除され、この操作は元に戻せません。';
  }

  @override
  String get noDescription => '説明はありません';

  @override
  String get categoryLabel => 'カテゴリ';

  @override
  String get searchNotFound => '関連するアプリが見つかりません';

  @override
  String get searchTryOtherKeywords => '他のキーワードで検索してみてください';

  @override
  String get searchInputHint => '上部の検索ボックスにキーワードを入力';

  @override
  String get searchPressEnter => 'Enter キーでアプリを検索';

  @override
  String searchResultCount(int count) {
    return '$count 件の結果が見つかりました';
  }

  @override
  String get searchInstalledApps => 'インストール済みのアプリを検索';

  @override
  String get noMatchingApp => '一致するアプリが見つかりません';

  @override
  String noMatchingAppHint(String query) {
    return '\"$query\" に関連するアプリが見つかりません';
  }

  @override
  String updateCount(int count) {
    return '$count 件のアプリを更新できます';
  }

  @override
  String ignoredUpdatesCount(int count) {
    return '除外中 ($count)';
  }

  @override
  String get ignoredUpdatesTitle => '除外された更新';

  @override
  String get ignoredUpdatesEmptyTitle => '除外されたアプリはありません';

  @override
  String get ignoredUpdatesEmptyDescription =>
      '更新可能なアプリのその他メニューから、アップグレードしたくないアプリを継続的に除外できます。';

  @override
  String get ignoreAppUpdates => 'このアプリの更新を除外';

  @override
  String get restoreUpdateNotifications => '更新通知を復元';

  @override
  String ignoredVersion(String version) {
    return '除外時のバージョン: $version';
  }

  @override
  String ignoreUpdateSuccess(String appName) {
    return '$appName の今後の更新を除外しました。「除外済み」から復元できます';
  }

  @override
  String ignoreUpdateActiveTask(String appName) {
    return '$appName は更新キューにあるため、現在中除できません';
  }

  @override
  String get ignoreUpdateFailed => '更新除外設定の保存に失敗しました。再試行してください';

  @override
  String get ignoreUpdateInvalidApp => 'このアプリを除外できません: アプリ識別子が無効です';

  @override
  String restoreUpdateSuccess(String appName) {
    return '$appName の更新通知を復元しました';
  }

  @override
  String get restoreUpdateFailed => '更新通知の復元に失敗しました。再試行してください';

  @override
  String get restoreUpdateRefreshFailed =>
      '更新通知は復元しましたが、更新チェックに失敗しました。あとで再試行できます';

  @override
  String a11yManageIgnoredUpdates(int count) {
    return '除外された更新を管理。全部で $count 件のアプリがあります';
  }

  @override
  String a11yIgnoreAppUpdates(String appName) {
    return '$appName の今後の更新を除外';
  }

  @override
  String a11yUpdateAppMoreActions(String appName) {
    return '$appName のその他の更新操作';
  }

  @override
  String a11yRestoreAppUpdates(String appName) {
    return '$appName の更新通知を復元';
  }

  @override
  String a11yIgnoredUpdateItem(String appName, String appId, String version) {
    return '$appName、アプリ ID $appId、除外時のバージョン $version';
  }

  @override
  String get updating => '更新中...';

  @override
  String get updateAll => 'すべて更新';

  @override
  String get updateCheckFailed => '更新のチェックに失敗しました';

  @override
  String get noUpdate => '更新はありません';

  @override
  String get allAppsUpToDate => 'すべてのアプリは最新バージョンです';

  @override
  String get noMore => 'これ以上ありません';

  @override
  String get appTitleShort => 'Linyaps ストア';

  @override
  String get detectingEnv => 'Linyaps 環境を検出中...';

  @override
  String get stepEnvCheck => '環境チェック';

  @override
  String get stepAppLoad => 'アプリ読み込み';

  @override
  String get stepUpdateCheck => '更新チェック';

  @override
  String get stepQueueRecovery => 'キュー復元';

  @override
  String get launchFailedTitle => '起動に失敗しました';

  @override
  String get skip => 'スキップ';

  @override
  String get cannotGetVersion => 'バージョン情報を取得できません';

  @override
  String newVersionAvailable(String version, String current) {
    return '新バージョン $version があります！\n現在のバージョン: $current';
  }

  @override
  String get languageZh => '中文';

  @override
  String get languageSelfName => '日本語';

  @override
  String get themeFollowSystem => 'システムに従う';

  @override
  String get themeLight => 'ライトモード';

  @override
  String get themeDark => 'ダークモード';

  @override
  String get clearingCache => '消去中...';

  @override
  String get clearCache => 'キャッシュを消去';

  @override
  String get clearCacheDesc =>
      'キャッシュを消去するとストレージ領域を解放できますが、アプリのアイコンと一部のデータが再ダウンロードされます。';

  @override
  String get clearCacheConfirm => 'キャッシュ消去の確認';

  @override
  String get clearCacheMessage => 'すべてのキャッシュを消去しますか？';

  @override
  String get cacheCleared => 'キャッシュを消去しました';

  @override
  String get clearCacheFailed => 'キャッシュの消去に失敗しました';

  @override
  String get appVersion => 'アプリバージョン';

  @override
  String get appCount => '収録アプリ数';

  @override
  String get operatingSystem => 'オペレーティングシステム';

  @override
  String get systemArch => 'システムアーキテクチャ';

  @override
  String get linglongVersion => 'Linyaps バージョン';

  @override
  String get checkNetwork => 'ネットワーク接続を確認してから再試行してください';

  @override
  String get copyContainerCommand => 'コンテナに入るコマンドをコピー';

  @override
  String get commandCopiedToClipboard => 'コマンドをクリップボードにコピーしました';

  @override
  String get copyAppId => 'アプリ ID をコピー';

  @override
  String stopSuccess(String name) {
    return '$name を停止しました';
  }

  @override
  String get stopFailed => '停止に失敗しました';

  @override
  String get processRefreshFailed => 'プロセスリストの更新に失敗しました...';

  @override
  String get noRunningApps => '現在実行中の Linyaps アプリはありません';

  @override
  String get notRefreshed => 'まだ更新されていません';

  @override
  String get lastRefresh => '前回の更新';

  @override
  String get refreshing => '更新中';

  @override
  String get appName => 'アプリ名';

  @override
  String get versionNo => 'バージョン番号';

  @override
  String get source => 'ソース';

  @override
  String get containerId => 'コンテナ ID';

  @override
  String get appRunningTitle => 'アプリが実行中です';

  @override
  String get appRunningMessage => 'このアプリは実行中のため、アンインストールする前に先に終了する必要があります';

  @override
  String get downgradeConfirm => 'ダウングレードの確認';

  @override
  String get downgradeMessage => '対象バージョンは現在のバージョンより低いため、ダウングレードしますか？';

  @override
  String get alreadyInstalledVersion => 'このバージョンはインストール済みです';

  @override
  String get waiting => '待機中';

  @override
  String get completed => '完了';

  @override
  String get remove => '削除';

  @override
  String get feedbackCategories => 'ストア不具合,アプリ更新,アプリ障害';

  @override
  String get feedbackCategory => '問題カテゴリ';

  @override
  String get overview => '概要';

  @override
  String get overviewHint => '問題を簡潔にご記入ください';

  @override
  String get detailDescription => '詳細な説明';

  @override
  String get none => 'なし';

  @override
  String get clearSearch => '検索語を消去';

  @override
  String get minimize => '最小化';

  @override
  String get restore => '元に戻す';

  @override
  String get maximize => '最大化';

  @override
  String get close => '閉じる';

  @override
  String get goRecommend => 'おすすめページを見てみましょう';

  @override
  String get processRefreshFailedHint =>
      'プロセスリストの更新に失敗しました。現在表示しているのは前回成功時に取得したデータです';

  @override
  String get moreActions => 'その他の操作';

  @override
  String appRunningUninstallMessage(String name) {
    return '$name は現在実行中のため、アンインストール前にすべての実行インスタンスを強制終了する必要があります。\n強制終了してアンインストールしますか？';
  }

  @override
  String get forceCloseAndUninstall => '強制終了してアンインストール';

  @override
  String downgradeMessageWithVersion(
    String appName,
    String currentVersion,
    String targetVersion,
  ) {
    return '現在 $appName v$currentVersion がインストールされています。より低いバージョン v$targetVersion をインストールしようとしています。\nダウングレードにより機能異常が発生する可能性があります。続行しますか？';
  }

  @override
  String get confirmDowngrade => 'ダウングレードを確認';

  @override
  String reinstallMessage(String appName, String version) {
    return '$appName v$version はインストール済みです。\n再インストールしますか（既存のインストールを上書きします）？';
  }

  @override
  String get forceReinstall => '強制再インストール';

  @override
  String get installingLabel => 'インストール中';

  @override
  String waitingCount(int count) {
    return '待機中 ($count)';
  }

  @override
  String get detailDescriptionHint => '遭遇した問題を詳しくご記入ください';

  @override
  String get linglongCommunity => 'Linyaps コミュニティ';

  @override
  String get unknown => '不明';

  @override
  String get copyPid => 'PID をコピー';

  @override
  String get copyContainerId => 'コンテナ ID をコピー';

  @override
  String get refreshProcessList => 'プロセスリストを更新';

  @override
  String get stopProcess => 'プロセスを停止';

  @override
  String get checkUpdateNetworkError => '更新のチェックに失敗しました。ネットワーク接続を確認してください';

  @override
  String get pruneServiceTitle => '廃止された基盤サービスを整理';

  @override
  String get pruneServiceMessage =>
      'll-cli prune コマンドを実行し、どのアプリからも依存されなくなった基盤ランタイムサービスをすべて削除します。\n\n整理後はディスク領域を節約できますが、他の操作が進行中の場合は再ダウンロードが必要になることがあります。';

  @override
  String get pruneServiceSuccess => '廃止された基盤サービスを整理しました';

  @override
  String get pruneServiceFailed => '整理に失敗しました。しばらくしてから再試行してください';

  @override
  String get clearCacheHint =>
      'キャッシュを消去するとストレージ領域を解放できますが、アプリがデータを再読み込みする必要が出る場合があります。';

  @override
  String get pruneBaseServiceMessage =>
      'll-cli prune コマンドを実行し、どのアプリからも依存されなくなった基盤ランタイムサービスをすべて削除します。\n\n整理後はディスク領域を節約できますが、他の操作が進行中の場合は再ダウンロードが必要になることがあります。';

  @override
  String get clean => '整理';

  @override
  String get baseServiceCleaned => '廃止された基盤サービスを整理しました';

  @override
  String get cleanFailed => '整理に失敗しました。しばらくしてから再試行してください';

  @override
  String appCountValue(int count) {
    return '$count 件';
  }

  @override
  String get llCliVersionLabel => 'll-cli バージョン';

  @override
  String get rankingTabDownload => 'ダウンロードランキング';

  @override
  String get rankingTabRising => 'ニューフェイスランキング';

  @override
  String get rankingTabUpdate => '更新ランキング';

  @override
  String get rankingTabHot => '人気ランキング';

  @override
  String get sidebarAllApps => 'すべて';

  @override
  String get sidebarRanking => 'ランキング';

  @override
  String get installErrorGeneric => 'インストールに失敗しました';

  @override
  String get installErrorTimeout => 'インストール失敗: プログレスがタイムアウトしました';

  @override
  String get installCancelled => 'インストールをキャンセルしました';

  @override
  String get installErrorUnknown => 'インストール失敗: 不明なエラー';

  @override
  String get installErrorAppNotFoundRemote => 'インストール失敗: リモートリポジトリにアプリが見つかりません';

  @override
  String get installErrorAppNotFoundLocal => 'インストール失敗: ローカルにアプリが見つかりません';

  @override
  String get installFailed => 'インストールに失敗しました';

  @override
  String get installErrorAppNotInRemote => 'インストール失敗: リモートに該当アプリがありません';

  @override
  String get installErrorSameVersion => 'インストール失敗: 同じバージョンがインストール済みです';

  @override
  String get installErrorDowngrade => 'インストール失敗: ダウングレードが必要です';

  @override
  String get installErrorModuleVersionNotAllowed =>
      'インストール失敗: モジュールのインストール時にバージョンは指定できません';

  @override
  String get installErrorModuleRequiresApp =>
      'インストール失敗: モジュールのインストールには先にアプリのインストールが必要です';

  @override
  String get installErrorModuleExists => 'インストール失敗: モジュールは既に存在します';

  @override
  String get installErrorArchMismatch => 'インストール失敗: アーキテクチャが一致しません';

  @override
  String get installErrorModuleNotInRemote => 'インストール失敗: リモートに該当モジュールがありません';

  @override
  String get installErrorMissingErofs => 'インストール失敗: erofs 展開コマンドが見つかりません';

  @override
  String get installErrorUnsupportedFormat => 'インストール失敗: 対応していないファイル形式です';

  @override
  String get installErrorNetwork => 'インストール失敗: ネットワークエラー';

  @override
  String get installErrorInvalidRef => 'インストール失敗: 無効な参照です';

  @override
  String get installErrorUnknownArch => 'インストール失敗: 不明なアーキテクチャです';

  @override
  String installErrorCode(int code) {
    return 'インストール失敗: エラーコード $code';
  }

  @override
  String get installStatusStarting => 'インストールを開始';

  @override
  String get installStatusInstallingApp => 'アプリをインストール中';

  @override
  String get installStatusInstallingRuntime => 'ランタイムをインストール中';

  @override
  String get installStatusInstallingBase => 'ベースパッケージをインストール中';

  @override
  String get installStatusDownloadingMeta => 'メタデータをダウンロード中';

  @override
  String get installStatusDownloadingFiles => 'ファイルをダウンロード中';

  @override
  String get installStatusPostProcessing => 'インストール後処理';

  @override
  String get installStatusCompleted => 'インストール完了';

  @override
  String get installStatusProcessing => '処理中';

  @override
  String waitingForOperation(String operation) {
    return '$operationを待っています...';
  }

  @override
  String get operationInstall => 'インストール';

  @override
  String get operationUpdate => '更新';

  @override
  String operationPreparing(String operation, String appId) {
    return '$operationを準備中 $appId...';
  }

  @override
  String operationCancelled(String operation) {
    return '$operationをキャンセルしました';
  }

  @override
  String operationCompleted(String operation) {
    return '$operationが完了しました';
  }

  @override
  String operationUnknown(String operation) {
    return '$operationの状態は不明です';
  }

  @override
  String operationConfirmFailed(String operation) {
    return '$operationの結果を確認できません';
  }

  @override
  String operationTimeout(String operation) {
    return '$operationがタイムアウトしました';
  }

  @override
  String operationFailed(String operation) {
    return '$operationに失敗しました';
  }

  @override
  String get taskCrashInterrupted => 'アプリがクラッシュし、タスクが中断されました';

  @override
  String get taskCrashRetryHint => '実行中にアプリがクラッシュしました。再試行してください';

  @override
  String uninstallFailedWithError(String error) {
    return 'アンインストールに失敗しました: $error';
  }

  @override
  String uninstallException(String error) {
    return 'アンインストール中に異常: $error';
  }

  @override
  String stopFailedWithError(String error) {
    return '終了に失敗しました: $error';
  }

  @override
  String stopException(String error) {
    return '終了中に異常: $error';
  }

  @override
  String shortcutCreatedWithPath(String path) {
    return 'ショートカットを作成しました: $path';
  }

  @override
  String shortcutCreateFailedWithError(String error) {
    return '作成に失敗しました: $error';
  }

  @override
  String pruneFailedWithError(String error) {
    return '整理に失敗しました: $error';
  }

  @override
  String pruneException(String error) {
    return '整理中に異常: $error';
  }

  @override
  String get getVersionFailed => 'バージョンの取得に失敗しました';

  @override
  String get llCliNotInstalled => 'll-cli がインストールされていません';

  @override
  String get uosEnvInstallHint =>
      'UOS システムに Linyaps 環境をインストールする前に、まずシステムの開発者モードを有効にし、現在のアカウントが root 権限を取得できることを確認してください（設定-一般-開発者オプション-開発者モードへ移行。業務用端末では IT 部門への相談をおすすめします）。';

  @override
  String get uosAppInstallFailureHint =>
      'UOS システムの場合は、システムの開発者モードが有効になっているかご確認ください（設定-一般-開発者オプション-開発者モードへ移行。業務用端末では IT 部門への相談をおすすめします）。';

  @override
  String get appInfoUnavailable => 'アプリ情報を取得できません';

  @override
  String shortcutCreateException(String error) {
    return 'ショートカットの作成に失敗しました: $error';
  }

  @override
  String get waitingForInstall => 'インストール待ち';

  @override
  String get cancelInstall => 'インストールをキャンセル';

  @override
  String get uninstallBlockedTitle => '現在アンインストールできません';

  @override
  String uninstallBlockedMessage(String activeTaskName) {
    return '現在「$activeTaskName」のインストール/更新が進行中です。Linyaps はインストールとアンインストールの同時実行に対応していません。現在のタスクの完了を待つか、先に現在のタスクをキャンセルしてからアンインストールしてください。';
  }

  @override
  String get iKnow => '了解';

  @override
  String get viewDownloadManager => 'ダウンロード管理を見る';

  @override
  String a11ySearchByTag(Object tag) {
    return 'タグで検索: $tag';
  }

  @override
  String a11yRemoveSearchTag(Object tag) {
    return '検索タグを削除: $tag';
  }

  @override
  String a11yInstallApp(Object appName) {
    return '$appName をインストール';
  }

  @override
  String a11yUpdateApp(Object appName) {
    return '$appName を更新';
  }

  @override
  String a11yOpenApp(Object appName) {
    return '$appName を開く';
  }

  @override
  String a11yUninstallApp(Object appName) {
    return '$appName をアンインストール';
  }

  @override
  String get a11ySearchBox => 'アプリを検索';

  @override
  String get a11ySearchInputHint => 'キーワードを入力して検索';

  @override
  String get a11yCommentInputHint => 'コメント内容を入力';

  @override
  String get a11ySidebarNav => 'サイドバーナビゲーション';

  @override
  String a11yAppCard(Object appName, Object version, Object status) {
    return '$appName、バージョン $version、$status';
  }

  @override
  String a11yRankingItem(Object rank, Object appName) {
    return '第 $rank 位、$appName';
  }

  @override
  String a11yProcessItem(Object name, Object pid) {
    return 'プロセス $name、PID $pid';
  }

  @override
  String a11yDownloadItem(Object appName, Object percent) {
    return '$appName のダウンロード、進捗 $percent%';
  }

  @override
  String get a11yRecommendPage => 'おすすめ';

  @override
  String get a11yAllAppsPage => 'すべてのアプリ';

  @override
  String get a11yRankingPage => 'ランキング';

  @override
  String get a11yMyAppsPage => 'マイアプリ';

  @override
  String get a11ySettingsPage => '設定';

  @override
  String get a11yAppDetailPage => 'アプリ詳細';

  @override
  String get a11yScreenshotArea => 'スクリーンショット領域';

  @override
  String get a11yCommentSection => 'コメント欄';

  @override
  String get a11yCarouselArea => 'カルーセル領域';

  @override
  String get a11yAppListArea => 'アプリリスト';

  @override
  String get a11ySidebarArea => 'サイドバー';

  @override
  String get a11yMinimize => '最小化';

  @override
  String get a11yMaximize => '最大化';

  @override
  String get a11yRestore => '元に戻す';

  @override
  String get a11yClose => '閉じる';

  @override
  String get a11yPrevious => '前へ';

  @override
  String get a11yNext => '次へ';

  @override
  String get a11yTabSelected => '選択中';

  @override
  String get a11yTabNotSelected => '未選択';

  @override
  String get a11yStatusInstalled => 'インストール済み';

  @override
  String get a11yStatusUpdatable => '更新可能';

  @override
  String get a11yStatusNotInstalled => '未インストール';

  @override
  String get noAppsInCategory => 'このカテゴリにはアプリがありません';

  @override
  String get noRanking => 'ランキングはありません';

  @override
  String get noRecommend => 'おすすめはありません';

  @override
  String get installTimeout => 'インストールがタイムアウトしました: 長時間進捗更新がありません';

  @override
  String get downloadManagerSlowInstallHint =>
      '進捗が遅く見える場合は、ソフトウェアに必要な依存関係をインストールしている可能性があります。もう少々お待ちください……';

  @override
  String get loadingInstalledApps => 'インストール済みアプリを読み込み中...';

  @override
  String get appDescriptionPlaceholder => 'アプリの説明';

  @override
  String get rankingTabNewUpload => '新着ランキング';

  @override
  String get rankingTabDownloadCount => 'ダウンロード数ランキング';

  @override
  String uploadedXHoursAgo(int count) {
    return '$count時間前に登録';
  }

  @override
  String uploadedXDaysAgo(int count) {
    return '$count日前に登録';
  }

  @override
  String uploadedOnDate(String date) {
    return '$dateに登録';
  }

  @override
  String downloadedXTimes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'ダウンロード $countString回';
  }

  @override
  String get repoManagementHintTitle => 'リポジトリ管理機能のみ提供';

  @override
  String get repoManagementHintMessage =>
      '本ストアが取得できるのは公式 stable リポジトリのアプリデータのみです。stable リポジトリは削除しないでください。削除するとアプリをインストールできなくなります。';

  @override
  String get envManagementTitle => 'Linyaps 環境管理';

  @override
  String get envManagementDescription => '環境の分析、リポジトリの管理、ベース環境の修復と保存先の移動';

  @override
  String get envManagementAnalysisTab => '環境分析';

  @override
  String get envManagementRepositoryTab => 'リポジトリ管理';

  @override
  String get envManagementStorageTab => '保存先';

  @override
  String get envManagementAnalyzing => 'Linyaps 環境を分析中...';

  @override
  String get envManagementApplying => '操作を実行中...';

  @override
  String get envManagementNotAnalyzed => '環境分析がまだ完了していません';

  @override
  String get envManagementHealthyTitle => '対応が必要な問題は見つかりませんでした';

  @override
  String get envManagementHealthyMessage =>
      'Linyaps ベース環境、リポジトリ、ローカルデータは現在いずれも正常です。';

  @override
  String get envManagementBaseEnvironment => 'ベース環境';

  @override
  String get envManagementRepositoryMetric => 'リポジトリ';

  @override
  String get envManagementLocalData => 'ローカルデータ';

  @override
  String get envManagementStorageLocation => '保存先';

  @override
  String get envManagementNotDetected => '未検出';

  @override
  String get envManagementUnknown => '不明';

  @override
  String envManagementUsagePercent(int percent) {
    return '使用率 $percent%';
  }

  @override
  String get envManagementEnvironmentHealthyUpgrade => '環境は正常（アップグレード推奨）';

  @override
  String get envManagementEnvironmentHealthy => '環境は正常';

  @override
  String get envManagementRepositoryReadFailed => 'リポジトリ設定の読み取りに失敗しました';

  @override
  String get envManagementEnvironmentAbnormal => '環境異常';

  @override
  String get envRepoStatusNormal => '正常';

  @override
  String get envRepoStatusNotConfigured => '未設定';

  @override
  String get envRepoStatusMisconfigured => '設定異常';

  @override
  String get envRepoStatusUnavailable => '利用不可';

  @override
  String get envRepoStatusUnknown => '不明';

  @override
  String get envLocalDataDetectionFailed => '検出に失敗しました';

  @override
  String get envLocalDataUnavailable => '利用不可';

  @override
  String get envLocalDataNormal => '正常';

  @override
  String get envIssueLlCliUnavailableTitle => 'll-cli が利用できません';

  @override
  String get envIssueLlCliUnavailableDescription =>
      '利用可能な Linyaps コマンドライン環境が検出されません。';

  @override
  String get envIssueRepositoryNotConfiguredTitle => 'Linyaps リポジトリが未設定';

  @override
  String get envIssueRepositoryNotConfiguredDescription =>
      '現在有効な Linyaps リポジトリ設定がありません。先にリポジトリを追加または修復する必要があります。';

  @override
  String get envIssueDataPermissionTitle => 'Linyaps データディレクトリの権限異常';

  @override
  String envIssueDataPermissionDescription(String serviceUser) {
    return 'll-package-manager はユーザー $serviceUser として実行されていますが、Linyaps データディレクトリまたは重要な状態ファイルの所有者が異常であり、リポジトリ移行、ダウンロードオブジェクトや layer の作成に失敗する可能性があります。';
  }

  @override
  String get envIssueLocalDataDetectionTitle => 'Linyaps ローカルデータの検出に失敗しました';

  @override
  String get envIssueLocalDataDetectionDescription =>
      'linyaps ローカルデータの読み取りチェックを実行できません。ll-cli と package-manager サービスの状態を確認してください。';

  @override
  String get envIssueLocalDataUnavailableTitle => 'Linyaps ローカルデータを利用できません';

  @override
  String get envIssueLocalDataUnavailableDescription =>
      'linyaps の実行パスに従ってインストール済みアプリデータを読み取れません。アプリリスト、インストールや実行に影響する可能性があります。先に Linyaps データディレクトリの権限とベース環境の状態を確認してから、必要に応じて修復を実行してください。';

  @override
  String get envIssueStorageSpaceTitle => 'Linyaps の保存先の空き領域が不足しています';

  @override
  String envIssueStorageSpaceDescription(String path, int percent) {
    return '現在 $path のあるファイルシステムの使用率は約 $percent% です。整理するか保存先を移動することをおすすめします。';
  }

  @override
  String get envIssueRunningAppsTitle => '実行中の Linyaps アプリがあります';

  @override
  String envIssueRunningAppsDescription(int count) {
    return '現在 $count 件の Linyaps アプリが実行中です。保存先を移動する前に必ず終了してください。';
  }

  @override
  String get envRepairAction => '修復';

  @override
  String get envHandleAction => '対処';

  @override
  String get envRepairLocalDataTitle => 'Linyaps ローカルデータを修復';

  @override
  String get envRepairLocalDataMessage =>
      '管理者権限で Linyaps ローカルデータの修復を試みます。再取得が必要なアプリやベース環境データが検出された場合は、ダウンロードが発生し時間がかかる可能性があります。続行しますか？';

  @override
  String get envRepairLocalDataConfirm => '修復を実行';

  @override
  String get envRepairPermissionTitle => 'Linyaps データディレクトリの権限を修復';

  @override
  String envRepairPermissionMessage(String rootPath, String serviceUser) {
    return '管理者権限で $rootPath の重要なディレクトリと状態ファイルの所有者を $serviceUser に戻し、Linyaps package-manager を再起動します。続行しますか？';
  }

  @override
  String get envRepairPermissionConfirm => '権限を修復';

  @override
  String get envMoveStorageTitle => 'Linyaps の保存先を移動';

  @override
  String envMoveStorageMessage(String rootPath, String targetPath) {
    return '$rootPath を $targetPath にコピーし、systemd bind mount を作成します。対象パーティションの空き容量が十分であることをご確認ください。';
  }

  @override
  String get envMoveStorageConfirm => '移動を開始';

  @override
  String get envAddRepositoryTitle => 'Linyaps リポジトリを追加';

  @override
  String get envRepositoryName => 'リポジトリ名';

  @override
  String get envRepositoryAddress => 'リポジトリアドレス';

  @override
  String get envRepositoryAliasOptional => '別名（任意）';

  @override
  String get envAddAction => '追加';

  @override
  String get envSaveAction => '保存';

  @override
  String get envDeleteAction => '削除';

  @override
  String envUpdateRepositoryTitle(String name) {
    return 'リポジトリアドレスを変更: $name';
  }

  @override
  String envSetPriorityTitle(String name) {
    return '優先度を設定: $name';
  }

  @override
  String get envRepositoryPriority => '優先度';

  @override
  String get envPriorityMustBeNumber => '優先度は数字である必要があります';

  @override
  String get envRemoveRepositoryTitle => 'リポジトリを削除';

  @override
  String envRemoveRepositoryMessage(String name) {
    return 'リポジトリ $name を削除しますか？';
  }

  @override
  String get envRepositoryAdded => 'リポジトリを追加しました';

  @override
  String envRepositoryAddFailed(String error) {
    return 'リポジトリの追加に失敗しました: $error';
  }

  @override
  String get envRepositoryUpdated => 'リポジトリを更新しました';

  @override
  String envRepositoryUpdateFailed(String error) {
    return 'リポジトリの更新に失敗しました: $error';
  }

  @override
  String get envPriorityUpdated => '優先度を更新しました';

  @override
  String envPriorityUpdateFailed(String error) {
    return '優先度の設定に失敗しました: $error';
  }

  @override
  String get envRepositoryRemoved => 'リポジトリを削除しました';

  @override
  String envRepositoryRemoveFailed(String error) {
    return 'リポジトリの削除に失敗しました: $error';
  }

  @override
  String get envDefaultRepositoryUpdated => 'デフォルトリポジトリを更新しました';

  @override
  String envDefaultRepositoryUpdateFailed(String error) {
    return 'デフォルトリポジトリの設定に失敗しました: $error';
  }

  @override
  String get envMirrorEnabled => 'ミラーを有効にしました';

  @override
  String get envMirrorDisabled => 'ミラーを無効にしました';

  @override
  String envMirrorUpdateFailed(String error) {
    return 'ミラー状態の変更に失敗しました: $error';
  }

  @override
  String get envOpenLogDirectoryFailed => 'ログディレクトリを開けませんでした';

  @override
  String get envRepositoryNotLoaded => 'リポジトリ設定がまだ読み込まれていません';

  @override
  String envRepositoryDefaultValue(String name) {
    return 'デフォルトリポジトリ: $name';
  }

  @override
  String get envNotSet => '未設定';

  @override
  String get envAddRepository => 'リポジトリを追加';

  @override
  String get envNoRepositories => 'リポジトリ設定がありません';

  @override
  String get envDefaultBadge => 'デフォルト';

  @override
  String envRepositoryDetails(String name, String priority) {
    return 'name=$name  priority=$priority';
  }

  @override
  String get envRepositoryActions => 'リポジトリ操作';

  @override
  String get envEditAddress => 'アドレスを変更';

  @override
  String get envSetDefault => 'デフォルトに設定';

  @override
  String get envSetPriority => '優先度を設定';

  @override
  String get envEnableMirror => 'ミラーを有効化';

  @override
  String get envDisableMirror => 'ミラーを無効化';

  @override
  String get envCurrentStorageLocation => '現在の保存先';

  @override
  String get envStorageNotAnalyzed => '保存先の分析がまだ完了していません';

  @override
  String envStorageSummary(String path, int percent) {
    return '$path  使用率 $percent%';
  }

  @override
  String get envNewStorageLocation => '新しい保存先';

  @override
  String get envStorageMoveMethod => '移動方式';

  @override
  String envStorageMoveMethodDescription(String rootPath) {
    return 'Linyaps は現在インストールディレクトリの直接変更に対応していません。ここではデータをコピーした後 systemd bind mount を作成し、新しいディレクトリを $rootPath にマウントします。';
  }

  @override
  String get envMoveStorageAction => '保存先を移動';

  @override
  String get envCloseAppsBeforeMoveTitle => '移動前にアプリを終了する必要があります';

  @override
  String envCloseAppsBeforeMoveMessage(int count) {
    return '現在 $count 件の Linyaps アプリが実行中です。';
  }

  @override
  String get envResultDataPermissionCompleted => 'Linyaps データディレクトリの権限を修復しました';

  @override
  String get envResultDataPermissionFailed => 'Linyaps データディレクトリの権限修復に失敗しました';

  @override
  String get envResultLocalDataUnsupported =>
      '現在のシステムコンポーネントは問題オブジェクトの自動消去に対応していないため、Linyaps ローカルデータを自動修復できません。システム関連コンポーネントをアップグレードするか、ディストリビューションのツールで対処してください。';

  @override
  String get envResultLocalDataCompleted => 'Linyaps ローカルデータの修復を実行しました';

  @override
  String get envResultLocalDataCompletedLegacy =>
      'Linyaps ローカルデータの修復を実行しました（旧バージョンのシステムパラメータと互換）';

  @override
  String get envResultLocalDataFailed => 'Linyaps ローカルデータの修復に失敗しました';

  @override
  String get envResultLocalDataChecksumMismatch =>
      'Linyaps ローカルデータの再検証でオブジェクトの checksum 不一致が発見され、自動消去後も修復が完了しませんでした。再取得後も再発する場合は通常、上流リポジトリデータまたは linyaps ローカルストレージの互換性修復が必要です。';

  @override
  String get envPartialCommitsUnknown => '一部 partial commits';

  @override
  String envPartialCommitsCount(int count) {
    return '$count 件の partial commits';
  }

  @override
  String envResultLocalDataRepullCompleted(String partialCommits) {
    return 'Linyaps ローカルデータの問題オブジェクトを消去し、$partialCommits を再取得して、再検証に合格しました。';
  }

  @override
  String envResultLocalDataRepullCompletedLegacy(String partialCommits) {
    return 'Linyaps ローカルデータの問題オブジェクトを消去し、$partialCommits を再取得して、再検証に合格しました（旧バージョンのシステムパラメータと互換）。';
  }

  @override
  String envResultLocalDataRepullFailed(String partialCommits) {
    return 'Linyaps ローカルデータの自動処理可能な問題オブジェクトを消去し、$partialCommits の再取得を試みましたが、再取得後も再検証に合格しませんでした。ログで各 ref の取得または再検証の失敗原因をご確認ください。';
  }

  @override
  String envResultLocalDataRepullFailedLegacy(String partialCommits) {
    return 'Linyaps ローカルデータの自動処理可能な問題オブジェクトを消去し、$partialCommits の再取得を試みましたが、再取得後も再検証に合格しませんでした。ログで各 ref の取得または再検証の失敗原因をご確認ください。（旧バージョンのシステムパラメータと互換）';
  }

  @override
  String envResultLocalDataRepullChecksumMismatch(String partialCommits) {
    return 'Linyaps ローカルデータの自動処理可能な問題オブジェクトを消去し、$partialCommits の再取得を試みましたが、再検証でも checksum 不一致が発見されました。上流リポジトリデータと linyaps ローカルストレージモードの非互換の可能性があります。';
  }

  @override
  String envResultLocalDataRepullChecksumMismatchLegacy(String partialCommits) {
    return 'Linyaps ローカルデータの自動処理可能な問題オブジェクトを消去し、$partialCommits の再取得を試みましたが、再検証でも checksum 不一致が発見されました。上流リポジトリデータと linyaps ローカルストレージモードの非互換の可能性があります。（旧バージョンのシステムパラメータと互換）';
  }

  @override
  String envResultStorageBlockedRunningApps(int count) {
    return 'まだ $count 件の Linyaps アプリが実行中です。終了してから保存先を移動してください。';
  }

  @override
  String get envResultStorageBlockedActiveTask =>
      'ダウンロード管理にまだインストールまたは更新タスクがあります。完了を待つかタスクをキャンセルしてから Linyaps の保存先を移動してください。';

  @override
  String envResultStorageBlockedNamedTask(String name) {
    return '現在「$name」を処理中です。完了を待つかタスクをキャンセルしてから Linyaps の保存先を移動してください。';
  }

  @override
  String envResultStorageAlreadyBindMounted(String path) {
    return '$path は既に bind mount されています。先に既存のマウント設定をご確認のうえ移行してください。';
  }

  @override
  String envResultStorageFilesystemUnavailable(String path) {
    return '対象パスのあるファイルシステムの容量を読み取れません: $path';
  }

  @override
  String get envResultStorageSpaceUnknown =>
      '現在のディレクトリまたは対象パスのディスク容量を確認できません。確認してから再試行してください。';

  @override
  String envResultStorageInsufficientSpace(
    String requiredSpace,
    String availableSpace,
  ) {
    return '対象パスの利用可能領域が不足しています。最低 $requiredSpace が必要で、現在利用可能なのは $availableSpace です。';
  }

  @override
  String get envResultStorageTargetNotAbsolute => '対象パスは絶対パスである必要があります。';

  @override
  String get envResultStorageTargetContainsLineBreak =>
      '対象パスに改行文字を含めることはできません。';

  @override
  String get envResultStorageTargetUnsafeSystemPath =>
      '対象パスはシステムのルートディレクトリや現在の Linyaps ディレクトリにすることはできません。';

  @override
  String get envResultStorageTargetInsideCurrentRoot =>
      '対象パスを現在の Linyaps ディレクトリの内部にすることはできません。';

  @override
  String get envResultStorageMoveCompleted => 'Linyaps の保存先を移動しました';

  @override
  String get envResultStorageMoveFailed => 'Linyaps の保存先の移動に失敗しました';

  @override
  String envResultUnexpectedFailure(String error) {
    return '操作に失敗しました: $error';
  }

  @override
  String get errorSolutionHelpTooltip => '解決策を見る';

  @override
  String get a11yErrorSolutionHelp => 'このインストールエラーの解決策を調べる';

  @override
  String get errorSolutionNoSolution => '解決策はまだありません';

  @override
  String get errorSolutionQueryFailed => '照会に失敗しました。再試行してください';

  @override
  String get errorSolutionRetry => '再照会';

  @override
  String get errorSolutionCommunityPost => 'コミュニティに投稿';

  @override
  String get errorSolutionRepair => 'ワンクリック修復';

  @override
  String get errorSolutionClose => '解決策を閉じる';

  @override
  String get errorSolutionRemoteImage => '解決策のリモート画像';

  @override
  String get errorSolutionImageBlocked => '非ネットワーク画像をブロックしました';

  @override
  String get errorSolutionImageLoadFailed => 'リモート画像の読み込みに失敗しました';

  @override
  String get scriptReviewTitle => 'スクリプト内容のプレビュー';

  @override
  String get scriptReviewSemanticLabel => 'まもなく実行される修復スクリプトの全文';

  @override
  String get executeRepairScript => '確認して実行';

  @override
  String get repairExecutionTitle => 'ワンクリック修復';

  @override
  String get repairExecuting => '修復スクリプトを実行中…';

  @override
  String get repairOutputTitle => 'リアルタイム出力';

  @override
  String get repairOutputEmpty => 'スクリプトの出力を待っています…';

  @override
  String repairOutputTruncated(int count) {
    return '画面では古い $count 行を省略しています。全文はログをご確認ください。';
  }

  @override
  String get repairCompleteRetry => '修復が完了しました。再度インストールをお試しください。';

  @override
  String repairFailedWithExitCode(int exitCode) {
    return '修復スクリプトの実行に失敗しました（終了コード $exitCode）。';
  }

  @override
  String get repairTimedOut =>
      '修復スクリプトの実行が 30 分を超えたため、待機を停止しました。ログでシステムの状態をご確認ください。';

  @override
  String repairExecutionError(String message) {
    return '修復スクリプトを実行できません: $message';
  }

  @override
  String get repairInvalidSignature => '修復スクリプトの署名が無効なため、実行をブロックしました。';

  @override
  String get openRepairLog => 'ログディレクトリを開く';

  @override
  String get copyRepairOutput => '現在の出力をコピー';

  @override
  String repairElapsedTime(String elapsed) {
    return '実行時間 $elapsed';
  }
}
