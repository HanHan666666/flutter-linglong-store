# Nightly AUR Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automated `linglong-store-nightly-bin` AUR publish flow to nightly builds while keeping stable/release behavior intact and rendering Nightly-specific user-facing metadata for nightly packages.

**Architecture:** Keep the existing stable release AUR pipeline as the default path and parameterize the packaging/template layer with a stable/nightly channel switch. Reuse the current nightly GitHub prerelease assets as the binary source of truth, then add a nightly-only AUR publish job that computes normalized AUR `pkgver`, validates the generated Arch metadata, and pushes to the nightly AUR repo.

**Tech Stack:** GitHub Actions, Bash packaging scripts, Arch `makepkg`/`namcap`, existing Linux packaging templates, Flutter Linux artifact naming helpers.

---

### Task 1: Add Nightly Channel Metadata Rendering

**Files:**
- Modify: `build/scripts/render-packaging-templates.sh`
- Modify: `build/packaging/linux/linglong-store.desktop.in`
- Modify: `build/packaging/linux/appimage/linglong-store.appdata.xml`
- Test: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`

- [ ] **Step 1: Extend the smoke tests to express missing nightly metadata behavior**

Update the shell smoke coverage so it checks the rendered template outputs rather than only asset renaming:

- `build/scripts/nightly-cli-smoke-test.sh`
  - create a temporary render output dir
  - invoke `build/scripts/render-packaging-templates.sh` in nightly mode
  - assert:
    - desktop file exists as `linglong-store-nightly.desktop`
    - desktop `Name=` contains `Nightly`
    - AppStream `<name>` contains `Nightly`
    - AppStream `<launchable>` points to `linglong-store-nightly.desktop`
- `build/scripts/release-cli-smoke-test.sh`
  - keep stable expectations unchanged
  - assert stable desktop file remains `linglong-store.desktop`

- [ ] **Step 2: Run the smoke tests to verify they fail for the missing nightly render mode**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
bash build/scripts/release-cli-smoke-test.sh
```

Expected:

- nightly smoke test fails because `render-packaging-templates.sh` has no nightly mode and still emits stable names
- release smoke test continues to pass or only fails if stable assumptions were accidentally broken while editing the test

- [ ] **Step 3: Add a channel/variant switch to `render-packaging-templates.sh`**

Implement a parameter such as `--channel stable|nightly` with `stable` as the default. In nightly mode, override only user-visible metadata:

- `display_name="玲珑应用商店社区版 Nightly"`
- `summary_text="Linglong Store Community Edition Nightly"`
- desktop filename variable: `linglong-store-nightly.desktop`
- desktop id / launchable target for AppStream: `linglong-store-nightly.desktop`

Keep unchanged:

- install paths
- executable command
- binary bundle layout
- stable default render behavior

- [ ] **Step 4: Parameterize the desktop and AppStream templates**

Update:

- `build/packaging/linux/linglong-store.desktop.in`
- `build/packaging/linux/appimage/linglong-store.appdata.xml`

to render through variables rather than assuming the stable desktop filename. Add placeholders for:

- desktop filename / launchable id
- display name

Do not duplicate the templates.

- [ ] **Step 5: Re-run smoke tests and confirm stable + nightly render behavior**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
bash build/scripts/release-cli-smoke-test.sh
```

Expected:

- both PASS
- nightly render outputs contain `Nightly`
- stable render outputs remain unchanged

- [ ] **Step 6: Commit the render-mode change**

```bash
git add build/scripts/render-packaging-templates.sh build/packaging/linux/linglong-store.desktop.in build/packaging/linux/appimage/linglong-store.appdata.xml build/scripts/nightly-cli-smoke-test.sh build/scripts/release-cli-smoke-test.sh
git commit -m "feat: 增加 nightly 打包元数据渲染模式"
```

### Task 2: Add Nightly AUR Version Normalization and Template Parameters

**Files:**
- Create: `build/scripts/normalize-nightly-aur-version.sh`
- Modify: `build/packaging/linux/aur/PKGBUILD.in`
- Modify: `build/packaging/linux/aur/linglong-store-bin.changelog.in`
- Modify: `build/scripts/render-packaging-templates.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: Write a shell-level regression check for AUR nightly version normalization**

Extend `build/scripts/nightly-cli-smoke-test.sh` with one small assertion:

- input nightly label: `3.0.2-nightly.20260324+8190b89`
- expected AUR version: `3.0.2_nightly.20260324.8190b89`

Expected command shape:

```bash
actual="$(bash build/scripts/normalize-nightly-aur-version.sh 3.0.2-nightly.20260324+8190b89)"
test "$actual" = "3.0.2_nightly.20260324.8190b89"
```

- [ ] **Step 2: Run the nightly smoke test to verify the new normalization assertion fails**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:

- FAIL because `build/scripts/normalize-nightly-aur-version.sh` does not exist yet

- [ ] **Step 3: Create `build/scripts/normalize-nightly-aur-version.sh`**

Implement a minimal script that:

- accepts one nightly label
- rewrites `-nightly.` to `_nightly.`
- rewrites `+` to `.`
- prints the normalized result
- errors on empty input

- [ ] **Step 4: Parameterize the AUR template for stable/nightly package identity**

Update `build/packaging/linux/aur/PKGBUILD.in` so the following become template variables:

- `pkgname`
- `pkgver`
- `arch`
- `provides`
- `conflicts`
- `changelog` filename
- source URLs/tag root
- desktop filename used in `package()`

Nightly expectations:

- `pkgname=linglong-store-nightly-bin`
- `arch=('x86_64')`
- `conflicts=('linglong-store-bin')`
- `provides=('linglong-store')`
- desktop file installed as `linglong-store-nightly.desktop`

Keep stable expectations intact.

- [ ] **Step 5: Parameterize the AUR changelog template**

Update `build/packaging/linux/aur/linglong-store-bin.changelog.in` so it can render for both:

- stable releases (`v<version>`)
- nightly prereleases (`nightly-<YYYYMMDD>` tag or nightly release download path as chosen in implementation)

Keep this as a single template unless a second nightly template is strictly simpler.

- [ ] **Step 6: Re-run the nightly smoke test and verify AUR version normalization passes**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:

- PASS
- normalized nightly AUR version assertion succeeds

- [ ] **Step 7: Commit the AUR version + template parameterization changes**

```bash
git add build/scripts/normalize-nightly-aur-version.sh build/packaging/linux/aur/PKGBUILD.in build/packaging/linux/aur/linglong-store-bin.changelog.in build/scripts/render-packaging-templates.sh build/scripts/nightly-cli-smoke-test.sh
git commit -m "feat: 支持 nightly AUR 版本与模板渲染"
```

### Task 3: Parameterize AUR Publish and Validate Scripts for Nightly

**Files:**
- Modify: `build/scripts/publish-aur.sh`
- Modify: `build/scripts/validate-aur-package.sh`
- Test: `build/scripts/validate-aur-package.sh`

- [ ] **Step 1: Add a failing nightly-mode validation path to the AUR validator**

Extend `build/scripts/validate-aur-package.sh` to accept parameters such as:

- `--channel stable|nightly`
- `--package-name`
- `--aur-version`

Add nightly assertions that expect:

- `pkgname = linglong-store-nightly-bin`
- `arch = x86_64`
- `conflicts = linglong-store-bin`
- desktop filename rendered as `linglong-store-nightly.desktop`

- [ ] **Step 2: Run the validator in nightly mode to verify it fails before implementation**

Run:

```bash
bash build/scripts/validate-aur-package.sh \
  --version "3.0.2-nightly.20260324+8190b89" \
  --channel nightly \
  --package-name linglong-store-nightly-bin \
  --aur-version "3.0.2_nightly.20260324.8190b89" \
  --sha256-amd64 "deadbeef" \
  --sha256-sig-amd64 "deadbeef" \
  --gpg-key-id "TESTKEY"
```

Expected:

- FAIL before the script supports nightly rendering and single-arch assumptions

- [ ] **Step 3: Implement nightly-aware validation in `build/scripts/validate-aur-package.sh`**

Adjust the validator so that:

- stable defaults remain unchanged
- nightly mode does not require arm64
- package filename lookup and `.SRCINFO` assertions become package-name aware
- nightly mode validates the nightly desktop/metainfo/package metadata

- [ ] **Step 4: Parameterize `build/scripts/publish-aur.sh`**

Add arguments for:

- `--channel`
- `--package-name`
- `--repo-url`
- `--aur-version`

Nightly mode must:

- clone `linglong-store-nightly-bin.git`
- use normalized `pkgver`
- render only `amd64/x86_64`
- write nightly desktop/metainfo/changelog names

Stable mode must continue to work without extra flags.

- [ ] **Step 5: Run stable + nightly AUR validation**

Run:

```bash
bash build/scripts/validate-aur-package.sh --version "3.0.2" --gpg-key-id "TESTKEY" --sha256-amd64 "deadbeef" --sha256-arm64 "deadbeef" --sha256-sig-amd64 "deadbeef" --sha256-sig-arm64 "deadbeef"
bash build/scripts/validate-aur-package.sh --version "3.0.2-nightly.20260324+8190b89" --channel nightly --package-name linglong-store-nightly-bin --aur-version "3.0.2_nightly.20260324.8190b89" --gpg-key-id "TESTKEY" --sha256-amd64 "deadbeef" --sha256-sig-amd64 "deadbeef"
```

Expected:

- stable validation path still behaves as before
- nightly validation path succeeds with nightly-only expectations

- [ ] **Step 6: Commit the publish/validate script changes**

```bash
git add build/scripts/publish-aur.sh build/scripts/validate-aur-package.sh
git commit -m "feat: 增加 nightly AUR 发布与校验参数"
```

### Task 4: Add Nightly AUR Publish Workflow Job

**Files:**
- Modify: `.github/workflows/nightly.yml`
- Test: `build/scripts/validate-release-workflow.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/release-cli-smoke-test.sh`

- [ ] **Step 1: Add a failing workflow structure assertion if needed**

If `build/scripts/validate-release-workflow.sh` currently cannot detect the new nightly AUR job safely, extend it first so the workflow structure is validated after the job is added.

- [ ] **Step 2: Add `publish-aur-nightly` to `.github/workflows/nightly.yml`**

Implement a job that:

- depends on `prepare-nightly` and `publish-nightly`
- only runs when nightly actually published successfully
- downloads the signed nightly assets
- computes:
  - `amd64` tarball SHA256
  - nightly tarball `.asc` SHA256
- normalizes AUR version via `build/scripts/normalize-nightly-aur-version.sh`
- validates the nightly AUR package
- publishes the nightly AUR repo

Use nightly-specific values:

- package name: `linglong-store-nightly-bin`
- repo URL: `ssh://aur@aur.archlinux.org/linglong-store-nightly-bin.git`
- channel: `nightly`
- only `amd64/x86_64`

- [ ] **Step 3: Re-run repository workflow validation**

Run:

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:

- all PASS
- workflow validation still accepts the three-workflow boundary

- [ ] **Step 4: Commit the nightly workflow change**

```bash
git add .github/workflows/nightly.yml build/scripts/validate-release-workflow.sh
git commit -m "feat: 增加 nightly AUR 自动发布流程"
```

### Task 5: Update Docs and Repo Guidance

**Files:**
- Modify: `docs/12-github-workflow-maintenance.md`
- Modify: `AGENTS.md`

- [ ] **Step 1: Document nightly AUR rules**

Update `docs/12-github-workflow-maintenance.md` with:

- nightly AUR package name
- nightly AUR only publishes `x86_64`
- nightly AUR conflicts with stable AUR package
- nightly `pkgver` normalization rule
- nightly desktop/metainfo naming rule
- nightly workflow now includes AUR publish after GitHub prerelease publish

- [ ] **Step 2: Update project memory in `AGENTS.md`**

Add one short rule capturing the invariant:

- `linglong-store-nightly-bin` is a replacement-style nightly AUR package, not a side-by-side install
- nightly user-visible metadata must be rendered as `Nightly`

- [ ] **Step 3: Run the final local verification set**

Run:

```bash
bash build/scripts/validate-release-workflow.sh
bash build/scripts/release-cli-smoke-test.sh
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:

- all PASS with fresh output

- [ ] **Step 4: Commit the docs update**

```bash
git add docs/12-github-workflow-maintenance.md AGENTS.md
git commit -m "docs: 记录 nightly AUR 发布约定"
```

### Task 6: End-to-End Runtime Verification

**Files:**
- Modify: none
- Test: `.github/workflows/nightly.yml`

- [ ] **Step 1: Push the branch or cherry-pick commits onto the target branch for CI verification**

Push the implementation branch or merge it according to the chosen integration workflow.

- [ ] **Step 2: Trigger nightly manually**

Run:

```bash
gh workflow run nightly.yml --ref <target-branch>
```

Expected:

- nightly GitHub prerelease succeeds
- `publish-aur-nightly` starts after `publish-nightly`

- [ ] **Step 3: Inspect GitHub Actions logs and AUR repo result**

Verify:

- nightly AUR validation passed
- `linglong-store-nightly-bin` repo received updated `PKGBUILD` and `.SRCINFO`
- rendered metadata shows `Nightly`

- [ ] **Step 4: Final integration commit(s) if workflow-only fixes are needed**

If CI reveals any runtime-only issue, fix it in isolated commits and rerun the workflow before closing the task.
