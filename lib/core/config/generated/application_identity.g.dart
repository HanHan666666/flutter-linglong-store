/// Linux 应用身份的编译期常量。
///
/// 本文件由 build/scripts/generate-application-identity.sh 根据
/// config/application_identity.conf 生成，请勿手工修改。
library;

/// 为 Dart 运行时提供与 Linux 构建、打包完全一致的应用身份。
abstract final class ApplicationIdentity {
  /// GLib、XDG 数据命名空间共同使用的主应用 ID。
  static const String applicationId = 'com.dongpl.linglong-store.v2';

  /// Freedesktop/AppStream 使用的 canonical desktop ID。
  static const String canonicalDesktopId =
      'com.dongpl.linglong-store.v2.desktop';

  /// Linux runner 与 Dart 端共同使用的系统通知 MethodChannel。
  static const String systemNotificationChannel =
      'com.dongpl.linglong-store.v2/system_notification';

  /// Linux runner 与 Dart 端共同使用的系统强调色 EventChannel。
  static const String systemAccentColorChannel =
      'com.dongpl.linglong-store.v2/system_accent_color';

  /// Stable 包保留的隐藏 desktop 兼容入口。
  static const List<String> stableCompatDesktopIds = <String>[
    'linglong-store.desktop',
  ];

  /// Nightly 包保留的隐藏 desktop 兼容入口。
  static const List<String> nightlyCompatDesktopIds = <String>[
    'linglong-store-nightly.desktop',
  ];
}
