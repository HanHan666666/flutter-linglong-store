# 特权 root helper（docs/47 §4.2/§12）。
#
# 构建约束：
# - 独立最小二进制，不链接 flutter、GTK、Flutter 插件或项目业务动态库；
# - 显式空 install RPATH，禁止继承 GUI 的 `$ORIGIN/lib`；
# - JSON 解析固定使用 vendored nlohmann/json（third_party/nlohmann）。
#
# 该目录既作为父工程的子目录参与 Flutter 构建，也支持被
# build/scripts/test-privileged-helper.sh 独立配置以编译单测。

# 独立配置单测时补齐最小工程头（作为父工程子目录时跳过）。
if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  cmake_minimum_required(VERSION 3.13)
  project(linglong_store_helper_standalone LANGUAGES CXX)
endif()

# --- 主 target：随 Flutter bundle 一起构建并安装到 bundle 的 libexec/ ---
add_executable(linglong_store_helper
  helper_main.cc
  helper_process.cc
  helper_protocol.cc
  helper_task_runner.cc
)
target_compile_features(linglong_store_helper PUBLIC cxx_std_17)
# 与父工程 APPLY_STANDARD_SETTINGS 保持一致；父工程函数不跨独立配置存在，
# 这里显式声明，避免两套口径漂移。
target_compile_options(linglong_store_helper PRIVATE -Wall -Werror)
target_compile_options(linglong_store_helper PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
target_compile_definitions(linglong_store_helper PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
# vendored 头文件按 SYSTEM 引入，避免第三方代码触发 -Wall -Werror。
target_include_directories(linglong_store_helper SYSTEM
  PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/third_party")
# 空 RPATH：helper 只依赖系统 libc，不读取 bundle 的 lib/ 目录。
set_target_properties(linglong_store_helper PROPERTIES
  BUILD_RPATH ""
  INSTALL_RPATH ""
)

# --- 单测 target：默认不构建，由 build/scripts/test-privileged-helper.sh 显式开启 ---
# 只链接纯逻辑模块（协议解析 + 串行状态机）；fork/exec 与 root 检查属于
# 真机验收范围，不进单测。
option(LINGLONG_BUILD_HELPER_TESTS "Build privileged helper unit tests" OFF)
if(LINGLONG_BUILD_HELPER_TESTS)
  add_executable(linglong_store_helper_tests
    helper_protocol.cc
    helper_task_runner.cc
    helper_tests.cc
  )
  target_compile_features(linglong_store_helper_tests PUBLIC cxx_std_17)
  target_compile_options(linglong_store_helper_tests PRIVATE -Wall -Werror)
  target_include_directories(linglong_store_helper_tests SYSTEM
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/third_party")
endif()
