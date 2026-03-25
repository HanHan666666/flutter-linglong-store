# Nightly Release Changelog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an automated changelog section to nightly GitHub prerelease notes while keeping the nightly workflow focused on orchestration and reusing the existing release changelog generation capability.

**Architecture:** Keep `.github/workflows/nightly.yml` responsible only for metadata lookup, job wiring, and publishing. Move nightly release note rendering into a dedicated shell script that composes fixed nightly metadata, a changelog generated from the previous nightly source commit to the current source commit, and the existing download/requirements footer. Reuse the existing Dart changelog CLI through `build/scripts/generate-changelog.sh` instead of duplicating grouping rules in the workflow.

**Tech Stack:** GitHub Actions, Bash release scripts, existing Dart changelog generator, shell smoke tests.

---

### Task 1: Lock down nightly release notes expectations with failing tests

**Files:**
- Modify: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: Extend the nightly smoke test with release-notes assertions**

Add assertions that model the new contract for nightly release notes generation:

- create a temporary git repo fixture with a previous nightly-tagged commit and a new commit range
- invoke the new nightly notes generator script with:
  - nightly label
  - nightly date
  - current source commit
  - previous nightly source commit
- assert the output includes:
  - `## Release Notes`
  - grouped changelog sections such as `## feat`
  - fixed nightly metadata lines (`Nightly source commit`, `Nightly source date`, `Nightly version label`)
  - download / requirements footer
- also assert the no-previous-nightly path emits a clear fallback changelog message

- [ ] **Step 2: Run the nightly smoke test to verify it fails before implementation**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:
- FAIL because the nightly release notes generator script does not exist yet

### Task 2: Add a dedicated nightly release notes generator script

**Files:**
- Create: `build/scripts/generate-nightly-release-notes.sh`
- Modify: `build/scripts/nightly-cli-smoke-test.sh`

- [ ] **Step 1: Create the generator script with strict inputs**

Implement a shell script that accepts explicit parameters:

- `--nightly-label`
- `--nightly-date`
- `--source-commit`
- `--previous-source-commit` (optional)
- `--output`

Behavior:

- validate required inputs and fail fast on missing values
- when `--previous-source-commit` is present, call `build/scripts/generate-changelog.sh "$nightly_label" "$previous_source_commit"`
  - run it from a git checkout where `HEAD` is the current nightly source commit
  - this keeps grouping logic centralized in the existing Dart tool
- when `--previous-source-commit` is absent, write a fallback `## Release Notes` message explaining there is no previous nightly baseline yet
- append the fixed nightly metadata, download section, and requirements section

- [ ] **Step 2: Re-run the nightly smoke test and confirm the script produces the expected content**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
```

Expected:
- PASS for both the changelog path and the fallback path

### Task 3: Wire the nightly workflow to publish generated notes

**Files:**
- Modify: `.github/workflows/nightly.yml`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] **Step 1: Expose the previous nightly source commit from the existing metadata lookup**

Update `prepare-nightly` so `Read existing nightly prerelease` also emits the previously published nightly source commit separately for release-note generation.

Requirements:

- do not break existing rerun / AUR recovery decisions
- keep current outputs used by AUR logic intact
- only add the minimum additional output needed by `publish-nightly`

- [ ] **Step 2: Replace inline heredoc note rendering with the generator script**

In `publish-nightly`:

- keep tag update and release publishing behavior unchanged
- replace the current `cat > nightly-release-notes.md <<EOF` block with a call to `build/scripts/generate-nightly-release-notes.sh`
- pass the current nightly label/date/source commit plus the previous nightly source commit output from `prepare-nightly`
- keep `body_path: nightly-release-notes.md`

- [ ] **Step 3: Verify workflow invariants remain intact**

Run:

```bash
bash build/scripts/validate-release-workflow.sh
```

Expected:
- PASS
- nightly workflow still contains the required publish/AUR structure

### Task 4: Run focused verification and capture final state

**Files:**
- Modify: `docs/12-github-workflow-maintenance.md` (only if the final implementation adds a lasting repository rule worth recording)
- Test: `build/scripts/nightly-cli-smoke-test.sh`
- Test: `build/scripts/validate-release-workflow.sh`

- [ ] **Step 1: Re-run focused verification after all code changes**

Run:

```bash
bash build/scripts/nightly-cli-smoke-test.sh
bash build/scripts/validate-release-workflow.sh
```

Expected:
- both PASS
- nightly release notes include changelog generation coverage and workflow validation remains green

- [ ] **Step 2: Update repo guidance only if a durable convention changed**

If the implementation introduces a lasting rule (for example: nightly release notes must always be generated by the dedicated script and must not be rendered inline in workflow YAML), add a concise entry to the relevant maintenance documentation or repo memory.

- [ ] **Step 3: Request code review and address findings**

Review the final diff before reporting completion, then fix any material issues found.
