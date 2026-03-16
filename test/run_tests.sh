#!/bin/bash

# 玲珑应用商店测试运行脚本
# 使用方法: ./run_tests.sh [选项]
#
# 选项:
#   unit      - 运行单元测试
#   widget    - 运行 Widget 测试
#   golden    - 运行 Golden 测试
#   all       - 运行所有测试
#   coverage  - 运行测试并生成覆盖率报告

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}玲珑应用商店测试运行器${NC}"
echo "================================"

# 检查 Flutter 是否安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: Flutter 未安装或未在 PATH 中${NC}"
    echo "请先安装 Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# 获取项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 解析参数
TEST_TYPE=${1:-all}

case $TEST_TYPE in
    unit)
        echo -e "${YELLOW}运行单元测试...${NC}"
        flutter test test/unit/ --reporter=expanded
        ;;
    widget)
        echo -e "${YELLOW}运行 Widget 测试...${NC}"
        flutter test test/widget/ --reporter=expanded
        ;;
    golden)
        echo -e "${YELLOW}运行 Golden 测试...${NC}"
        flutter test test/golden/ --reporter=expanded
        ;;
    coverage)
        echo -e "${YELLOW}运行测试并生成覆盖率报告...${NC}"
        flutter test --coverage
        if command -v lcov &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html
            echo -e "${GREEN}覆盖率报告已生成: coverage/html/index.html${NC}"
        else
            echo -e "${YELLOW}lcov 未安装，跳过 HTML 报告生成${NC}"
            echo "覆盖率数据已保存到: coverage/lcov.info"
        fi
        ;;
    all)
        echo -e "${YELLOW}运行所有测试...${NC}"
        flutter test --reporter=expanded
        ;;
    *)
        echo -e "${RED}未知选项: $TEST_TYPE${NC}"
        echo "可用选项: unit, widget, golden, all, coverage"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}测试完成!${NC}"