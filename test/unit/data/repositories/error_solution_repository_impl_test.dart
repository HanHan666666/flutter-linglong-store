import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/logging/app_logger.dart';
import 'package:linglong_store/data/models/error_solution_dto.dart';
import 'package:linglong_store/data/repositories/error_solution_repository_impl.dart';
import 'package:mockito/mockito.dart';
import 'package:retrofit/retrofit.dart';

import '../../../mocks/mock_classes.mocks.dart';

/// 错误解决方案仓储测试。
///
/// 覆盖未命中、正常映射和协议错误，确保展示层能够可靠地区分“暂无方案”与
/// “查询失败”，并验证仓储不会复用上一次结果。
void main() {
  late MockAppApiService apiService;
  late ErrorSolutionRepositoryImpl repository;

  setUpAll(AppLogger.init);

  setUp(() {
    apiService = MockAppApiService();
    repository = ErrorSolutionRepositoryImpl.withService(apiService);
  });

  test('未命中时返回 null 且透传原始 message 和语言', () async {
    when(apiService.findErrorSolution(any)).thenAnswer(
      (_) async =>
          _response(const ErrorSolutionResponse(code: 200, data: null)),
    );

    final result = await repository.find(
      message: 'RequestInteraction',
      language: 'zh',
    );

    expect(result, isNull);
    final request =
        verify(apiService.findErrorSolution(captureAny)).captured.single
            as ErrorSolutionFindRequest;
    expect(request.message, 'RequestInteraction');
    expect(request.language, 'zh');
  });

  test('每次查询都访问后端并映射 Markdown 与脚本', () async {
    when(apiService.findErrorSolution(any)).thenAnswer(
      (_) async => _response(
        const ErrorSolutionResponse(
          code: 200,
          data: ErrorSolutionDto(
            title: '需要切换软件源',
            markdown: '# 原因\n请检查软件源。',
            repairScript: '#!/usr/bin/env bash\necho ok\n',
            repairScriptSignature: 'signature',
          ),
        ),
      ),
    );

    final first = await repository.find(message: 'same', language: 'zh');
    final second = await repository.find(message: 'same', language: 'zh');

    expect(first?.title, '需要切换软件源');
    expect(first?.markdown, contains('请检查软件源'));
    expect(first?.hasRepairScript, isTrue);
    expect(second?.title, first?.title);
    verify(apiService.findErrorSolution(any)).called(2);
  });

  test('业务状态码异常时抛错而不是伪装成未命中', () async {
    when(apiService.findErrorSolution(any)).thenAnswer(
      (_) async =>
          _response(const ErrorSolutionResponse(code: 500, message: '命中多条规则')),
    );

    expect(
      () => repository.find(message: 'duplicate', language: 'zh'),
      throwsA(isA<StateError>()),
    );
  });
}

/// 构造 Retrofit HTTP 响应。
HttpResponse<ErrorSolutionResponse> _response(ErrorSolutionResponse body) {
  return HttpResponse(
    body,
    Response<void>(
      requestOptions: RequestOptions(path: '/app/error-solution/find'),
    ),
  );
}
