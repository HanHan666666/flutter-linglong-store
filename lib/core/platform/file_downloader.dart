import 'dart:async';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

/// 文件下载异常。
class FileDownloadException implements Exception {
  const FileDownloadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'FileDownloadException: $message';
}

/// 用户取消文件下载。
///
/// 单独类型让 XDG 工作区把 Dio 取消转换为领域取消事件，普通网络错误仍保持原样。
class FileDownloadCancelledException extends FileDownloadException {
  /// 创建下载取消异常。
  const FileDownloadCancelledException({Object? cause})
    : super('下载已取消', cause: cause);
}

/// 通用文件下载器。
///
/// 使用 Dio 流式下载到本地文件，支持进度回调；下载失败统一抛
/// [FileDownloadException]，由调用方决定如何展示。
class FileDownloader {
  FileDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// 下载 [url] 到 [destinationPath]。
  ///
  /// [onProgress] 回调参数为（已接收字节数，总字节数）；总字节数未知时为 -1。
  Future<File> downloadToFile({
    required String url,
    required String destinationPath,
    void Function(int received, int total)? onProgress,
    Future<void>? cancellationSignal,
  }) async {
    final cancelToken = CancelToken();
    if (cancellationSignal != null) {
      unawaited(
        cancellationSignal.then((_) {
          if (!cancelToken.isCancelled) {
            cancelToken.cancel('user-cancelled');
          }
        }),
      );
    }
    try {
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(seconds: 30),
          followRedirects: true,
        ),
        cancelToken: cancelToken,
      );

      final body = response.data;
      if (body == null) {
        throw const FileDownloadException('下载响应为空');
      }

      // Dio 的 contentLength 为非空 int；无 Content-Length 头时为 -1。
      final total = body.contentLength;
      final file = File(destinationPath);
      await file.parent.create(recursive: true);

      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in body.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
      } finally {
        await sink.close();
      }
      return file;
    } on FileDownloadException {
      rethrow;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw FileDownloadCancelledException(cause: e);
      }
      throw FileDownloadException('下载失败: ${e.message}', cause: e);
    } on FileSystemException catch (e) {
      throw FileDownloadException('写入文件失败: ${e.message}', cause: e);
    }
  }
}

/// 计算文件的 SHA-256 摘要（十六进制字符串）。
///
/// 使用增量哈希避免把整个文件读入内存。
Future<String> computeFileSha256(File file) async {
  final sha256 = Sha256();
  final sink = sha256.newHashSink();
  await for (final chunk in file.openRead()) {
    sink.add(chunk);
  }
  sink.close();
  final digest = await sink.hash();
  return digest.bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
}
