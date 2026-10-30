# mattas-net/.github

Shared GitHub Actions for the mattas-net organization. Every project follows
the same release flow:

1. Push to `main` → the repo's checks workflow runs automatically.
2. Bump the version in the manifest (`package.json`, `pyproject.toml`,
   `manifest.json`; for mobile apps the XcodeGen `project.yml` or
   `gradle.properties`), merge to `main`.
3. Actions → Release → Run workflow → enter the version (bare semver: `1.4.2`
   or `1.4.2-beta1`, never `v1.4.2`).
4. `create-release.yml` verifies the manifest on `main` matches, that no tag
   exists, and that the checks passed on `main` HEAD; then it tags `main`,
   creates the GitHub Release, and the caller chains the build/publish job.

Nothing is tagged when a check fails, so fix the manifest and re-run.

## Workflows

### create-release.yml

`workflow_call` inputs: `version` (required), `manifest` (required path),
`manifest-key`, `require-workflow` (name of the checks workflow; empty skips
the gate), `title-prefix`. Outputs `tag` and `prerelease`.

Version lookup by manifest type:

| Manifest | Read from |
|---|---|
| `.json` | `.version` |
| `.toml` | `[project]`, `[package]` or `[tool.poetry]` `version` |
| `.yml` / `.yaml` | every `<manifest-key>:` line (default `MARKETING_VERSION`) at any indentation, so top level or nested under `settings`/`targets`; all must agree. A pre-release `1.4.2-beta1` matches `1.4.2`, because App Store versions are numeric. |
| `.properties` | the `<manifest-key>=` line (default `version`), e.g. `wjm.versionName`. Like the iOS manifest it holds `X.Y.Z`: a pre-release `1.4.2-beta1` matches `1.4.2`. |

### node-ci.yml

Lint / typecheck / test (each `--if-present`) and
`npm audit --omit=dev --audit-level=<audit-level>`. Inputs: `node-version`
(22), `npm-ci-args` (`--ignore-scripts`), `audit-level` (high).

### docker-build-push.yml

Builds the Dockerfile and pushes `ghcr.io/mattas-net/<repo>:<tag>` plus
`latest` (skipped for pre-release tags). Inputs: `ref` (tag to build; empty
means the run was dispatched from a tag), `build-args`, `platforms`
(`linux/amd64`; QEMU is set up for others), `verify` (run node-ci first),
`node-version`, `npm-ci-args`.

### docs.yml

Builds every documented version with Zensical and publishes the versioned
site (mike) to the caller's `gh-pages` branch by running the caller's
`scripts/publish_versioned_docs.py --push`: `dev` = `main`, `X.Y` = newest
patch tag of each documented minor line, `latest` = highest stable release.
Job `publish` checks out `main` with full history (every release tag is
rebuilt from its own sources), installs the tools, sets the
`github-actions[bot]` author and a token remote, and publishes under
job-level concurrency `docs-gh-pages` (never cancelled). Public repos serve
`gh-pages` with Pages; private repos build it and keep Pages disabled.
Inputs: `version` (informational; release.yml passes it), `python-version`
(`3.13`), `install`
(`python -m pip install --disable-pip-version-check -r requirements-docs.txt`).
The caller job needs `permissions: contents: write`.

`.github/workflows/docs.yml` (every documented repo; only `with:` overrides
may differ)

```yaml
name: Docs
on:
  push:
    branches: [main]
  workflow_dispatch:
  workflow_call:
    inputs:
      version:
        description: Release version that triggered the publish (informational)
        type: string
        default: ""
permissions:
  contents: read
jobs:
  docs:
    uses: mattas-net/.github/.github/workflows/docs.yml@main
    permissions:
      contents: write # the publish script pushes the gh-pages branch
    with:
      version: ${{ inputs.version }}
```

`release.yml` ends with a job that republishes after tagging:

```yaml
  docs:
    needs: release
    uses: ./.github/workflows/docs.yml
    permissions:
      contents: write
    with:
      version: ${{ inputs.version }}
```

## Caller templates

`.github/workflows/checks.yml` — automatic on push to main; on pull requests
the run waits at the `approve` job (no runner minutes) until a required
reviewer approves it in the repo's `approval` environment, which is what lets
the ruleset's required `node / checks` attach to the PR. A manually dispatched
run does not attach to a PR, so it cannot satisfy the gate.

```yaml
name: Checks
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
concurrency:
  group: checks-${{ github.ref }}
  cancel-in-progress: true
jobs:
  approve:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    environment: approval
    steps:
      - run: echo "Checks approved by ${GITHUB_TRIGGERING_ACTOR}"
  node:
    needs: approve
    if: always() && needs.approve.result != 'failure' && needs.approve.result != 'cancelled'
    uses: mattas-net/.github/.github/workflows/node-ci.yml@main
    permissions:
      contents: read
```

`.github/workflows/release.yml`

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: Version to release (bare semver, e.g. 1.4.2)
        required: true
        type: string
jobs:
  release:
    uses: mattas-net/.github/.github/workflows/create-release.yml@main
    permissions:
      contents: write
      actions: read
    with:
      version: ${{ inputs.version }}
      manifest: package.json
      require-workflow: Checks
  image:
    needs: release
    uses: mattas-net/.github/.github/workflows/docker-build-push.yml@main
    permissions:
      contents: read
      packages: write
    with:
      ref: ${{ inputs.version }}
      verify: false
```

`.github/workflows/docker-build-push.yml` (manual rebuild of an existing tag)

```yaml
name: Rebuild Docker Image
on:
  workflow_dispatch:
jobs:
  image:
    uses: mattas-net/.github/.github/workflows/docker-build-push.yml@main
    permissions:
      contents: read
      packages: write
```

Used by: mattas-net-next, anthonymattas-com-next, adhdbytes-com-next,
law18-app-next, we-just-might-next, mattas-net-strapi; calendar-mcp,
homeassistant-mcp, ics-combiner, todoist-mcp, hass-dmp, pydmp.

## Python (PyPI libraries, MCP servers) and Home Assistant (HACS)

Same release flow. Ruff is the one linter and formatter in every Python repo
(`ruff check` + `ruff format --check`; Home Assistant core's toolset), plus
mypy and pytest. Manifest: `pyproject.toml` `[project].version` for libraries
and MCP servers, `custom_components/<domain>/manifest.json` `version` for HACS
integrations (HACS installs from GitHub Releases, so the release is the
publish step).

### python-ci.yml

Jobs: `checks` (matrix over `python-versions`: install, ruff, `extra-lint`,
actionlint on the first matrix entry, `typecheck`, `test`, `extra-checks`,
`python -m build` + `twine check` when twine is installed) and `security`
(dependency review on pull requests, then `pip-audit --strict` over `pip freeze --exclude-editable` after
`audit-install`, which installs the project editable so an unreleased version
is never looked up on PyPI). Inputs: `python-versions`
(`'["3.12"]'`), `install`, `lint-paths` (`.`), `extra-lint`, `typecheck`
(`python -m mypy`; empty skips), `typecheck-blocking` (true), `test`
(`python -m pytest -q`), `extra-checks`, `build` (true), `actionlint` (true),
`audit-install`, `audit` (`strict` | `warn` | `off`), `cache-dependency-path`
(`**/pyproject.toml` and `**/requirements*.txt`; setup-python fails when no
file matches).

### CodeQL

There is no shared CodeQL workflow: every repo uses CodeQL default setup
(repository settings), with languages limited to real source code. Callers do
not add a `codeql` job.

### python-build.yml

Checks out the release tag, builds the sdist and wheel, runs
`twine check --strict`, fails unless the wheel's version equals the tag
(PEP 440), and uploads the `dist` artifact. Inputs: `ref` (required),
`python-version`, `test` / `install` (optional re-test on the tag).

PyPI trusted publishing does not work from inside a reusable workflow, so
the publish job stays in the caller's `release.yml`; register the PyPI
trusted publisher (or pending publisher, for a new project) for workflow
`release.yml`, environment `pypi`.

### hacs-ci.yml

Jobs `hassfest` and `hacs` (`hacs/action`, category `integration`). Input:
`hacs-ignore` (`brands`). The HACS check also needs the repository to be
public with a description, topics and issues enabled.

### Python caller templates

`.github/workflows/checks.yml` (library or MCP server)

```yaml
name: Checks
on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
concurrency:
  group: checks-${{ github.ref }}
  cancel-in-progress: true
permissions:
  contents: read
jobs:
  approve:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    environment: approval
    steps:
      - run: echo "Checks approved by ${GITHUB_TRIGGERING_ACTOR}"
  python:
    needs: approve
    if: always() && needs.approve.result != 'failure' && needs.approve.result != 'cancelled'
    uses: mattas-net/.github/.github/workflows/python-ci.yml@main
    permissions:
      contents: read
    with:
      python-versions: '["3.12", "3.13"]'
```

A HACS integration adds a nightly `schedule` trigger and a second job:

```yaml
  hacs:
    needs: approve
    if: always() && needs.approve.result != 'failure' && needs.approve.result != 'cancelled'
    uses: mattas-net/.github/.github/workflows/hacs-ci.yml@main
    permissions:
      contents: read
```

with `python` installing `-r requirements.test.txt`, `build: false` and
`audit: off` (the pinned Home Assistant test environment is not actionable;
dependency review still runs on PRs).

`.github/workflows/release.yml` (PyPI library)

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: Version to release (bare semver, e.g. 1.4.2)
        required: true
        type: string
permissions:
  contents: read
jobs:
  release:
    uses: mattas-net/.github/.github/workflows/create-release.yml@main
    permissions:
      contents: write
      actions: read
    with:
      version: ${{ inputs.version }}
      manifest: pyproject.toml
      require-workflow: Checks
  build:
    needs: release
    uses: mattas-net/.github/.github/workflows/python-build.yml@main
    permissions:
      contents: read
    with:
      ref: ${{ inputs.version }}
  publish:
    needs: build
    runs-on: ubuntu-24.04
    environment: pypi # must match the PyPI trusted publisher
    permissions:
      contents: write # attach the files to the release
      id-token: write # trusted publishing
      attestations: write
    steps:
      - uses: actions/download-artifact@9000827ccba6bdab643e8b6fd33ac0654aef8333 # v8.0.2
        with:
          name: dist
          path: dist/
      - uses: actions/attest-build-provenance@4d101475d8b20a2381f78447822ac1eab6504dd8 # v4.2.2
        with:
          subject-path: dist/*
      - uses: pypa/gh-action-pypi-publish@7245906fb61fa33a13554f9d5fb856fe61758086 # v1.14.3
      - env:
          GH_TOKEN: ${{ github.token }}
          TAG: ${{ inputs.version }}
        run: gh release upload "$TAG" dist/* --repo "$GITHUB_REPOSITORY"
```

A HACS integration's `release.yml` is the `release` job alone with
`manifest: custom_components/<domain>/manifest.json`.

Used by: pydmp, aioddp, pyminleon, hass-dmp, hass-ddp, calendar-mcp,
homeassistant-mcp, ics-combiner.

## Mobile

The iOS and Android apps use the same release flow: bump the manifest,
merge, then Actions → Release → Run workflow with the version.
`create-release.yml` tags `main` and creates the GitHub Release, then the
platform job builds that tag, uploads it to the store and attaches the binary
to the release.

- **Tags** are bare semver: `1.4.2`, or a pre-release such as `1.4.2-beta1`,
  never `v1.4.2`.
- **Build number** (iOS `CURRENT_PROJECT_VERSION`, Android `versionCode`) is
  not derived from the version. It is `YYYYMMDD*100 + NN`: the UTC date this
  release was published (its GitHub Release `publishedAt`), and NN (01–99) is
  its 1-based position among the repository's GitHub Releases published that
  UTC date, ordered by publishedAt. `create-release.yml` publishes the release
  before the platform job runs, so the first release on 2026-10-29 builds as
  `2026102901`, the second as `2026102902`, and the next day starts at
  `2026103001`. Numbers only grow, and there is no special value for a final
  release: whatever was released most recently is the one that ships,
  pre-release or not.
  - Every run for the same tag, the same day or any later day, recomputes the
    same number, because releases published after it sort after it. Deleting
    an earlier release of that date shifts the count down and can repeat a
    number.
  - On Android, a rerun after a successful Play upload is rejected by Play for
    the repeated versionCode.
  - A 100th release in one UTC date fails.

  No build-number tags are pushed and nothing is committed: the release
  workflow stamps the numbers on the runner only.
- **Pre-release** versions (hyphen suffix) go to TestFlight / the Play
  `internal` track only. Stable versions go to App Store Connect (TestFlight;
  review submission stays a manual step) and to the Play track the caller
  names.
- **Marketing version / versionName** is the tag's `X.Y.Z` on both platforms
  (App Store versions cannot carry a suffix), so the manifest for
  `1.4.2-beta1` holds `1.4.2`.
- **CI** runs on macOS runners, so it never runs on push. Pull requests wait
  at the `approve` job until a reviewer approves the `approval` environment;
  `workflow_dispatch` runs it on any branch. The release workflow always runs
  the checks on the tag before archiving, and that is why the mobile callers
  pass `require-workflow: ""`.

| Platform | Manifest | `manifest-key` |
|---|---|---|
| iOS (XcodeGen) | `<project-dir>/project.yml` | `MARKETING_VERSION` (default) |
| Android | `gradle.properties` | the property the build reads `versionName` from, e.g. `wjm.versionName` |

### ios-ci.yml

Jobs (all `macos-26`): `test` (`swift test` in `package-path`, then
`test-commands`), `lint` (pinned, digest-verified SwiftLint), `app-build`
(compile-only `xcodebuild build`, signing off), `app-test` (`xcodebuild test`
on the newest iPhone simulator, or the Mac) and `archive-validate` (signed
archive + export, only on `refs/heads/main`). `platform: macOS` switches the
destinations for a Mac app (no caller uses it today). Each check job publishes `<job>-result`, so a
repo whose ruleset requires a bare check name can keep a thin job of that
name (see the thin `test` job under the caller templates).

Main inputs: `project-dir`, `xcodegen` (false for a checked-in .xcodeproj),
`xcode-version` / `xcode-version-file`, `package-path`, `swift-test-args`,
`test-commands`, `test-env`, `lint-dir`, `lint-args`, `swiftlint-version` /
`swiftlint-sha256`, `app-scheme` (required), `app-build`,
`app-build-commands`, `app-test`, `app-test-args`, `archive-validate`,
`archive-scheme`, `export-options`, `bundle-id`, `signing-overrides`,
`google-service-info-plist`, `rust-core-ref`.

### ios-release.yml

Runs `ios-ci.yml` on the tag (`verify`, default true), then on `macos-26` in
the `Deploy` environment: stamps `MARKETING_VERSION` and
`CURRENT_PROJECT_VERSION` into `project.yml`, generates the project, installs
the signing assets (`.github/actions/apple-signing`), archives `scheme`,
exports with `export-options` (teamID and provisioningProfiles are filled
from the installed profiles), uploads with `xcodebuild -exportArchive`
(destination upload, App Store Connect API key), and attaches
`<repo>-<version>.ipa` and `<repo>-<version>-dSYMs.zip` to the release.
`signing-overrides: true` passes the team and profile on the archive command
line (We Just Might); leave it false when `project.yml` sets release signing
per target (law18, oh-toto) so SwiftPM dependency targets are not forced onto
the app profile. `release-check-commands` run before anything builds.

### android-ci.yml

One `check` job on `ubuntu-24.04`: JDK (`java-version`, 17), Gradle, then
`gradle-tasks` (default `test<Flavor>DebugUnitTest lint<Flavor>Debug
assemble<Flavor>Debug`) with `gradle-args`. Publishes `check-result`.

### android-release.yml

Runs `android-ci.yml` on the tag, then on `ubuntu-24.04` in the `Deploy`
environment: writes `keystore.properties` from the `UPLOAD_KEYSTORE_*`
secrets, runs `bundle<Flavor>Release` with
`-P<version-name-property>=<X.Y.Z>` and
`-P<version-code-property>=<YYYYMMDDNN build number>` (plus
`-P<build-number-property>` when set), uploads to Play with
`r0adkll/upload-google-play` (`prerelease-track`, default `internal`, for a
pre-release; `track` otherwise; `release-status`), and attaches
`<repo>-<version>.aab` (and the R8 mapping) to the release.

### Rust core (We Just Might)

`rust-core-ref` names a file holding the `we-just-might-core` commit
(`scripts/core-ref`) or the SHA itself. The workflows then run the core
repo's own composite action
(`mattas-net/we-just-might-core/.github/actions/build-ios@main` or
`build-android@main`), which checks the core out at that commit into
`../we-just-might-core` with the `WJM_CORE_DEPLOY_KEY` deploy key and builds
it. The core repository must allow Actions access from mattas-net
repositories (Settings → Actions → General → Access).

### Secrets

Pass them with `secrets: inherit`. Repository secrets work everywhere; a
secret stored only in the `Deploy` environment is visible to the upload job
but not to the CI run before it, so keep `WJM_CORE_DEPLOY_KEY` at repository
level. The release workflows forward only `WJM_CORE_DEPLOY_KEY` to their
nested CI run; the signing and store secrets reach the upload job alone.
Every checkout in the mobile workflows sets `persist-credentials: false`
(nothing uses git with the token afterwards; `gh` reads `GH_TOKEN`), and
`xcode-version`/`xcode-version-file` fail the job unless the selected Xcode
reports that major.minor.

| Secret | Used by |
|---|---|
| `DISTRIBUTION_CERT_P12_BASE64` | iOS: base64 PKCS#12 Apple Distribution certificate |
| `DISTRIBUTION_CERT_PASSWORD` | iOS: its password |
| `PROVISIONING_PROFILE_BASE64` | iOS: base64 App Store profile for the app |
| `EXTRA_PROVISIONING_PROFILE_BASE64` | iOS, optional: a second profile (app extension) |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` | iOS: App Store Connect API key (App Manager role) |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | iOS, with `google-service-info-plist` |
| `UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD`, `UPLOAD_KEY_ALIAS`, `UPLOAD_KEY_PASSWORD` | Android: Play upload key |
| `PLAY_SERVICE_ACCOUNT_JSON` | Android: Play service account key (release manager on the app) |
| `GOOGLE_SERVICES_JSON_BASE64` | Android, with `google-services-json` |
| `WJM_CORE_DEPLOY_KEY` | We Just Might: read-only deploy key for `we-just-might-core` |

### Mobile caller templates

`.github/workflows/checks.yml` (iOS)

```yaml
name: Checks
on:
  pull_request:
  workflow_dispatch:
concurrency:
  group: checks-${{ github.ref }}
  cancel-in-progress: true
jobs:
  approve:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    environment: approval
    steps:
      - run: echo "Checks approved by ${GITHUB_TRIGGERING_ACTOR}"
  ios:
    needs: approve
    if: always() && needs.approve.result != 'failure' && needs.approve.result != 'cancelled'
    uses: mattas-net/.github/.github/workflows/ios-ci.yml@main
    permissions:
      contents: read
    secrets: inherit
    with:
      project-dir: src
      package-path: src/MyApp
      lint-dir: src
      app-scheme: MyApp
```

A ruleset that requires bare check names (`test`, `lint`) keeps thin jobs
with those ids that read the reusable workflow's results:

```yaml
  test:
    needs: ios
    # always(): a rejected approval or failed shared job must report failure, not a skip
    # (a skipped required check counts as passing).
    if: always()
    runs-on: ubuntu-24.04
    steps:
      - env:
          RESULT: ${{ needs.ios.outputs.test-result }}
        run: test "$RESULT" = success
```

`.github/workflows/release.yml` (iOS)

```yaml
name: Release
on:
  workflow_dispatch:
    inputs:
      version:
        description: Version to release (bare semver, e.g. 1.4.2 or 1.4.2-beta1)
        required: true
        type: string
jobs:
  release:
    uses: mattas-net/.github/.github/workflows/create-release.yml@main
    permissions:
      contents: write
      actions: read
    with:
      version: ${{ inputs.version }}
      manifest: src/project.yml
      require-workflow: ""
  ios:
    needs: release
    uses: mattas-net/.github/.github/workflows/ios-release.yml@main
    permissions:
      contents: write
    secrets: inherit
    with:
      version: ${{ inputs.version }}
      project-dir: src
      scheme: MyApp
      package-path: src/MyApp
      lint-dir: src
```

`.github/workflows/checks.yml` and `release.yml` (Android): the same shape
with `android-ci.yml` (job id `check`) and

```yaml
  release:
    uses: mattas-net/.github/.github/workflows/create-release.yml@main
    permissions:
      contents: write
      actions: read
    with:
      version: ${{ inputs.version }}
      manifest: gradle.properties
      manifest-key: myapp.versionName
      require-workflow: ""
  android:
    needs: release
    uses: mattas-net/.github/.github/workflows/android-release.yml@main
    permissions:
      contents: write
    secrets: inherit
    with:
      version: ${{ inputs.version }}
      package-name: net.mattas.myapp
      track: internal
      version-name-property: myapp.versionName
      version-code-property: myapp.versionCode
```

### Store prerequisites

- App Store Connect: the app record exists for the bundle id, and the API key
  has the App Manager role. A new marketing version needs no manual step;
  the upload creates it.
- Google Play: the app exists in the Play Console, the first bundle was
  uploaded by hand (the API cannot create an app), the service account has
  release permissions for it, and Play App Signing is enabled with the upload
  key in `UPLOAD_KEYSTORE_*`. An app still in draft needs
  `release-status: draft`.

Used by: we-just-might-ios, law18-ios, oh-toto, ok-rocket (CI only),
we-just-might-android, law18-android.

## This repository's checks

`.github/workflows/checks.yml` lints every workflow in this repository with
actionlint (release binary pinned by version and verified against its
sha256). Same triggers and `approve` gate as the caller templates: automatic
on push to `main`; on pull requests it waits in the `approval` environment.
Required check (default-branch ruleset): `actionlint`.
