# Coding Standards

This document defines the coding standards and best practices for applications in this
boilerplate. It assumes a team that maintains two kinds of applications:

- **Legacy applications** — Native PHP 8.3+, MySQL 8.0, jQuery, vanilla HTML/CSS
- **Modern applications** — Laravel, Inertia.js, Vue 3, TypeScript, Tailwind CSS

A short **Python** section is included for service/CLI projects such as the example app in
`src/example-site`.

Standards are organized into groups: **Shared** (applies everywhere), **Legacy**, **Modern**,
and **Python**.

All examples use a neutral domain — a **task tracker** with `Project`, `Task`, `User`,
`Comment`, and `Tag` entities. Adapt the conventions to your own domain.

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

### Python Standards
15. [Python Standards](#python-standards)

### Reference
16. [Code Review Checklist](#code-review-checklist)

---

# Shared Standards

These standards apply to **all** code — legacy and modern.

---

## Non-Negotiables

Every file, every pull request, every time. No exceptions.

1. **Strict types.** All PHP files MUST begin with `declare(strict_types=1);`. Python functions MUST use type hints.
2. **Type hints.** All function/method parameters, return types, and class properties MUST have explicit type declarations.
3. **Doc comments.** All classes and public methods MUST have doc comments with parameter, return, and exception details.
4. **No raw SQL with string interpolation.** All database queries MUST use parameterized bindings or an ORM.
5. **Input validation.** All user input MUST be validated before use.
6. **PSR-12.** All PHP code MUST follow PSR-12. Python code follows PEP 8.
7. **No `any` types.** TypeScript code MUST NOT use `any`. Define proper types or use `unknown` with type guards.

---

## General PHP Rules

### Formatting
- 4 spaces for indentation (no tabs)
- Opening braces on the same line for classes and methods
- One blank line after the namespace declaration
- Max line length: 120 characters
- Always use full `<?php` tags (never short tags)

### Type Hints

```php
<?php

declare(strict_types=1);

// ✅ Correct: Fully typed
public function findOpenTasks(int $limit = 10): Collection
{
    return $this->repository->getOpen($limit);
}

public function findById(int $id): ?Task
{
    return Task::find($id);
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
$this->createTask(
    projectId: $project->id,
    assigneeId: $user->id,
    isUrgent: true,
);

// ❌ Ambiguous
$this->createTask($project->id, $user->id, true);
```

### Naming Conventions

| What | Convention | Example |
|------|------------|---------|
| Class | PascalCase | `TaskService`, `ProjectMember` |
| Method / Function | camelCase | `createTask()`, `validateStatus()` |
| Variable | camelCase | `$taskData`, `$projectId` |
| Constant | UPPER_SNAKE_CASE | `MAX_TITLE_LENGTH`, `DEFAULT_LIMIT` |
| Table | plural, snake_case | `tasks`, `project_members` |
| Column | snake_case | `project_id`, `created_date` |
| Primary Key | `{table_singular}_id` | `task_id`, `project_id` |
| Foreign Key | `{referenced_table_singular}_id` | `project_id`, `user_id` |
| Pivot Table | alphabetical, singular | `tag_task`, `project_user` |

---

## PHPDoc Documentation

All classes, public methods, and complex private methods MUST have PHPDoc comments.

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\Task;
use Illuminate\Support\Collection;
use Illuminate\Validation\ValidationException;

/**
 * Service for managing tasks within projects.
 *
 * Handles creation, updating, deletion, and validation of tasks
 * including status transitions and history tracking.
 */
class TaskService
{
    /**
     * Create a new TaskService instance.
     *
     * @param TaskHistoryService $historyService Service for task history
     */
    public function __construct(
        private readonly TaskHistoryService $historyService
    ) {}

    /**
     * Create a new task with validation and history tracking.
     *
     * @param array<string, mixed> $data Task data from a validated request
     * @return Task The newly created task
     * @throws ValidationException If the status or priority is invalid
     */
    public function createTask(array $data): Task
    {
        $this->validateStatus($data['status']);

        $task = Task::create($data);

        $this->historyService->record($task, 'created');

        return $task;
    }

    /**
     * Get tasks for a project filtered by status.
     *
     * @param int $projectId The project's ID
     * @param string $status The status to filter by (todo|in_progress|done)
     * @return Collection<int, Task> Collection of matching tasks
     */
    public function getTasksByStatus(int $projectId, string $status): Collection
    {
        return Task::where('project_id', $projectId)
            ->where('status', $status)
            ->whereNull('deleted_date')
            ->get();
    }
}
```

### PHPDoc Checklist
- **Classes:** Class-level PHPDoc describing the responsibility.
- **Methods:** Description, `@param` for each parameter, `@return` (if not void), `@throws` for each exception.

---

## Database Standards

### Naming Conventions
- **Tables:** plural, snake_case (`tasks`, `project_members`)
- **Columns:** snake_case (`project_id`, `created_date`)
- **Primary keys:** `{table_singular}_id` (`task_id`, `project_id`)
- **Foreign keys:** `{referenced_table_singular}_id` (`project_id`, `user_id`)
- **Pivot tables:** alphabetical order, singular (`tag_task`)
- **Timestamps:** integer Unix timestamps (`created_date`, `updated_date`)

### Soft Deletes Pattern

All applications use a nullable `deleted_date` integer column (Unix timestamp) rather than a
framework's built-in soft-delete trait. Queries must exclude rows where `deleted_date IS NOT NULL`.

```sql
deleted_date INT(11) NULL DEFAULT NULL;
CREATE INDEX idx_deleted_date ON tasks (deleted_date);
```

### Indexes

```sql
-- Single column
CREATE INDEX idx_project_id ON tasks (project_id);
CREATE INDEX idx_deleted_date ON tasks (deleted_date);

-- Composite index for a common query pattern
CREATE INDEX idx_project_status ON tasks (project_id, status);

-- Unique constraint
CREATE UNIQUE INDEX idx_project_user ON project_members (project_id, user_id);
```

### Migration Best Practices (Laravel)

Always write reversible migrations with existence checks:

```php
public function up(): void
{
    if (!Schema::hasTable('tasks')) {
        Schema::create('tasks', function (Blueprint $table) {
            $table->id('task_id');
            $table->unsignedBigInteger('project_id');
            $table->unsignedBigInteger('assignee_id')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('todo');
            $table->string('priority')->default('medium');
            $table->integer('created_date');
            $table->integer('deleted_date')->nullable();

            $table->foreign('project_id')
                ->references('project_id')->on('projects')
                ->onDelete('cascade');

            $table->index(['project_id', 'status']);
            $table->index('deleted_date');
        });
    }
}

public function down(): void
{
    Schema::dropIfExists('tasks');
}
```

---

## Security Standards

### Input Validation

```php
// ✅ Laravel: Form Request validation
class StoreTaskRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'project_id' => ['required', 'integer', 'exists:projects,project_id'],
            'title'      => ['required', 'string', 'max:255'],
            'status'     => ['required', 'in:todo,in_progress,done'],
            'priority'   => ['required', 'in:low,medium,high'],
        ];
    }
}

// ✅ Legacy: Manual validation
function validateTaskData(array $data): array
{
    $errors = [];
    if (empty($data['title'])) {
        $errors[] = 'A task title is required.';
    }
    if (!in_array($data['status'] ?? '', ['todo', 'in_progress', 'done'], true)) {
        $errors[] = 'Invalid status.';
    }
    return $errors;
}
```

### SQL Injection Prevention

All database queries MUST use parameterized bindings:

```php
// ✅ Correct: Parameterized (legacy PDO)
$stmt = $pdo->prepare('SELECT * FROM tasks WHERE project_id = :id');
$stmt->execute(['id' => $projectId]);

// ✅ Correct: Eloquent (Laravel)
$tasks = Task::where('project_id', $projectId)->get();

// ❌ NEVER: String interpolation
$tasks = DB::select("SELECT * FROM tasks WHERE project_id = $projectId");
$result = mysqli_query($conn, "SELECT * FROM tasks WHERE project_id = $projectId");
```

### Output Escaping

```php
// ✅ Legacy: htmlspecialchars for all output
<p><?= htmlspecialchars($task->title, ENT_QUOTES, 'UTF-8') ?></p>

// ✅ Laravel Blade: double braces escape automatically
<p>{{ $task->title }}</p>

// ✅ Vue: template interpolation escapes automatically
<p>{{ task.title }}</p>

// ❌ NEVER in Blade unless content is explicitly trusted
<p>{!! $task->title !!}</p>
```

### CSRF Protection

```php
// ✅ Legacy: include a CSRF token in all forms
$_SESSION['csrf_token'] = bin2hex(random_bytes(32));
// <input type="hidden" name="csrf_token" value="...">
if (!hash_equals($_SESSION['csrf_token'], $_POST['csrf_token'] ?? '')) {
    http_response_code(403);
    exit('Invalid CSRF token');
}

// ✅ Laravel: handled automatically by Inertia and middleware
```

### Authentication & Authorization

```php
// ✅ Legacy: check at the top of every protected script
session_start();
if (!isset($_SESSION['user_id'])) {
    header('Location: /login.php');
    exit;
}
if (!userHasPermission($_SESSION['user_id'], 'tasks.edit')) {
    http_response_code(403);
    exit('Forbidden');
}

// ✅ Laravel: Policy + middleware
$this->authorizeResource(Task::class, 'task');
```

### Sensitive Data

```php
// ❌ Wrong
Log::info('User login', ['password' => $request->password]);

// ✅ Correct
Log::info('User login attempt', ['email' => $request->email]);
```

---

## Error Handling & Logging

### Principles
- **Never swallow exceptions silently.** Every `catch` block must handle the error meaningfully or re-throw it.
- **Log with context.** Include enough information to diagnose the issue.
- **User-facing messages must be generic.** Never expose stack traces, SQL errors, or internal paths.
- **Use appropriate log levels.** `error` for failures, `warning` for recoverable issues, `info` for significant events, `debug` for diagnostics.

### Laravel Example

```php
public function createTask(array $data): Task
{
    try {
        $this->validateStatus($data['status']);
        $task = Task::create($data);

        Log::info('Task created', [
            'task_id'    => $task->task_id,
            'project_id' => $data['project_id'],
            'created_by' => auth()->id(),
        ]);

        return $task;
    } catch (ValidationException $e) {
        throw $e; // re-throw domain exceptions for the controller to handle
    } catch (\Throwable $e) {
        Log::error('Failed to create task', [
            'data'  => $data,
            'error' => $e->getMessage(),
        ]);
        throw new \RuntimeException('Unable to create task. Please try again.');
    }
}
```

---

## Testing Standards

### Test Framework
- **Laravel apps:** Pest PHP with `it()` / `test()` syntax.
- **Legacy apps:** PHPUnit directly.
- **Python apps:** pytest.

### Coverage Requirements

| Scope | Minimum Coverage |
|-------|-----------------|
| Overall codebase | 80% |
| Critical business logic (services, calculations) | 80% |
| Authentication and authorization | 100% |
| Security-sensitive operations | 100% |

### Test Structure

Every public-facing feature requires at minimum:
- A **happy path** test (expected input produces expected output)
- A **validation failure** test (invalid input is rejected)
- An **authorization** test (unauthenticated/unauthorized users are blocked)

### Pest PHP (Laravel)

```php
<?php

declare(strict_types=1);

use App\Models\Project;
use App\Models\User;

describe('Task Creation', function () {

    it('creates a task for an authenticated user', function () {
        $user = User::factory()->create();
        $project = Project::factory()->create();

        $response = $this->actingAs($user)
            ->post(route('tasks.store'), [
                'project_id' => $project->project_id,
                'title'      => 'Write the docs',
                'status'     => 'todo',
                'priority'   => 'high',
            ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('tasks', ['title' => 'Write the docs']);
    });

    it('rejects unauthenticated users', function () {
        $this->post(route('tasks.store'), [])->assertRedirect(route('login'));
    });

    it('validates the status value', function () {
        $user = User::factory()->create();
        $this->actingAs($user)
            ->post(route('tasks.store'), ['status' => 'banana'])
            ->assertSessionHasErrors(['status']);
    });
});
```

---

## Performance Standards

### N+1 Query Prevention

```php
// ❌ Wrong: N+1 queries
$tasks = Task::all();
foreach ($tasks as $task) {
    echo $task->project->name; // queries the DB for each row
}

// ✅ Correct: eager load relationships
$tasks = Task::with(['project', 'assignee'])->get();
```

### Select Only Needed Columns

```php
// ❌ Wrong
$users = User::all();

// ✅ Correct
$users = User::select(['user_id', 'name', 'email'])->get();
```

### Caching Strategy

```php
public function getAllTags(): Collection
{
    return Cache::remember('tags.all', 3600, fn () => Tag::orderBy('name')->get());
}
Cache::forget('tags.all'); // clear when data changes
```

---

## Environment & Configuration

- `.env` files MUST NOT be committed to version control.
- A `.env.example` file MUST be maintained with all required keys (blank or safe defaults).
- Sensitive values (API keys, DB passwords) MUST NOT appear in code, config files, or logs.

```php
// ✅ Use config/env helpers
$apiUrl = config('services.export.url');

// ❌ NEVER hardcode environment-specific values
$apiUrl = 'https://api.production.example.com';
$dbPassword = 'supersecret123';
```

---

# Legacy Application Standards

These standards apply to native PHP applications that do not use a modern framework.

---

## Legacy Architecture

### Directory Structure

```
project-root/
├── config/
│   ├── config.php              # Environment config (not committed)
│   └── config.example.php      # Config template (committed)
├── public/                     # Web root
│   ├── index.php
│   ├── css/
│   └── js/
├── src/                        # PHP source files
│   ├── Controllers/
│   ├── Services/
│   ├── Models/
│   └── Helpers/
├── templates/                  # HTML templates
├── tests/
├── composer.json
├── .env.example
└── .gitignore
```

### Separation of Concerns

Even without a framework, business logic must be separated from presentation and data access:

```php
<?php
// ✅ Correct: separated responsibilities

declare(strict_types=1);

// src/Services/TaskService.php
class TaskService
{
    public function __construct(private readonly PDO $pdo) {}

    /**
     * Get tasks for a project.
     *
     * @param int $projectId The project's ID
     * @return array<int, array<string, mixed>>
     */
    public function getByProject(int $projectId): array
    {
        $stmt = $this->pdo->prepare(
            'SELECT * FROM tasks WHERE project_id = :id AND deleted_date IS NULL'
        );
        $stmt->execute(['id' => $projectId]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
```

---

## Legacy Frontend

### jQuery Standards

```javascript
// ✅ Correct: event delegation, namespaced events, CSRF, error handling
$(document).on('click.taskModule', '.delete-task', function (e) {
    e.preventDefault();
    var taskId = $(this).data('task-id');
    if (!confirm('Delete this task?')) return;

    $.ajax({
        url: '/api/tasks/' + taskId,
        method: 'DELETE',
        headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
        success: function () {
            $('#task-' + taskId).fadeOut(function () { $(this).remove(); });
        },
        error: function (xhr) {
            alert('Failed to delete task. Please try again.');
            console.error('Delete failed:', xhr.responseText);
        }
    });
});
```

### HTML & CSS
- Use semantic HTML5 elements (`<header>`, `<nav>`, `<main>`, `<section>`, `<footer>`).
- Keep CSS in external stylesheets, not embedded in PHP files.
- Follow BEM naming for custom CSS classes: `.block__element--modifier`.

---

## Legacy Database Access

### PDO (Required)

All legacy applications MUST use PDO with prepared statements. Do not use `mysqli_*` for new code.

```php
<?php

declare(strict_types=1);

function createConnection(array $config): PDO
{
    $dsn = sprintf('mysql:host=%s;dbname=%s;charset=utf8mb4', $config['host'], $config['name']);

    return new PDO($dsn, $config['username'], $config['password'], [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
}
```

### Transactions

```php
public function reassignTask(int $taskId, int $newAssigneeId): bool
{
    try {
        $this->pdo->beginTransaction();

        $stmt = $this->pdo->prepare('UPDATE tasks SET assignee_id = :a WHERE task_id = :id');
        $stmt->execute(['a' => $newAssigneeId, 'id' => $taskId]);

        $stmt = $this->pdo->prepare(
            'INSERT INTO task_history (task_id, action, created_date) VALUES (:id, :action, :now)'
        );
        $stmt->execute(['id' => $taskId, 'action' => 'reassigned', 'now' => time()]);

        $this->pdo->commit();
        return true;
    } catch (PDOException $e) {
        $this->pdo->rollBack();
        error_log("Reassign failed for task {$taskId}: " . $e->getMessage());
        return false;
    }
}
```

---

# Modern Application Standards (Laravel)

---

## Laravel Architecture

### Technology Stack
- **Laravel** — PHP framework
- **Inertia.js** — server-side routing with an SPA experience
- **Vue 3** — progressive JavaScript framework
- **TypeScript** — type-safe JavaScript
- **Tailwind CSS** — utility-first CSS framework
- **Laravel Sail** — Docker development environment

### Controllers

Controllers MUST be "skinny" — no business logic, no validation, no direct database queries:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Requests\Task\StoreTaskRequest;
use App\Models\Task;
use App\Services\TaskService;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response as InertiaResponse;

/**
 * Controller for managing tasks.
 */
class TaskController extends Controller
{
    public function __construct(private readonly TaskService $taskService)
    {
        $this->authorizeResource(Task::class, 'task');
    }

    /**
     * Display a listing of tasks.
     */
    public function index(): InertiaResponse
    {
        $tasks = Task::with(['project', 'assignee'])->latest()->paginate(20);

        return Inertia::render('Task/Index', ['tasks' => $tasks]);
    }

    /**
     * Store a newly created task.
     */
    public function store(StoreTaskRequest $request): RedirectResponse
    {
        $task = $this->taskService->createTask($request->validated());

        return redirect()->route('tasks.show', $task)
            ->with('success', 'Task created successfully');
    }
}
```

### Service Layer

All business logic belongs in Service classes, injected via the constructor. Services are stateless.

### Models

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Task model.
 *
 * @property int $task_id
 * @property int $project_id
 * @property int|null $assignee_id
 * @property string $status
 * @property int|null $deleted_date
 */
class Task extends Model
{
    /** @var array<int, string> */
    protected $fillable = ['project_id', 'assignee_id', 'title', 'description', 'status', 'priority'];

    /** @return BelongsTo<Project, Task> */
    public function project(): BelongsTo
    {
        return $this->belongsTo(Project::class, 'project_id', 'project_id');
    }

    /** @return BelongsTo<User, Task> */
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assignee_id', 'user_id');
    }
}
```

> **Mass assignment:** Use `$fillable` to explicitly list assignable fields. Always pair with
> `$request->validated()` in controllers — never `$request->all()`.

### Form Requests & Policies
- Always use FormRequest classes for validation — controllers MUST NOT validate directly.
- Use Policy classes for all authorization logic.

---

## Vue/TypeScript Standards

### Composition API (Required)

Always use the Composition API with `<script setup lang="ts">`. Options API is not permitted.

```vue
<script setup lang="ts">
import { ref, computed } from 'vue';
import type { Task } from '@/types/models';

interface Props {
  tasks: Task[];
}
const props = defineProps<Props>();

const isLoading = ref(false);
const openTasks = computed(() => props.tasks.filter(t => t.status !== 'done'));

const handleSubmit = async (): Promise<void> => {
  isLoading.value = true;
  try {
    // submit
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div class="task-list">
    <h1>{{ openTasks.length }} open tasks</h1>
    <button @click="handleSubmit" :disabled="isLoading">Submit</button>
  </div>
</template>
```

### TypeScript Strict Mode

Never use `any`:

```typescript
// ✅ Correct: full type definitions
interface Task {
  task_id: number;
  project_id: number;
  assignee_id: number | null;
  title: string;
  status: 'todo' | 'in_progress' | 'done';
  priority: 'low' | 'medium' | 'high';
  created_date: number;
  deleted_date: number | null;
}

const filterByStatus = (tasks: Task[], status: Task['status']): Task[] =>
  tasks.filter(t => t.status === status);

// ❌ Wrong: using 'any'
const filterByStatus = (tasks: any, status: any): any =>
  tasks.filter((t: any) => t.status === status);
```

### Props Validation

```vue
<script setup lang="ts">
import type { Task } from '@/types/models';

interface Props {
  task: Task;
  isEditable?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  isEditable: false,
});
</script>
```

---

# Python Standards

For service and CLI projects (such as `src/example-site`).

### Code Quality
- Type hints on every function signature (parameters and return).
- Docstrings for modules and public functions.
- Follow PEP 8: `snake_case` for functions/variables, `PascalCase` for classes.
- Keep functions small and single-responsibility; isolate I/O.
- Use an `if __name__ == '__main__':` guard for executables.

### Database & SQL

```python
# ✅ Correct: parameterized query
def get_tasks_by_project(db: sqlite3.Connection, project_id: int) -> list[dict]:
    """Return non-deleted tasks for a project."""
    rows = db.execute(
        "SELECT * FROM tasks WHERE project_id = ? AND deleted_date IS NULL",
        (project_id,),
    ).fetchall()
    return [dict(row) for row in rows]

# ❌ Wrong: string interpolation
rows = db.execute(f"SELECT * FROM tasks WHERE project_id = {project_id}")
```

### Validation & Errors

```python
class ValidationError(ValueError):
    """Raised when input fails validation."""


def create_task(db: sqlite3.Connection, data: dict) -> dict:
    """Create a task after validating its fields."""
    if not data.get("title"):
        raise ValidationError("Title is required.")
    if data.get("status") not in {"todo", "in_progress", "done"}:
        raise ValidationError("Invalid status.")
    # ... insert with parameterized SQL ...
```

### Testing
- Use `pytest` with fixtures for setup and seeded data.
- Cover happy path, validation failures, and edge cases.
- Verify coverage with `pytest --cov` (≥80%).

---

## Code Review Checklist

Before approving any change, verify:

- [ ] Strict types / type hints present
- [ ] Doc comments on classes and public methods
- [ ] All queries parameterized — no string interpolation
- [ ] All user input validated server-side
- [ ] Output escaped for its context (HTML/JSON)
- [ ] Authorization enforced at the controller/route level
- [ ] No sensitive data in logs or responses
- [ ] No debug statements (`dd()`, `dump()`, `console.log`, `print()`, `pdb.set_trace()`)
- [ ] No hardcoded values that belong in config/env
- [ ] Tests cover happy path, validation failure, and authorization
- [ ] Coverage meets the threshold (80%, or 100% for auth/security)
- [ ] No N+1 queries; only needed columns selected
- [ ] Soft deletes use `deleted_date`; queries exclude deleted rows
- [ ] CHANGELOG and relevant docs updated in the same change

---

**Version:** 1.0.0
**Last Updated:** 2026-06-01
