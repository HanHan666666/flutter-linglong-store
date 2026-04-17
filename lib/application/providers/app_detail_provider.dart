import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../domain/models/installed_app.dart';
import '../../../domain/models/app_detail.dart' as dm;
import '../../../domain/models/app_comment.dart' as dm;
import '../../../domain/models/app_version.dart' as dm;
import '../../../data/repositories/app_repository_impl.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/di/providers.dart';

part 'app_detail_provider.g.dart';

/// 应用详情状态
class AppDetailState {
  const AppDetailState({
    this.app,
    this.appDetail,
    this.screenshots = const [],
    this.comments = const [],
    this.versions = const [],
    this.isLoading = false,
    this.isLoadingComments = false,
    this.isLoadingVersions = false,
    this.commentsError,
    this.versionsError,
    this.error,
    this.isSubmittingComment = false,
    this.isDescriptionExpanded = false,
    this.isVersionListExpanded = false,
  });

  final InstalledApp? app;
  final dm.AppDetail? appDetail;
  final List<dm.AppScreenshot> screenshots;
  final List<dm.AppComment> comments;
  final List<dm.AppVersion> versions;
  final bool isLoading;
  final bool isLoadingComments;
  final bool isLoadingVersions;
  final String? commentsError;
  final String? versionsError;
  final String? error;
  final bool isSubmittingComment;
  final bool isDescriptionExpanded;
  final bool isVersionListExpanded;

  /// 获取截图 URL 列表
  List<String> get screenshotUrls => screenshots.map((s) => s.url).toList();

  AppDetailState copyWith({
    InstalledApp? app,
    dm.AppDetail? appDetail,
    List<dm.AppScreenshot>? screenshots,
    List<dm.AppComment>? comments,
    List<dm.AppVersion>? versions,
    bool? isLoading,
    bool? isLoadingComments,
    bool? isLoadingVersions,
    String? commentsError,
    String? versionsError,
    String? error,
    bool? isSubmittingComment,
    bool? isDescriptionExpanded,
    bool? isVersionListExpanded,
    bool clearError = false,
    bool clearCommentsError = false,
    bool clearVersionsError = false,
    bool clearAppDetail = false,
  }) {
    return AppDetailState(
      app: app ?? this.app,
      appDetail: clearAppDetail ? null : (appDetail ?? this.appDetail),
      screenshots: screenshots ?? this.screenshots,
      comments: comments ?? this.comments,
      versions: versions ?? this.versions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isLoadingVersions: isLoadingVersions ?? this.isLoadingVersions,
      commentsError: clearCommentsError
          ? null
          : (commentsError ?? this.commentsError),
      versionsError: clearVersionsError
          ? null
          : (versionsError ?? this.versionsError),
      error: clearError ? null : (error ?? this.error),
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      isDescriptionExpanded:
          isDescriptionExpanded ?? this.isDescriptionExpanded,
      isVersionListExpanded:
          isVersionListExpanded ?? this.isVersionListExpanded,
    );
  }
}

/// 应用详情 Provider
@riverpod
class AppDetail extends _$AppDetail {
  @override
  AppDetailState build(String appId) {
    return const AppDetailState();
  }

  /// 加载应用详情
  ///
  /// [initialApp] 可选的初始应用信息，从列表页传递时可用于快速显示
  Future<void> loadDetail(InstalledApp? initialApp) async {
    // 如果有初始数据，先显示
    if (initialApp != null) {
      state = AppDetailState(app: initialApp);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final repository = ref.read(appRepositoryProvider);

      // 调用真实 API 获取应用详情
      final appDetail = await repository.getAppDetail(appId);

      // 将详情转换为 InstalledApp 模型
      final repo = ref.read(appRepositoryProvider) as AppRepositoryImpl;
      final app = repo.mapDetailToInstalledAppFromDomain(appDetail);

      // 更新状态，包含截图列表
      state = state.copyWith(
        app: app,
        appDetail: appDetail,
        screenshots: appDetail.screenshots,
        isLoading: false,
        clearCommentsError: true,
        clearVersionsError: true,
      );

      // 评论区在版本列表之前展示，优先等待评论加载完成，版本列表继续异步补齐。
      await _loadComments();
      _loadVersions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadComments() async {
    state = state.copyWith(isLoadingComments: true, clearCommentsError: true);

    try {
      final repository = ref.read(appRepositoryProvider);
      final comments = await repository.getAppComments(appId);
      state = state.copyWith(
        comments: comments,
        isLoadingComments: false,
        clearCommentsError: true,
      );
    } catch (e) {
      AppLogger.warning('[AppDetail] 评论列表加载失败: $appId - $e');
      state = state.copyWith(
        isLoadingComments: false,
        commentsError: e.toString(),
      );
    }
  }

  /// 加载版本历史列表
  Future<void> _loadVersions() async {
    state = state.copyWith(isLoadingVersions: true, clearVersionsError: true);

    try {
      final repository = ref.read(appRepositoryProvider);
      final versions = await repository.getVersions(
        appId,
        // 版本列表接口必须沿用详情页当前应用的仓库与架构，避免后端默认值查到错误仓库。
        repoName: state.appDetail?.repoName ?? state.app?.repoName,
        arch: state.appDetail?.arch ?? state.app?.arch,
      );

      state = state.copyWith(
        versions: versions,
        isLoadingVersions: false,
        clearVersionsError: true,
      );
    } catch (e) {
      // 版本列表失败不阻塞详情页主体，但要保留轻量错误态供用户重试和排查。
      AppLogger.warning('[AppDetail] 版本历史加载失败: $appId - $e');
      state = state.copyWith(
        isLoadingVersions: false,
        versionsError: e.toString(),
      );
    }
  }

  /// 刷新详情
  Future<void> refresh() async {
    await loadDetail(null);
  }

  /// 仅重试版本列表，避免因为局部失败重置整个详情页主体。
  Future<void> retryVersions() async {
    await _loadVersions();
  }

  Future<void> retryComments() async {
    await _loadComments();
  }

  Future<void> submitComment(String remark, {String? version}) async {
    final normalizedRemark = remark.trim();
    if (normalizedRemark.isEmpty) {
      return;
    }

    state = state.copyWith(isSubmittingComment: true, clearCommentsError: true);

    try {
      final repository = ref.read(appRepositoryProvider);
      final success = await repository.saveAppComment(
        appId: appId,
        remark: normalizedRemark,
        version: version,
      );
      if (!success) {
        throw Exception('评论提交失败');
      }

      final comments = await repository.getAppComments(appId);
      state = state.copyWith(
        comments: comments,
        isLoadingComments: false,
        isSubmittingComment: false,
        clearCommentsError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isSubmittingComment: false,
        commentsError: e.toString(),
      );
      rethrow;
    }
  }

  /// 切换描述展开状态
  void toggleDescription() {
    state = state.copyWith(isDescriptionExpanded: !state.isDescriptionExpanded);
  }

  /// 切换版本列表展开状态
  void toggleVersionList() {
    state = state.copyWith(isVersionListExpanded: !state.isVersionListExpanded);
  }
}
