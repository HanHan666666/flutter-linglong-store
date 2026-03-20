#!/usr/bin/env bash
set -euo pipefail

snapshot_timestamp="${DEBIAN_SNAPSHOT_TIMESTAMP:-}"
apt_protocol="${DEBIAN_APT_PROTOCOL:-http}"

if [[ "$apt_protocol" != "http" && "$apt_protocol" != "https" ]]; then
  echo "Unsupported DEBIAN_APT_PROTOCOL: $apt_protocol" >&2
  exit 64
fi

write_snapshot_sources() {
  cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] ${apt_protocol}://snapshot.debian.org/archive/debian/${snapshot_timestamp} buster main
deb [check-valid-until=no] ${apt_protocol}://snapshot.debian.org/archive/debian-security/${snapshot_timestamp} buster/updates main
deb [check-valid-until=no] ${apt_protocol}://snapshot.debian.org/archive/debian/${snapshot_timestamp} buster-updates main
EOF
}

write_archive_sources() {
  cat > /etc/apt/sources.list <<EOF
deb [check-valid-until=no] ${apt_protocol}://archive.debian.org/debian buster main
deb [check-valid-until=no] ${apt_protocol}://archive.debian.org/debian-security buster/updates main
deb [check-valid-until=no] ${apt_protocol}://archive.debian.org/debian buster-updates main
EOF
}

cat > /etc/apt/apt.conf.d/99snapshot <<'EOF'
Acquire::Check-Valid-Until "false";
Acquire::Retries "5";
Acquire::By-Hash "no";
Acquire::PDiffs "false";
Acquire::http::Pipeline-Depth "0";
Acquire::https::Pipeline-Depth "0";
Acquire::http::AllowRedirect "true";
Acquire::BrokenProxy "true";
EOF

rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/partial/*
apt-get clean

refresh_apt_indices() {
  rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /var/cache/apt/archives/partial/*
  apt-get clean
  apt-get update -o Acquire::Check-Valid-Until=false
}

if [[ -n "$snapshot_timestamp" ]]; then
  write_snapshot_sources
  if ! refresh_apt_indices; then
    echo "Snapshot Debian 10 indexes failed, falling back to archive.debian.org" >&2
    write_archive_sources
    refresh_apt_indices
  fi
else
  write_archive_sources
  refresh_apt_indices
fi
