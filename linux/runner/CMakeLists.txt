cmake_minimum_required(VERSION 3.13)

# 本目录支持两种配置形态：
# 1. 作为 Flutter 父工程（linux/CMakeLists.txt）的子目录：构建 runner 主程序；
# 2. 由 build/scripts/test-system-accent-color.sh 独立配置：只构建系统强调色
#    纯逻辑单测，此时不存在 BINARY_NAME、flutter target 等父工程变量，
#    主程序段落整体跳过，测试 target 通过 PkgConfig 链接 GLib/GIO。
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  project(linglong_store_accent_color_tests_standalone LANGUAGES CXX)
  set(LINGLONG_RUNNER_STANDALONE ON)
else()
  project(runner LANGUAGES CXX)
  set(LINGLONG_RUNNER_STANDALONE OFF)
endif()

if(NOT LINGLONG_RUNNER_STANDALONE)
# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "system_notification_channel.cc"
  "system_accent_color_channel.cc"
  "system_accent_color_portal.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# 检测当前 Flutter SDK 是否提供 Impeller 开关 API（fl_dart_project_set_enable_impeller，
# Flutter 3.47+ 才引入）。龙芯构建锁定的 3.46 SDK 既没有该 API、引擎也没有 Impeller，
# 因此通过扫描引擎头文件生成编译宏，让同一份 runner 代码在两套 SDK 下都能编译，
# my_application.cc 中的禁用调用必须由该宏保护。
set(FLUTTER_DART_PROJECT_HEADER
    "${FLUTTER_MANAGED_DIR}/ephemeral/flutter_linux/fl_dart_project.h")
if(EXISTS "${FLUTTER_DART_PROJECT_HEADER}")
  file(STRINGS "${FLUTTER_DART_PROJECT_HEADER}" impeller_switch_api_line
       REGEX "fl_dart_project_set_enable_impeller")
  if(impeller_switch_api_line)
    target_compile_definitions(${BINARY_NAME} PRIVATE
        FLUTTER_SDK_HAS_IMPELLER_SWITCH=1)
    message(STATUS "Flutter SDK provides Impeller switch API; runner will disable Impeller")
  else()
    message(STATUS "Flutter SDK has no Impeller switch API; skipping Impeller disable call")
  endif()
endif()

# Add dependency libraries. Add any application-specific dependencies here.
# GTK is already linked through the flutter target, no need to link again.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
endif()

# --- 系统强调色纯逻辑单测：默认不构建，由脚本显式开启 ---
# 只编译 system_accent_color_portal.cc（纯 GLib/GIO，禁止依赖 flutter/GTK），
# 保证解析/校验逻辑可以脱离 Flutter 构建链路独立验证（docs/48 §12.4）。
option(LINGLONG_BUILD_ACCENT_COLOR_TESTS
       "Build system accent color portal unit tests" OFF)
if(LINGLONG_BUILD_ACCENT_COLOR_TESTS)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(ACCENT_COLOR_GLIB REQUIRED IMPORTED_TARGET
                   glib-2.0 gio-2.0)
  add_executable(linglong_store_accent_color_tests
    system_accent_color_portal.cc
    system_accent_color_tests.cc
  )
  target_compile_features(linglong_store_accent_color_tests PUBLIC cxx_std_17)
  # 编译选项与特权 helper 测试保持同一口径，保证告警即错误。
  target_compile_options(linglong_store_accent_color_tests PRIVATE -Wall -Werror)
  target_link_libraries(linglong_store_accent_color_tests
                        PRIVATE PkgConfig::ACCENT_COLOR_GLIB)
endif()
