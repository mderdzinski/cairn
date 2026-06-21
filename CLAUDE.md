# Cairn — repo conventions

## Commit messages

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<optional scope>): <description>

[optional body]
[optional footer]
```

**Allowed types:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `ci`, `build`, `perf`, `style`, `revert`.

**Scope** is optional but encouraged for multi-target work. Common scopes here:
- `ios` — phone app target
- `watch` — watch app target
- `xcode` — project file, build settings, schemes
- `ci` — when the scope itself isn't `ci` (rare; usually the type already covers it)

**Description** is imperative, lowercase, no trailing period. Subject ≤72 chars.

**Examples (taken from this repo's history):**
- `chore(xcode): scaffold iOS and watchOS app targets`
- `ci: add SwiftFormat, SwiftLint, lefthook, and GitHub Actions workflow`
- `docs: add project README and Swift/Xcode .gitignore`

## Branching and merging

- **Never commit directly to `main`.** All changes land via PR.
- **Squash-on-merge only.** The repo is configured to disallow merge commits and rebase-merges.
- **The PR title becomes the squashed commit message on `main`** — so PR titles must also follow Conventional Commits. The PR body becomes the commit body.
- Branch commits (work-in-progress on a feature branch) don't need to be conventional — they collapse on squash. Only the PR title matters for `main`'s history.
- Branches are auto-deleted on merge.

## Linting

- **SwiftFormat** and **SwiftLint** run on every commit via the lefthook pre-commit hook.
- CI re-runs both in lint mode as a backstop.
- Config lives in `.swiftformat` and `.swiftlint.yml`. Force-unwrapping, force-casting, and force-trying are errors, not warnings.
