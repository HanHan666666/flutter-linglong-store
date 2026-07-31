import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/platform/file_downloader.dart';

/// 可控 Dio 适配器：返回预设内容与状态码，避免 flutter_test 拦截真实 HTTP。
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body, {this.statusCode = 200});

  final List<int> body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody(
      Stream.value(Uint8List.fromList(body)),
      statusCode,
      headers: <String, List<String>>{
        Headers.contentLengthHeader: <String>[body.length.toString()],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

FileDownloader _buildDownloader(_FakeAdapter adapter) {
  return FileDownloader(dio: Dio()..httpClientAdapter = adapter);
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dl_test_');
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // 忽略清理失败。
    }
  });

  test('downloads bytes to destination and reports progress', () async {
    final bytes = utf8.encode('hello world payload');
    final downloader = _buildDownloader(_FakeAdapter(bytes));
    final dest = '${tempDir.path}/out.bin';
    final progressRecords = <(int, int)>[];

    final file = await downloader.downloadToFile(
      url: 'https://example.com/file.bin',
      destinationPath: dest,
      onProgress: (received, total) => progressRecords.add((received, total)),
    );

    expect(await file.readAsBytes(), bytes);
    expect(progressRecords, isNotEmpty);
    expect(progressRecords.last.$1, bytes.length);
    expect(progressRecords.last.$2, bytes.length);
  });

  test('creates parent directories of destination', () async {
    final bytes = utf8.encode('x');
    final downloader = _buildDownloader(_FakeAdapter(bytes));
    final dest = '${tempDir.path}/nested/deep/out.bin';

    final file = await downloader.downloadToFile(
      url: 'https://example.com/file.bin',
      destinationPath: dest,
    );

    expect(file.existsSync(), isTrue);
  });

  test('computeSha256 matches known digest for "abc"', () async {
    final file = File('${tempDir.path}/hash.bin');
    await file.writeAsBytes(utf8.encode('abc'));

    final digest = await computeSha256(file);

    // sha256("abc") 的标准摘要。
    expect(
      digest,
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('throws FileDownloadException on HTTP error', () async {
    final downloader = _buildDownloader(
      _FakeAdapter(utf8.encode('x'), statusCode: 500),
    );

    await expectLater(
      downloader.downloadToFile(
        url: 'https://example.com/fail.bin',
        destinationPath: '${tempDir.path}/fail.bin',
      ),
      throwsA(isA<FileDownloadException>()),
    );
  });
}
