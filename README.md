# mattas-net/.github

Shared GitHub Actions workflows, community-health files and ruleset templates for the mattas-net
organization and the amattas repositories.

**The fleet standard lives in the private repo mattas-net/standards** (not readable from this public repo): repo classes, caller templates (`checks.yml`,
`release.yml`, `docs.yml`, `docker-build-push.yml`), check naming, triggers, versions and tags, the release
and deployment procedure, policy files, Node and Python version rules, rulesets, and the onboarding
checklist. Ruleset JSON is in [`rulesets/`](rulesets/).

Release in one line: bump the manifest, merge to `main`, then Actions, Release, Run workflow with a
bare-semver version (`1.4.2` or `1.4.2-beta1`, never `v1.4.2`).

Callers reference the reusables as
`uses: mattas-net/.github/.github/workflows/<name>.yml@main`.

## Reusable workflows

Generated from each file's `workflow_call` block (`""` is an empty-string default). Behavior notes follow the
tables.

### `android-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string | `""` |  |
| `java-version` | string | `17` |  |
| `flavor` | string | `""` |  |
| `gradle-tasks` | string | `""` |  |
| `gradle-args` | string | `""` |  |
| `rust-core-ref` | string | `""` |  |

Secrets: `WJM_CORE_DEPLOY_KEY`

Outputs: `checks-result`, `security-result`, `check-result`

### `android-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `environment` | string | `Deploy` |  |
| `verify` | boolean | `true` |  |
| `package-name` | string |  | yes |
| `track` | string | `production` |  |
| `prerelease-track` | string | `internal` |  |
| `release-status` | string | `completed` |  |
| `module` | string | `app` |  |
| `flavor` | string | `""` |  |
| `java-version` | string | `17` |  |
| `version-name-property` | string | `versionName` |  |
| `version-code-property` | string | `versionCode` |  |
| `build-number-property` | string | `""` |  |
| `gradle-args` | string | `""` |  |
| `google-services-json` | string | `""` |  |
| `gradle-tasks` | string | `""` |  |
| `ci-flavor` | string | `""` |  |
| `rust-core-ref` | string | `""` |  |

Secrets: `UPLOAD_KEYSTORE_BASE64` (required), `UPLOAD_KEYSTORE_PASSWORD` (required), `UPLOAD_KEY_ALIAS` (required), `UPLOAD_KEY_PASSWORD` (required), `PLAY_SERVICE_ACCOUNT_JSON` (environment secret, asserted at runtime), `WJM_CORE_DEPLOY_KEY`, `GOOGLE_SERVICES_JSON_BASE64`

### `create-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `manifest` | string |  | yes |
| `manifest-key` | string | `""` |  |
| `require-workflow` | string | `""` |  |
| `title-prefix` | string | `""` |  |
| `dry-run` | boolean | `false` |  |
| `notes-file` | string | `""` |  |

Outputs: `tag`, `prerelease`

### `docker-build-push.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string | `""` |  |
| `build-args` | string | `""` |  |
| `platforms` | string | `linux/amd64` |  |
| `verify` | boolean | `true` |  |
| `node-version` | string | `24` |  |
| `npm-ci-args` | string | `--ignore-scripts` |  |
| `image-tag` | string | `""` |  |
| `context` | string | `.` |  |
| `file` | string | `./Dockerfile` |  |
| `path` | string | `""` |  |
| `extra-repository` | string | `""` |  |
| `extra-path` | string | `""` |  |
| `extra-ref-file` | string | `""` |  |
| `push` | boolean | `true` |  |

Secrets: `extra-ssh-key`

### `docs.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string | `""` |  |
| `python-version` | string | `3.14` |  |
| `install` | string | `python -m pip install --disable-pip-version-check -r requirements-docs.txt` |  |
| `working-directory` | string | `.` |  |
| `dry-run` | boolean | `false` |  |

### `fuzz-batch.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `language` | string |  | yes |
| `fuzz-seconds` | number | `3600` |  |

### `hacs-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `hacs-ignore` | string | `brands` |  |

Outputs: `checks-result`, `security-result`

### `infra-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `terraform-dirs` | string | `terraform` |  |
| `helm-dirs` | string | `kubernetes/helm` |  |

Outputs: `checks-result`, `security-result`

### `ios-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string | `""` |  |
| `platform` | string | `iOS` |  |
| `project-dir` | string | `.` |  |
| `project` | string | `""` |  |
| `xcodegen` | boolean | `true` |  |
| `xcodegen-version` | string | `2.46.0` |  |
| `xcodegen-sha256` | string | `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806` |  |
| `xcode-version` | string | `""` |  |
| `xcode-version-file` | string | `""` |  |
| `package-path` | string | `""` |  |
| `swift-test-args` | string | `""` |  |
| `test-commands` | string | `""` |  |
| `test-env` | string | `""` |  |
| `lint` | boolean | `true` |  |
| `lint-dir` | string | `.` |  |
| `lint-args` | string | `""` |  |
| `swiftlint-version` | string | `0.63.3` |  |
| `swiftlint-sha256` | string | `fb045e85e7cb3374f42a4840b6b85a0106302afa69035c0c6f29af4a44c810b6` |  |
| `app-scheme` | string |  | yes |
| `app-build` | boolean | `true` |  |
| `app-build-commands` | string | `""` |  |
| `app-test` | boolean | `false` |  |
| `app-test-args` | string | `""` |  |
| `rust-core-ref` | string | `""` |  |
| `archive-validate` | boolean | `false` |  |
| `archive-scheme` | string | `""` |  |
| `archive-configuration` | string | `Release` |  |
| `export-options` | string | `ExportOptions.plist` |  |
| `bundle-id` | string | `""` |  |
| `signing-overrides` | boolean | `false` |  |
| `google-service-info-plist` | string | `""` |  |

Secrets: `WJM_CORE_DEPLOY_KEY`, `DISTRIBUTION_CERT_P12_BASE64`, `DISTRIBUTION_CERT_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `EXTRA_PROVISIONING_PROFILE_BASE64`, `GOOGLE_SERVICE_INFO_PLIST_BASE64`

Outputs: `checks-result`, `security-result`, `test-result`, `lint-result`, `app-build-result`, `app-test-result`

### `ios-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `environment` | string | `Deploy` |  |
| `verify` | boolean | `true` |  |
| `release-check-commands` | string | `""` |  |
| `scheme` | string |  | yes |
| `configuration` | string | `Release` |  |
| `export-options` | string | `ExportOptions.plist` |  |
| `bundle-id` | string | `""` |  |
| `signing-overrides` | boolean | `false` |  |
| `google-service-info-plist` | string | `""` |  |
| `project-dir` | string | `.` |  |
| `project` | string | `""` |  |
| `xcodegen` | boolean | `true` |  |
| `xcodegen-version` | string | `2.46.0` |  |
| `xcodegen-sha256` | string | `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806` |  |
| `xcode-version` | string | `""` |  |
| `xcode-version-file` | string | `""` |  |
| `rust-core-ref` | string | `""` |  |
| `package-path` | string | `""` |  |
| `swift-test-args` | string | `""` |  |
| `test-commands` | string | `""` |  |
| `test-env` | string | `""` |  |
| `lint` | boolean | `true` |  |
| `lint-dir` | string | `.` |  |
| `lint-args` | string | `""` |  |
| `swiftlint-version` | string | `0.63.3` |  |
| `swiftlint-sha256` | string | `fb045e85e7cb3374f42a4840b6b85a0106302afa69035c0c6f29af4a44c810b6` |  |
| `app-scheme` | string | `""` |  |
| `app-build` | boolean | `true` |  |
| `app-build-commands` | string | `""` |  |
| `app-test` | boolean | `false` |  |
| `app-test-args` | string | `""` |  |

Secrets: `DISTRIBUTION_CERT_P12_BASE64` (required), `DISTRIBUTION_CERT_PASSWORD` (required), `PROVISIONING_PROFILE_BASE64` (required), `EXTRA_PROVISIONING_PROFILE_BASE64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (environment secrets, asserted at runtime), `WJM_CORE_DEPLOY_KEY`, `GOOGLE_SERVICE_INFO_PLIST_BASE64`

### `node-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `working-directory` | string | `.` |  |
| `node-version` | string | `24` |  |
| `npm-ci-args` | string | `--ignore-scripts` |  |
| `audit-level` | string | `high` |  |

Outputs: `checks-result`, `security-result`

### `python-build.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string |  | yes |
| `python-version` | string | `3.12` |  |
| `test` | string | `""` |  |
| `install` | string | `python -m pip install --quiet -e ".[dev]"` |  |

### `python-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `working-directory` | string | `.` |  |
| `python-versions` | string | `["3.12"]` |  |
| `install` | string | `python -m pip install --quiet -e ".[dev]"` |  |
| `lint-paths` | string | `.` |  |
| `extra-lint` | string | `""` |  |
| `typecheck` | string | `python -m mypy` |  |
| `typecheck-blocking` | boolean | `true` |  |
| `test` | string | `python -m pytest -q` |  |
| `extra-checks` | string | `""` |  |
| `build` | boolean | `true` |  |
| `actionlint` | boolean | `true` |  |
| `audit-install` | string | `python -m pip install --quiet -e ".[dev]"` |  |
| `audit` | string | `strict` |  |
| `cache-dependency-path` | string | `**/pyproject.toml
**/requirements*.txt
` |  |
| `fuzz` | boolean | `false` |  |
| `fuzz-seconds` | number | `600` |  |

Outputs: `checks-result`, `security-result`

### `rust-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `working-directory` | string | `.` |  |
| `toolchain` | string | `stable` |  |
| `features` | string | `""` |  |
| `test` | string | `cargo test --locked` |  |
| `extra-checks` | string | `""` |  |
| `macos` | boolean | `false` |  |
| `macos-commands` | string | `cargo test --locked` |  |
| `fuzz` | boolean | `false` |  |
| `fuzz-seconds` | number | `600` |  |

Outputs: `checks-result`, `security-result`

## Notes

- Every CI reusable (`python-ci`, `node-ci`, `hacs-ci`, `ios-ci`, `android-ci`, `rust-ci`, `infra-ci`) exposes
  `checks-result` and `security-result`. Callers end `checks.yml` with two alias jobs named `checks` and
  `security` that assert those outputs equal `success`, so rulesets require exactly those two contexts (alias
  block: fleet standard, mattas-net/standards (private), `docs/ci-cd/ci-workflows.md`). `android-ci`'s `check-result` is a deprecated alias of `checks-result`
  (removed in WP-2d); `ios-ci` also keeps its per-step outputs.
- `create-release.yml` reads the version by manifest type: `.json` `.version`; `.toml` the first of
  `[project]`, `[package]`, `[tool.poetry]`, `[workspace.package]` that has a `version`; `.yml`/`.yaml` every
  `<manifest-key>:` line (default `MARKETING_VERSION`), all must agree; `.properties` the
  `<manifest-key>=` line (default `version`). `dry-run` runs every check and tags locally, then prints the push
  and the release instead of doing them; `notes-file` is a repo path whose copy at the tag becomes the release
  notes (generated notes when absent).
- `docker-build-push.yml` pushes `ghcr.io/<owner>/<repo>:<tag>` plus `latest` (skipped when the tag contains `-`, i.e. pre-releases; a dispatch rebuild of a stable tag therefore moves `latest` too).
  `image-tag` pushes exactly that tag from any ref with no `latest`. `push: false` builds only: no registry login,
  nothing pushed, no `latest` (used by the self-test). `extra-repository`, `extra-path`,
  `extra-ref-file` and the `extra-ssh-key` secret check out a second repository (we-just-might-server builds
  against we-just-might-core this way; its caller is shown in the we-just-might-server `release.yml`).
- `node-ci.yml` jobs: `checks` (lint, typecheck, test, each `--if-present`) and `security` (`npm audit`, dependency
  review on PRs). `node-version` must equal `.nvmrc` and the Dockerfile `ARG NODE_VERSION`.
- `python-ci.yml` jobs: `checks` (matrix over `python-versions`: install, ruff, mypy, pytest, build), `security`
  (dependency review on PRs, `pip-audit`) and `matrix-result`, which turns the matrix result into
  `checks-result`. `audit` is `strict`, `warn` or `off`.
- `rust-ci.yml` jobs: `checks` (fmt, clippy `-D warnings`, test), optional `macos`, and `security` (cargo-deny).
  `infra-ci.yml` jobs: `terraform`, `helm`, `shellcheck` and `security` (trivy config); the tools are pinned,
  sha256-verified binaries.
- Fuzzing (`fuzz: true` on `python-ci` / `rust-ci`) adds a `fuzz` job that runs on pull requests only:
  ClusterFuzzLite (`google/clusterfuzzlite/actions/build_fuzzers` and `run_fuzzers`, SHA-pinned) builds the
  caller's `.clusterfuzzlite/` targets with AddressSanitizer and fuzzes them in `code-change` mode.
  `security-result` is `success` only when `security` passed and, when the fuzz job runs, `fuzz` passed too;
  with `fuzz` off, or on push and dispatch runs, the job is skipped and does not affect it, so there is no new
  required check. The actions clone the repo themselves with `github.token` (no checkout step); there is no
  SARIF upload, and crash inputs are uploaded as workflow artifacts.
- `fuzz-seconds` is per target (default `600` in `python-ci` / `rust-ci`, `3600` in `fuzz-batch`).
  ClusterFuzzLite's own `fuzz-seconds` is one total split across the targets, so after the build a step
  counts the targets in `build-out` with run_fuzzers' discovery rule (oss-fuzz `infra/utils.py`
  `is_fuzz_target_local`: name minus an optional `.exe` matching `^[A-Za-z0-9_-]+$`, not `jazzer_driver*`,
  executable, and either ending in `_fuzzer` or containing `LLVMFuzzerTestOneInput`) and passes
  per-target × count. No targets fails the job. Both jobs use the hosted-runner maximum of 360 minutes, and
  the total is clamped to 19800 s (330 minutes, leaving build headroom); a clamped run emits a warning with
  the requested and effective per-target seconds (e.g. six batch targets at `3600` get 3300 s each).
- Fuzz-job permissions: ClusterFuzzLite needs `contents: read` to clone and `actions: read` to find earlier
  batch runs' corpus and build artifacts (without it that lookup fails, logged and not fatal, and fuzzing
  starts from the seed corpus). A called job cannot be granted more than the calling job, and GitHub checks
  that when it loads the workflow, even for jobs an `if:` skips. So the `fuzz` job in `python-ci` / `rust-ci`
  has no `permissions` block and inherits the calling job's token (existing callers are unaffected), and a
  caller that sets `fuzz: true` must grant both on the calling job:

  ```yaml
  ci:
    permissions:
      contents: read
      actions: read
    uses: mattas-net/.github/.github/workflows/rust-ci.yml@main
    with:
      fuzz: true
  ```

  `fuzz-batch.yml` requests `contents: read` and `actions: read` itself, so its caller job must grant both too.
- `fuzz-batch.yml` is the deep run: the same build in `batch` mode, `language` `rust` or `python` (must match
  `.clusterfuzzlite/project.yaml`). Callers dispatch it from a `fuzz.yml` named `Fuzz`
  (`on: workflow_dispatch` only).
- Exception to SHA pinning: the ClusterFuzzLite actions are pinned by commit, but they run the Docker images
  `gcr.io/oss-fuzz-base/clusterfuzzlite-build-fuzzers:v1` and `clusterfuzzlite-run-fuzzers:v1` (and the
  `:ubuntu-24-04-v1` variants they pivot to) by tag, which Google can move. Pinning them by digest would
  need a fork of the actions, so the unpinned images are an accepted exception.
- `python-build.yml` builds the sdist and wheel, runs `twine check --strict` and fails unless the wheel version
  equals the tag. PyPI publishing stays in the caller (trusted publishing does not work inside a reusable
  workflow).
- `docs.yml` publishes versioned Zensical/mike docs to the caller's `gh-pages` branch via the caller's
  `scripts/publish_versioned_docs.py --push`; the caller job needs `permissions: contents: write`. With
  `dry-run` it builds the triggering ref with `zensical build --clean --strict` and publishes nothing.
- `working-directory` (where present) runs the reusable against a subdirectory; this repository's self-test uses
  it to exercise each reusable on `tests/fixtures/<class>/`.
- There is no shared CodeQL workflow: every repo uses CodeQL default setup in repository settings, limited to
  real source languages.
- `rust-core-ref` (`ios-ci`, `ios-release`, `android-ci`, `android-release`) builds the private
  mattas-net/we-just-might-core with this repository's composite actions `.github/actions/wjm-core-ios` and
  `.github/actions/wjm-core-android`: they check out the pinned core SHA with the `WJM_CORE_DEPLOY_KEY` deploy
  key into `../we-just-might-core` and run its `scripts/build-ios.sh` / `scripts/build-android.sh`, so the
  core only has to keep those scripts and `rust-toolchain.toml` working.
- Mobile mechanics (build numbers, signing secrets, store prerequisites) are in
  the fleet standard (mattas-net/standards, private), `docs/ci-cd/mobile-release.md`.

## This repository's checks

`.github/workflows/checks.yml` runs `actionlint` over every workflow here (release binary pinned by version and
verified against its sha256) and a `self-test` job that calls reusables from the PR ref against `tests/fixtures/`,
so a broken reusable fails here before callers pick it up from `@main`. Same triggers and `approve` gate as the
caller templates. Required checks (org ruleset): `checks` and `security`, aliases over `actionlint`, `self-test`
and the self-test security results.

Self-tested on fixtures:

| Reusable | Fixture / mode |
|---|---|
| `python-ci`, `node-ci`, `rust-ci` | `tests/fixtures/<class>/` |
| `docs` | `tests/fixtures/docs`, `dry-run: true` |
| `infra-ci` | `tests/fixtures/infra` (`terraform-dirs`, `helm-dirs`; a shell script) |
| `create-release` | `dry-run: true`, version `0.0.0`, manifest `tests/fixtures/node/package.json` (read from `main`, so the fixture must exist there; the `0.0.0` tag must not) |
| `docker-build-push` | `tests/fixtures/docker`, `push: false`, `image-tag: selftest` |
| `ios-release`, `android-release` | parse only: `yq` asserts the `on.workflow_call` inputs and secrets blocks (plus `actionlint` over every workflow); they need signing secrets |

Not self-tested (gaps):

- `ios-ci`: no Swift fixture under `tests/fixtures/`, and every job runs on macOS runners. The core build step
  (`.github/actions/wjm-core-ios`, only when `rust-core-ref` is set) now lives in this repository, so it no
  longer blocks a call from here; a SwiftPM fixture (`swift test` + SwiftLint) gated to `ios-*` changes would
  close the gap.
- `android-ci`: needs a Gradle project at the repository root (no `working-directory` input).
- `hacs-ci`: hassfest and the HACS action validate the repository root, which has no `custom_components/`.
- `python-build`: builds the repository root and requires `ref` to be a published tag equal to the built version.
- The signing, upload and store-submission paths of `ios-release` and `android-release`.
- The `fuzz` job of `python-ci` / `rust-ci` and `fuzz-batch`: the fixtures have no `.clusterfuzzlite/`, so the
  self-test runs with `fuzz` off (the job is skipped).
