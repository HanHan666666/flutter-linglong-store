import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

const String kScreenshotPreviewWindowType = 'screenshot_preview';
const String kScreenshotPreviewUpdateMethod = 'preview_update';
const String kScreenshotPreviewActivateMethod = 'preview_activate';
const String kScreenshotPreviewCloseMethod = 'window_close';

/// 截图预览子窗口的启动/更新参数。
class ScreenshotPreviewWindowPayload {
  const ScreenshotPreviewWindowPayload({
    required this.screenshots,
    required this.initialIndex,
    required this.localeTag,
    required this.isDarkMode,
    this.type = kScreenshotPreviewWindowType,
  });

  final String type;
  final List<String> screenshots;
  final int initialIndex;
  final String localeTag;
  final bool isDarkMode;

  Locale get locale => Locale(localeTag);

  ScreenshotPreviewWindowPayload copyWith({
    String? type,
    List<String>? screenshots,
    int? initialIndex,
    String? localeTag,
    bool? isDarkMode,
  }) {
    return ScreenshotPreviewWindowPayload(
      type: type ?? this.type,
      screenshots: screenshots ?? this.screenshots,
      initialIndex: initialIndex ?? this.initialIndex,
      localeTag: localeTag ?? this.localeTag,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'screenshots': screenshots,
      'initialIndex': initialIndex,
      'localeTag': localeTag,
      'isDarkMode': isDarkMode,
    };
  }

  String toArguments() => jsonEncode(toJson());

  static ScreenshotPreviewWindowPayload? tryParseArguments(String arguments) {
    try {
      final decoded = jsonDecode(arguments);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return tryParseJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static ScreenshotPreviewWindowPayload? tryParseJson(
    Map<String, dynamic> map,
  ) {
    final type = map['type'];
    final screenshots = map['screenshots'];
    final initialIndex = map['initialIndex'];
    final localeTag = map['localeTag'];
    final isDarkMode = map['isDarkMode'];

    if (type is! String ||
        screenshots is! List ||
        initialIndex is! int ||
        localeTag is! String ||
        isDarkMode is! bool) {
      return null;
    }

    final screenshotList = screenshots.whereType<String>().toList(
      growable: false,
    );
    if (screenshotList.length != screenshots.length) {
      return null;
    }

    if (type != kScreenshotPreviewWindowType) {
      return null;
    }

    if (screenshotList.isEmpty ||
        initialIndex < 0 ||
        initialIndex >= screenshotList.length) {
      return null;
    }

    return ScreenshotPreviewWindowPayload(
      type: type,
      screenshots: screenshotList,
      initialIndex: initialIndex,
      localeTag: localeTag,
      isDarkMode: isDarkMode,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ScreenshotPreviewWindowPayload &&
        other.type == type &&
        listEquals(other.screenshots, screenshots) &&
        other.initialIndex == initialIndex &&
        other.localeTag == localeTag &&
        other.isDarkMode == isDarkMode;
  }

  @override
  int get hashCode => Object.hash(
    type,
    Object.hashAll(screenshots),
    initialIndex,
    localeTag,
    isDarkMode,
  );
}
