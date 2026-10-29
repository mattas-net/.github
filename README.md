# mattas-net/.github

Shared GitHub Actions for the mattas-net organization. Every project follows
the same release flow:

1. Push to `main` → the repo's checks workflow runs automatically.
2. Bump the version in the manifest (`package.json`, `pyproject.toml`,
   `manifest.json`), merge to `main`.
3. Actions → Release → Run workflow → enter the version (bare semver: `1.4.2`
   or `1.4.2-beta1`, never `v1.4.2`).
4. `create-release.yml` verifies the manifest on `main` matches, that no tag
   exists, and that the checks passed on `main` HEAD; then it tags `main`,
   creates the GitHub Release, and the caller chains the build/publish job.

Nothing is tagged when a check fails, so fix the manifest and re-run.

## Workflows

### create-release.yml

`workflow_call` inputs: `version` (required), `manifest` (required path),
`require-workflow` (name of the checks workflow; empty skips the gate),
`title-prefix`. Outputs `tag` and `prerelease`.

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
