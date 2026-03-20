#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import shutil
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


DEFAULT_GITHUB_REPO = "HanHan666666/flutter-linglong-store"
DEFAULT_GITEE_REPO = "hanplus/flutter-linglong-store"
DEFAULT_MAX_RELEASES = 10
DEFAULT_MAX_FILE_SIZE = 100 * 1024 * 1024
USER_AGENT = "flutter-linglong-store-gitee-sync"


@dataclass(frozen=True)
class SyncConfig:
    github_token: str
    gitee_token: str
    github_repo: str
    gitee_repo: str
    max_releases: int
    max_file_size: int
    temp_dir: Path


def normalize_gitee_repo(value: str) -> str:
    repo = value.strip()
    if not repo:
        raise ValueError("GITEE_REPO is empty")

    if "://" in repo:
        parsed = urllib.parse.urlparse(repo)
        if parsed.netloc != "gitee.com":
            raise ValueError(f"Unsupported Gitee host: {parsed.netloc}")
        repo = parsed.path

    repo = repo.strip("/")
    if repo.endswith(".git"):
        repo = repo[:-4]

    parts = [part for part in repo.split("/") if part]
    if len(parts) != 2:
        raise ValueError(
            "GITEE_REPO must be in owner/repo form or a gitee.com repository URL"
        )

    return "/".join(parts)


def needs_update(github_release: dict[str, Any], gitee_release: dict[str, Any] | None) -> bool:
    if gitee_release is None:
        return True

    github_body = (github_release.get("body") or "").strip()
    gitee_body = (gitee_release.get("body") or "").strip()
    if github_body != gitee_body:
        return True

    github_assets = github_release.get("assets") or []
    gitee_assets = gitee_release.get("assets") or []
    if len(github_assets) != len(gitee_assets):
        return True

    gitee_asset_map = {asset["name"]: asset["size"] for asset in gitee_assets}
    for asset in github_assets:
        if gitee_asset_map.get(asset["name"]) != asset["size"]:
            return True

    return False


def request(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
    timeout: int = 120,
    parse_json: bool = True,
) -> Any:
    request_obj = urllib.request.Request(
        url,
        data=data,
        headers=headers or {},
        method=method,
    )
    with urllib.request.urlopen(request_obj, timeout=timeout) as response:
        payload = response.read()
    if not parse_json:
        return payload
    if not payload:
        return None
    return json.loads(payload.decode("utf-8"))


def github_request(
    config: SyncConfig,
    endpoint: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
    parse_json: bool = True,
) -> Any:
    merged_headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {config.github_token}",
        "User-Agent": USER_AGENT,
    }
    if headers:
        merged_headers.update(headers)
    url = f"https://api.github.com{endpoint}"
    return request(
        url,
        method=method,
        headers=merged_headers,
        data=data,
        parse_json=parse_json,
    )


def gitee_request(
    config: SyncConfig,
    endpoint: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
    parse_json: bool = True,
) -> Any:
    merged_headers = {
        "User-Agent": USER_AGENT,
    }
    if headers:
        merged_headers.update(headers)
    separator = "&" if "?" in endpoint else "?"
    url = f"https://gitee.com/api/v5{endpoint}{separator}access_token={config.gitee_token}"
    return request(
        url,
        method=method,
        headers=merged_headers,
        data=data,
        parse_json=parse_json,
    )


def get_github_releases(config: SyncConfig) -> list[dict[str, Any]]:
    print(
        f"Fetching GitHub releases for {config.github_repo} "
        f"(latest {config.max_releases})..."
    )
    releases = github_request(
        config,
        f"/repos/{config.github_repo}/releases?per_page={config.max_releases}",
    )
    print(f"Found {len(releases)} GitHub releases.")
    return releases


def get_gitee_releases(config: SyncConfig) -> list[dict[str, Any]]:
    print(f"Fetching Gitee releases for {config.gitee_repo}...")
    try:
        releases = gitee_request(
            config,
            f"/repos/{config.gitee_repo}/releases?page=1&per_page=100",
        )
    except urllib.error.HTTPError as error:
        if error.code == 404:
            print("Gitee release list not found yet. Treating as first sync.")
            return []
        raise
    print(f"Found {len(releases)} Gitee releases.")
    return releases


def delete_gitee_release(config: SyncConfig, release_id: int) -> None:
    gitee_request(
        config,
        f"/repos/{config.gitee_repo}/releases/{release_id}",
        method="DELETE",
        parse_json=False,
    )


def create_gitee_release(config: SyncConfig, github_release: dict[str, Any]) -> dict[str, Any]:
    payload = json.dumps(
        {
            "tag_name": github_release["tag_name"],
            "name": github_release.get("name") or github_release["tag_name"],
            "body": github_release.get("body") or "",
            "prerelease": github_release.get("prerelease") or False,
            "target_commitish": github_release.get("target_commitish") or "master",
        }
    ).encode("utf-8")
    return gitee_request(
        config,
        f"/repos/{config.gitee_repo}/releases",
        method="POST",
        headers={"Content-Type": "application/json;charset=UTF-8"},
        data=payload,
    )


def download_asset(config: SyncConfig, asset: dict[str, Any], destination: Path) -> None:
    data = github_request(
        config,
        asset["url"],
        headers={"Accept": "application/octet-stream"},
        parse_json=False,
    )
    destination.write_bytes(data)


def upload_asset_to_gitee_release(
    config: SyncConfig,
    release_id: int,
    asset_path: Path,
) -> None:
    boundary = f"----LinglongBoundary{int(time.time() * 1000)}"
    mime_type = mimetypes.guess_type(asset_path.name)[0] or "application/octet-stream"
    header = (
        f"--{boundary}\r\n"
        f'Content-Disposition: form-data; name="file"; filename="{asset_path.name}"\r\n'
        f"Content-Type: {mime_type}\r\n\r\n"
    ).encode("utf-8")
    footer = f"\r\n--{boundary}--\r\n".encode("utf-8")
    body = header + asset_path.read_bytes() + footer
    gitee_request(
        config,
        f"/repos/{config.gitee_repo}/releases/{release_id}/attach_files",
        method="POST",
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        data=body,
    )


def sync_release(
    config: SyncConfig,
    github_release: dict[str, Any],
    gitee_release: dict[str, Any] | None,
) -> None:
    tag_name = github_release["tag_name"]
    print(f"\nProcessing {tag_name}...")

    if not needs_update(github_release, gitee_release):
        print("  Release is already up to date.")
        return

    if gitee_release is not None:
        print("  Existing Gitee release differs, deleting it first.")
        delete_gitee_release(config, gitee_release["id"])

    try:
        created_release = create_gitee_release(config, github_release)
    except urllib.error.HTTPError as error:
        error_body = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(
            f"Failed to create Gitee release for {tag_name}: {error.code} {error_body}\n"
            "Make sure the matching tag has already been pushed to Gitee."
        ) from error

    print(f"  Created Gitee release #{created_release['id']}.")

    assets = github_release.get("assets") or []
    uploaded_count = 0
    for asset in assets:
        if asset["size"] > config.max_file_size:
            print(
                f"  Skipping {asset['name']} because it exceeds "
                f"{config.max_file_size // (1024 * 1024)} MB."
            )
            continue

        temp_file = config.temp_dir / asset["name"]
        print(f"  Downloading {asset['name']}...")
        download_asset(config, asset, temp_file)

        print(f"  Uploading {asset['name']}...")
        last_error: Exception | None = None
        for attempt in range(1, 4):
            try:
                upload_asset_to_gitee_release(config, created_release["id"], temp_file)
                uploaded_count += 1
                last_error = None
                break
            except Exception as error:  # noqa: BLE001
                last_error = error
                if attempt < 3:
                    print(f"    Upload failed, retrying ({attempt}/3)...")
                    time.sleep(2)
        temp_file.unlink(missing_ok=True)
        if last_error is not None:
            raise RuntimeError(
                f"Failed to upload {asset['name']} after retries: {last_error}"
            ) from last_error

    print(f"  Uploaded {uploaded_count}/{len(assets)} assets.")


def build_config(args: argparse.Namespace) -> SyncConfig:
    github_token = os.environ.get("GITHUB_TOKEN", "").strip()
    gitee_token = os.environ.get("GITEE_TOKEN", "").strip()
    if not github_token or not gitee_token:
        missing = []
        if not github_token:
            missing.append("GITHUB_TOKEN")
        if not gitee_token:
            missing.append("GITEE_TOKEN")
        raise SystemExit(f"Missing required environment variables: {', '.join(missing)}")

    github_repo = (args.github_repo or os.environ.get("GITHUB_REPO") or DEFAULT_GITHUB_REPO).strip()
    gitee_repo = normalize_gitee_repo(
        args.gitee_repo or os.environ.get("GITEE_REPO") or DEFAULT_GITEE_REPO
    )
    temp_dir = Path(tempfile.mkdtemp(prefix="gitee-release-sync-"))
    return SyncConfig(
        github_token=github_token,
        gitee_token=gitee_token,
        github_repo=github_repo,
        gitee_repo=gitee_repo,
        max_releases=args.max_releases,
        max_file_size=args.max_file_size_mb * 1024 * 1024,
        temp_dir=temp_dir,
    )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sync GitHub releases and assets into a Gitee repository."
    )
    parser.add_argument("--github-repo", help="GitHub owner/repo. Defaults to env or current repo.")
    parser.add_argument(
        "--gitee-repo",
        help="Gitee owner/repo or full gitee.com repository URL.",
    )
    parser.add_argument(
        "--max-releases",
        type=int,
        default=DEFAULT_MAX_RELEASES,
        help=f"Maximum number of GitHub releases to sync. Default: {DEFAULT_MAX_RELEASES}.",
    )
    parser.add_argument(
        "--max-file-size-mb",
        type=int,
        default=DEFAULT_MAX_FILE_SIZE // (1024 * 1024),
        help="Skip assets larger than this size in MB.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    config = build_config(args)
    try:
        github_releases = get_github_releases(config)
        gitee_release_map = {
            release["tag_name"]: release for release in get_gitee_releases(config)
        }
        for github_release in github_releases:
            sync_release(
                config,
                github_release,
                gitee_release_map.get(github_release["tag_name"]),
            )
    finally:
        shutil.rmtree(config.temp_dir, ignore_errors=True)
    print("\nSync completed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
