#!/usr/bin/env bash
# 重放 Flutter/Dart 生成器并验证所有生成源码已经完整提交。
#
# 该脚本只检查生成源码路径，不会把调用者正在开发的普通业务文件误判为生成漂移。
# 生成器升级或注解、ARB 变更后，应先更新生成物并与输入源码一起提交。

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DART_BIN="${DART_BIN:-dart}"
FLUTTER_BIN="${FLUTTER_BIN:-flutter}"

generated_pathspecs=(
  ":(glob)**/*.g.dart"
  ":(glob)**/*.freezed.dart"
  ":(glob)**/*.mocks.dart"
  "lib/core/i18n/l10n/app_localizations.dart"
  ":(glob)lib/core/i18n/l10n/app_localizations_*.dart"
  "linux/generated/application_identity.cmake"
)

cd "$ROOT_DIR"

"$DART_BIN" run build_runner build --delete-conflicting-outputs
"$FLUTTER_BIN" gen-l10n
bash build/scripts/generate-application-identity.sh --check

generated_status="$(
  git status \
    --porcelain=v1 \
    --untracked-files=all \
    -- \
    "${generated_pathspecs[@]}"
)"

if [[ -n "$generated_status" ]]; then
  printf '%s\n' \
    "生成源码与当前提交不一致：" \
    "$generated_status" \
    "" \
    "请重新执行 build/scripts/verify-generated-sources.sh，审查并提交上述生成文件。" \
    >&2
  exit 1
fi

printf 'generated source verification passed\n'
