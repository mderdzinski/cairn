---
name: release-notes
description: Generate user-facing release notes for a Cairn release by reading the actual code diffs between two semantic-release tags. Use when preparing App Store "What's New" text or a GitHub release writeup.
---

# Release Notes between Tags

Generate user-facing release notes by reading actual code diffs between two semantic-release tags (e.g. `v1.1.0 v1.1.1`).

## Step 1: Fetch latest tags

Pull the latest state of main so the tag list is up to date:

```
git fetch origin main --tags
```

## Step 2: Parse inputs

The command args ($ARGUMENTS) should contain two tag names: `<from-tag> <until-tag>`.

- If two args are provided, use them as the start and end of the range (inclusive of until-tag).
- If only one arg is provided, treat it as `<from-tag>` and default `<until-tag>` to the latest tag on main:
  ```
  git describe --tags --abbrev=0 origin/main
  ```
- If no args are provided, default `<until-tag>` to the latest tag on main and `<from-tag>` to the tag before it:
  ```
  git describe --tags --abbrev=0 <until-tag>^
  ```
  Semantic-release keeps tags linear on main, so "the previous release" is well-defined. Tell the user which range you inferred.

The commit range is `<from-tag>..<until-tag>` (i.e., commits after from-tag up to and including until-tag).

## Step 3: Validate the range

Run these checks (stop and report if any fail):

```
git rev-parse --verify <from-tag>^{commit}
git rev-parse --verify <until-tag>^{commit}
git merge-base --is-ancestor <from-tag> <until-tag>
```

If a tag does not exist, list available tags with `git tag --sort=-creatordate | head -10` and ask the user to pick one.

## Step 4: List commits and check range size

```
git log --oneline <from-tag>..<until-tag>
```

Every commit on main is a squash-merged PR, so this list is effectively the PR list for the release. If the range contains more than 40 commits, warn the user with the count and ask them to confirm before continuing.

## Step 5: Read code diffs

First, read the combined net diff for the entire range, excluding tests, CI, lint config, and project-file churn:

```
git diff <from-tag>..<until-tag> -- \
  ':(exclude)CairnTests' ':(exclude)CairnUITests' \
  ':(exclude)Cairn Watch AppTests' ':(exclude)Cairn Watch AppUITests' \
  ':(exclude).github' ':(exclude)*.pbxproj' \
  ':(exclude).swiftformat' ':(exclude).swiftlint.yml' \
  ':(exclude)lefthook.yml' ':(exclude)*.md' ':(exclude).releaserc.json'
```

- For large diffs, pipe through `| head -500` and read more only if needed for classification.
- If changes are ambiguous or you need to attribute them to a specific PR, drill into individual commit diffs from the Step 4 list — each one is a complete PR.
- **The code diff is the primary source for classification and writing — not commit messages.** Commit messages are hints at best; the diff is ground truth.

## Step 6: Classification rules

- **Omit entirely**: Changes invisible to someone using the app — CI, lint and formatting config, semantic-release setup, docs, Xcode project housekeeping, privacy manifests, dependency bumps — unless they have a user-visible side effect. (Asset changes are a judgment call: a redesigned icon or complication is user-visible; a re-export at new resolutions is not.)
- **New**: Significant new user-visible capabilities. Rebuilds or rewrites of existing features also go here, but describe them as improvements to existing functionality.
- **Improvements**: Minor enhancements, UX polish, and performance work the user would actually feel (e.g. a tab loading noticeably faster).
- **Fixes**: Anything a user would perceive as "that was broken and now it's fixed."
- **Platform scoping**: When a change is watch-only, say so ("On Apple Watch, …"). iPhone-side changes don't need a platform label. A change that spans both usually doesn't need the detail at all.

## Step 7: Writing rules

- Keep each bullet brief. Introducing the primary change is enough — don't over-explain.
  - Cut implementation details (SwiftUI/SwiftData terms, class or view names, sync internals) and where-the-fix-lives detail.
  - For fixes especially: state what now works correctly. Don't explain the bug's mechanics, name the counter that was off, or include the before/after math.
  - Cut narrow examples that read as exhaustive enumeration; a single broad phrase is better.
- **Frame positively.** Lead with what now works well, not what used to fail.
- **Match tone to the app.** Cairn's voice is calm, plain, and unhurried. No hype, no exclamation points. A quiet sentence that says what changed is the goal.
- **Use Cairn's own vocabulary** the way the app does — stones, cairn, moments, Path, Patterns — and never invent marketing names for things the app doesn't name.
- **One feature, one bullet.** When a feature ships alongside follow-up fixes to that same feature, fold everything into the feature bullet — users never saw the broken intermediate state.
- **Reclassify on review.** A bullet drafted under New may belong in Improvements if it's really an existing capability made better. Re-check section assignment after writing each bullet.
- Write in plain language for a general (non-technical) reader.
- Communicate user impact, not implementation.
- Group related changes into a single bullet with sub-bullets when it improves readability.
- Use a single hyphen `-` for asides, not em dashes (—) or double hyphens (--).
- Avoid LLM-voice clichés: don't use "seamlessly", "robust", "leverage", "ensures", "enhances", "streamlined", "elevate", or "whether you're…" constructions.
- Prefer short, direct sentences. Don't pad bullets with filler like "for a smoother experience" unless it adds real information.
- Vary sentence structure. Don't start every fix with "Fixed" or every feature with "You can now".

## Step 8: Write the notes

Use exactly this section structure (omit any section that would be empty):

```
## Cairn <until-tag>

### New
* <list>

### Improvements
* <list>

### Fixes
* <list>
```

Keep the whole thing well under App Store Connect's 4,000-character What's New limit — with the headers stripped, the bullets should paste directly into the What's New field.

## Step 9: Completeness check

Before writing the notes:

- Every user-visible commit must appear exactly once (individually or grouped with related changes).
- Internal-only commits may be omitted entirely — that is expected and correct.

## Step 10: Write to file

Write the final release notes to `docs/release-notes/<until-tag>.md` and report the output file path.
