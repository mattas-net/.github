# mattas-net/.github

Shared GitHub Actions workflows, community-health files and ruleset templates for the mattas-net
organization and the amattas repositories.

**The standard lives in [STANDARD.md](STANDARD.md)**: repo classes, caller templates (`checks.yml`,
`release.yml`, `docs.yml`, `docker-build-push.yml`), check naming, triggers, versions and tags, the release
and deployment procedure, policy files, Node and Python version rules, rulesets, and the onboarding
checklist. Ruleset JSON is in [`rulesets/`](rulesets/).

Release in one line: bump the manifest, merge to `main`, then Actions, Release, Run workflow with a
bare-semver version (`1.4.2` or `1.4.2-beta1`, never `v1.4.2`).

Callers reference the reusables as
`uses: mattas-net/.github/.github/workflows/<name>.yml@main`.

## Reusable workflows

Generated from each file's `workflow_call` block. Behavior notes for the non-obvious ones follow the
tables.

### `android-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string |  |  |
| `java-version` | string | `17` |  |
| `flavor` | string |  |  |
| `gradle-tasks` | string |  |  |
| `gradle-args` | string |  |  |
| `rust-core-ref` | string |  |  |

Secrets: `WJM_CORE_DEPLOY_KEY`

Outputs: `check-result`

### `android-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `environment` | string | `Deploy` |  |
| `verify` | boolean | `True` |  |
| `package-name` | string |  | yes |
| `track` | string | `production` |  |
| `prerelease-track` | string | `internal` |  |
| `release-status` | string | `completed` |  |
| `module` | string | `app` |  |
| `flavor` | string |  |  |
| `java-version` | string | `17` |  |
| `version-name-property` | string | `versionName` |  |
| `version-code-property` | string | `versionCode` |  |
| `build-number-property` | string |  |  |
| `gradle-args` | string |  |  |
| `google-services-json` | string |  |  |
| `gradle-tasks` | string |  |  |
| `ci-flavor` | string |  |  |
| `rust-core-ref` | string |  |  |

Secrets: `UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD`, `UPLOAD_KEY_ALIAS`, `UPLOAD_KEY_PASSWORD`, `PLAY_SERVICE_ACCOUNT_JSON`, `WJM_CORE_DEPLOY_KEY`, `GOOGLE_SERVICES_JSON_BASE64`

### `create-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `manifest` | string |  | yes |
| `manifest-key` | string |  |  |
| `require-workflow` | string |  |  |
| `title-prefix` | string |  |  |

Outputs: `tag`, `prerelease`

### `docker-build-push.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string |  |  |
| `build-args` | string |  |  |
| `platforms` | string | `linux/amd64` |  |
| `verify` | boolean | `True` |  |
| `node-version` | string | `22` |  |
| `npm-ci-args` | string | `--ignore-scripts` |  |
| `image-tag` | string |  |  |
| `context` | string | `.` |  |
| `file` | string | `./Dockerfile` |  |
| `path` | string |  |  |
| `extra-repository` | string |  |  |
| `extra-path` | string |  |  |
| `extra-ref-file` | string |  |  |

Secrets: `extra-ssh-key`

### `docs.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  |  |
| `python-version` | string | `3.13` |  |
| `install` | string | `python -m pip install --disable-pip-version-check -r requirements-docs.txt` |  |

### `hacs-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `hacs-ignore` | string | `brands` |  |

### `ios-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string |  |  |
| `platform` | string | `iOS` |  |
| `project-dir` | string | `.` |  |
| `project` | string |  |  |
| `xcodegen` | boolean | `True` |  |
| `xcodegen-version` | string | `2.46.0` |  |
| `xcodegen-sha256` | string | `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806` |  |
| `xcode-version` | string |  |  |
| `xcode-version-file` | string |  |  |
| `package-path` | string |  |  |
| `swift-test-args` | string |  |  |
| `test-commands` | string |  |  |
| `test-env` | string |  |  |
| `lint` | boolean | `True` |  |
| `lint-dir` | string | `.` |  |
| `lint-args` | string |  |  |
| `swiftlint-version` | string | `0.63.3` |  |
| `swiftlint-sha256` | string | `fb045e85e7cb3374f42a4840b6b85a0106302afa69035c0c6f29af4a44c810b6` |  |
| `app-scheme` | string |  | yes |
| `app-build` | boolean | `True` |  |
| `app-build-commands` | string |  |  |
| `app-test` | boolean | `False` |  |
| `app-test-args` | string |  |  |
| `rust-core-ref` | string |  |  |
| `archive-validate` | boolean | `False` |  |
| `archive-scheme` | string |  |  |
| `archive-configuration` | string | `Release` |  |
| `export-options` | string | `ExportOptions.plist` |  |
| `bundle-id` | string |  |  |
| `signing-overrides` | boolean | `False` |  |
| `google-service-info-plist` | string |  |  |

Secrets: `WJM_CORE_DEPLOY_KEY`, `DISTRIBUTION_CERT_P12_BASE64`, `DISTRIBUTION_CERT_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `EXTRA_PROVISIONING_PROFILE_BASE64`, `GOOGLE_SERVICE_INFO_PLIST_BASE64`

Outputs: `test-result`, `lint-result`, `app-build-result`, `app-test-result`

### `ios-release.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `version` | string |  | yes |
| `environment` | string | `Deploy` |  |
| `verify` | boolean | `True` |  |
| `release-check-commands` | string |  |  |
| `scheme` | string |  | yes |
| `configuration` | string | `Release` |  |
| `export-options` | string | `ExportOptions.plist` |  |
| `bundle-id` | string |  |  |
| `signing-overrides` | boolean | `False` |  |
| `google-service-info-plist` | string |  |  |
| `project-dir` | string | `.` |  |
| `project` | string |  |  |
| `xcodegen` | boolean | `True` |  |
| `xcodegen-version` | string | `2.46.0` |  |
| `xcodegen-sha256` | string | `4d9e34b62172d645eed6457cac13fc222569974098ef4ee9c3368bedf0196806` |  |
| `xcode-version` | string |  |  |
| `xcode-version-file` | string |  |  |
| `rust-core-ref` | string |  |  |
| `package-path` | string |  |  |
| `swift-test-args` | string |  |  |
| `test-commands` | string |  |  |
| `test-env` | string |  |  |
| `lint` | boolean | `True` |  |
| `lint-dir` | string | `.` |  |
| `lint-args` | string |  |  |
| `swiftlint-version` | string | `0.63.3` |  |
| `swiftlint-sha256` | string | `fb045e85e7cb3374f42a4840b6b85a0106302afa69035c0c6f29af4a44c810b6` |  |
| `app-scheme` | string |  |  |
| `app-build` | boolean | `True` |  |
| `app-build-commands` | string |  |  |
| `app-test` | boolean | `False` |  |
| `app-test-args` | string |  |  |

Secrets: `DISTRIBUTION_CERT_P12_BASE64`, `DISTRIBUTION_CERT_PASSWORD`, `PROVISIONING_PROFILE_BASE64`, `EXTRA_PROVISIONING_PROFILE_BASE64`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `WJM_CORE_DEPLOY_KEY`, `GOOGLE_SERVICE_INFO_PLIST_BASE64`

### `node-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `node-version` | string | `22` |  |
| `npm-ci-args` | string | `--ignore-scripts` |  |
| `audit-level` | string | `high` |  |

### `python-build.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `ref` | string |  | yes |
| `python-version` | string | `3.12` |  |
| `test` | string |  |  |
| `install` | string | `python -m pip install --quiet -e ".[dev]"` |  |

### `python-ci.yml`

| Input | Type | Default | Required |
|---|---|---|---|
| `python-versions` | string | `["3.12"]` |  |
| `install` | string | `python -m pip install --quiet -e ".[dev]"` |  |
| `lint-paths` | string | `.` |  |
| `extra-lint` | string |  |  |
| `typecheck` | string | `python -m mypy` |  |
| `typecheck-blocking` | boolean | `True` |  |
| `test` | string | `python -m pytest -q` |  |
| `extra-checks` | string |  |  |
| `build` | boolean | `True` |  |
| `actionlint` | boolean | `True` |  |
| `audit-install` | string | `python -m pip install --quiet -e ".[dev]"` |  |
| `audit` | string | `strict` |  |
| `cache-dependency-path` | string | `**/pyproject.toml **/requirements*.txt` |  |


## Notes

- `create-release.yml` reads the version by manifest type: `.json` `.version`; `.toml` the first of
  `[project]`, `[package]`, `[tool.poetry]`, `[workspace.package]` that has a `version`; `.yml`/`.yaml` every
  `<manifest-key>:` line (default `MARKETING_VERSION`), all must agree; `.properties` the
  `<manifest-key>=` line (default `version`).
- `docker-build-push.yml` pushes `ghcr.io/<owner>/<repo>:<tag>` plus `latest` (skipped for pre-releases).
  `image-tag` pushes exactly that tag from any ref with no `latest`. `extra-repository`, `extra-path`,
  `extra-ref-file` and the `extra-ssh-key` secret check out a second repository (we-just-might-server builds
  against we-just-might-core this way; its caller is shown in the we-just-might-server `release.yml`).
- `python-ci.yml` has two jobs: `checks` (matrix over `python-versions`: install, ruff, mypy, pytest, build)
  and `security` (dependency review on PRs, `pip-audit`). `audit` is `strict`, `warn` or `off`.
- `python-build.yml` builds the sdist and wheel, runs `twine check --strict` and fails unless the wheel version
  equals the tag. PyPI publishing stays in the caller (trusted publishing does not work inside a reusable
  workflow).
- `docs.yml` publishes versioned Zensical/mike docs to the caller's `gh-pages` branch via the caller's
  `scripts/publish_versioned_docs.py --push`; the caller job needs `permissions: contents: write`.
- There is no shared CodeQL workflow: every repo uses CodeQL default setup in repository settings, limited to
  real source languages.
- Mobile mechanics (build numbers, signing secrets, store prerequisites) are in
  [STANDARD.md](STANDARD.md#reference-mobile-release-mechanics).

## This repository's checks

`.github/workflows/checks.yml` lints every workflow here with actionlint (release binary pinned by version and
verified against its sha256). Same triggers and `approve` gate as the caller templates. Required check
(default-branch ruleset): `actionlint`.
