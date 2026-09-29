#!/usr/bin/env bash
# Nightly GitHub Release 与 AUR 共用的 tag 规则；新发布按北京时间月份滚动，历史日 tag 仅用于手动恢复。

# 将 Nightly 的北京时间日期映射为当月唯一可更新的 Release tag。
nightly_release_tag_from_date() {
  local nightly_date="$1"

  if [[ ! "$nightly_date" =~ ^[0-9]{8}$ ]]; then
    echo "Invalid nightly date: $nightly_date" >&2
    return 64
  fi

  printf 'nightly-%s\n' "${nightly_date:0:6}"
}

# 从资产版本标签解析 tag；显式覆盖只允许同一日期的历史日 tag 或所属月份的月 tag。
nightly_release_tag_for_label() {
  local nightly_label="$1"
  local requested_tag="${LINGLONG_NIGHTLY_RELEASE_TAG:-}"
  local nightly_date=""

  if [[ ! "$nightly_label" =~ -nightly\.([0-9]{8})\+[0-9A-Fa-f]+$ ]]; then
    echo "Invalid nightly version label: $nightly_label" >&2
    return 64
  fi
  nightly_date="${BASH_REMATCH[1]}"

  if [[ -z "$requested_tag" ]]; then
    nightly_release_tag_from_date "$nightly_date"
    return
  fi

  if [[ "$requested_tag" != "nightly-${nightly_date:0:6}" \
    && "$requested_tag" != "nightly-$nightly_date" ]]; then
    echo "Nightly release tag $requested_tag does not match version label $nightly_label" >&2
    return 64
  fi

  printf '%s\n' "$requested_tag"
}
