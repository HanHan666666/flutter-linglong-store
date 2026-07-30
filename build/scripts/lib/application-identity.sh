#!/usr/bin/env bash
# Linux 应用身份配置的严格读取器。
#
# 业务定位：
#   为构建、打包、发布和维护脚本提供同一套应用身份，不允许各脚本复制
#   application ID 或 desktop ID。配置按数据解析，禁止通过 source/eval 执行。
#
# 调用约束：
#   每个进程只调用一次 load_application_identity；成功后身份变量会被设为
#   全局只读，防止脚本后续阶段意外覆盖已经校验的构建身份。

# 输出身份配置错误。78 对应 EX_CONFIG，便于 CI 区分配置错误和普通构建失败。
_application_identity_fail() {
  printf '应用身份配置错误: %s\n' "$1" >&2
  return 78
}

# 输出指定发行渠道的兼容 desktop ID，每行一个。
#
# 调用方必须先成功执行 load_application_identity。逐行接口避免消费者自行
# 解析逗号列表，也为一个渠道保留多个历史别名提供稳定边界。
application_identity_compat_desktop_ids() {
  if [[ "$#" -ne 1 ]]; then
    _application_identity_fail '兼容 desktop ID 查询必须提供一个发行渠道'
    return 78
  fi

  local encoded_ids
  case "$1" in
    stable)
      encoded_ids="$STABLE_COMPAT_DESKTOP_IDS"
      ;;
    nightly)
      encoded_ids="$NIGHTLY_COMPAT_DESKTOP_IDS"
      ;;
    *)
      _application_identity_fail "不支持的发行渠道: $1"
      return 78
      ;;
  esac

  local -a desktop_ids=()
  IFS=',' read -r -a desktop_ids <<<"$encoded_ids"
  printf '%s\n' "${desktop_ids[@]}"
}

# 从声明文件加载并校验应用身份。
#
# 参数允许 smoke 测试传入隔离配置；生产调用应传仓库中的
# config/application_identity.conf。解析过程不展开变量、不执行命令。
load_application_identity() {
  if [[ "$#" -ne 1 || -z "$1" ]]; then
    _application_identity_fail 'load_application_identity 必须提供配置文件路径'
    return 78
  fi

  local config_path="$1"
  if [[ ! -f "$config_path" ]]; then
    _application_identity_fail "找不到配置文件: $config_path"
    return 78
  fi

  local line=""
  local line_number=0
  local key=""
  local value=""
  local -A values=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi

    if [[ "$line" != *=* || "$line" == =* ]]; then
      _application_identity_fail "${config_path}:${line_number} 必须使用 KEY=VALUE 格式"
      return 78
    fi

    key="${line%%=*}"
    value="${line#*=}"
    if [[ ! "$key" =~ ^[A-Z][A-Z0-9_]*$ || -z "$value" ]]; then
      _application_identity_fail "${config_path}:${line_number} 包含非法字段或空值"
      return 78
    fi

    case "$key" in
      APPLICATION_ID|STABLE_COMPAT_DESKTOP_IDS|NIGHTLY_COMPAT_DESKTOP_IDS)
        ;;
      *)
        _application_identity_fail "${config_path}:${line_number} 包含未知字段 $key"
        return 78
        ;;
    esac

    if [[ -n "${values[$key]+present}" ]]; then
      _application_identity_fail "${config_path}:${line_number} 重复定义字段 $key"
      return 78
    fi
    values["$key"]="$value"
  done <"$config_path"

  local required_key
  for required_key in \
    APPLICATION_ID \
    STABLE_COMPAT_DESKTOP_IDS \
    NIGHTLY_COMPAT_DESKTOP_IDS; do
    if [[ -z "${values[$required_key]+present}" ]]; then
      _application_identity_fail "$config_path 缺少字段 $required_key"
      return 78
    fi
  done

  local application_id="${values[APPLICATION_ID]}"
  if [[ "${#application_id}" -gt 255 ||
        ! "$application_id" =~ ^[A-Za-z][A-Za-z0-9_-]*(\.[A-Za-z][A-Za-z0-9_-]*)+$ ]]; then
    _application_identity_fail "APPLICATION_ID 不符合反向 DNS/GLib 标识格式: $application_id"
    return 78
  fi

  local canonical_desktop_id="${application_id}.desktop"
  local stable_ids="${values[STABLE_COMPAT_DESKTOP_IDS]}"
  local nightly_ids="${values[NIGHTLY_COMPAT_DESKTOP_IDS]}"
  local encoded_ids
  local channel
  local desktop_id
  local -a parsed_ids=()
  local -A seen_desktop_ids=()

  for channel in stable nightly; do
    if [[ "$channel" == "stable" ]]; then
      encoded_ids="$stable_ids"
    else
      encoded_ids="$nightly_ids"
    fi

    if [[ "$encoded_ids" == ,* || "$encoded_ids" == *, ||
          "$encoded_ids" == *,,* ]]; then
      _application_identity_fail "${channel} 兼容 desktop ID 列表包含空项"
      return 78
    fi

    parsed_ids=()
    IFS=',' read -r -a parsed_ids <<<"$encoded_ids"
    if [[ "${#parsed_ids[@]}" -eq 0 ]]; then
      _application_identity_fail "${channel} 至少需要一个兼容 desktop ID"
      return 78
    fi

    for desktop_id in "${parsed_ids[@]}"; do
      if [[ ! "$desktop_id" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.desktop$ ]]; then
        _application_identity_fail "${channel} 兼容 desktop ID 非法: $desktop_id"
        return 78
      fi
      if [[ "$desktop_id" == "$canonical_desktop_id" ]]; then
        _application_identity_fail "兼容 desktop ID 不能等于 canonical desktop ID: $desktop_id"
        return 78
      fi
      if [[ -n "${seen_desktop_ids[$desktop_id]+present}" ]]; then
        _application_identity_fail "兼容 desktop ID 重复: $desktop_id"
        return 78
      fi
      seen_desktop_ids["$desktop_id"]="$channel"
    done
  done

  # 这些变量是所有脚本消费者的只读契约；派生值不再进入人工配置。
  declare -gr APPLICATION_ID="$application_id"
  declare -gr CANONICAL_DESKTOP_ID="$canonical_desktop_id"
  declare -gr STABLE_COMPAT_DESKTOP_IDS="$stable_ids"
  declare -gr NIGHTLY_COMPAT_DESKTOP_IDS="$nightly_ids"
  declare -gr WM_CLASS="$application_id"
  declare -gr SYSTEM_NOTIFICATION_CHANNEL="${application_id}/system_notification"
}
