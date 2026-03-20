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


if __name__ == "__main__":
    unittest.main()
