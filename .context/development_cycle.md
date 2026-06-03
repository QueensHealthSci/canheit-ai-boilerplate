# Development Cycle Workflow

This document defines the standardized development process for projects in this boilerplate.
All team members and AI assistants must follow this workflow to ensure consistency, quality,
and maintainability.

> This example uses **GitHub** (Issues + Pull Requests) and a `develop` integration branch.
> Adapt the tooling references to your own host (GitHub, GitLab, Bitbucket) as needed.

## Workflow Overview

1. **GitHub Issue** — Create an issue to track the work
2. **Project Plans** — Plan complex features (AI drafts, with a User Approval Gate)
3. **Branch Creation** — Create a feature branch from `develop` (AI)
4. **Coding** — Implement the feature and write tests (AI)
5. **Testing** — Run automated tests (AI)
6. **UAT** — User acceptance testing (User)
7. **Committing** — Commit the code and documentation, then push the branch (AI)
8. **Pull Request** — Advise the user the branch is ready for a PR and review (AI)
9. **Cleanup** — Once the user confirms the merge, run the cleanup commands (AI)

## Step 1: GitHub Issue

Create a GitHub issue to track the work. Every task must have an associated issue.

### Prompt User to Create the Issue

Ask the user to create a GitHub issue and provide the following:

```
Please create a GitHub issue for this task and provide me with:

1. **Issue #:** [Issue number from GitHub]

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
Issue #: 123

Description:
Users need to export the task list as CSV for analysis in a spreadsheet.
Currently only viewing tasks in the browser is supported.

Acceptance Criteria:
- [ ] Export button appears on the task list page
- [ ] CSV file downloads with proper formatting
- [ ] All task columns are included
- [ ] File name includes project name and date

Expected Results:
Users click "Export CSV" and receive a downloadable CSV file
with all task data properly formatted.
```

### Record the Information
Once the user provides the issue details:
1. **Note the Issue #** — You'll use this for branch naming and commits
2. **Save the Description, Acceptance Criteria, and Expected Results** — You'll include these in the project plan (Step 2)

**Exit Criteria:** Issue # and all details received from the user.

---

## Step 2: Project Plans (Optional)

For complex features or architectural changes, create a project plan document.

### When to Create a Plan — Decision Tree

**CREATE A PLAN IF ANY ARE TRUE:**
- ✅ Touches 3+ files/components
- ✅ Requires database schema changes
- ✅ Changes API contracts or endpoints
- ✅ Affects authentication/authorization
- ✅ Affects multiple user roles or permissions
- ✅ You're uncertain about the implementation approach
- ✅ Requires architectural decisions

**SKIP PLAN IF ALL ARE TRUE:**
- ✅ Single file or component change
- ✅ No database changes
- ✅ Clear, straightforward implementation path
- ✅ Estimated < 2 hours of work
- ✅ No breaking changes

**When in doubt, create a plan.** Better to over-plan than under-plan.

### Create Plan Document
1. Create the plan in `.docs/project-plans/`
2. Use the naming convention: `ISSUE-###-feature-name-plan.md`
3. **Include all details from Step 1**
4. Add technical planning sections (see `.global-docs/TEMPLATE_PLAN.md`)

### Prompt User for Approval
Present the plan to the user and ask:
```
I've created a project plan for this feature. Please review:
[Link or summary of plan]

Does this approach look good, or would you like any changes?
```

**If approved:** Proceed to Step 3
**If not approved:** Update the plan based on feedback and re-submit

**Exit Criteria:**
- Simple tasks: No plan needed, proceed to Step 3
- Complex tasks: Plan approved by the user

---

## Step 3: Branch Creation

Create a feature branch from `develop` with the issue number.

### Branch Naming Convention
```
feature/###-descriptive-name   (for new features)
bug-fix/###-bug-description     (for bug fixes)
hotfix/###-critical-fix         (for critical production bugs)
chore/###-task-description      (for tasks/chores)
```

Where `###` is the issue number.

### Create Branch
```bash
# Ensure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create and checkout the feature branch
git checkout -b feature/123-csv-export

# Verify you're on the new branch
git branch
```

### Pre-Flight Checklist
Before starting development, verify your environment is ready:

```bash
# 1. Verify containers are running
docker compose ps

# 2. Check disk space
df -h

# 3. Verify the test suite passes on the base branch
docker compose exec app <test command>
```

**Pre-Flight Checklist:**
- [ ] Containers running
- [ ] Database accessible (if applicable)
- [ ] Dependencies installed
- [ ] Base tests passing
- [ ] Coverage tooling working
- [ ] `.env` file configured

**Exit Criteria:** Clean feature branch created from latest `develop` with a verified working environment.

---

## Step 4: Coding

Implement the feature and write tests.

### Coding Standards

📘 **IMPORTANT:** Follow the comprehensive standards documented in:
- **[rules/coding_standards.md](./rules/coding_standards.md)** — language/framework standards
- **[docker_setup.md](./docker_setup.md)** — container configuration

### Development Principles
- **Single Responsibility:** Each function/class does one thing well
- **DRY:** Don't repeat yourself — extract common logic
- **SOLID:** Follow SOLID principles for OOP
- **Security First:** Validate input, escape output, use parameterized queries
- **Error Handling:** Implement proper try/catch (or try/except) and logging

### Write Tests
**Test Coverage Requirements:**
- Overall codebase: 80%
- Critical business logic: 80%+
- Authentication/authorization: 100%
- Security-sensitive operations: 100%

**Test Checklist:**
- [ ] Test the happy path (expected behavior)
- [ ] Test edge cases (boundary conditions)
- [ ] Test error conditions (invalid input)
- [ ] Test authorization (permissions)
- [ ] Mock external dependencies
- [ ] Use factories/fixtures for test data

**Exit Criteria:** Feature implemented with tests written.

---

## Step 5: Testing

Run the complete test suite to ensure nothing is broken.

### Run All Tests
```bash
# Run the full suite with coverage (command varies by stack)
docker compose exec app <full suite command> --coverage
```

### Test Results

**If ALL tests pass:** ✅ Proceed to Step 6 (UAT)

**If ANY tests fail:** ❌ Analyze the failure, fix the issue, and run again until all pass.

### Test Failure Troubleshooting

**1. My new code broke existing tests:**
- ❌ **Don't modify the tests** — fix your code instead
- Review what the existing test expects; ensure backward compatibility

**2. My new tests are failing:**
- Review test logic and assertions
- Check fixture/seed data and database state
- Check for hardcoded values or dates
- Ensure proper test isolation (no shared state)

**3. Environmental issues (tests fail randomly):**
```bash
docker compose restart app
# clear caches / reset the test database as appropriate for your stack
```

**4. Code reveals architectural problems:**
- ⏸️ **PAUSE** — do not proceed
- Consult the user about architectural changes
- Update the project plan if one exists

**Exit Criteria:** All tests pass, no linting errors.

---

## Step 6: UAT (User Acceptance Testing)

**⏸️ PAUSE: User Review Required**

The AI assistant must pause here and request user review.

### Present Changes to User

**UAT Presentation Checklist:**
- [ ] Screenshots or a short clip of the new functionality
- [ ] List of modified files with line counts (+/-)
- [ ] Database changes summary (migrations, new tables/columns)
- [ ] Test coverage report (percentage and number of tests)
- [ ] Specific URLs or routes to test
- [ ] Sample data or credentials for testing
- [ ] Step-by-step testing scenarios with expected results

**Present to the user:**
```
I've completed the implementation for Issue #XXX. Here's what was done:

**Summary:**
- [Brief description]

**Changes Made:**
- [List of specific changes]
- Modified X files (+234/-56 lines)
- [Database changes if any]

**Tests:**
- [Number] new tests added
- All tests passing ✅
- Test coverage: X% (overall), Y% (new code)

**Testing Instructions:**
1. **Scenario 1: [Name]** — Navigate to [URL], do [steps], expect [result]
2. **Scenario 2: [Name]** — Navigate to [URL], do [steps], expect [result]

Please test and let me know:
✅ Everything works (I'll proceed to commit)
❌ There are issues (I'll fix them before committing)
```

### Definition of Done
Before requesting UAT approval, verify:
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Test coverage ≥80% (100% for auth/security)
- [ ] No linting errors
- [ ] No console errors or warnings
- [ ] Database migrations tested (up and down)
- [ ] No hardcoded values (uses config/env)
- [ ] Error handling implemented
- [ ] Success/error messages shown to the user
- [ ] Documentation updated

### User Decision

**If the user approves (✅):** Proceed to Step 7 (Committing)
**If the user requests changes (❌):** Return to Step 4, make changes, re-run tests, re-request approval

**Exit Criteria:** User explicitly approves the changes.

---

## Step 7: Committing

Commit the changes (and all updated documentation) and push the feature branch.

### Self-Review Checklist
Before committing, perform a final review:
- [ ] No commented-out code left in files
- [ ] No debug statements (`console.log`, `dd()`, `var_dump()`, `print()`, `pdb.set_trace()`)
- [ ] No TODO/FIXME comments without an issue
- [ ] No hardcoded values (use `.env` or config)
- [ ] No security vulnerabilities (SQL injection, XSS, CSRF)
- [ ] Proper error handling throughout
- [ ] Edge cases handled
- [ ] Performance considerations addressed (N+1 queries, large loops)
- [ ] Sensitive data not logged or exposed

### Update Documentation

**Update `.docs/CHANGELOG.md`:**
```markdown
## [Unreleased]

### YYYY-MM-DD - Brief Feature Description

#### Added
- CSV export for the task list (Issue #123)

#### Changed
- Updated TaskController to support multiple export formats

#### Fixed
- Resolved date formatting issue in export
```

**Update the project plan:** Mark completed tasks `[x]` and update progress.

### Stage and Commit
```bash
git add .

git commit -m "feat(tasks): add CSV export

Implemented CSV export for the task list with proper formatting.
Users can now download tasks as a CSV file for external analysis.

Resolves #123"
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

Resolves #<issue-number>
```

**Commit Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `style`, `perf`, `chore`

**Scope Examples:** `auth`, `tasks`, `projects`, `comments`, `database`, `api`

### Push the branch
```bash
git push -u origin feature/123-csv-export
```

**Exit Criteria:** All changes (code + documentation) committed and pushed to the feature branch.

---

## Step 8: Pull Request

Open a pull request for review and merge.

**Prompt the user:**
```
Branch pushed successfully! Please open a Pull Request on GitHub:

1. Source branch: feature/###-descriptive-name
2. Target branch: develop
3. Title: feat(scope): Description (#123)
4. Description:
   ## Summary
   - [List of changes]

   ## Testing
   - [x] Unit tests pass
   - [x] Feature tests pass
   - [x] Manual UAT completed

   ## Related Issue
   Resolves #123

Once merged, please confirm so I can clean up your local branch.
```

> **Optional:** with the GitHub CLI configured you can automate this:
>
> ```bash
> gh pr create --base develop --head feature/123-csv-export \
>   --title "feat(tasks): add CSV export (#123)" --body "..."
> ```

**Exit Criteria:** User confirms the merge is complete.

---

## Step 9: Cleanup

Clean up your local environment after the user confirms the merge.

**Prerequisites:** User has confirmed the PR was merged to `develop`.

```bash
# Switch back to develop and pull the merged changes
git checkout develop
git pull origin develop

# Delete the local feature branch
git branch -d feature/123-csv-export

# Prune deleted upstream branches
git fetch --prune

# Verify clean state
git branch
git status
```

**Prompt the user to close the issue:**
```
The task is complete! Please close Issue #XXX with a comment:
"Completed and merged to develop ✅"
```

> **Optional** with the GitHub CLI:
>
> ```bash
> gh issue close 123 -c "Completed and merged to develop ✅"
> ```

### Clear the Session
 
**Prompt the user to clear the session once cleanup is complete:**
```
Task complete and cleanup done! Please clear this session (/clear)
before starting the next task to reset context.
```
 
**Exit Criteria:**
- Switched to develop branch
- Local feature branch deleted
- GitLab issue closed
- Clean working directory
- User prompted to clear the session

---

## Emergency Procedures

### Hotfix Process
For critical production bugs requiring an immediate fix:

1. **Create a hotfix issue** with the "hotfix" label
2. **Create a hotfix branch** from `main` (not `develop`)
   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/456-critical-fix
   ```
3. **Make minimal changes** (only what's needed)
4. **Test thoroughly**
5. **Fast-track review** — notify the team immediately
6. **Merge to `main`** — deploy
7. **Merge to `develop`** — ensure the fix is in `develop` too

### Rollback Process
If a merged feature causes issues:

```bash
git checkout develop
git revert -m 1 <merge-commit-hash>
git push origin develop
```

Then notify the team, document the issue, and fix in a new branch following the standard process.

---

## Best Practices Summary

### Do's ✅
- Create an issue for every task
- Get user approval on plans before coding
- Write tests as you code (TDD preferred)
- Run the full test suite before requesting UAT
- Get explicit user approval before committing
- Update `CHANGELOG.md` and the project plan before committing
- Use conventional commit format
- Clean up branches after merge

### Don'ts ❌
- Skip creating an issue
- Skip user approval (UAT step)
- Commit without running tests
- Merge without user approval
- Skip updating documentation
- Commit directly to `develop` or `main`
- Push untested code
- Leave debug statements in code
- Hardcode values that belong in config/env

---

**Version:** 1.0.0
**Last Updated:** 2026-06-01
