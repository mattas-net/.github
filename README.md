# mattas-net/.github

Shared GitHub Actions for the mattas-net organization.

## docker-build-push.yml (reusable)

Builds a site's Dockerfile and pushes it to `ghcr.io/mattas-net/<repo>:<tag>`,
where the tag is derived from the branch the caller was dispatched on
(`release/latest` -> `latest`, `release/v2` -> `v2`). Runs lint, typecheck,
test and `npm audit` first when the scripts exist.

Caller (`.github/workflows/docker-build-push.yml` in each site repo):

```yaml
name: Build and Push Docker Image
on:
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
