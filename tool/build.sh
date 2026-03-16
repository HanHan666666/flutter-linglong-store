#!/usr/bin/env bash
# 构建脚本

set -e

echo "Building Linglong Store..."

# 获取依赖
flutter pub get

# 生成代码
dart run build_runner build --delete-conflicting-outputs

# 构建 Linux 版本
flutter build linux --release

echo "Build complete!"
echo "Output: build/linux/x64/release/bundle/"