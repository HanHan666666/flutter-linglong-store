cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "system_notification_channel.cc"
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
