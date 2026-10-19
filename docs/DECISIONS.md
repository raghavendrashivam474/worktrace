# Decisions â€" Worktrace

> Record of architectural, product, and process decisions.
> Status values: **Accepted** | **Proposed** | **Deferred**

---

## DEC-001 â€" Product Name and Category

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | The product is named **Worktrace** and is categorized as a personal developer workspace. |
| **Reasoning** | Name reflects the core concept: tracing units of work for easy resumption. |
| **Consequences** | All documentation, repository naming, and branding use this name. |
| **Date** | 2026-10 |

---

## DEC-002 â€" Target Platform

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Android is the initial target platform. |
| **Reasoning** | Aligns with the primary user base (students) and allows focused development. |
| **Consequences** | Flutter is configured for Android output first. iOS/desktop deferred. Minimum SDK to be verified against actual Flutter and plugin requirements during S0.2. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-003 â€" Application Framework

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Flutter and Dart for the application framework. |
| **Reasoning** | Cross-platform capable, strong ecosystem, suitable for a single-developer project. |
| **Consequences** | All application code will be Dart. Platform-specific code minimized. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-004 â€" Local Persistence

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | SQLite via the Drift package for local data storage. |
| **Reasoning** | Drift provides type-safe queries, reactive streams, and migration support on top of SQLite. Well-suited for local-first apps. |
| **Consequences** | Database schema defined in Dart. Migration strategy required from feature sprints onward. Schema, migrations, path_provider, and database initialization deferred until an actual feature requires them. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-005 â€" State Management

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Riverpod (flutter_riverpod) for state management. |
| **Reasoning** | Compile-safe, testable, and widely adopted in the Flutter ecosystem. Scales well from simple to complex state. |
| **Consequences** | ProviderScope at app root. No Provider or Bloc usage. Code generation (riverpod_generator) is optional and will only be introduced when a real need justifies it. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-006 â€" Data Strategy

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Local-first data model. Synchronization is a future consideration, not a V1 feature. |
| **Reasoning** | Eliminates backend dependency for V1. Keeps the app usable offline and without accounts. |
| **Consequences** | Data layer must be designed to allow sync later without a full rewrite. No cloud infrastructure in V1. |
| **Date** | 2026-10 |

---

## DEC-007 â€" V1 Feature Scope

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | V1 includes tasks and reusable code snippets only. |
| **Reasoning** | Narrow scope ensures a completable, useful product for the target audience. |
| **Consequences** | See [SCOPE.md](SCOPE.md) for the full in/out/deferred breakdown. |
| **Date** | 2026-10 |

---

## DEC-008 â€" Theming

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Adaptive light and dark themes following system preference, using Material 3. |
| **Reasoning** | Standard expectation for modern Android apps. Material 3 ColorScheme.fromSeed provides a coherent palette from a single brand color. |
| **Consequences** | Theme configuration in S0.3. ThemeMode.system by default. No manual theme toggle in V1. Exact brand palette remains provisional until S0.3 visual review. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-009 â€" Brand Concept

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | Brand imagery combines modular pieces, a connecting trace, and an open endpoint representing continuity and resumability. |
| **Reasoning** | Visually communicates the product's core value proposition. |
| **Consequences** | Logo and visual identity to be reviewed and implemented in S0.3. The existing concept is a direction, not a finalized production asset. |
| **Date** | 2026-10 |

---

## DEC-010 â€" Repository Structure

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Worktrace lives in its own dedicated directory (Worktrace/) within the parent workspace, with its own Git repository. |
| **Reasoning** | Prevents entanglement with unrelated projects in the parent workspace. Clean ownership and history. |
| **Consequences** | Parent directory (Anti-grav) is not version-controlled as part of this project. |
| **Date** | 2026-10 |

---

## DEC-011 â€" Application Structure

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Feature-first directory structure inside lib/ with app/, features/, and shared/ top-level groups. |
| **Reasoning** | Lightweight enough for a small app, scales naturally as features are added. Avoids premature layering or empty abstractions. |
| **Consequences** | lib/main.dart as entry point. lib/app/ for MaterialApp config, theme, and navigation. lib/features/ for task and snippet modules (created when needed). lib/shared/ for genuinely shared widgets only â€" no speculative modules. |
| **Date** | S0.1 |

---

## DEC-012 â€" Sync-Readiness

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Maintain clean domain/data boundaries to preserve a future path to synchronization, without building sync infrastructure now. |
| **Reasoning** | Local-first is the product direction (DEC-006). Clean separation of domain models from persistence implementation makes future sync feasible without a rewrite. Premature sync abstractions add cost without current value. |
| **Consequences** | Domain models are plain Dart classes, not coupled to Drift-generated data classes. No network layer, auth, sync queue, or conflict resolution in Phase 0. Entity identifier strategy (UUID vs. other) deferred to the data-model design sprint when task/snippet schemas are defined. |
| **Date** | S0.1 |

---

## DEC-013 â€" Quality Baseline

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Minimum per-sprint checks: dart format, flutter analyze, flutter test (where applicable), and a successful Android debug build. |
| **Reasoning** | Ensures each sprint leaves the codebase in a verifiable, working state without imposing heavyweight CI before it is needed. |
| **Consequences** | Formatting and analysis are mandatory every sprint. Tests required where applicable. Android build verified every sprint from S0.2 onward. Code generation (build_runner) run only when the project uses generated code. Generated Dart source required by the build (e.g., Drift .g.dart files) is committed to the repository for reproducible builds â€" see .gitignore policy. CI/CD pipeline deferred. |
| **Date** | S0.1 |

---

*Add new decisions at the bottom of this file using the same format.*

---

## DEC-014 â€" Task Identifier Strategy

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Task identifiers use UUID v4, generated client-side via the `uuid` package. |
| **Reasoning** | UUID v4 provides collision-resistant identifiers without requiring a central authority or sequential counter. This preserves the local-first model (DEC-006) and keeps the future sync path open (DEC-012) â€" UUIDs merge cleanly across devices. |
| **Consequences** | The `uuid` package is added as a dependency. Task IDs are opaque strings, not auto-increment integers. The domain model generates IDs at creation time, not at persistence time. |
| **Date** | S1.1 |

---

## DEC-015 â€" Database Architecture

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | A single `AppDatabase` class in `lib/core/data/` hosts all Drift tables. Feature-specific tables live in their feature directory (e.g., `lib/features/tasks/data/tasks_table.dart`) and are registered in the shared database. The database accepts a `QueryExecutor` via constructor injection. |
| **Reasoning** | A single database avoids multiple SQLite connections and simplifies migrations. Constructor injection of the executor keeps the database testable (in-memory for tests, file-based for production) without global state. Feature-local table definitions preserve the feature-first structure (DEC-011). |
| **Consequences** | `AppDatabase` is in `lib/core/data/`, not inside any single feature. Table files use `@DataClassName` annotations to avoid name collisions with domain models (DEC-012). Production initialization with `path_provider` will be wired in S1.2. |
| **Date** | S1.1 |

---

## DEC-016 â€" Domain Model Validation

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Domain validation uses factory constructors that throw `ArgumentError` for invalid input. No separate validation result type or Either/Result wrapper. |
| **Reasoning** | The initial task model has a single validation rule (non-empty title). A factory constructor is the simplest Dart-idiomatic approach. A Result type would add complexity without current benefit and can be introduced later if validation rules grow. |
| **Consequences** | Callers must catch `ArgumentError` or validate input before calling the factory. The repository layer trusts that domain objects passed to it are already valid. |
| **Date** | S1.1 |
---

## DEC-017 â€" Database Initialization

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | The production database is opened asynchronously in `main()` before `runApp()`, then injected into the widget tree via `ProviderScope.overrides`. The `databaseProvider` throws `UnimplementedError` if accessed without an override. |
| **Reasoning** | Async initialization in `main()` avoids race conditions and keeps the database lifecycle tied to the application lifecycle. The throwing default catches wiring bugs immediately rather than producing silent null errors. |
| **Consequences** | `main()` is now `async`. Tests override `taskRepositoryProvider` directly with fakes, bypassing the database entirely. No global singleton or late-initialized variable. |
| **Date** | S1.2 |

---

## DEC-018 â€" Task UI Interaction Patterns

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Task creation uses a modal `AlertDialog` with a `TextField`. Task deletion requires a confirmation dialog. Task completion uses an inline `Checkbox`. All mutations persist through the provider before updating the UI. |
| **Reasoning** | Dialog-based creation is the simplest Material 3 pattern for a single-field form. Confirmation before deletion prevents accidental data loss. Inline checkbox is the standard Material pattern for binary toggle. Persist-before-render ensures the UI never shows state that doesn't match the database. |
| **Consequences** | No separate task editor screen in this phase. Task editing (title change after creation) deferred to a future sprint. The `TextEditingController` is disposed after a 300ms delay to accommodate the dialog exit animation. |
| **Date** | S1.3 |
## DEC-019: Presentation-Local Task Organization & Self-Contained Dialog Lifecycle
- **Status:** Approved
- **Context:** S1.4 required title editing, search, completion filtering, and sorting. S1.5 required resolving dialog lifecycle fragility (delayed controller disposal).
- **Decision:** Search query, filter selection, and sort options are evaluated in-memory inside TasksScreen (ConsumerStatefulWidget). Dialogs use a dedicated _TaskFormDialog stateful widget that manages controller creation in initState and cleanup in dispose.
- **Consequences:** Keeps presentation state localized without introducing unnecessary global providers or Drift schema bloat. Eliminates Future.delayed(300ms) controller disposal workarounds.

## DEC-020: SQLite Timestamp Precision and Local Time Semantics
- **Status:** Approved
- **Context:** Drift/SQLite date-time storage operates with second-level precision.
- **Decision:** Retain Drift default second-level DateTime mapping for createdAt and updatedAt.
- **Consequences:** Sufficient for task ordering and auditing without database schema migrations. Test fixtures use microsecond-truncated fixed dates to ensure deterministic assertions.

## DEC-021 - Snippet Domain Model and Validation

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Snippet identifiers use UUID v4 (DEC-014). Domain validation uses factory constructors throwing `ArgumentError` (DEC-016). Fields: id, title, code, language, createdAt, updatedAt. Language is normalized to lowercase. Title, code, and language must be non-empty after trimming. Timestamps use second precision (DEC-020). |
| **Reasoning** | Mirrors the established Task domain patterns exactly. UUID v4 preserves sync-readiness (DEC-012). Lowercase language simplifies future filtering and grouping. Three required text fields (title, code, language) represent the minimum useful snippet without over-engineering. |
| **Consequences** | `Snippet.create()` and `Snippet.update()` throw `ArgumentError` for invalid input. The repository layer trusts that domain objects are pre-validated. No separate validation result type. |
| **Date** | S2.3 |
