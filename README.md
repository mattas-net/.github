# mattas-net/.github

Shared GitHub Actions for the mattas-net organization.

## docker-build-push.yml (reusable)

Builds a site's Dockerfile and pushes it to `ghcr.io/mattas-net/<repo>` tagged
with the release tag (for example `v1.4.0`) plus `latest`, unless the release is
marked pre-release. Runs lint, typecheck, test and `npm audit` first when the
scripts exist.

Release flow: merge to `main`, then publish a release (`gh release create
v1.4.0 --generate-notes`). GitHub creates the tag and the caller fires. A manual
dispatch from an existing tag rebuilds it; a dispatch from a branch does nothing.

Caller (`.github/workflows/docker-build-push.yml` in each site repo):

```yaml
name: Build and Push Docker Image
on:
  release:
    types: [published]
  workflow_dispatch:
jobs:
  image:
    uses: mattas-net/.github/.github/workflows/docker-build-push.yml@main
    permissions:
      contents: read
      packages: write
    with:
      node-version: "22"
      build-args: |
        NEXT_PUBLIC_EXAMPLE=${{ vars.EXAMPLE }}
```

Inputs: `build-args`, `node-version` (default 22), `npm-ci-args`
(default `--ignore-scripts`), `verify` (default true), `platforms`
(default `linux/amd64`).

Used by: mattas-net-next, anthonymattas-com-next, adhdbytes-com-next,
law18-app-next, we-just-might-next.
