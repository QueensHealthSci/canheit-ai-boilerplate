> # Worked examples — reference, not rules
>
> **The rules live in the framework root's `.claude/rules/`** (path-scoped files that load when you
> touch a matching file). This document is the long-form companion: worked examples,
> rationale and the fuller treatment of topics the rule files state in a line. Where the two
> disagree, the rule file wins.
>
> **Repaired.** An end-to-end audit found the examples contradicting the
> document's own rules and the rules contradicting the code. Twenty-two defects were fixed
> in place:
>
> | Was | Now |
> | --- | --- |
> | `->latest()` in a controller, ordering by the forbidden `created_at` | explicit `orderBy('created_date', 'desc')`, with the reason |
> | `env('EXTERNAL_API_URL')` in application code | `config('services.external.url')`, with the `config/` file that reads the variable |
> | error handler logging the full `$data` payload | identifiers only, and the original exception chained via `previous:` instead of erased |
> | `@vueuse/core` imported, depended on by no repo | hand-rolled debounce, with a note |
> | "All applications use `deleted_date`" | stated per lineage — legacy-lineage repos do, Laravel-default repos use `SoftDeletes`, Prisma repos use `deletedAt` |
> | "Legacy apps MUST use PDO" | match the repo's existing DB abstraction layer where there is one, PDO elsewhere |
> | PrimeVue `Dropdown` / `Calendar` | `Select` / `DatePicker` — renamed in PrimeVue 4, which every repo runs |
> | Pinia required | marked optional; Inertia shared data is the default pattern |
> | `->whereNull('deleted_date')` beside the global scope that already does it | removed, with the reason |
> | service taking `array $data` next to a section requiring DTOs | takes the DTO; the section says where the line falls |
> | naming table and soft-delete pattern each stated twice | stated once, cross-referenced |
> | project-prefixed table and CSS names | generic `learners`, `brand-orange` |
> | "Native PHP 8.3+" | no version claim — PHP and Laravel versions differ from repo to repo |
>
> Two things were **not** changed. Coverage figures were already correct and read
> 80/100. The four `ActivityService` definitions are independent illustrations of
> different points, not one class contradicting itself, and are now labelled as such.

# Coding Standards

> **A note on the examples.** `ActivityService`, `Activity` and `learners` recur throughout
> as illustrative names. The four `ActivityService` definitions below are **independent
> examples of different points** — PHPDoc, error handling, separation of concerns, the
> service layer — not one class shown evolving. Do not read them as contradicting each
> other, and do not assemble them into a single class.

This document defines the coding standards and best practices for all applications managed by the team. We maintain two types of applications:

- **Legacy applications** — in-house PHP frameworks on MySQL 8.0, a DB abstraction layer or PDO, jQuery, vanilla HTML/CSS
- **Modern applications** — Laravel, Inertia.js, Vue 3, TypeScript, PrimeVue 4, Tailwind CSS
- **TypeScript applications** — NestJS, Next.js, Prisma on Postgres

Versions differ per repo and are not stated here, because they drift. Read
`composer.json` or `package.json` in the repo you are in.

Standards are organized into three groups: **Shared** (applies everywhere), **Legacy** (native PHP apps), and **Modern** (Laravel stack).

---

## Table of Contents

### Shared Standards
1. [Non-Negotiables](#non-negotiables)
2. [General PHP Rules](#general-php-rules)
3. [PHPDoc Documentation](#phpdoc-documentation)
4. [Database Standards](#database-standards)
5. [Security Standards](#security-standards)
6. [Error Handling & Logging](#error-handling--logging)
7. [Testing Standards](#testing-standards)
8. [Performance Standards](#performance-standards)
9. [Environment & Configuration](#environment--configuration)

### Legacy Application Standards
10. [Legacy Architecture](#legacy-architecture)
11. [Legacy Frontend](#legacy-frontend)
12. [Legacy Database Access](#legacy-database-access)

### Modern Application Standards (Laravel)
13. [Laravel Architecture](#laravel-architecture)
14. [Vue/TypeScript Standards](#vuetypescript-standards)
15. [Inertia.js Patterns](#inertiajs-patterns)
16. [PrimeVue Usage](#primevue-usage)
17. [Tailwind CSS Conventions](#tailwind-css-conventions)
18. [API Standards](#api-standards)

### Reference
19. [Modernization Guidelines](#modernization-guidelines)
20. [File Structure Conventions](#file-structure-conventions)
21. [Code Review Checklist](#code-review-checklist)

---

# Shared Standards

These standards apply to **all** code — legacy and modern.

---

## Non-Negotiables

Every PHP file, every pull request, every time. No exceptions.

1. **Strict types.** All PHP files (classes, interfaces, traits, tests) MUST begin with `declare(strict_types=1);`.
2. **Type hints.** All function/method parameters, return types, and class properties MUST have explicit type declarations.
3. **PHPDoc.** All classes and public methods MUST have PHPDoc comments with `@param`, `@return`, and `@throws` tags.
4. **No raw SQL with string interpolation.** All database queries MUST use parameterized bindings or an ORM.
5. **Input validation.** All user input MUST be validated before use.
6. **PSR-12.** All PHP code MUST follow PSR-12 coding standards.
7. **No `any` types.** TypeScript code MUST NOT use `any`. Define proper types or use `unknown` with type guards.

---

## General PHP Rules

These rules apply to all PHP code regardless of framework.

### Formatting
- 4 spaces for indentation (no tabs)
- Opening braces on same line for classes and methods
- One blank line after namespace declaration
- Max line length: 120 characters
- Always use full `<?php` tags (never short tags)

### Type Hints

Always use type hints for parameters, return types, and properties:

```php
<?php

declare(strict_types=1);

// ✅ Correct: Fully typed
public function findActiveUsers(int $limit = 10): Collection
{
    return $this->repository->getActive($limit);
}

public function findById(int $id): ?User
{
    return User::find($id);
}

// ❌ Wrong: No type hints
public function doSomething($data)
{
    return $data;
}
```

### Named Arguments

Preferred for boolean flags or functions with 3+ arguments:

```php
// ✅ Clear intent
$this->createActivity(
    learnerId: $learner->id,
    hospitalId: $hospital->id,
    isTemporary: true,
);

// ❌ Ambiguous
$this->createActivity($learner->id, $hospital->id, true);
```

### Naming Conventions

| What | Convention | Example |
|------|------------|---------|
| Class | PascalCase | `ActivityService`, `LearnerProgram` |
| Method / Function | camelCase | `createActivity()`, `validateDateOverlap()` |
| Variable | camelCase | `$activityData`, `$hospitalId` |
| Constant | UPPER_SNAKE_CASE | `MAX_PERCENTAGE`, `DEFAULT_LIMIT` |
| Table | plural, snake_case | `activities`, `learner_programs` |
| Column | snake_case | `learner_id`, `created_date` |
| Primary Key | `{table_singular}_id` | `activity_id`, `learner_id` |
| Foreign Key | `{referenced_table_singular}_id` | `learner_id`, `hospital_id` |
| Pivot Table | alphabetical, singular | `hospital_user`, `program_service` |

---

## PHPDoc Documentation

All classes, public methods, and complex private methods MUST have PHPDoc comments.

### Complete Example

This single example demonstrates all required patterns — class-level docs, constructor docs, method docs with `@param`/`@return`/`@throws`, and complex logic descriptions:

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Activity;
use App\Models\Quarter;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

/**
 * Service for managing medical training activities.
 *
 * Handles creation, updating, deletion, and validation of learner activities
 * including date overlap checking and history tracking.
 */
class ActivityService
{
    /**
     * Create a new ActivityService instance.
     *
     * @param QuarterService $quarterService Service for quarter validation
     * @param ActivityHistoryService $historyService Service for activity history
     */
    public function __construct(
        private readonly QuarterService $quarterService,
        private readonly ActivityHistoryService $historyService
    ) {}

    /**
     * Create a new activity with validation and history tracking.
     *
     * Validates date ranges, checks for overlaps, and creates an activity
     * history entry upon successful creation.
     *
     * @param array<string, mixed> $data Activity data from form request
     * @return Activity The newly created activity
     * @throws ValidationException If date overlap detected
     * @throws QuarterBoundaryException If dates outside quarter boundaries
     */
    public function createActivity(array $data): Activity
    {
        $this->validateDateOverlap($data);

        $activity = Activity::create($data);

        $this->historyService->createHistory($activity, 'created');

        return $activity;
    }

    /**
     * Validate and resolve date overlaps for activity scheduling.
     *
     * Performs multi-step validation:
     * 1. Checks if dates fall within valid quarter boundaries
     * 2. Verifies no overlap with existing activities for the learner
     * 3. Validates that combined percentages don't exceed 100% for any day
     *
     * @param array<string, mixed> $data Activity data containing learner_id, start_date, end_date
     * @param int|null $excludeActivityId Activity ID to exclude from overlap check (for updates)
     * @return bool True if validation passes
     * @throws ValidationException If validation fails with specific error details
     */
    private function validateDateOverlap(array $data, ?int $excludeActivityId = null): bool
    {
        // Implementation
    }

    /**
     * Get activities by learner within a date range.
     *
     * @param int $learnerId The learner's ID
     * @param int $startDate Unix timestamp for range start
     * @param int $endDate Unix timestamp for range end
     * @return Collection<int, Activity> Collection of matching activities
     */
    public function getActivitiesByLearner(
        int $learnerId,
        int $startDate,
        int $endDate
    ): Collection {
        return Activity::where('learner_id', $learnerId)
            ->whereBetween('start_date', [$startDate, $endDate])
            ->get();
    }
}
```

### PHPDoc Checklist

**Classes:**
- [ ] Class-level PHPDoc with description of responsibility

**Methods/Functions:**
- [ ] Description of what the method does
- [ ] `@param` for each parameter with type and description
- [ ] `@return` with type and description (if not void)
- [ ] `@throws` for each exception that can be thrown
- [ ] `@deprecated` if method is deprecated

**Simple getters/setters** require PHPDoc but can be brief:

```php
/**
 * Get the learner's full name.
 *
 * @return string Full name in "Firstname Lastname" format
 */
public function getFullName(): string
{
    return "{$this->firstname} {$this->lastname}";
}
```

---

## Database Standards

### Naming Conventions

See the naming table under [General PHP Rules](#naming-conventions) — tables, columns, keys
and pivots are listed there once and are not repeated here.

**Timestamps depend on the repo's declared lineage**, and this is the one naming rule that
is not universal:

| Lineage | Timestamps | Soft delete | Primary key |
| --- | --- | --- | --- |
| legacy | integer Unix `created_date`, `updated_date` | `deleted_date` | `{table_singular}_id` |
| framework-default | `created_at`, `updated_at` | `deleted_at` | `id` |
| prisma | `createdAt`, `updatedAt` | `deletedAt` | `id` uuid |

Framework-owned tables (sessions, cache, jobs, migrations) keep their own schema in every
lineage.

### Indexes

Add indexes for frequently queried columns:

```sql
-- Single column indexes
CREATE INDEX idx_learner_id ON activities (learner_id);
CREATE INDEX idx_deleted_date ON activities (deleted_date);

-- Composite indexes for common query patterns
CREATE INDEX idx_learner_dates ON activities (learner_id, start_date, end_date);
CREATE INDEX idx_hospital_active ON activities (hospital_id, deleted_date);

-- Unique constraints
CREATE UNIQUE INDEX idx_org_username ON users (organisation_id, username);
```

### Soft Deletes Pattern

**Not universal — it follows the lineage declared in the repo's `CLAUDE.md`.** The claim that
"all applications use `deleted_date`" is wrong in any mixed set of repos: legacy-lineage repos
do, Laravel-default repos use `SoftDeletes` (`deleted_at`), and Prisma repos use `deletedAt`.

For the legacy lineage:

```sql
-- Migration / table definition
deleted_date INT(11) NULL DEFAULT NULL;
CREATE INDEX idx_deleted_date ON activities (deleted_date);
```

The trait, its traps and the query-builder hazard are covered once in
[Soft Deletes (Laravel Implementation)](#soft-deletes-laravel-implementation). Do not
restate them.

### Migration Best Practices (Laravel)

Always write reversible migrations with existence checks:

```php
public function up(): void
{
    if (!Schema::hasTable('activities')) {
        Schema::create('activities', function (Blueprint $table) {
            $table->id('activity_id');
            $table->unsignedBigInteger('learner_id');
            $table->unsignedBigInteger('hospital_id');
            $table->integer('start_date');
            $table->integer('end_date');
            $table->decimal('percentage', 5, 2);
            $table->integer('created_date');
            $table->integer('deleted_date')->nullable();

            $table->foreign('learner_id')
                ->references('learner_id')
                ->on('learners')
                ->onDelete('cascade');

            $table->index(['learner_id', 'start_date', 'end_date']);
            $table->index('deleted_date');
        });
    }
}

public function down(): void
{
    Schema::dropIfExists('activities');
}
```

Adding columns to existing tables:

```php
public function up(): void
{
    Schema::table('activities', function (Blueprint $table) {
        if (!Schema::hasColumn('activities', 'notes')) {
            $table->text('notes')->nullable()->after('percentage');
        }
    });
}

public function down(): void
{
    Schema::table('activities', function (Blueprint $table) {
        if (Schema::hasColumn('activities', 'notes')) {
            $table->dropColumn('notes');
        }
    });
}
```

---

## Security Standards

### Input Validation

All user input MUST be validated before use, regardless of stack.

```php
// ✅ Laravel: Form Request validation
class StoreActivityRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'learner_id' => ['required', 'integer', 'exists:learners,learner_id'],
            'percentage' => ['required', 'numeric', 'min:0', 'max:100'],
        ];
    }
}

// ✅ Legacy: Manual validation
function validateActivityData(array $data): array
{
    $errors = [];

    if (!isset($data['learner_id']) || !is_numeric($data['learner_id'])) {
        $errors[] = 'A valid learner ID is required.';
    }

    if (!isset($data['percentage']) || $data['percentage'] < 0 || $data['percentage'] > 100) {
        $errors[] = 'Percentage must be between 0 and 100.';
    }

    return $errors;
}
```

### SQL Injection Prevention

All database queries MUST use parameterized bindings:

```php
// ✅ Correct: Parameterized (legacy)
$stmt = $pdo->prepare('SELECT * FROM activities WHERE learner_id = :id');
$stmt->execute(['id' => $learnerId]);

// ✅ Correct: Eloquent (Laravel)
$activities = Activity::where('learner_id', $learnerId)->get();

// ✅ Correct: Query builder (Laravel)
$activities = DB::table('activities')->where('learner_id', $learnerId)->get();

// ❌ NEVER: String interpolation
$activities = DB::select("SELECT * FROM activities WHERE learner_id = $learnerId");
$result = mysqli_query($conn, "SELECT * FROM activities WHERE learner_id = $learnerId");
```

### Output Escaping

Prevent XSS by escaping all user-generated output:

```php
// ✅ Legacy: htmlspecialchars for all output
<p><?= htmlspecialchars($user->name, ENT_QUOTES, 'UTF-8') ?></p>

// ✅ Laravel Blade: Double braces escape automatically
<p>{{ $user->name }}</p>

// ✅ Vue: Template interpolation escapes automatically
<p>{{ user.name }}</p>

// ❌ NEVER in Blade unless content is explicitly trusted
<p>{!! $user->name !!}</p>

// ❌ NEVER in legacy PHP
<p><?= $user->name ?></p>
```

### CSRF Protection

```php
// ✅ Legacy: Include CSRF token in all forms
// Generate token in session
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));

// Include in form
<input type="hidden" name="csrf_token" value="<?= htmlspecialchars($_SESSION['csrf_token']) ?>">

// Validate on submission
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    http_response_code(403);
    exit('Invalid CSRF token');
}

// ✅ Laravel: Handled automatically by Inertia and middleware
// No additional action needed for Inertia requests
```

### Authentication & Authorization

Check permissions at every level:

```php
// ✅ Legacy: Check at the top of every script
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: /login.php');
    exit;
}
if (!userHasPermission($_SESSION['user_id'], 'activities.edit')) {
    http_response_code(403);
    exit('Forbidden');
}

// ✅ Laravel: Policy + middleware (see Laravel Architecture section)
$this->authorizeResource(Activity::class, 'activity');
```

### Sensitive Data

Never log or expose sensitive data:

```php
// ❌ Wrong
Log::info('User login', ['password' => $request->password]);
error_log("Login attempt: password={$password}");

// ✅ Correct
Log::info('User login attempt', ['username' => $request->username]);
error_log("Login attempt: username={$username}");
```

---

## Error Handling & Logging

### Principles

- **Never swallow exceptions silently.** Every `catch` block must either handle the error meaningfully or re-throw it.
- **Log with context.** Always include enough information to diagnose the issue.
- **User-facing messages must be generic.** Never expose stack traces, SQL errors, or internal paths to end users.
- **Use appropriate log levels.** `error` for failures requiring attention, `warning` for recoverable issues, `info` for significant events, `debug` for development diagnostics.

### Legacy PHP

```php
<?php

declare(strict_types=1);

/**
 * Process an activity update.
 *
 * @param int $activityId The activity to update
 * @param array<string, mixed> $data The update data
 * @return bool True if update succeeded
 */
function updateActivity(int $activityId, array $data): bool
{
    try {
        $pdo = getDbConnection();
        $stmt = $pdo->prepare('UPDATE activities SET percentage = :pct WHERE activity_id = :id');
        $stmt->execute(['pct' => $data['percentage'], 'id' => $activityId]);

        return true;
    } catch (PDOException $e) {
        // ✅ Log the real error with context
        error_log(sprintf(
            '[%s] Failed to update activity %d: %s',
            date('Y-m-d H:i:s'),
            $activityId,
            $e->getMessage()
        ));

        // ✅ Return generic message to user
        return false;
    }
}

// ❌ NEVER expose internal errors
// echo "Database error: " . $e->getMessage();
// echo "Query failed: " . $sql;
```

### Laravel

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Exceptions\ActivityOverlapException;
use Illuminate\Support\Facades\Log;

/**
 * Service for managing activities.
 */
class ActivityService
{
    /**
     * Create a new activity.
     *
     * @param array<string, mixed> $data Activity data
     * @return Activity The created activity
     * @throws ActivityOverlapException If dates overlap with existing activities
     */
    public function createActivity(array $data): Activity
    {
        try {
            $this->validateDateOverlap($data);
            $activity = Activity::create($data);

            Log::info('Activity created', [
                'activity_id' => $activity->activity_id,
                'learner_id' => $data['learner_id'],
                'created_by' => auth()->id(),
            ]);

            return $activity;
        } catch (ActivityOverlapException $e) {
            // ✅ Re-throw domain exceptions for the controller to handle
            throw $e;
        } catch (\Throwable $e) {
            // ✅ Log identifiers, never the payload — $data may carry PHI or credentials
            //    (see Sensitive Data above). Chain the original exception with `previous`
            //    so the stack trace is not erased.
            Log::error('Failed to create activity', [
                'learner_id' => $data['learner_id'] ?? null,
                'error' => $e->getMessage(),
            ]);

            throw new \RuntimeException(
                'Unable to create activity. Please try again.',
                previous: $e,
            );
        }
    }
}
```

### Custom Exception Classes

Define domain-specific exceptions for business logic errors:

```php
<?php

declare(strict_types=1);

namespace App\Exceptions;

use RuntimeException;

/**
 * Thrown when an activity's dates overlap with existing activities.
 */
class ActivityOverlapException extends RuntimeException
{
    /**
     * Create a new ActivityOverlapException.
     *
     * @param int $learnerId The learner whose activities overlap
     * @param string $dateRange Human-readable date range description
     */
    public function __construct(int $learnerId, string $dateRange)
    {
        parent::__construct(
            "Activity dates overlap for learner {$learnerId} in range {$dateRange}."
        );
    }
}
```

---

## Testing Standards

### Test Framework

- **Laravel apps**: Use Pest PHP with the `it()` / `test()` syntax.
- **Legacy apps**: Use PHPUnit directly.

Do not mix Pest and PHPUnit syntax within the same project.

### Coverage Requirements

From `AGENTS.md` non-negotiable 6. These are the only coverage figures in force anywhere in the
framework; if you find another number, it is stale.

| Scope | Minimum Coverage |
|-------|-----------------|
| Overall codebase | 80% |
| Authentication and authorization | 100% |
| Payments | 100% |
| PHI (personal health information) | 100% |

Coverage must be measured with pcov or Xdebug. If the repo has no coverage driver,
report coverage as unmeasurable — do not claim a number.

### Test Structure

Every public-facing feature requires at minimum:
- A **happy path** test (expected input produces expected output)
- A **validation failure** test (invalid input is rejected)
- An **authorization** test (unauthenticated/unauthorized users are blocked)

### Pest PHP (Laravel)

```php
<?php

declare(strict_types=1);

use App\Models\Activity;
use App\Models\Learner;
use App\Models\User;

describe('Activity Creation', function () {

    it('creates an activity for an authenticated user', function () {
        $user = User::factory()->create();
        $learner = Learner::factory()->create();

        $response = $this->actingAs($user)
            ->post(route('activities.store'), [
                'learner_id' => $learner->learner_id,
                'hospital_id' => 1,
                'service_id' => 1,
                'start_date' => time(),
                'end_date' => time() + 86400,
                'percentage' => 50.0,
            ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('activities', [
            'learner_id' => $learner->learner_id,
            'percentage' => 50.0,
        ]);
    });

    it('rejects unauthenticated users', function () {
        $response = $this->post(route('activities.store'), []);

        $response->assertRedirect(route('login'));
    });

    it('validates percentage is within range', function () {
        $user = User::factory()->create();

        $response = $this->actingAs($user)
            ->post(route('activities.store'), [
                'percentage' => 150,
            ]);

        $response->assertSessionHasErrors(['percentage']);
    });

});
```

### PHPUnit (Legacy)

```php
<?php

declare(strict_types=1);

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;

/**
 * Tests for activity validation functions.
 */
class ActivityValidationTest extends TestCase
{
    /**
     * Test that valid activity data passes validation.
     *
     * @return void
     */
    public function testValidActivityDataPassesValidation(): void
    {
        $data = [
            'learner_id' => 1,
            'hospital_id' => 1,
            'percentage' => 50.0,
        ];

        $errors = validateActivityData($data);

        $this->assertEmpty($errors);
    }

    /**
     * Test that percentage over 100 fails validation.
     *
     * @return void
     */
    public function testPercentageOverOneHundredFailsValidation(): void
    {
        $data = [
            'learner_id' => 1,
            'hospital_id' => 1,
            'percentage' => 150.0,
        ];

        $errors = validateActivityData($data);

        $this->assertNotEmpty($errors);
    }
}
```

### Test File Organization

```
tests/
├── Feature/                          # Laravel integration tests
│   ├── Activity/
│   │   ├── CreateActivityTest.php
│   │   ├── UpdateActivityTest.php
│   │   └── ActivityOverlapTest.php
│   └── Auth/
│       └── SsoLoginTest.php
├── Unit/                             # Isolated unit tests (both stacks)
│   ├── Services/
│   │   ├── ActivityServiceTest.php
│   │   └── QuarterServiceTest.php
│   └── Models/
│       └── ActivityTest.php
└── Legacy/                           # Legacy app-specific tests
    ├── ValidationTest.php
    └── DatabaseAccessTest.php
```

---

## Performance Standards

### N+1 Query Prevention

```php
// ❌ Wrong: N+1 queries
$activities = Activity::all();
foreach ($activities as $activity) {
    echo $activity->learner->name; // Queries DB for each row
}

// ✅ Correct: Eager load relationships
$activities = Activity::with(['learner', 'hospital', 'service'])->get();
```

### Select Only Needed Columns

```php
// ❌ Wrong: Select everything
$learners = Learner::all();

// ✅ Correct: Select specific columns
$learners = Learner::select(['learner_id', 'firstname', 'lastname'])->get();
```

### Caching Strategy

Cache frequently accessed, rarely changed data:

```php
use Illuminate\Support\Facades\Cache;

/**
 * Get all quarters, cached for one hour.
 *
 * @return Collection<int, Quarter>
 */
public function getAllQuarters(): Collection
{
    return Cache::remember('quarters.all', 3600, function () {
        return Quarter::orderBy('start_date', 'desc')->get();
    });
}

// Clear cache when data changes
Cache::forget('quarters.all');
```

### Frontend Performance

Debounce user input to avoid excessive requests:

```vue
<script setup lang="ts">
import { ref, watch } from 'vue';

const searchQuery = ref('');
let timer: ReturnType<typeof setTimeout> | undefined;

watch(searchQuery, (value) => {
  clearTimeout(timer);
  timer = setTimeout(() => {
    // Perform search
  }, 300);
});
</script>
```

> This example previously imported `useDebounceFn` from `@vueuse/core`, which is not a
> dependency of any repo here. Add the package to the repo before importing from it, or
> hand-roll as above.

---

## Environment & Configuration

### `.env` Handling

- `.env` files MUST NOT be committed to version control.
- A `.env.example` file MUST be maintained with all required keys (values left blank or set to safe defaults).
- Sensitive values (API keys, database passwords, SSO secrets) MUST NOT appear in code, config files, or logs.

### Environment-Specific Behavior

```php
// ✅ Read configuration through config(), always
$apiUrl = config('services.external.url');
$debug = config('app.debug');

// ❌ NEVER call env() outside config/*.php — it returns null once config is cached,
//    which fails in production and nowhere else
$apiUrl = env('EXTERNAL_API_URL');

// ❌ NEVER hardcode environment-specific values
$apiUrl = 'https://api.production.example.com';
$dbPassword = 'supersecret123';
```

The environment variable is read once, in `config/services.php`:

```php
// config/services.php
return [
    'external' => ['url' => env('EXTERNAL_API_URL')],
];
```

PHPStan enforces this — see `.global-docs/linters/phpstan.neon`.

### Legacy Applications

Legacy applications that don't use Laravel's config system should use a similar pattern:

```php
// config.php (NOT committed to version control)
<?php

declare(strict_types=1);

return [
    'db_host' => 'localhost',
    'db_name' => 'myapp',
    'db_user' => 'app_user',
    'db_pass' => 'password_here',
    'debug' => false,
];
```

```php
// bootstrap.php
$config = require __DIR__ . '/config.php';
```

---

# Legacy Application Standards

These standards apply to native PHP applications that do not use Laravel.

---

## Legacy Architecture

### Directory Structure

Legacy applications should follow a consistent directory structure:

```
project-root/
├── config/
│   ├── config.php              # Environment config (not committed)
│   ├── config.example.php      # Config template (committed)
│   └── database.php            # Database connection setup
├── public/                     # Web root (DocumentRoot points here)
│   ├── index.php               # Front controller or entry point
│   ├── css/
│   │   └── app.css
│   ├── js/
│   │   └── app.js
│   └── images/
├── src/                        # PHP source files
│   ├── Controllers/            # Request handlers
│   ├── Services/               # Business logic
│   ├── Models/                 # Data access classes
│   ├── Helpers/                # Utility functions
│   └── Middleware/             # Auth checks, CSRF, etc.
├── templates/                  # HTML templates
│   ├── layouts/
│   │   └── main.php
│   ├── partials/
│   │   ├── header.php
│   │   └── footer.php
│   └── pages/
│       ├── activities/
│       │   ├── index.php
│       │   └── edit.php
│       └── dashboard.php
├── tests/
├── vendor/                     # Composer dependencies
├── composer.json
├── .env.example
└── .gitignore
```

### Separation of Concerns

Even without a framework, business logic should be separated from presentation and data access:

```php
<?php
// ❌ Wrong: Everything in one file
// activities.php
session_start();
$conn = mysqli_connect('localhost', 'root', '', 'myapp');
$result = mysqli_query($conn, "SELECT * FROM activities WHERE learner_id = {$_GET['id']}");
echo "<table>";
while ($row = mysqli_fetch_assoc($result)) {
    echo "<tr><td>{$row['name']}</td></tr>";
}
echo "</table>";
```

```php
<?php
// ✅ Correct: Separated responsibilities

// src/Services/ActivityService.php
declare(strict_types=1);

/**
 * Service for managing activities.
 */
class ActivityService
{
    /**
     * @param PDO $pdo Database connection
     */
    public function __construct(private readonly PDO $pdo) {}

    /**
     * Get activities for a learner.
     *
     * @param int $learnerId The learner's ID
     * @return array<int, array<string, mixed>> Array of activity rows
     */
    public function getByLearner(int $learnerId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM activities WHERE learner_id = :id AND deleted_date IS NULL'
        );
        $stmt->execute(['id' => $learnerId]);

        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}

// templates/pages/activities/index.php
// Only handles presentation
<?php foreach ($activities as $activity): ?>
    <tr>
        <td><?= htmlspecialchars($activity['name'], ENT_QUOTES, 'UTF-8') ?></td>
    </tr>
<?php endforeach; ?>
```

### Authentication Pattern

Every page that requires authentication should include a guard at the top:

```php
<?php

declare(strict_types=1);

require_once __DIR__ . '/../src/Middleware/auth.php';

// auth.php
session_start();

/**
 * Require an authenticated session. Redirects to login if not authenticated.
 *
 * @return void
 */
function requireAuth(): void
{
    if (!isset($_SESSION['user_id'])) {
        header('Location: /login.php');
        exit;
    }
}

/**
 * Check if the current user has a specific permission.
 *
 * @param string $permission The permission name to check
 * @return bool True if the user has the permission
 */
function hasPermission(string $permission): bool
{
    return in_array($permission, $_SESSION['permissions'] ?? [], true);
}
```

---

## Legacy Frontend

### jQuery Standards

- Use jQuery 3.x where possible. Avoid deprecated methods.
- Prefer event delegation over direct binding for dynamic content.
- Always use strict equality (`===`) in JavaScript.

```javascript
// ✅ Correct: Event delegation, namespaced events
$(document).on('click.activityModule', '.delete-activity', function (e) {
    e.preventDefault();
    var activityId = $(this).data('activity-id');

    if (!confirm('Are you sure you want to delete this activity?')) {
        return;
    }

    $.ajax({
        url: '/api/activities/' + activityId,
        method: 'DELETE',
        headers: {
            'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        },
        success: function () {
            $('#activity-' + activityId).fadeOut(function () {
                $(this).remove();
            });
        },
        error: function (xhr) {
            alert('Failed to delete activity. Please try again.');
            console.error('Delete failed:', xhr.responseText);
        }
    });
});

// ❌ Wrong: Direct binding, no error handling, no CSRF
$('.delete-activity').click(function () {
    $.ajax({
        url: '/api/activities/' + $(this).attr('id'),
        method: 'DELETE'
    });
});
```

### DataTables

Use jQuery DataTables for tabular data. Configure server-side processing for tables with more than 500 rows:

```javascript
$('#activities-table').DataTable({
    processing: true,
    serverSide: true,
    ajax: {
        url: '/api/activities/datatable',
        type: 'POST',
        headers: {
            'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        }
    },
    columns: [
        { data: 'learner_name', title: 'Learner' },
        { data: 'hospital_name', title: 'Hospital' },
        { data: 'start_date', title: 'Start Date' },
        { data: 'percentage', title: '%' }
    ],
    order: [[2, 'desc']]
});
```

### HTML & CSS

- Use semantic HTML5 elements (`<header>`, `<nav>`, `<main>`, `<section>`, `<footer>`).
- Use CSS classes rather than inline styles.
- Keep CSS in external stylesheets, not embedded in PHP files.
- Follow BEM naming convention for custom CSS classes: `.block__element--modifier`.

```html
<!-- ✅ Correct: Semantic, BEM, external CSS -->
<main class="activity-list">
    <section class="activity-list__filters">
        <select class="activity-list__filter--hospital" id="hospital-filter">
            <option value="">All Hospitals</option>
        </select>
    </section>
    <table class="activity-list__table" id="activities-table">
        <!-- DataTable renders here -->
    </table>
</main>

<!-- ❌ Wrong: Div soup, inline styles -->
<div style="margin: 20px;">
    <div style="float: left;">
        <select style="width: 200px;">...</select>
    </div>
    <div>
        <table border="1">...</table>
    </div>
</div>
```

---

## Legacy Database Access

### PDO and DB abstraction layers

**Match the connection layer the application already uses. Never `mysqli_*` in new code.**

The earlier version of this document said all legacy applications must use PDO. That was
wrong: many legacy apps use a DB abstraction library throughout, with a global `$db`
connection. Introducing PDO alongside it means two connection pools and two transaction scopes in one
request.

- **Repos with a DB abstraction layer:** parameterize with its quoting or binding (e.g.
  `$db->qstr()`); use its fetch helpers for all rows, one row and one scalar; check for
  `false` before using a result if the layer returns `false` rather than throwing; use its
  begin / commit / rollback transactions.
- **Other legacy PHP:** PDO with prepared statements, as shown here.

```php
<?php

declare(strict_types=1);

/**
 * Create a PDO database connection.
 *
 * @param array<string, string> $config Database configuration
 * @return PDO The database connection
 */
function createConnection(array $config): PDO
{
    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $config['db_host'], $config['db_name']);

    $pdo = new PDO($dsn, $config['db_user'], $config['db_pass'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);

    return $pdo;
}
```

### Query Patterns

```php
<?php

declare(strict_types=1);

/**
 * Repository for activity data access.
 */
class ActivityRepository
{
    /**
     * @param PDO $pdo Database connection
     */
    public function __construct(private readonly PDO $pdo) {}

    /**
     * Find an activity by ID.
     *
     * @param int $id The activity ID
     * @return array<string, mixed>|null The activity row or null
     */
    public function findById(int $id): ?array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM activities WHERE activity_id = :id AND deleted_date IS NULL'
        );
        $stmt->execute(['id' => $id]);
        $result = $stmt->fetch();

        return $result !== false ? $result : null;
    }

    /**
     * Get activities for a learner within a date range.
     *
     * @param int $learnerId The learner's ID
     * @param int $startDate Unix timestamp for range start
     * @param int $endDate Unix timestamp for range end
     * @return array<int, array<string, mixed>> Array of activity rows
     */
    public function getByLearnerAndDateRange(int $learnerId, int $startDate, int $endDate): array
    {
        $stmt = $this->pdo->prepare('
            SELECT a.*, l.firstname, l.lastname, h.hospital_name
            FROM activities a
            JOIN learners l ON l.learner_id = a.learner_id
            JOIN hospitals h ON h.hospital_id = a.hospital_id
            WHERE a.learner_id = :learner_id
              AND a.start_date >= :start_date
              AND a.end_date <= :end_date
              AND a.deleted_date IS NULL
            ORDER BY a.start_date DESC
        ');

        $stmt->execute([
            'learner_id' => $learnerId,
            'start_date' => $startDate,
            'end_date' => $endDate,
        ]);

        return $stmt->fetchAll();
    }

    /**
     * Soft-delete an activity.
     *
     * @param int $id The activity ID
     * @return bool True if the delete succeeded
     */
    public function softDelete(int $id): bool
    {
        $stmt = $this->pdo->prepare(
            'UPDATE activities SET deleted_date = :now WHERE activity_id = :id'
        );

        return $stmt->execute(['now' => time(), 'id' => $id]);
    }
}
```

### Transactions

Wrap multi-step operations in transactions:

```php
/**
 * Transfer an activity between hospitals.
 *
 * @param int $activityId The activity to transfer
 * @param int $newHospitalId The target hospital
 * @return bool True if transfer succeeded
 */
public function transferActivity(int $activityId, int $newHospitalId): bool
{
    try {
        $this->pdo->beginTransaction();

        $stmt = $this->pdo->prepare(
            'UPDATE activities SET hospital_id = :hospital WHERE activity_id = :id'
        );
        $stmt->execute(['hospital' => $newHospitalId, 'id' => $activityId]);

        $stmt = $this->pdo->prepare(
            'INSERT INTO activity_history (activity_id, action, created_date) VALUES (:id, :action, :now)'
        );
        $stmt->execute(['id' => $activityId, 'action' => 'transferred', 'now' => time()]);

        $this->pdo->commit();
        return true;
    } catch (PDOException $e) {
        $this->pdo->rollBack();
        error_log("Transfer failed for activity {$activityId}: " . $e->getMessage());
        return false;
    }
}
```

---

# Modern Application Standards (Laravel)

These standards apply to applications built on the Laravel stack.

---

## Laravel Architecture

### Technology Stack

- **Laravel** — PHP framework
- **Inertia.js** — Server-side routing with SPA experience
- **Vue 3** — Progressive JavaScript framework
- **TypeScript** — Type-safe JavaScript
- **PrimeVue** — UI component library
- **Tailwind CSS** — Utility-first CSS framework
- **Laravel Sail** — Docker development environment

### Modular Architecture

Use `nwidart/laravel-modules` for organizing features. All new features should be built as self-contained modules:

```
app/Modules/
├── Billing/
│   ├── Controllers/
│   │   └── InvoiceController.php
│   ├── Models/
│   │   └── Invoice.php
│   ├── Services/
│   │   └── InvoiceService.php
│   ├── Requests/
│   │   ├── StoreInvoiceRequest.php
│   │   └── UpdateInvoiceRequest.php
│   ├── Resources/
│   │   └── InvoiceResource.php
│   ├── Policies/
│   │   └── InvoicePolicy.php
│   └── Tests/
│       ├── CreateInvoiceTest.php
│       └── InvoiceServiceTest.php
└── Activity/
    └── ...
```

**Namespacing:** `App\Modules\{ModuleName}\{Layer}` (e.g., `App\Modules\Billing\Services\InvoiceService`).

**Cross-module communication:** Reference other modules via their Service classes, never via direct database queries.

### Controllers

Controllers MUST be "skinny" — no business logic, no validation, no direct database queries:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\Activity\StoreActivityRequest;
use App\Http\Requests\Activity\UpdateActivityRequest;
use App\Models\Activity;
use App\Services\ActivityService;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response as InertiaResponse;

/**
 * Controller for managing medical training activities.
 */
class ActivityController extends Controller
{
    /**
     * @param ActivityService $activityService Service for activity business logic
     */
    public function __construct(
        private readonly ActivityService $activityService
    ) {
        $this->authorizeResource(Activity::class, 'activity');
    }

    /**
     * Display a listing of activities.
     *
     * @return InertiaResponse Inertia response with activities data
     */
    public function index(): InertiaResponse
    {
        // `->latest()` orders by `created_at`, which does not exist in the
        // legacy lineage. Order by an explicit column.
        $activities = Activity::with(['learner', 'hospital'])
            ->orderBy('created_date', 'desc')
            ->paginate(20);

        return Inertia::render('Activity/Index', [
            'activities' => $activities,
        ]);
    }

    /**
     * Store a newly created activity.
     *
     * @param StoreActivityRequest $request Validated request data
     * @return RedirectResponse Redirect to activity show page
     */
    public function store(StoreActivityRequest $request): RedirectResponse
    {
        $activity = $this->activityService->createActivity(
            $request->validated()
        );

        return redirect()
            ->route('activities.show', $activity)
            ->with('success', 'Activity created successfully');
    }

    /**
     * Display the specified activity.
     *
     * @param Activity $activity The activity to display
     * @return InertiaResponse Inertia response with activity data
     */
    public function show(Activity $activity): InertiaResponse
    {
        return Inertia::render('Activity/Show', [
            'activity' => $activity->load(['learner', 'hospital', 'service']),
        ]);
    }

    /**
     * Update the specified activity.
     *
     * @param UpdateActivityRequest $request Validated request data
     * @param Activity $activity The activity to update
     * @return RedirectResponse Redirect to activity show page
     */
    public function update(
        UpdateActivityRequest $request,
        Activity $activity
    ): RedirectResponse {
        $this->activityService->updateActivity($activity, $request->validated());

        return redirect()
            ->route('activities.show', $activity)
            ->with('success', 'Activity updated successfully');
    }

    /**
     * Remove the specified activity.
     *
     * @param Activity $activity The activity to delete
     * @return RedirectResponse Redirect to activities index
     */
    public function destroy(Activity $activity): RedirectResponse
    {
        $this->activityService->deleteActivity($activity);

        return redirect()
            ->route('activities.index')
            ->with('success', 'Activity deleted successfully');
    }
}
```

### Service Layer

All business logic belongs in Service classes, injected via constructor:

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Activity;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

/**
 * Service for managing medical training activities.
 */
class ActivityService
{
    /**
     * @param QuarterService $quarterService Service for quarter validation
     * @param ActivityHistoryService $historyService Service for activity history
     */
    public function __construct(
        private readonly QuarterService $quarterService,
        private readonly ActivityHistoryService $historyService
    ) {}

    /**
     * Create a new activity with validation and history tracking.
     *
     * @param CreateActivityDTO $data Activity data, built from the validated request
     * @return Activity The newly created activity
     * @throws ValidationException If business validation fails
     */
    public function createActivity(CreateActivityDTO $data): Activity
    {
        $this->validateDateOverlap($data);

        $activity = Activity::create([
            'learner_id' => $data->learnerId,
            'hospital_id' => $data->hospitalId,
            'service_id' => $data->serviceId,
            'start_date' => $data->startDate,
            'end_date' => $data->endDate,
            'percentage' => $data->percentage,
        ]);

        $this->historyService->createHistory($activity, 'created');

        return $activity;
    }
}
```

### Data Transfer Objects

Use readonly DTOs to pass structured data between layers. Avoid passing raw associative
arrays for complex data.

**Where the line falls.** A DTO earns its cost once a payload has more than two or three
fields, or crosses a module boundary — it gives you named properties, types the IDE can
follow, and a compile-time error when a field is added and a caller is missed. A single
scalar or a two-field update does not need one.

Several earlier examples in this document take `array $data`; they predate this rule and
are being brought into line as they are touched. Where the two disagree, this section is
right.

```php
<?php

declare(strict_types=1);

namespace App\DTOs;

/**
 * Data transfer object for activity creation data.
 */
readonly class CreateActivityDTO
{
    /**
     * @param int $learnerId The learner's ID
     * @param int $hospitalId The hospital's ID
     * @param int $serviceId The service's ID
     * @param int $startDate Unix timestamp for start
     * @param int $endDate Unix timestamp for end
     * @param float $percentage Activity percentage (0-100)
     */
    public function __construct(
        public int $learnerId,
        public int $hospitalId,
        public int $serviceId,
        public int $startDate,
        public int $endDate,
        public float $percentage,
    ) {}
}
```

### Models

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Activity model for medical training activities.
 *
 * @property int $activity_id
 * @property int $learner_id
 * @property int $hospital_id
 * @property float $percentage
 * @property int|null $deleted_date
 */
class Activity extends Model
{
    /**
     * Fields explicitly allowed for mass assignment.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'learner_id',
        'hospital_id',
        'service_id',
        'start_date',
        'end_date',
        'percentage',
        'created_by',
    ];

    /**
     * Get the learner that owns this activity.
     *
     * @return BelongsTo<Learner, Activity>
     */
    public function learner(): BelongsTo
    {
        return $this->belongsTo(Learner::class, 'learner_id', 'learner_id');
    }

    /**
     * Get the hospital for this activity.
     *
     * @return BelongsTo<Hospital, Activity>
     */
    public function hospital(): BelongsTo
    {
        return $this->belongsTo(Hospital::class, 'hospital_id', 'hospital_id');
    }
}
```

> **Note on mass assignment:** Use `$fillable` to explicitly list assignable fields. This protects against mass assignment even if a developer accidentally passes unvalidated input. Always pair this with `$request->validated()` in controllers — never use `$request->all()`.

### Soft Deletes (Laravel Implementation)

Our applications use integer Unix timestamps for soft deletes (`deleted_date`) rather than Laravel's built-in `SoftDeletes` trait (which uses a `deleted_at` datetime column). Use this custom trait instead:

```php
<?php

declare(strict_types=1);

namespace App\Models\Traits;

/**
 * Custom soft delete trait using integer Unix timestamps.
 *
 * This trait is used instead of Laravel's built-in SoftDeletes trait
 * to maintain consistency with our legacy database schema which uses
 * integer timestamps throughout.
 *
 * WARNING: Do NOT use Illuminate\Database\Eloquent\SoftDeletes alongside this trait.
 */
trait HasSoftDeletes
{
    /**
     * Boot the trait and add a global scope to exclude deleted records.
     *
     * @return void
     */
    protected static function bootHasSoftDeletes(): void
    {
        static::addGlobalScope('notDeleted', function ($builder) {
            $builder->whereNull($builder->getModel()->getTable() . '.deleted_date');
        });
    }

    /**
     * Soft delete the model by setting deleted_date to current timestamp.
     *
     * @return bool True if delete was successful
     */
    public function softDelete(): bool
    {
        $this->deleted_date = time();
        return $this->save();
    }

    /**
     * Restore a soft-deleted model.
     *
     * @return bool True if restore was successful
     */
    public function restore(): bool
    {
        $this->deleted_date = null;
        return $this->save();
    }

    /**
     * Check if the model is soft deleted.
     *
     * @return bool True if model is deleted
     */
    public function isDeleted(): bool
    {
        return $this->deleted_date !== null;
    }
}
```

> **Important:** The method is named `softDelete()`, not `delete()`, to avoid overriding Eloquent's built-in `delete()` method which has other side effects.

### Form Requests

Always use Form Request classes for validation. Controllers MUST NOT validate data directly:

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests\Activity;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Form request for creating a new activity.
 */
class StoreActivityRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     *
     * @return bool
     */
    public function authorize(): bool
    {
        return $this->user()->can('create', Activity::class);
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, array<int, mixed>>
     */
    public function rules(): array
    {
        return [
            'learner_id' => ['required', 'integer', 'exists:learners,learner_id'],
            'hospital_id' => ['required', 'integer', 'exists:hospitals,hospital_id'],
            'service_id' => ['required', 'integer', 'exists:hospital_services,service_id'],
            'start_date' => ['required', 'integer', 'lte:end_date'],
            'end_date' => ['required', 'integer', 'gte:start_date'],
            'percentage' => ['required', 'numeric', 'min:0', 'max:100'],
        ];
    }

    /**
     * Get custom error messages.
     *
     * @return array<string, string>
     */
    public function messages(): array
    {
        return [
            'start_date.lte' => 'Start date must be before or equal to end date.',
            'percentage.max' => 'Percentage cannot exceed 100%.',
        ];
    }
}
```

### Policies

Use Policy classes for all authorization logic:

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Activity;
use App\Models\User;

/**
 * Authorization policy for Activity model.
 */
class ActivityPolicy
{
    /**
     * Determine if user can view activities.
     *
     * @param User $user The authenticated user
     * @return bool
     */
    public function viewAny(User $user): bool
    {
        return $user->hasPermissionTo('activities.view');
    }

    /**
     * Determine if user can create activities.
     *
     * @param User $user The authenticated user
     * @return bool
     */
    public function create(User $user): bool
    {
        return $user->hasPermissionTo('activities.create');
    }

    /**
     * Determine if user can update a specific activity.
     *
     * @param User $user The authenticated user
     * @param Activity $activity The activity to update
     * @return bool
     */
    public function update(User $user, Activity $activity): bool
    {
        return $user->hasPermissionTo('activities.edit')
            && ($user->id === $activity->created_by || $user->hasRole('admin'));
    }

    /**
     * Determine if user can delete a specific activity.
     *
     * @param User $user The authenticated user
     * @param Activity $activity The activity to delete
     * @return bool
     */
    public function delete(User $user, Activity $activity): bool
    {
        return $user->hasPermissionTo('activities.delete')
            && $user->hasRole('admin');
    }
}
```

### Dependency Injection

Always use constructor injection:

```php
// ✅ Correct: Constructor injection
public function __construct(
    private readonly ActivityService $activityService,
    private readonly QuarterService $quarterService
) {}

// ❌ Wrong: Service container in methods
$quarterService = app(QuarterService::class);

// ❌ Wrong: Static calls
$quarters = QuarterService::getAll();
```

### Eloquent ORM

Always use Eloquent ORM. Avoid raw SQL unless absolutely necessary:

```php
// ✅ Correct: Eloquent with relationships.
//    No ->whereNull('deleted_date') — the HasSoftDeletes global scope already excludes
//    deleted rows. Adding it by hand suggests the scope is optional, and it is not.
$activities = Activity::with(['learner', 'hospital', 'service'])
    ->whereBetween('start_date', [$startDate, $endDate])
    ->orderBy('start_date', 'desc')
    ->get();

// ✅ Acceptable: Query builder for aggregations
$stats = DB::table('activities')
    ->selectRaw('COUNT(*) as total, SUM(percentage) as total_percentage')
    ->where('learner_id', $learnerId)
    ->groupBy('hospital_id')
    ->get();

// ❌ Wrong: Raw query with string interpolation
$activities = DB::select("SELECT * FROM activities WHERE learner_id = $learnerId");

// ⚠️ Last resort only: Raw query with bindings
$activities = DB::select(
    'SELECT * FROM activities WHERE learner_id = ?',
    [$learnerId]
);
```

---

## Vue/TypeScript Standards

### Composition API (Required)

Always use Composition API with `<script setup lang="ts">`. Options API is not permitted:

```vue
<script setup lang="ts">
// ✅ Correct: Composition API
import { ref, computed, onMounted } from 'vue';
import { useForm } from '@inertiajs/vue3';
import type { Activity, Learner } from '@/types/models';

interface Props {
  activity: Activity;
  learners: Learner[];
}

const props = defineProps<Props>();

const isLoading = ref(false);
const selectedLearner = ref<Learner | null>(null);

const learnerName = computed(() => {
  return selectedLearner.value
    ? `${selectedLearner.value.firstname} ${selectedLearner.value.lastname}`
    : '';
});

const handleSubmit = async (): Promise<void> => {
  isLoading.value = true;
  try {
    // Handle form submission
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  // Component mounted logic
});
</script>

<template>
  <div class="activity-form">
    <h1>{{ learnerName }}</h1>
    <button @click="handleSubmit" :disabled="isLoading">
      Submit
    </button>
  </div>
</template>
```

### TypeScript Strict Mode

Use TypeScript in strict mode with proper typing. Never use `any`:

```typescript
// ✅ Correct: Full type definitions
interface Activity {
  activity_id: number;
  learner_id: number;
  hospital_id: number;
  service_id: number;
  start_date: number;
  end_date: number;
  percentage: number;
  created_by: number;
  created_date: number;
  updated_date: number | null;
  deleted_date: number | null;
  learner?: Learner;
  hospital?: Hospital;
  service?: HospitalService;
}

// ✅ Correct: Typed function
const filterActivities = (
  activities: Activity[],
  hospitalId: number
): Activity[] => {
  return activities.filter(a => a.hospital_id === hospitalId);
};

// ❌ Wrong: Using 'any'
const filterActivities = (activities: any, hospitalId: any): any => {
  return activities.filter((a: any) => a.hospital_id === hospitalId);
};
```

### Component Structure

Organize `<script>`, `<template>`, and `<style>` in this order with imports grouped logically:

```vue
<script setup lang="ts">
// 1. Vue core
import { ref, computed, onMounted } from 'vue';

// 2. External libraries
import { router, useForm } from '@inertiajs/vue3';

// 3. PrimeVue components
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';

// 4. Local components
import ActivityCard from '@/Components/Activity/ActivityCard.vue';
import LoadingSpinner from '@/Components/Common/LoadingSpinner.vue';

// 5. Composables and stores
import { useActivity } from '@/composables/useActivity';
import { useUserStore } from '@/stores/userStore';

// 6. Types
import type { Activity, Learner } from '@/types/models';

// 7. Utilities
import { formatDate } from '@/utils/date';

// Props and emits
interface Props {
  activities: Activity[];
}
const props = defineProps<Props>();
const emit = defineEmits<{
  update: [activity: Activity];
  delete: [id: number];
}>();

// State
const selectedActivity = ref<Activity | null>(null);

// Computed
const hasActivities = computed(() => props.activities.length > 0);

// Methods
const handleEdit = (activity: Activity): void => {
  emit('update', activity);
};

// Lifecycle
onMounted(() => {
  // ...
});
</script>

<template>
  <!-- Template content -->
</template>

<style scoped>
/* Component-specific styles only when Tailwind is insufficient */
</style>
```

### Props Validation

Always validate props with TypeScript interfaces. Use `withDefaults` for default values:

```vue
<script setup lang="ts">
import type { Activity, Learner } from '@/types/models';

// ✅ Correct: Typed props with defaults
interface Props {
  activity: Activity;
  learners?: Learner[];
  isEditable?: boolean;
  maxPercentage?: number;
}

const props = withDefaults(defineProps<Props>(), {
  learners: () => [],
  isEditable: false,
  maxPercentage: 100,
});

// ❌ Wrong: No type checking
const props = defineProps({
  activity: Object,
  learners: Array,
});
</script>
```

### Composables

Use composables for reusable logic:

```typescript
// composables/useActivity.ts
import { ref, computed } from 'vue';
import { router } from '@inertiajs/vue3';
import type { Activity } from '@/types/models';

/**
 * Composable for managing activities.
 *
 * Provides reactive state and methods for fetching, creating, updating,
 * and deleting activities with proper error handling.
 *
 * @returns Object containing activities state and management methods
 */
export function useActivity() {
  const activities = ref<Activity[]>([]);
  const isLoading = ref(false);
  const error = ref<string | null>(null);

  const activeActivities = computed(() =>
    activities.value.filter(a => !a.deleted_date)
  );

  const fetchActivities = async (): Promise<void> => {
    isLoading.value = true;
    error.value = null;

    try {
      // Fetch logic
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Unknown error';
    } finally {
      isLoading.value = false;
    }
  };

  const deleteActivity = (id: number): void => {
    router.delete(route('activities.destroy', id), {
      onSuccess: () => {
        activities.value = activities.value.filter(a => a.activity_id !== id);
      },
    });
  };

  return {
    activities,
    isLoading,
    error,
    activeActivities,
    fetchActivities,
    deleteActivity,
  };
}
```

### Pinia Stores — not the default

**Pinia is not a default dependency** of the Laravel + Inertia stack, and an earlier version
of this document required it. Do not add the dependency to satisfy a rule that no longer exists.

Shared state comes from Inertia: `usePage().props` for page data, Inertia shared data for
globals such as the authenticated user and permissions. Local state is `ref` and `computed`.
If something genuinely needs a store, raise it rather than adding the dependency quietly.

The example below is retained only so the pattern is recognisable if you meet it elsewhere:

```typescript
// stores/userStore.ts
import { defineStore } from 'pinia';
import { ref, computed } from 'vue';
import type { User } from '@/types/models';

/**
 * Pinia store for managing authenticated user state.
 */
export const useUserStore = defineStore('user', () => {
  const currentUser = ref<User | null>(null);
  const permissions = ref<string[]>([]);

  const isAdmin = computed(() =>
    currentUser.value?.roles?.some(role => role.name === 'admin') ?? false
  );

  const hasPermission = (permission: string): boolean => {
    return permissions.value.includes(permission);
  };

  const setUser = (user: User): void => {
    currentUser.value = user;
    permissions.value = user.permissions?.map(p => p.name) ?? [];
  };

  return { currentUser, permissions, isAdmin, hasPermission, setUser };
});
```

### Naming Conventions (Vue/TypeScript)

| What | Convention | Example |
|------|------------|---------|
| Component file | PascalCase | `UserProfileCard.vue` |
| Composable file | camelCase with `use` prefix | `useActivity.ts` |
| Type/Interface | PascalCase | `Activity`, `PageProps` |
| Store file | camelCase with `Store` suffix | `userStore.ts` |
| Utility file | camelCase | `date.ts`, `formatting.ts` |

---

## Inertia.js Patterns

### Page Components

Place page components in `resources/js/Pages/` mirroring controller structure:

```
resources/js/Pages/
├── Activity/
│   ├── Index.vue
│   ├── Create.vue
│   ├── Edit.vue
│   └── Show.vue
├── Dashboard.vue
└── Admin/
    ├── Users/
    └── Settings/
```

### Typed Props from Controllers

```php
// Controller
return Inertia::render('Activity/Index', [
    'activities' => ActivityResource::collection($activities),
    'filters' => $request->only(['search', 'hospital_id']),
    'hospitals' => HospitalResource::collection($hospitals),
]);
```

```vue
<script setup lang="ts">
import type { Activity, Hospital } from '@/types/models';
import type { PaginatedData } from '@/types/api';

interface Props {
  activities: PaginatedData<Activity>;
  filters: {
    search?: string;
    hospital_id?: number;
  };
  hospitals: Hospital[];
}

const props = defineProps<Props>();
</script>
```

### Form Handling

Use Inertia's form helper with proper typing:

```vue
<script setup lang="ts">
import { useForm } from '@inertiajs/vue3';

interface ActivityForm {
  learner_id: number | null;
  hospital_id: number | null;
  service_id: number | null;
  start_date: number | null;
  end_date: number | null;
  percentage: number;
}

const form = useForm<ActivityForm>({
  learner_id: null,
  hospital_id: null,
  service_id: null,
  start_date: null,
  end_date: null,
  percentage: 0,
});

const submit = (): void => {
  form.post(route('activities.store'), {
    onSuccess: () => form.reset(),
    onError: (errors) => console.error('Validation errors:', errors),
  });
};
</script>

<template>
  <form @submit.prevent="submit">
    <div>
      <label for="percentage">Percentage:</label>
      <InputNumber
        id="percentage"
        v-model="form.percentage"
        :class="{ 'p-invalid': form.errors.percentage }"
      />
      <small v-if="form.errors.percentage" class="p-error">
        {{ form.errors.percentage }}
      </small>
    </div>

    <Button
      type="submit"
      label="Save"
      :loading="form.processing"
      :disabled="form.processing"
    />
  </form>
</template>
```

### Persistent Layouts

Use persistent layouts to avoid remounting shared UI on navigation:

```vue
<!-- Layouts/AppLayout.vue -->
<script setup lang="ts">
import { ref } from 'vue';
import { Link } from '@inertiajs/vue3';

const sidebarOpen = ref(false);
</script>

<template>
  <div class="app-layout">
    <header><!-- Header --></header>
    <aside><!-- Sidebar --></aside>
    <main>
      <slot />
    </main>
    <footer><!-- Footer --></footer>
  </div>
</template>
```

```vue
<!-- Pages/Activity/Index.vue -->
<script setup lang="ts">
import AppLayout from '@/Layouts/AppLayout.vue';

defineOptions({ layout: AppLayout });
</script>
```

---

## PrimeVue Usage

### Registration Strategy

Register commonly-used components globally in `app.ts`:

```typescript
import Button from 'primevue/button';
import DataTable from 'primevue/datatable';
import Column from 'primevue/column';
import InputText from 'primevue/inputtext';
import InputNumber from 'primevue/inputnumber';
import Select from 'primevue/select';        // was Dropdown in PrimeVue 3
import DatePicker from 'primevue/datepicker'; // was Calendar in PrimeVue 3
import Dialog from 'primevue/dialog';
import Toast from 'primevue/toast';
import ConfirmDialog from 'primevue/confirmdialog';

app.component('Button', Button);
app.component('DataTable', DataTable);
// ... etc.
```

Import specialized components locally:

```vue
<script setup lang="ts">
import Chart from 'primevue/chart';
import FileUpload from 'primevue/fileupload';
</script>
```

### Theming with Tailwind

Use PrimeVue's passthrough for deep customization with Tailwind classes:

```vue
<template>
  <DataTable
    :value="activities"
    :pt="{
      root: { class: 'rounded-lg shadow-md' },
      header: { class: 'bg-gray-50 border-b' },
      bodyRow: { class: 'hover:bg-gray-50 transition-colors' }
    }"
  >
    <Column field="learner.name" header="Learner" />
  </DataTable>
</template>
```

### Accessibility

All interactive PrimeVue components MUST have proper ARIA attributes:

```vue
<template>
  <!-- ✅ Correct: Icon button with accessible label -->
  <Button
    icon="pi pi-trash"
    aria-label="Delete activity"
    severity="danger"
    @click="handleDelete"
  />

  <!-- ✅ Correct: Modal dialog with description -->
  <Dialog
    v-model:visible="showDialog"
    header="Confirm Deletion"
    modal
    :aria-describedby="'dialog-description'"
  >
    <p id="dialog-description">
      Are you sure you want to delete this activity?
    </p>
  </Dialog>

  <!-- ❌ Wrong: No accessible label -->
  <Button icon="pi pi-trash" @click="handleDelete" />
</template>
```

---

## Tailwind CSS Conventions

### Utility-First Approach

Prefer Tailwind utilities over custom CSS. Avoid inline styles:

```vue
<template>
  <!-- ✅ Correct: Tailwind utilities -->
  <div class="bg-white rounded-lg shadow-md p-6 mb-4">
    <h2 class="text-xl font-semibold text-brand-orange mb-4">
      Activity Details
    </h2>
  </div>

  <!-- ❌ Wrong: Inline styles -->
  <div style="background: white; padding: 24px;">
    <h2 style="font-size: 20px; color: #e76f51;">Activity Details</h2>
  </div>
</template>
```

### Custom Theme Colors

Use configured theme colors from the design system:

```vue
<template>
  <button class="bg-brand-teal hover:bg-brand-teal-dark text-white">Primary Action</button>
  <button class="bg-brand-green hover:bg-green-600 text-white">Add</button>
  <button class="bg-brand-red hover:bg-red-700 text-white">Delete</button>
  <h2 class="text-brand-orange font-semibold">Section Heading</h2>
</template>
```

### Responsive Design

Use mobile-first responsive classes:

```vue
<template>
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
    <div class="p-4">Item 1</div>
    <div class="p-4">Item 2</div>
    <div class="p-4">Item 3</div>
  </div>

  <!-- Stack on mobile, side-by-side on desktop -->
  <div class="flex flex-col md:flex-row gap-4">
    <div class="w-full md:w-1/2">Left</div>
    <div class="w-full md:w-1/2">Right</div>
  </div>
</template>
```

### Extracting Repeated Patterns

When the same utility combination appears in 3+ places, extract it:

```css
/* styles/components.css */
.btn-primary {
  @apply px-4 py-2 bg-brand-green hover:bg-green-600 text-white font-semibold rounded transition-colors;
}
```

---

## API Standards

### Response Format

All API endpoints MUST return consistent JSON structures:

```php
// ✅ Success response
return response()->json([
    'data' => ActivityResource::collection($activities),
    'meta' => [
        'total' => $activities->total(),
        'per_page' => $activities->perPage(),
        'current_page' => $activities->currentPage(),
    ],
]);

// ✅ Error response
return response()->json([
    'error' => [
        'message' => 'Activity not found.',
        'code' => 'ACTIVITY_NOT_FOUND',
    ],
], 404);

// ✅ Validation error response (handled automatically by Laravel)
// Returns 422 with { "message": "...", "errors": { "field": ["..."] } }
```

### API Resources

Always use API Resources to control response structure. Never return models directly:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * API resource for Activity model.
 */
class ActivityResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @param Request $request
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->activity_id,
            'learner_id' => $this->learner_id,
            'hospital_id' => $this->hospital_id,
            'start_date' => $this->start_date,
            'end_date' => $this->end_date,
            'percentage' => $this->percentage,
            'learner' => new LearnerResource($this->whenLoaded('learner')),
            'hospital' => new HospitalResource($this->whenLoaded('hospital')),
        ];
    }
}
```

### Route Conventions

```php
// API routes use consistent prefixing and versioning
Route::prefix('api/v1')->middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('activities', Api\ActivityController::class);
    Route::apiResource('learners', Api\LearnerController::class);
});
```

---

# Reference

---

## Modernization Guidelines

When working on legacy applications, follow these guidelines to decide when and how to modernize.

### When Touching Legacy Code

- **Bug fixes**: Fix the bug using existing patterns. Add PHPDoc and type hints to any functions you touch, but don't restructure.
- **Small features**: Follow the existing architecture but apply shared standards (strict types, parameterized queries, PHPDoc, type hints).
- **Large features**: If the feature requires significant new code (3+ files, new data models), discuss with the team whether it should be built as a new Laravel module that integrates with the legacy app.

### When to Propose a Rebuild

Consider proposing a rebuild to the Laravel stack when:
- A legacy application needs a major feature that would require restructuring most of the codebase.
- The application has recurring security or stability issues tied to its architecture.
- The majority of the team's maintenance time is spent on a specific legacy app.

Rebuilds should be proposed as a project with a clear scope, timeline, and migration plan — not done incrementally without a plan.

### What NOT to Do

- Do not introduce Laravel patterns (Eloquent, Blade, etc.) into a legacy app piecemeal. This creates a harder-to-maintain hybrid.
- Do not refactor working legacy code purely for style without a business reason.
- Do not add Composer packages to legacy apps without team discussion — dependency management in legacy apps requires extra care.

---

## File Structure Conventions

### Laravel Application

```
app/
├── Http/
│   ├── Controllers/
│   ├── Requests/
│   │   └── Activity/
│   │       ├── StoreActivityRequest.php
│   │       └── UpdateActivityRequest.php
│   ├── Resources/
│   │   ├── ActivityResource.php
│   │   └── LearnerResource.php
│   └── Middleware/
├── Models/
│   ├── Activity.php
│   ├── Learner.php
│   └── Traits/
│       ├── HasSoftDeletes.php
│       └── UsesIntegerTimestamps.php
├── Modules/                          # nwidart/laravel-modules
│   └── Billing/
│       ├── Controllers/
│       ├── Models/
│       ├── Services/
│       ├── Requests/
│       ├── Policies/
│       └── Tests/
├── Policies/
├── Services/
└── Exceptions/
```

### Vue/TypeScript

```
resources/js/
├── Pages/
│   ├── Activity/
│   │   ├── Index.vue
│   │   ├── Create.vue
│   │   ├── Edit.vue
│   │   └── Show.vue
│   └── Dashboard.vue
├── Components/
│   ├── Common/
│   │   ├── DateRangePicker.vue
│   │   ├── LoadingSpinner.vue
│   │   └── ConfirmDialog.vue
│   └── Activity/
│       ├── ActivityCard.vue
│       └── ActivityFilters.vue
├── Layouts/
│   ├── AppLayout.vue
│   └── GuestLayout.vue
├── composables/
│   ├── useActivity.ts
│   └── usePermissions.ts
├── stores/
│   └── userStore.ts
├── types/
│   ├── models.ts
│   ├── forms.ts
│   ├── props.ts
│   └── api.ts
└── utils/
    ├── date.ts
    ├── formatting.ts
    └── validation.ts
```

---

## Code Review Checklist

Use this as a PR template or review guide. Not every item applies to every PR — use judgment.

### All PHP Code
- [ ] `declare(strict_types=1)` present
- [ ] All methods have type hints for parameters and return types
- [ ] All classes and public methods have PHPDoc comments
- [ ] No raw SQL with string interpolation
- [ ] All user input validated
- [ ] No sensitive data logged or exposed
- [ ] PSR-12 compliant

### Laravel-Specific
- [ ] Controllers are skinny (no business logic)
- [ ] Validation in Form Requests (not controllers)
- [ ] Authorization via Policies
- [ ] Business logic in Service classes
- [ ] Relationships eager loaded (no N+1)
- [ ] Only necessary columns selected
- [ ] `$request->validated()` used (not `$request->all()`)
- [ ] Tests cover happy path, validation failure, and authorization

### Legacy-Specific
- [ ] Parameterized queries through the repo's existing layer — the DB layer's quoting/binding or PDO prepared statements, never `mysqli_*`
- [ ] `htmlspecialchars()` on all output
- [ ] CSRF token validated on form submissions
- [ ] Authentication checked at top of script
- [ ] Error handling doesn't expose internals to user

### Vue/TypeScript
- [ ] Composition API with `<script setup lang="ts">`
- [ ] All props typed with TypeScript interfaces
- [ ] No `any` types
- [ ] Imports grouped and ordered per convention

### Security
- [ ] Authorization checks at every level
- [ ] No mass assignment vulnerabilities
- [ ] CSRF protection in place

---

**Version:** 2.0.0
**Last Updated:** 2026-02-12
**Owner:** Application Services, Queen's Health Sciences IT
