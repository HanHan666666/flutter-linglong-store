import importlib.util
import pathlib
import sys
import unittest


MODULE_PATH = (
    pathlib.Path(__file__).resolve().parents[4]
    / "tool"
    / "release"
    / "sync_github_release_to_gitee.py"
)


def load_module():
    spec = importlib.util.spec_from_file_location(
        "sync_github_release_to_gitee",
        MODULE_PATH,
    )
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class SyncGithubReleaseToGiteeTests(unittest.TestCase):
    def test_normalize_gitee_repo_accepts_owner_repo_and_url(self):
        module = load_module()

        self.assertEqual(
            module.normalize_gitee_repo("hanplus/flutter-linglong-store"),
            "hanplus/flutter-linglong-store",
        )
        self.assertEqual(
            module.normalize_gitee_repo(
                "https://gitee.com/hanplus/flutter-linglong-store.git"
            ),
            "hanplus/flutter-linglong-store",
        )

    def test_needs_update_detects_body_and_asset_changes(self):
        module = load_module()

        github_release = {
            "body": "new body",
            "assets": [{"name": "a.deb", "size": 12}],
        }
        gitee_release = {
            "body": "old body",
            "assets": [{"name": "a.deb", "size": 12}],
        }
        self.assertTrue(module.needs_update(github_release, gitee_release))

        gitee_release = {
            "body": "new body",
            "assets": [{"name": "a.deb", "size": 11}],
        }
        self.assertTrue(module.needs_update(github_release, gitee_release))

        gitee_release = {
            "body": "new body",
            "assets": [{"name": "a.deb", "size": 12}],
        }
        self.assertFalse(module.needs_update(github_release, gitee_release))

    def test_needs_update_ignores_gitee_generated_source_archives(self):
        module = load_module()

        github_release = {
            "tag_name": "v3.0.2",
            "body": "new body",
            "assets": [{"name": "a.deb", "size": 12}],
        }
        gitee_release = {
            "tag_name": "v3.0.2",
            "body": "new body",
            "assets": [
                {"name": "v3.0.2.zip", "size": None},
                {"name": "v3.0.2.tar.gz", "size": None},
                {"name": "a.deb", "size": 12},
            ],
        }

        self.assertFalse(module.needs_update(github_release, gitee_release))

    def test_needs_update_accepts_gitee_assets_without_size_field(self):
        module = load_module()

        github_release = {
            "tag_name": "v3.0.2",
            "body": "new body",
            "assets": [{"name": "a.deb", "size": 12}],
        }
        gitee_release = {
            "tag_name": "v3.0.2",
            "body": "new body",
            "assets": [{"name": "a.deb"}],
        }

        self.assertFalse(module.needs_update(github_release, gitee_release))

    def test_resolve_api_url_keeps_absolute_asset_urls(self):
        module = load_module()

        self.assertEqual(
            module.resolve_api_url(
                "https://api.github.com",
                "https://api.github.com/repos/test/releases/assets/1",
            ),
            "https://api.github.com/repos/test/releases/assets/1",
        )
        self.assertEqual(
            module.resolve_api_url("https://api.github.com", "/repos/test/releases"),
            "https://api.github.com/repos/test/releases",
        )

    def test_release_asset_download_url_prefers_browser_download_url(self):
        module = load_module()

        self.assertEqual(
            module.release_asset_download_url(
                {
                    "url": "https://api.github.com/repos/test/releases/assets/1",
                    "browser_download_url": "https://github.com/test/releases/download/v1/a.deb",
                }
            ),
            "https://github.com/test/releases/download/v1/a.deb",
        )


if __name__ == "__main__":
    unittest.main()
