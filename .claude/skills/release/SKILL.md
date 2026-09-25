---
name: release
description: Ship an approved branch (commit, push, pull-request text) or, with "cut", roll the Unreleased changelog into a versioned release and tag it. Use after Gate 2 approval, or when the user asks to cut a release.
---

# Release

Two modes. **Default** ships the branch after Gate 2 (`AGENTS.md` Step 6). **`cut`** rolls
`## [Unreleased]` into a version. Both obey one rule above all: **never read
`CHANGELOG.md` whole.** Changelogs here run to 250 KB; reading one costs more context than the
task that prompted it. Work on the head of the file only.

## Ship (default)

1. Confirm Gate 2 was passed — an explicit yes from the user, not an inference.
2. Confirm the `## [Unreleased]` block has a line for this change. Read only the file head.
3. Stage by path. Commit as Conventional Commits:

   ```
   <type>(<scope>): <subject>

   <body — why, not what>

   Resolves #NN
   ```
   Types: `feat` `fix` `refactor` `test` `docs` `style` `perf` `chore`. The issue number
   lives in the body, **never** the subject — `#31 fix(...)` breaks every changelog generator.
4. Push the branch. Tell the user it is ready for a pull request against `develop`, with the
   PR title `<type>(<scope>): <subject>`. A hotfix targets `develop` like any other branch;
   say that it needs fast-track review and a release cut as soon as it merges.
5. Do not merge. That is the user's.

## Cut

1. Read the head of `.docs/CHANGELOG.md` to the `## [Unreleased]` heading and the latest
   version. Stop there.
2. `git log <last-tag>..HEAD --oneline --no-merges`. Any commit without a changelog line is a
   gap; Conventional Commit subjects map straight onto lines, which is why the format matters.
3. Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`; open a fresh empty `## [Unreleased]`
   above it. One line per entry, grouped Added / Changed / Fixed / Removed, linking the issue.
   Rationale belongs in `.docs/design/`, not here.
4. Semver: breaking → major, feature → minor, fix only → patch.
5. Run `scripts/check-framework.sh` if present and report what it says — drift surfacing as
   numbers at release time is the point. Do not fix it silently in the release commit.
6. Commit `chore(release): X.Y.Z`, tag, push the tag. Summarise what changed since the last
   release in three or four lines, not the whole block.
