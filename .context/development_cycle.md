# Development Cycle Workflow

> **Reference material, not authority.** `AGENTS.md` owns the cycle, the gates, the
> branch and plan locations, the coverage figures and the definition of done. Where this
> document and `AGENTS.md` differ, `AGENTS.md` wins and this document is the thing to fix.
> Do not read it end to end; open the checklist or procedure you need.

This document expands the protocol with checklists, worked commands and troubleshooting.
It applies to every repo under the framework root.

**Substitute the placeholders from the repo's `CLAUDE.md` before running anything:**

| Placeholder | Means | Example |
| --- | --- | --- |
| `{EXEC}` | the repo's exec prefix plus its framework CLI | `docker compose exec app php artisan`, `./vendor/bin/sail artisan`, `npm run` |
| `{EXEC_RAW}` | the repo's exec prefix alone | `docker compose exec app`, `./vendor/bin/sail` |
| `{EXEC_NODE}` | the repo's node service | `docker compose exec node`, `./vendor/bin/sail npm` |

The container service is named differently in almost every repo, so a literal
`docker compose exec app` is wrong in most of them. Take it from the repo's `CLAUDE.md`
rather than from memory. Anywhere this document names a project, a table or a port, treat
it as an example, not as a value to copy.

## How this document's steps map to the protocol

`AGENTS.md` defines the cycle in seven steps with two gates. This document was written
around eight and still uses its own numbering in the headings below. Use this mapping; the
protocol's shape is the one in force.

| This document | `AGENTS.md` |
| --- | --- |
| Step 1 GitHub Issue, Step 2 Project Plans | 1. Intake and plan (`/ticket`, `/plan`) → **Gate 1** |
| Step 3 Branch Creation | 2. Branch |
| Step 4 Coding | 3. Implement |
| Step 5 Testing | 4. Verify (`/verify`) |
| Step 6 UAT | 5. Review, then hand back → **Gate 2** — a reviewer subagent runs first |
| Step 7 Committing | 6. Ship (`/release`) |
| Step 8 Cleanup | 7. Cleanup |

Three differences worth naming. The protocol runs a **reviewer subagent before** UAT, so the
user reviews work already reviewed once. It has **work tiers**: a Trivial fix skips the
written plan and Gate 1 that Step 2 below describes. And its checklists — pre-flight, the
UAT hand-back, the definition of done — now live in the skills, so this document's copies are
the long-form reference, not the thing to follow.

## Step 1: GitHub Issue

Create a GitHub issue to track the work. Every task must have an associated issue.

### Prompt User to Create GitHub Issue

Ask the user to create a GitHub issue manually and provide the following information:

```
Please create a GitHub issue for this task and provide me with:

1. **GitHub Issue #:** [Issue number from GitHub]

2. **Description:**
   What needs to be done? Provide context about the feature, bug, or task.

3. **Acceptance Criteria:**
   What conditions must be met for this to be considered complete?
   - [ ] Criterion 1
   - [ ] Criterion 2
   - [ ] Criterion 3

4. **Expected Results:**
   What should the user see/experience when this is complete?
```

### Example Response from User
```
GitHub Issue #: 123

Description:
Users need to export reports in CSV format for analysis in Excel.
Currently only viewing reports in the browser is supported.

Acceptance Criteria:
- [ ] Export button appears on all report pages
- [ ] CSV file downloads with proper formatting
- [ ] All report data columns are included
- [ ] File name includes report type and date

Expected Results:
Users click "Export CSV" button and receive a downloadable CSV file
with all report data properly formatted for Excel.
```

### Record the Information
Once the user provides the issue details:
1. **Note the GitHub Issue #** - You'll use this for branch naming and commits
2. **Save the Description, Acceptance Criteria, and Expected Results** - You'll include these in the project plan (Step 2)

**Exit Criteria:** GitHub issue # and all details received from user.

---

## Step 2: Project Plans (Optional)

For complex features or architectural changes, create a project plan document.

### When to Create a Plan - Decision Tree:

**CREATE A PLAN IF ANY ARE TRUE:**
- ✅ Touches 3+ files/components
- ✅ Requires database schema changes
- ✅ Changes API contracts or endpoints
- ✅ Affects authentication/authorization
- ✅ Affects multiple user roles or permissions
- ✅ You're uncertain about implementation approach
- ✅ Requires architectural decisions

**SKIP PLAN IF ALL ARE TRUE:**
- ✅ Single file or component change
- ✅ No database changes
- ✅ Clear, straightforward implementation path
- ✅ Estimated < 2 hours of work
- ✅ No breaking changes

**When in doubt, create a plan.** Better to over-plan than under-plan.

### Create Plan Document
1. Create plan at `.docs/plans/<issue>-<slug>.md`
2. Use naming convention: `ISSUE-###-feature-name-plan.md`
3. **Include all details from Step 1** (GitHub issue information)
4. Add technical planning sections

### Plan Template

Use `../../.global-docs/TEMPLATE_PLAN.md`, saved to `.docs/plans/<issue>-<slug>.md`. This
document used to carry its own copy of the template; two copies drift, and a plan written
from the wrong one is a plan the reviewer cannot compare against the others. The protocol
adds three things the plan must state, whatever else it contains: every file it touches, the
**blast radius** (what breaks that the diff will not show), and whether it touches auth,
authorization, payments or PHI.

### Prompt User for Approval
Present the plan to the user and ask:
```
I've created a project plan for this feature. Please review:
[Link or summary of plan]

Does this approach look good, or would you like any changes?
```

**If approved:** Proceed to Step 3
**If not approved:** Update plan based on feedback and re-submit

**Exit Criteria:**
- Simple tasks: No plan needed, proceed to Step 3
- Complex tasks: Plan approved by user

---

## Step 3: Branch Creation

Create a feature branch from develop with the GitHub issue number.

### Branch Naming Convention
```
feature/###-descriptive-name   (for new features)
bug-fix/###-bug-description    (for bug fixes)
hotfix/###-critical-fix        (for critical production bugs)
chore/###-chore-description    (for tooling, dependencies, docs and test-only work)
```

Where `###` is the GitHub issue number.

### Create Branch
```bash
# Ensure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create and checkout feature branch
git checkout -b feature/123-csv-export

# Verify you're on the new branch
git branch
```

### Pre-Flight Checklist
Before starting development, verify your environment is ready:

```bash
# 1. Verify Docker containers are running
docker compose ps

# 2. Check disk space (need at least 5GB free)
df -h

# 3. Verify database is accessible
{EXEC} db:show

# 4. Run migrations to ensure database is up to date
{EXEC} migrate

# 5. Verify dependencies are installed
{EXEC_RAW} composer install
{EXEC_NODE} npm install

# 6. Verify test suite passes on base branch
{EXEC} test

# 7. Verify code coverage tools are available (requires Xdebug/PCOV)
{EXEC} test --coverage --min=1 2>&1 | grep -q "coverage" && echo "✅ Coverage available" || echo "❌ Coverage not configured"
```

**Pre-Flight Checklist:**
- [ ] Docker containers running
- [ ] Database accessible
- [ ] Migrations up to date
- [ ] Dependencies installed
- [ ] Base tests passing
- [ ] Code coverage tools working
- [ ] Adequate disk space
- [ ] .env file configured

**Exit Criteria:** Clean feature branch created from latest develop with verified working environment.

---

## Step 4: Coding

Implement the feature and write tests.

### Coding Standards

📘 **IMPORTANT**: Follow the comprehensive coding standards documented in:
- **`.claude/rules/*.md`** — stack standards, loaded automatically when you touch a matching file. Do not go looking for them; they arrive.
- **[reference/docker.md](./reference/docker.md)** — container conventions and the port registry
- **[reference/coding-standards-examples.md](./reference/coding-standards-examples.md)** — worked examples and rationale, repaired 2026-09-21. Reference, not rules: `.claude/rules/` wins where they differ.

### Development Principles
- **Single Responsibility:** Each function/class does one thing well
- **DRY:** Don't repeat yourself - extract common logic
- **SOLID:** Follow SOLID principles for OOP
- **Security First:** Validate input, escape output, use parameterized queries
- **Error Handling:** Implement proper try-catch blocks and logging

### Key Requirements Summary

#### PHP Backend
- **PHPDoc required** for all classes and methods (@param, @return, @throws)
- Implement Form Requests for validation
- Use Resource Controllers for REST APIs
- Implement Policies for authorization
- Services for complex business logic
- Follow PSR-12 coding standards
- Use type hints for all parameters and returns (strict mode)

#### Laravel Backend
- **PHPDoc required** for all classes and methods (@param, @return, @throws)
- Use Eloquent ORM (avoid raw queries)
- Implement Form Requests for validation
- Use Resource Controllers for REST APIs
- Implement Policies for authorization
- Services for complex business logic
- Follow PSR-12 coding standards
- Use type hints for all parameters and returns (strict mode)

#### Vue Frontend
- Use Composition API (required, not Options API)
- Implement proper prop validation with TypeScript
- Use Pinia for state management
- Follow Vue.js style guide
- Use TypeScript strict mode (no `any` types)
- Implement proper error handling

#### Stack detail lives in `.claude/rules/`, which loads by path — see `../../.claude/rules/README.md`

### Database Migrations (Laravel)
If database changes are needed:
```bash
# Create migration
{EXEC} make:migration descriptive_migration_name

# Edit migration file
# - Add hasTable/hasColumn checks for idempotency
# - Ensure reversible (proper down() method)

# Run migration
{EXEC} migrate

# Test rollback
{EXEC} migrate:rollback
{EXEC} migrate
```

**Database Migration Checklist:**
- [ ] Migration has existence checks (hasTable, hasColumn)
- [ ] Migration is reversible (down() method works)
- [ ] Foreign keys properly defined
- [ ] Indexes added for frequently queried columns

### Write Tests
**Test Coverage Requirements** (from `AGENTS.md` Rule 4 — the only figures in force):
- Overall codebase: 80%
- Authentication, authorization, payments and PHI: 100%
- Must be measured with pcov or Xdebug. No driver means report it as unmeasurable;
  never claim a number you did not measure.

```bash
# Create test
{EXEC} make:test Feature/CsvExportTest

# Run tests as you develop
{EXEC} test

# Run specific test
{EXEC} test --filter CsvExportTest
```

**Test Checklist:**
- [ ] Test happy path (expected behavior)
- [ ] Test edge cases (boundary conditions)
- [ ] Test error conditions (invalid input)
- [ ] Test authorization (permissions)
- [ ] Mock external dependencies
- [ ] Use factories for test data

**Exit Criteria:** Feature implemented with tests written.

---

## Step 5: Testing

Run the complete test suite to ensure nothing is broken.

### Run All Tests
```bash
# Run full Laravel test suite
{EXEC} test

# Run with coverage report
{EXEC} test --coverage

# Run frontend tests (if applicable)
{EXEC_NODE} npm run test
```

### Test Results

**If ALL tests pass:**
- ✅ Proceed to Step 6 (UAT)

**If ANY tests fail:**
- ❌ Analyze failure type (see troubleshooting below)
- Fix the issue
- Run tests again until all pass

### Test Failure Troubleshooting

**1. My new code broke existing tests:**
- ❌ **Don't modify the tests** - fix your code instead
- Ensure backward compatibility
- Review what the existing test expects
- Your code should work with existing functionality

**2. My new tests are failing:**
- Review test logic and assertions
- Check factory/seeder data
- Verify database state (migrations run?)
- Check for hardcoded values or dates
- Ensure proper test isolation (no shared state)

**3. Environmental issues (tests fail randomly):**
```bash
# Try these steps in order, stopping as soon as the tests pass:
{EXEC} restart
{EXEC} config:clear
{EXEC} cache:clear
{EXEC} test
```

**4. Database/migration conflicts:**

Do not reach for `migrate:fresh`. Find which migration conflicts and fix it — a suite that
only passes after the database is dropped is hiding the defect, not fixing it.

If a rebuild really is the only way forward, Non-Negotiable 2 applies: **dump first**,
save to `database/backups/`, then restore when testing is done.

```bash
{EXEC} migrate:status        # which migration is actually the problem?
{EXEC} migrate               # apply what is pending
```

**5. Code reveals architectural problems:**
- ⏸️ **PAUSE**: Do not proceed
- Consult with user about architectural changes needed
- May require design changes or refactoring
- Update project plan if one exists

**When to ask for help:**
- Tests fail and you can't determine why after troubleshooting
- Environmental issues persist
- Architectural conflicts discovered

### Linting
```bash
# Run PHP linter
{EXEC_RAW} composer run lint

# Run frontend linter
{EXEC_NODE} npm run lint

# Auto-fix linting issues
{EXEC_RAW} composer run lint:fix
{EXEC_NODE} npm run lint:fix
```

**Exit Criteria:** All tests pass, no linting errors.

---

## Step 6: UAT (User Acceptance Testing)

**⏸️ PAUSE: User Review Required**

The AI assistant must pause here and request user review.

### Present Changes to User

**UAT Presentation Checklist:**
Before presenting to user, prepare the following:
- [ ] Screenshots or GIF/video of new functionality
- [ ] List of modified files with line counts (+/-)
- [ ] Database changes summary (migrations, new tables/columns)
- [ ] Test coverage report (percentage and number of tests)
- [ ] Performance impact notes (if measurable)
- [ ] Specific URLs or routes to test
- [ ] Sample data or credentials for testing
- [ ] Step-by-step testing scenarios with expected results

**Present to user:**
```
I've completed the implementation for Issue #XXX. Here's what was done:

**Summary:**
- [Brief description of what was implemented]

**Changes Made:**
- [List of specific changes]
- Modified X files (+234/-56 lines)
- [Database changes if any]

**Tests:**
- [Number] new tests added
- All tests passing ✅
- Test coverage: X% (overall), Y% (new code)

**Testing Instructions:**
Please test the following scenarios:

1. **Scenario 1: [Name]**
   - Navigate to: [URL]
   - Steps: [Detailed steps]
   - Expected: [What should happen]

2. **Scenario 2: [Name]**
   - Navigate to: [URL]
   - Steps: [Detailed steps]
   - Expected: [What should happen]

**Sample Data:**
- Use account: [username/credentials if needed]
- Test with: [specific data to use]

**Screenshots/Demo:**
[Include screenshots or note where to see demo]

Please test the changes and let me know if:
✅ Everything works as expected (I'll proceed to commit)
❌ There are issues (I'll fix them before committing)
```

### Definition of Done
Before requesting UAT approval, verify:
- [ ] All acceptance criteria met (from issue)
- [ ] All tests passing (unit, feature, integration)
- [ ] Test coverage ≥80% overall, 100% for auth, authorization, payments and PHI, and measured
- [ ] No linting errors (PHP + frontend)
- [ ] No console errors or warnings (browser console)
- [ ] Database migrations tested (up and down)
- [ ] Responsive design verified (mobile, tablet, desktop)
- [ ] Keyboard navigation works
- [ ] No hardcoded values (uses config/env)
- [ ] Error handling implemented
- [ ] Loading states implemented
- [ ] Success/error messages shown to user
- [ ] Documentation updated (if applicable)

### User Decision

**If user approves (✅):**
- Proceed to Step 7 (Committing)

**If user requests changes (❌):**
- Return to Step 4
- Make requested modifications
- Return to Step 5 (run tests again)
- Return to Step 6 (request approval again)

**Exit Criteria:** User explicitly approves the changes.

---

## Step 7: Committing

Commit changes, push to remote, create pull request, and merge.

### Self-Review Checklist
Before committing, perform a final review:
- [ ] No commented-out code left in files
- [ ] No debug statements (console.log, dd(), var_dump(), dump())
- [ ] No TODO or FIXME comments without GitHub issues
- [ ] No hardcoded values (use .env or config files)
- [ ] No security vulnerabilities (SQL injection, XSS, CSRF)
- [ ] Proper error handling throughout
- [ ] Loading states implemented for async operations
- [ ] Edge cases handled
- [ ] Performance considerations addressed (N+1 queries, large loops)
- [ ] Sensitive data not logged or exposed
- [ ] API responses properly structured
- [ ] User feedback messages clear and helpful

### Update Documentation

**Update CHANGELOG.md:**
Document your changes in `.docs/CHANGELOG.md`:
```markdown
## [Unreleased]

### YYYY-MM-DD - Brief Feature Description

#### Added
- CSV export functionality for all report types (Issue #123)
- Export button in Report/Index.vue with loading state

#### Changed
- Updated ReportController to support multiple export formats
- Enhanced ExportController with CSV formatters

#### Fixed
- Resolved date formatting issue in report generation
- Fixed timezone handling in exported dates

#### Removed
- (if applicable)
```

**Update the plan:**
Mark completed tasks in `.docs/plans/<issue>-<slug>.md`:
```markdown
- Change [ ] to [x] for completed tasks
- Add notes if implementation differs from plan
- Set the plan's Status when the work is done
```
There is no master `PLAN.md` and no `.docs/project-plans/` directory. One plan per issue.

### Stage and Commit
```bash
# Stage by path — never `git add .`, `git add -A` or `git commit -a`
git status
git add app/Services/ReportExporter.php tests/Feature/CsvExportTest.php

# Create commit with conventional commit format
git commit -m "feat(reports): add CSV export functionality

Implemented CSV export for all report types with proper formatting.
Users can now download reports as CSV files for external analysis.

Resolves #123

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### Commit Message Format

**Structure:**
```
<type>(<scope>): <subject>

<body>

Resolves #<issue-number>

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Commit Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no functional changes)
- `test`: Adding/updating tests
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic changes)
- `perf`: Performance improvements
- `chore`: Build process, dependencies, tooling (branch prefix `chore/`)

**Scope Examples:**
- `auth`: Authentication
- `reports`: Reporting system
- `activities`: Activity tracking
- `admin`: Admin panel
- `database`: Database changes
- `api`: API endpoints

### Push and Create Pull Request
```bash
# Push branch to remote
git push -u origin feature/123-csv-export
```

### Prompt User to Create Pull Request and Merge

**Prompt the user:**
```
Branch has been pushed successfully! Please complete the following steps on GitHub:

1. **Create Pull Request:**
   - Navigate to the repository on GitHub
   - Click "Compare & pull request"
   - Set compare branch: feature/###-descriptive-name
   - Set base branch: develop
   - Title: feat(scope): description
   - Description:
     ## Summary
     - [List of changes]

     ## Testing
     - [x] Unit tests pass
     - [x] Integration tests pass
     - [x] Manual UAT completed

     ## Related Issue
     Resolves #123

     🤖 Generated with [Claude Code](https://claude.com/claude-code)

2. **Get Approval & Merge:**
   - Get required approvals from reviewers
   - Merge to develop branch
   - Delete remote branch (if not auto-deleted)

Once merged, please confirm so I can clean up your local branch.
```

<!-- FUTURE: Create via GitHub CLI (see `.docs/design/0002-github-mcp.md`)
```bash
# Create pull request
gh pr create --base develop \
  --title "feat(reports): add CSV export" \
  --body "..."

# Merging stays with the user
```
-->

**Exit Criteria:** User confirms merge is complete.

---

## Step 8: Cleanup

Clean up your local environment after user confirms the merge is complete.

**Prerequisites:** User has confirmed the pull request was successfully merged to develop.

### Switch Back to Develop
```bash
# Switch to develop branch
git checkout develop

# Pull latest changes (includes your merged feature)
git pull origin develop

# Verify your changes are in develop
git log --oneline -5
```

### Delete Local Branch
```bash
# Delete the feature branch locally
git branch -d feature/123-csv-export

# If branch wasn't fully merged and you're sure you want to delete
git branch -D feature/123-csv-export
```

### Close GitHub Issue

**Prompt the user to close the GitHub issue:**
```
The task is complete! Please close GitHub Issue #XXX:

1. Navigate to the issue on GitHub
2. Add a comment: "Completed and merged to develop ✅"
3. Click "Close issue"

This will mark the issue as resolved.
```

<!-- FUTURE: When the GitHub CLI or MCP server is configured
```bash
# Close via GitHub CLI, with a closing comment
gh issue close 123 --comment "Completed and merged to develop ✅"
```
-->

### Verify Clean State
```bash
# Verify you're on develop
git branch

# Verify no uncommitted changes
git status

# Verify Docker containers still running
docker compose ps
```

**Exit Criteria:**
- Switched to develop branch
- Local feature branch deleted
- GitHub issue closed
- Clean working directory

---

## Emergency Procedures

### Hotfix Process
For critical production bugs requiring an immediate fix. **A hotfix follows the same path as
every other branch — from `develop`, back to `develop`.** What differs is the pace: minimal
change, fast-track review, and a release cut as soon as it merges. There is no separate
`main`-based flow; an earlier version of this document described one, and it was wrong.

1. **Create hotfix issue** on GitHub with the "hotfix" label
2. **Create the branch** from an up-to-date `develop`
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b hotfix/456-critical-security-fix
   ```
3. **Make minimal changes** — only what fixes the issue
4. **Test thoroughly** — `/verify` as usual; a hotfix is not a reason to skip the ledger
5. **Fast-track review** — notify the team immediately; Gate 2 still applies
6. **Merge to `develop`**
7. **Cut a release** (`/release cut`) so the fix reaches `main` and production without waiting
   for the normal cycle

### Rollback Process
If a merged feature causes issues:

1. **Revert the merge commit:**
   ```bash
   git checkout develop
   git revert -m 1 <merge-commit-hash>
   git push origin develop
   ```
2. **Notify team** of rollback
3. **Document issue** on GitHub
4. **Fix in new branch** following standard process

---

## Best Practices Summary

### Do's ✅
- Create GitHub issue for every task
- Get user approval on plans before coding
- Write tests as you code (TDD preferred)
- Run full test suite before requesting UAT
- Get explicit user approval before committing
- Update CHANGELOG.md and the issue's plan before committing
- Use conventional commit format
- Clean up branches after merge

### Don'ts ❌
- Skip creating GitHub issue
- Skip user approval (UAT step)
- Commit without running tests
- Merge without user approval
- Skip updating CHANGELOG.md or the issue's plan
- Leave dead branches lying around
- Commit directly to develop
- Push untested code
- Leave debug statements in code
- Hardcode values that should be in config/env

---

## Tools & Commands Reference

### Useful Laravel Commands
```bash
# Run migrations
{EXEC} migrate

# Rollback last migration
{EXEC} migrate:rollback

# Fresh migration DROPS ALL TABLES. Non-Negotiable 2: dump to database/backups/ first,
# restore when testing is done. Prefer fixing the offending migration.

# Run tests
{EXEC} test

# Run tests with coverage
{EXEC} test --coverage

# Run linter
{EXEC_RAW} composer run lint

# Clear caches
{EXEC} cache:clear
{EXEC} config:clear
{EXEC} route:clear
{EXEC} view:clear
```

### Useful Git Commands
```bash
# Stash uncommitted changes
git stash

# Apply stashed changes
git stash pop

# View commit history
git log --oneline --graph

# View changes in a file
git diff filename.php

# Undo last commit, keeping the changes staged
git reset --soft HEAD~1

# To discard committed work, use `git revert <sha>`: it is reviewable and recoverable.
# `git reset --hard` destroys work with no way back and is not house practice.
```

### Docker Commands
```bash
# Start containers
docker compose up -d

# Stop containers
docker compose down

# View logs
docker compose logs -f app

# Execute command in container
{EXEC} migrate

# Rebuild containers
docker compose up -d --build

# View running containers
docker compose ps
```

<!-- FUTURE: GitHub CLI Commands (when configured)
### GitHub CLI Commands (gh)
```bash
# Install gh: https://cli.github.com

# Authenticate
gh auth login

# Create issue
gh issue create

# View issue
gh issue view 123

# Close issue
gh issue close 123

# Create pull request
gh pr create --base develop

# View pull request
gh pr view 456
```
-->

---

## Questions?

If you have questions about this workflow:
1. Check existing project documentation in `.docs/`
2. Ask in team chat/Slack
3. Bring up in standup/team meeting
4. Update this document with clarifications

---

**Version:** 3.2.0
**Last Updated:** 2026-09-22

---

## Changelog

### Version 3.2.0 (2026-09-21)
**Second pass, reconciled with the rewritten `AGENTS.md`:**
- Hotfix procedure corrected: hotfixes branch from `develop` and merge back to it like every
  other branch, then release promptly. The `main`-based flow this document described did not
  match team practice
- Step mapping updated to the final protocol (Ship / `/release`; reviewer subagent before UAT)
- Embedded plan template removed in favour of `TEMPLATE_PLAN.md`; one template, one path
- Checklists (pre-flight, UAT hand-back, definition of done) are now skill content; the
  copies here are reference

### Version 3.1.0 (2026-09-21)
**Reconciled with `AGENTS.md` (framework review):**
- Demoted to reference; `AGENTS.md` is authoritative where the two differ
- Coverage stated once: 80% overall, 100% for auth, authorization, payments and PHI
- Branch prefix `task/` replaced by `chore/`
- One plan path: `.docs/plans/<issue>-<slug>.md`; `PROJECT_PLAN.md` and
  `.docs/project-plans/` removed — neither ever existed
- `git add .` replaced with staging by path

### Version 3.0.0 (2025-11-25)
**Major improvements to workflow clarity and completeness:**
- Added clear decision tree for "when to create a plan" (Step 2)
- Added comprehensive pre-flight checklist with code coverage verification (Step 3)
- Added detailed test failure troubleshooting guide (Step 5)
- Added UAT presentation checklist and Definition of Done (Step 6)
- Added self-review checklist before committing (Step 7)
- Moved CHANGELOG.md and PROJECT_PLAN.md updates to Step 7 (before commit)
- Added requirement to update PROJECT_PLAN.md for all tasks
- Enhanced best practices with additional guidance
- Improved error handling and troubleshooting throughout

### Version 2.0.0 (2025-11-21)
- Initial structured workflow with 8 steps
- Added conventional commit format
- Added UAT approval gate
- Added hotfix and rollback procedures
