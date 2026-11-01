# Repository standard

Applies to every repository under `mattas-net` and `amattas` except the deferred list at the end. Shared
reusable workflows live in this repository and are called as
`uses: mattas-net/.github/.github/workflows/<name>.yml@main`. Inputs and outputs of each reusable are listed in
[README.md](README.md).

## Repo classes

| Class | Repos | `checks.yml` calls | `release.yml` calls | Other |
|---|---|---|---|---|
| python-lib | aioddp, pydmp, pyminleon, neewer-sacn | python-ci | create-release, python-build, PyPI publish | docs.yml |
| python-service | calendar-mcp, homeassistant-mcp, ics-combiner, retail-demo (no image) | python-ci | create-release, docker-build-push | docs.yml, docker-build-push.yml (dispatch rebuild) |
| hacs | hass-ddp, hass-dmp | python-ci + hacs-ci | create-release | docs.yml |
| node-site | anthonymattas-com-next, law18-app-next, mattas-net-next, mattas-net-strapi, we-just-might-next | node-ci | create-release, docker-build-push | docs.yml, docker-build-push.yml |
| ios | law18-ios, we-just-might-ios, oh-toto, ok-rocket | ios-ci | create-release, ios-release (not ok-rocket) | docs.yml |
| android | law18-android, we-just-might-android | android-ci | create-release, android-release | docs.yml |
| rust | we-just-might-core, we-just-might-server | rust-ci | server: create-release, docker-build-push; core: create-release | docs.yml |
| infra | mattas-net-infra | infra-ci | none | docs.yml |
| content-only | policies, obsidian, omscs, conda-env, dog-button, ussf-report, tkctf_2025, flag, microsoft-excalidraw, signalrgb-govee, GetEmbedToken | none | none | rulesets only; LICENSE if public |

`ok-rocket` stays checks-only until it is ready to ship; add `release.yml` then.

## Check naming

Every `checks.yml` ends with two thin alias jobs named exactly `checks` and `security` (`runs-on: ubuntu-24.04`,
`if: always()`, `needs:` the shared job). They pass only when the shared job's `checks-result` /
`security-result` outputs are `success`. Rulesets require exactly the contexts `checks` and `security` on every
repo, so changing a Python matrix can never invalidate a ruleset. A skipped required check counts as passing,
which is why the aliases always run and assert.

```yaml
  checks:
    needs: <shared-job-id>
    if: always()   # a skipped required check counts as passing, so always run and assert
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Require the shared checks job
        env:
          RESULT: ${{ needs.<shared-job-id>.outputs.checks-result }}
        run: test "$RESULT" = success

  security:
    needs: <shared-job-id>
    if: always()
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - name: Require the shared security job
        env:
          RESULT: ${{ needs.<shared-job-id>.outputs.security-result }}
        run: test "$RESULT" = success
```

## Triggers

- `checks.yml`: `push: branches: [main]`, `pull_request:`, `workflow_dispatch:`. HACS adds
  `schedule: - cron: "0 0 * * *"`. Concurrency `checks-${{ github.ref }}`, cancel-in-progress. An `approve` job
  gated on the `approval` environment holds pull-request runs until a reviewer approves them (no runner minutes
  are spent while waiting). A dispatched run does not attach to a PR, so it cannot satisfy the ruleset gate.
- `release.yml`: `workflow_dispatch` with a `version` input only.
- `docs.yml`: push to `main`, `workflow_dispatch`, and `workflow_call` with a `version` input.
- `docker-build-push.yml` (rebuild): `workflow_dispatch` only.
- iOS and Android checks use the same triggers as every other class: push to `main`, pull requests (which wait at
  `approve`), and `workflow_dispatch` on any branch. They run on macOS or Gradle-heavy runners, so expect them to
  cost more minutes than the other classes.

## Required workflows per class

### `checks.yml` (all classes)

```yaml
# Checks — automatic on push to main; PR runs wait at `approve` until a reviewer approves in the
# `approval` environment. Release requires a successful run on main HEAD.
# Required checks (default-branch ruleset): "checks" and "security". See mattas-net/.github STANDARD.md.
name: Checks

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
  # hacs only:
  # schedule:
  #   - cron: "0 0 * * *"

concurrency:
  group: checks-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  approve:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    environment: approval
    steps:
      - run: echo "Checks approved by ${GITHUB_TRIGGERING_ACTOR}"

  <class>:            # python | node | ios | android | rust | infra  (hacs: python + hacs, two jobs)
    needs: approve
    if: always() && needs.approve.result != 'failure' && needs.approve.result != 'cancelled'
    uses: mattas-net/.github/.github/workflows/<class>-ci.yml@main
    permissions:
      contents: read
    # secrets: inherit   # ios/android only
    with:
      <class-specific inputs>

  # alias jobs `checks` and `security` from "Check naming", verbatim
```

Class-specific `with:` examples:

```yaml
# python-lib
with:
  python-versions: '["3.12", "3.13", "3.14"]'
# python-service and hacs
with:
  python-versions: '["3.14"]'
# node-site
with:
  node-version: "24"
# ios
with:
  project-dir: src
  package-path: src/MyApp
  lint-dir: src
  app-scheme: MyApp
```

HACS adds a second job `hacs` (calling `hacs-ci.yml`) beside `python`, with `python` installing
`-r requirements.test.txt`, `build: false` and `audit: off` (the pinned Home Assistant test environment is not
actionable; dependency review still runs on PRs). The `checks` alias `needs:` both jobs.

### `release.yml`

All classes start with the `create-release` job; what follows depends on the class.

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
      manifest: <manifest path>
      require-workflow: Checks     # "" for ios/android (see mobile notes)
```

- python-lib: `manifest: pyproject.toml`, then `build` (`python-build.yml`, `ref: ${{ inputs.version }}`), then a
  `publish` job in the caller (PyPI trusted publishing does not work from inside a reusable workflow; register
  the trusted publisher for workflow `release.yml`, environment `pypi`):

  ```yaml
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

  Copy the pinned SHAs from the current `pyminleon` `release.yml` when they have moved on.
- python-service and node-site: `manifest: pyproject.toml` or `package.json`, then

  ```yaml
    image:
      needs: release
      uses: mattas-net/.github/.github/workflows/docker-build-push.yml@main
      permissions:
        contents: read
        packages: write
      with:
        ref: ${{ inputs.version }}
        verify: false
        # node-version: "24"   # node-site only
  ```
- hacs and rust-core: the `release` job alone (hacs: `manifest: custom_components/<domain>/manifest.json`; rust:
  `manifest: Cargo.toml`), then the local `docs` job.
- rust-server: `manifest: Cargo.toml`, then `docker-build-push` with the core checkout inputs (see README).
- ios: `manifest: <project-dir>/project.yml`, `require-workflow: ""`, then `ios-release.yml` with
  `secrets: inherit`, `version`, `project-dir`, `scheme`, `package-path`, `lint-dir`.
- android: `manifest: gradle.properties`, `manifest-key: <app>.versionName`, `require-workflow: ""`, then
  `android-release.yml` with `secrets: inherit`, `package-name`, `track: internal`, `version-name-property`,
  `version-code-property`.

Every documented repo ends `release.yml` with a job that republishes docs after tagging:

```yaml
  docs:
    needs: release        # or the last build/publish job
    uses: ./.github/workflows/docs.yml
    permissions:
      contents: write
    with:
      version: ${{ inputs.version }}
```

### `docs.yml`

Every documented repo; only `with:` overrides may differ. `python-version: "3.14"` everywhere (also the shared default).

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
      python-version: "3.14"
```

Docs are Zensical + mike, published to the repo's `gh-pages` branch by `scripts/publish_versioned_docs.py`.
Public repos serve `gh-pages` with Pages; private repos build it and keep Pages disabled.

### `docker-build-push.yml` (manual rebuild; python-service, node-site, rust-server)

```yaml
# Manual rebuild of an existing release tag's image (e.g. after a base-image fix). Normal
# releases build via release.yml. Pushes ghcr.io/<owner>/<repo>:<tag> (+ latest unless prerelease).
name: Rebuild Docker Image
on:
  workflow_dispatch:
    inputs:
      ref:
        description: Release tag to rebuild (bare semver)
        required: true
        type: string
jobs:
  image:
    uses: mattas-net/.github/.github/workflows/docker-build-push.yml@main
    permissions:
      contents: read
      packages: write
    with:
      ref: ${{ inputs.ref }}
      verify: true
      # node-version: "24"   # node-site only
```

## Versions and tags

Bare semver `X.Y.Z` or `X.Y.Z-suffix`; never a `v` prefix. The manifest that carries the version, per class:

| Class | Manifest |
|---|---|
| python | `pyproject.toml` `[project].version` |
| hacs | `custom_components/<domain>/manifest.json` `version` |
| node | `package.json` `version` |
| ios | `project.yml` `MARKETING_VERSION` |
| android | `gradle.properties` `<app>.versionName` |
| rust | `Cargo.toml` `version` (workspace root: `[workspace.package]`) |

`create-release` verifies the manifest on `main` equals the input version before tagging.

## Release procedure

1. Bump the version in the class manifest on a `dev/*` branch; merge by PR (merge commit) to `main`.
2. Wait for the `Checks` workflow to succeed on `main` HEAD (it runs on push).
3. Actions, Release, Run workflow, enter the bare-semver `version`.
4. `create-release` then, in order:
   - validates the version as bare semver (`^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.]+)?$`);
   - verifies the manifest on `main` carries the version (for `project.yml` and `gradle.properties`, a
     pre-release `1.4.2-beta1` matches `1.4.2`, because store versions are numeric);
   - refuses if the tag already exists;
   - requires a successful run of the `require-workflow` (`Checks`) on `main` HEAD (empty skips; mobile
     callers skip it because their release workflow re-runs the checks on the tag);
   - tags `main` HEAD and publishes the GitHub Release, marking it a pre-release when the version has a hyphen
     suffix.
   `dry-run: true` runs every check and the local tag, then prints the push and the release instead of doing
   them; `notes-file` (a repo path read at the tag) replaces the generated release notes.
5. The caller then runs the chained job: build and publish (python), image push (service/site), store upload
   (mobile), docs republish.

A pre-release (`-suffix`) never moves the `latest` image tag, and mobile pre-releases go to TestFlight or the
Play `internal` track only. Nothing is tagged when a check fails: fix the manifest and re-run. Tags are never
deleted or moved (the tag ruleset forbids it); a bad release is fixed forward with a new version.

## Deployment

Production is Keel on `latest`; cluster credentials stay off GitHub.

1. Dispatch **Release** in the app repository (non-pre-release version, e.g. `1.4.2`).
2. `docker-build-push` pushes `ghcr.io/<owner>/<repo>:<version>` and `:latest`.
3. Keel force-polls the registry every 5 minutes (`keel.policy: force`, `trigger: poll`,
   `pollSchedule: "@every 5m"`, `image.tag: latest`, `pullPolicy: Always`) and rolls the deployment when the
   `latest` digest changes. Expect production to update within about 5 minutes of the build finishing.

A pre-release (`1.4.2-beta1`) pushes only its own tag and never moves `latest`, so Keel does not touch
production. That is the only staging path: pull the pre-release tag explicitly where you want to try it. The
pre-release test is a `-` in the tag name (the image workflow checks the tag string, not GitHub's pre-release
flag).

**Rollback.** Re-dispatch `docker-build-push.yml` in the app repository with `ref` set to the previous stable
tag. A dispatch from a stable tag rebuilds that tag from source and pushes `<tag>` and `latest` (the `latest`
condition is "the tag has no `-`"; dispatching does not skip it, only `image-tag` does), so Keel rolls
production back within about 5 minutes. The rebuild is not a retag: its digest can differ from the original
image of that version. If a rebuild is not acceptable, fix forward by publishing a patch release.

**`helm upgrade --set image.tag=<version>` is not a deploy path.** It pins the pod to that tag, and a pinned
tag is no longer `latest`, so Keel stops seeing the deployment as auto-rolling and the app silently drops out of
automatic rollout until `image.tag` is set back to `latest`. Use helm only for chart or values changes (in
`mattas-net-infra`, [`DEPLOY.md`](https://github.com/mattas-net/mattas-net-infra/blob/main/DEPLOY.md)). When
you do, do not combine `--reuse-values` with a chart whose `values.yaml` gained new keys since the last
install; `--reuse-values` keeps the old computed values and silently ignores new defaults. Pass the full
values file (or `--reset-then-reuse-values`) and check `helm get values <release> -n <ns>`.

**How to see what is running.** Compare the pod's image digest with the digest of the version in GHCR:

```sh
kubectl -n <ns> get deploy <app> -o jsonpath='{..imageID}'
```

The `imageID` ends in `@sha256:<digest>`; it should equal the digest GHCR shows for `<version>` (and for
`latest`) on the package page.

## Policy files

| File | `mattas-net` repos | `amattas` repos |
|---|---|---|
| LICENSE (MIT) | public repos only | every public repo |
| SECURITY.md | inherited from this repository's root; do not add per repo | inherited from the public `amattas/.github`; do not add per repo |
| CODEOWNERS | `.github/CODEOWNERS` with `* @amattas` | same |
| PR template, issue templates | inherited from this repository | pydmp and aioddp keep theirs; others none |
| dependabot.yml | standard per class | same |
| CODE_OF_CONDUCT, CONTRIBUTING | not required (the org default is in this repository) | not required |

Community-health files in this repository's root (`SECURITY.md`, `CODE_OF_CONDUCT.md`,
`PULL_REQUEST_TEMPLATE.md`, `ISSUE_TEMPLATE/`) apply to every `mattas-net` repo that lacks its own. GitHub does
not inherit across owners, so the `amattas` repos get the same files from `amattas/.github`, a public
community-health repository (an owner-level `.github` repo only supplies defaults when it is public). Its
`SECURITY.md` has the same text as this repository's; per-repo copies in `amattas` repos are removed.

### Dependabot

Header comment, `version: 2`, one entry per ecosystem present. Every entry has `schedule.interval: monthly`,
`cooldown.default-days: 7`, and one group `<ecosystem>` with `patterns: ['*']`. Keep any existing `ignore:` lists.

| Class | Ecosystems |
|---|---|
| python-lib, python-service, hacs | `pip`, `github-actions` (+ `docker` if a Dockerfile exists) |
| node-site | `npm`, `docker`, `pip` (docs), `github-actions` |
| ios | `swift`, `pip`, `github-actions` |
| android | `gradle`, `pip`, `github-actions` |
| rust | `cargo`, `github-actions` (+ `docker`, `gradle`, `swift` where those directories exist) |
| infra | `helm`, `terraform`, `pip`, `github-actions` |

## Node version rule

Node 24 LTS everywhere.

- `.nvmrc` at the repo root contains `24`.
- Dockerfile: `ARG NODE_VERSION=24` on line 1 (after the syntax line) and every `FROM node:<x>-alpine` becomes
  `FROM node:${NODE_VERSION}-alpine`. Dependabot's `docker` entry then stops proposing base bumps; that is
  intended. Bump `.nvmrc` and the ARG together, by hand.
- `checks.yml`, `release.yml` and `docker-build-push.yml` pass `node-version: "24"` explicitly (reusable inputs
  cannot read files). The `node-ci.yml` and `docker-build-push.yml` defaults are `"24"`.

## Python matrix rule

- Libraries (aioddp, pydmp, pyminleon, neewer-sacn) test Python 3.12 through 3.14.
- Services (calendar-mcp, homeassistant-mcp, ics-combiner) and HACS integrations (hass-ddp, hass-dmp) test the
  single runtime version they ship on: 3.14.
- Ruff is the one linter and formatter (`ruff check` plus `ruff format --check`), with mypy and pytest.
- Docs builds use Python 3.14 (explicit `python-version: "3.14"` in every `docs.yml`; the shared default is 3.14).

## Rulesets

Governance: `mattas-net` repos are governed by organization rulesets; the eight `amattas` repos keep
repository-level rulesets. Three rulesets, as JSON in [`rulesets/`](rulesets/) (apply commands in
[`rulesets/README.md`](rulesets/README.md)):

| Ruleset | File | Effect |
|---|---|---|
| Protect main | `protect-main.json` | No deletion or force-push; PR required (merge commits only, thread resolution required, stale approvals dismissed, 0 required approvals); required status checks `checks` and `security` (strict); CodeQL code-scanning gate at high or higher; admin role may bypass |
| Protect release tags | `protect-release-tags.json` | Tags cannot be deleted or updated; org repos also enforce bare-semver tag names; admin role may bypass |
| Block Invalid Branch Patterns | `block-invalid-branches.json` | Branch creation is blocked except `main`, `gh-pages`, `dev/*`, `feature/*`, `bugfix/*`, `release/<semver>`, `release/<semver>-*`, `release/latest` |

Variants: `protect-main-contentonly.json` (content-only and CI-less repos: no required checks, no code scanning),
`protect-main-nochecks.json` (code scanning gate without `checks`/`security`), and
`protect-release-tags-user.json` (user-owned repos, see below).

Confirmed platform behavior:

1. The `tag_name_pattern` rule is rejected on user-owned (`amattas`) repos (platform limitation). Only
   `mattas-net` repos can enforce bare-semver tags in the ruleset. `amattas` repos use
   `protect-release-tags-user.json`; the tag-name pattern there is enforced by `create-release`, which refuses
   anything that is not bare semver before it tags.
2. `Block Invalid Branch Patterns` includes `refs/heads/*` (single level), so two-level names such as
   `dependabot/<ecosystem>/<name>` are not blocked.

### This repository

Its `Checks` workflow ends with the standard `checks` and `security` alias jobs (`checks` asserts `actionlint` and
`self-test`; `security` asserts the self-test security results) and runs `actionlint` over
`.github/workflows` and a `self-test` job that calls `python-ci`, `node-ci`, `rust-ci`, `infra-ci`, `docs`
(`dry-run`), `create-release` (`dry-run`) and `docker-build-push` (`push: false`) from the PR ref against
`tests/fixtures/<class>/`, and parses `ios-release` and `android-release` (`on.workflow_call` check only), so a broken reusable fails here
before callers pick it up from `@main`. The org ruleset requires `checks` and `security`; `self-test` asserts the `checks-result` and `security-result` outputs of each reusable (and the
`docs`, `create-release` and `docker-build-push` job results) equal `success`.
Not self-tested: `ios-ci` (it resolves a private we-just-might-core action this repository cannot access), `android-ci` and `hacs-ci` (they validate the repository root and have no `working-directory` input), `python-build` (it needs a published tag equal to the built version), and the signing and store-upload paths of the release workflows (they need secrets).

## Onboarding a new repo

1. Pick the class; add `.github/workflows/checks.yml`, `release.yml`, `docs.yml` (and `docker-build-push.yml`
   for image classes) from the templates above, with the `checks` and `security` aliases.
2. Create the `approval` environment (required reviewer: the owner) and, for mobile repos, `Deploy`; for PyPI
   libraries, `pypi` plus the PyPI trusted publisher.
3. Add `.github/dependabot.yml` for the class, `.github/CODEOWNERS` (`* @amattas`), `.nvmrc` and the Dockerfile
   ARG (node), and `LICENSE` (MIT) if public. For `amattas` repos add `SECURITY.md`.
4. Set the manifest version (start at `0.1.0` or `1.0.0`); confirm the first `Checks` run is green on `main`.
5. Enable CodeQL default setup (real source languages only) and private vulnerability reporting.
6. Apply the rulesets from `rulesets/` (`protect-main.json` only after `checks`/`security` have run once, else
   use `protect-main-nochecks.json` first), choosing the org or user tag variant.
7. Do the first release through Actions, Release, with the bare-semver version, and verify the tag, GitHub
   Release and downstream artifact (image, package, store build).

## Deferred repos

Untouched by this standard until revisited: netographer, busybar-teams, photo-gallery, soccer-sim,
quicken-mac-visualizer, busybar-claude, demo-god.

## Reference: mobile release mechanics

- **Build number** (iOS `CURRENT_PROJECT_VERSION`, Android `versionCode`) is not derived from the version. It is
  `YYYYMMDD*100 + NN`: the UTC date the release was published (its GitHub Release `publishedAt`), and NN (01 to
  99) is its 1-based position among the repository's GitHub Releases published that UTC date. Numbers only
  grow. Every rerun for the same tag recomputes the same number (deleting an earlier same-day release shifts
  the count down and can repeat a number). On Android a rerun after a successful Play upload is rejected for
  the repeated versionCode. A 100th release in one UTC date fails. Nothing is committed; the workflow stamps
  the numbers on the runner only.
- **Marketing version / versionName** is the tag's `X.Y.Z` on both platforms (store versions cannot carry a
  suffix), so the manifest for `1.4.2-beta1` holds `1.4.2`.
- iOS manifest `<project-dir>/project.yml`, key `MARKETING_VERSION`; Android manifest `gradle.properties`, key
  the property the build reads `versionName` from (for example `wjm.versionName`).
- The release workflows always run the checks on the tag before archiving.
- Store prerequisites: App Store Connect app record exists for the bundle id and the API key has App Manager
  role. Google Play: the app exists, the first bundle was uploaded by hand, the service account has release
  permission, Play App Signing is enabled with the upload key in `UPLOAD_KEYSTORE_*`; an app still in draft needs
  `release-status: draft`.
- Pass secrets with `secrets: inherit`. A secret stored only in the `Deploy` environment is visible to the upload
  job but not to the CI run before it, so keep `WJM_CORE_DEPLOY_KEY` at repository level.

| Secret | Used by |
|---|---|
| `DISTRIBUTION_CERT_P12_BASE64`, `DISTRIBUTION_CERT_PASSWORD` | iOS: Apple Distribution certificate (base64 PKCS#12) and password |
| `PROVISIONING_PROFILE_BASE64`, `EXTRA_PROVISIONING_PROFILE_BASE64` | iOS: App Store profile; optional second profile (extension) |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` | iOS: App Store Connect API key (App Manager) |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | iOS, with `google-service-info-plist` |
| `UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD`, `UPLOAD_KEY_ALIAS`, `UPLOAD_KEY_PASSWORD` | Android: Play upload key |
| `PLAY_SERVICE_ACCOUNT_JSON` | Android: Play service account key |
| `GOOGLE_SERVICES_JSON_BASE64` | Android, with `google-services-json` |
| `WJM_CORE_DEPLOY_KEY` | We Just Might: read-only deploy key for `we-just-might-core` |
