# Ruleset templates

Repository rulesets applied to every repo in the standard (see [STANDARD.md](../STANDARD.md#rulesets)).
The JSON files are sanitized exports: no ids, no timestamps. `integration_id` 15368 is the GitHub
Actions app. The bypass actor `actor_id: 5` is the repository Admin role.

| File | Apply to |
|---|---|
| `protect-main.json` | Every repo with a `checks.yml` (target state: required contexts `checks` and `security`) |
| `protect-main-contentonly.json` | Content-only repos and repos with no CI yet: PR + deletion/force-push protection, no required checks, no code scanning |
| `protect-main-nochecks.json` | Repos with CodeQL but no `checks`/`security` jobs yet (code scanning gate only) |
| `protect-release-tags.json` | `mattas-net` (org) repos: blocks tag delete/update and enforces bare-semver tag names |
| `protect-release-tags-user.json` | `amattas` (user) repos: same without `tag_name_pattern` (see below) |
| `block-invalid-branches.json` | Every repo: only `main`, `gh-pages`, `dev/*`, `feature/*`, `bugfix/*` and `release/*` branch names can be created |

## Apply

Create (replace `<owner>/<repo>`):

```sh
gh api -X POST repos/<owner>/<repo>/rulesets --input rulesets/protect-main.json
```

Update an existing ruleset in place (find its id with `gh api repos/<owner>/<repo>/rulesets --jq '.[] | [.id,.name] | @tsv'`):

```sh
gh api -X PUT repos/<owner>/<repo>/rulesets/<ruleset-id> --input rulesets/protect-main.json
```

Run one `gh` command per shell invocation.

## Known platform behavior

- `tag_name_pattern` is rejected on user-owned (`amattas`) repos with `Invalid rule 'tag_name_pattern'`.
  Only org (`mattas-net`) repos can enforce bare-semver tags in the ruleset. `amattas` repos use
  `protect-release-tags-user.json` and rely on `create-release.yml`, which validates the version as bare
  semver before it tags.
- `block-invalid-branches.json` includes `refs/heads/*` (a single path level). `dependabot/<ecosystem>/<name>`
  has two levels after `refs/heads/`, so Dependabot branches are not blocked. `dev/*`, `feature/*` and
  `bugfix/*` are excluded explicitly.
- Required-check contexts in the live rulesets still carry each repo's legacy names until WP-1 pass 2
  moves them to `checks` / `security` after that repo's caller migration merges. The templates here are the
  target state.
