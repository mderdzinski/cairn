---
name: prepare-release
description: Prepare a Cairn App Store release - bump the Xcode project version to the latest semantic-release tag and generate user-facing release notes covering everything since the last shipped version. Pass two tags as args to generate notes only, with no version bump.
---

# Prepare an App Store Release

This skill has two parts. **Part 1** bumps the Xcode project version to match the latest semantic-release tag. **Part 2** generates user-facing release notes from the actual code diffs, covering everything since the last *shipped* version.

Which parts to run:

- **No args**: full release prep — run Part 1, then Part 2 with the tag range Part 1 derived.
- **Two tags** (`<from-tag> <until-tag>`): notes only — skip Part 1 entirely and run Part 2 on that range.
- **One tag**: notes only — treat it as `<from-tag>` and default `<until-tag>` to the latest tag on main.

Key model: semantic-release tags every merge to main, but App Store releases ship only occasionally — so a release usually spans *several* tags. The pbxproj's `MARKETING_VERSION` records what last shipped (it is only ever bumped at release time), which makes "notes since the last bump" mean `v<current MARKETING_VERSION>..v<latest tag>`, not merely the previous tag.

## Part 1: Version bump

### Step 1: Fetch and determine versions

```
git fetch origin main --tags
```

- **Last shipped version**: read the current `MARKETING_VERSION` from `Cairn.xcodeproj/project.pbxproj`. This is the App Store baseline. `<from-tag>` = `v<that version>`.
- **Target version**: the latest tag on main:
  ```
  git describe --tags --abbrev=0 origin/main
  ```
  The new `MARKETING_VERSION` is that tag without the `v` prefix.
- If target equals the last shipped version, there is nothing to release — stop and tell the user.
- Confirm the plan with the user before editing: "bumping <old> → <new>, notes will cover `v<old>..v<new>`".

One caveat worth knowing: the `v<old>` tag approximates the last shipped binary — the actual archive may have included a few post-tag commits (version-bump chores and the like). Those are internal-only and get omitted by classification anyway, so the approximation is safe.

### Step 2: Branch

Never commit to main. If not already on a release branch, create one:

```
git checkout -b chore/release-<version>
```

### Step 3: Apply the bump

- Set `MARKETING_VERSION` to the target version in **every** config block of the pbxproj (app, watch app, widgets, and test targets — uniform is simplest, and App Store validation requires embedded targets to match the containing app).
- Set `CURRENT_PROJECT_VERSION` everywhere to (current maximum + 1). Build numbers must be uniform across targets and must always increase across App Store uploads.

```
sed -i '' -e 's/MARKETING_VERSION = <old>;/MARKETING_VERSION = <new>;/g' Cairn.xcodeproj/project.pbxproj
```

Verify uniformity — this must print exactly one distinct value for each setting:

```
grep -h "MARKETING_VERSION\|CURRENT_PROJECT_VERSION" Cairn.xcodeproj/project.pbxproj | sort | uniq -c
```

### Step 4: Continue to notes, then commit

Run Part 2 with the range derived in Step 1, then commit the bump and the notes file together on the release branch.

PR title (it becomes the squash commit on main, so it must be Conventional):

```
chore(xcode): bump version to <version> for App Store release
```

It must be a `chore` — a `feat`/`fix` PR title would make semantic-release mint a *new* tag on merge, leapfrogging the version being shipped.

## Part 2: Release notes

### Step 5: Validate the range

Run these checks (stop and report if any fail):

```
git rev-parse --verify <from-tag>^{commit}
git rev-parse --verify <until-tag>^{commit}
git merge-base --is-ancestor <from-tag> <until-tag>
```

If a tag does not exist, list available tags with `git tag --sort=-creatordate | head -10` and ask the user to pick one.

### Step 6: List commits and check range size

```
git log --oneline <from-tag>..<until-tag>
```

Every commit on main is a squash-merged PR, so this list is effectively the PR list for the release. If the range contains more than 40 commits, warn the user with the count and ask them to confirm before continuing.

### Step 7: Read code diffs

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
- If changes are ambiguous or you need to attribute them to a specific PR, drill into individual commit diffs from the Step 6 list — each one is a complete PR.
- **The code diff is the primary source for classification and writing — not commit messages.** Commit messages are hints at best; the diff is ground truth.

### Step 8: Classification rules

- **Omit entirely**: Changes invisible to someone using the app — CI, lint and formatting config, semantic-release setup, docs, Xcode project housekeeping, privacy manifests, dependency bumps — unless they have a user-visible side effect. (Asset changes are a judgment call: a redesigned icon or complication is user-visible; a re-export at new resolutions is not.)
- **New**: Significant new user-visible capabilities. Rebuilds or rewrites of existing features also go here, but describe them as improvements to existing functionality.
- **Improvements**: Minor enhancements, UX polish, and performance work the user would actually feel (e.g. a tab loading noticeably faster).
- **Fixes**: Anything a user would perceive as "that was broken and now it's fixed."
- **Platform scoping**: When a change is watch-only, say so ("On Apple Watch, …"). iPhone-side changes don't need a platform label. A change that spans both usually doesn't need the detail at all.

### Step 9: Writing rules

- Keep each bullet brief. Introducing the primary change is enough — don't over-explain.
  - Cut implementation details (SwiftUI/SwiftData terms, class or view names, sync internals) and where-the-fix-lives detail.
  - For fixes especially: state what now works correctly. Don't explain the bug's mechanics, name the counter that was off, or include the before/after math.
  - Cut narrow examples that read as exhaustive enumeration; a single broad phrase is better.
- **Frame positively.** Lead with what now works well, not what used to fail.
- **Match tone to the app.** Cairn's voice is calm, plain, and unhurried. No hype, no exclamation points. A quiet sentence that says what changed is the goal.
- **Use Cairn's own vocabulary** the way the app does — stones, cairn, moments, Path, Patterns — and never invent marketing names for things the app doesn't name.
- **One feature, one bullet.** When a feature ships alongside follow-up fixes to that same feature, fold everything into the feature bullet — users never saw the broken intermediate state. This applies across tags within the range: a feature from one tag and its fix from a later tag are one bullet.
- **Reclassify on review.** A bullet drafted under New may belong in Improvements if it's really an existing capability made better. Re-check section assignment after writing each bullet.
- Write in plain language for a general (non-technical) reader.
- Communicate user impact, not implementation.
- Group related changes into a single bullet with sub-bullets when it improves readability.
- Use a single hyphen `-` for asides, not em dashes (—) or double hyphens (--).
- Avoid LLM-voice clichés: don't use "seamlessly", "robust", "leverage", "ensures", "enhances", "streamlined", "elevate", or "whether you're…" constructions.
- Prefer short, direct sentences. Don't pad bullets with filler like "for a smoother experience" unless it adds real information.
- Vary sentence structure. Don't start every fix with "Fixed" or every feature with "You can now".

### Step 10: Write the notes

The file's body is pasted **verbatim** into App Store Connect's What's New field, which renders plain text — so no markdown ceremony at all: no title (the filename carries the version), no `#` headers, no `*` bullets. Plain section labels and hyphen bullets only. Use exactly this structure (omit any section that would be empty):

```
New

- <list>

Improvements

- <list>

Fixes

- <list>
```

Keep the whole thing well under App Store Connect's 4,000-character What's New limit.

### Step 11: Completeness check

Before writing the notes:

- Every user-visible commit must appear exactly once (individually or grouped with related changes).
- Internal-only commits may be omitted entirely — that is expected and correct.

### Step 12: Write to file

Write the final release notes to `docs/release-notes/<until-tag>.md` and report the output file path. In full release-prep mode, commit this file together with the version bump (Step 4).
