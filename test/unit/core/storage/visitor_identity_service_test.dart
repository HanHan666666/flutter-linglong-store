import 'package:flutter_test/flutter_test.dart';
import 'package:linglong_store/core/storage/preferences_service.dart';
import 'package:linglong_store/core/storage/visitor_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 匿名访问标识服务测试。
///
/// 验证既有标识不会发生迁移或替换，并确保首次生成后在后续请求中稳定复用。
void main() {
  const service = VisitorIdentityService();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    if (!PreferencesService.isInitialized) {
      await PreferencesService.init();
    }
  });

  setUp(PreferencesService.clear);

  test('优先复用匿名统计已经保存的 visitorId', () async {
    await PreferencesService.setString(
      VisitorIdentityService.storageKey,
      'existing-visitor-id',
    );

    final visitorId = service.getOrCreateVisitorId();

    expect(visitorId, 'existing-visitor-id');
  });

  test('首次生成后持久化并稳定复用', () async {
    final first = service.getOrCreateVisitorId();
    await Future<void>.delayed(Duration.zero);
    final second = service.getOrCreateVisitorId();

    expect(first, isNotEmpty);
    expect(second, first);
    expect(
      PreferencesService.getString(VisitorIdentityService.storageKey),
      first,
    );
  });
}
