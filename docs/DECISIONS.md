# Decisions — Worktrace

> Record of architectural, product, and process decisions.
> Status values: **Accepted** | **Proposed** | **Deferred**

---

## DEC-001 — Product Name and Category

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | The product is named **Worktrace** and is categorized as a personal developer workspace. |
| **Reasoning** | Name reflects the core concept: tracing units of work for easy resumption. |
| **Consequences** | All documentation, repository naming, and branding use this name. |
| **Date** | 2026-10 |

---

## DEC-002 — Target Platform

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Android is the initial target platform. |
| **Reasoning** | Aligns with the primary user base (students) and allows focused development. |
| **Consequences** | Flutter is configured for Android output first. iOS/desktop deferred. Minimum SDK to be verified against actual Flutter and plugin requirements during S0.2. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-003 — Application Framework

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Flutter and Dart for the application framework. |
| **Reasoning** | Cross-platform capable, strong ecosystem, suitable for a single-developer project. |
| **Consequences** | All application code will be Dart. Platform-specific code minimized. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-004 — Local Persistence

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | SQLite via the Drift package for local data storage. |
| **Reasoning** | Drift provides type-safe queries, reactive streams, and migration support on top of SQLite. Well-suited for local-first apps. |
| **Consequences** | Database schema defined in Dart. Migration strategy required from feature sprints onward. Schema, migrations, path_provider, and database initialization deferred until an actual feature requires them. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-005 — State Management

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Riverpod (flutter_riverpod) for state management. |
| **Reasoning** | Compile-safe, testable, and widely adopted in the Flutter ecosystem. Scales well from simple to complex state. |
| **Consequences** | ProviderScope at app root. No Provider or Bloc usage. Code generation (riverpod_generator) is optional and will only be introduced when a real need justifies it. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-006 — Data Strategy

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Local-first data model. Synchronization is a future consideration, not a V1 feature. |
| **Reasoning** | Eliminates backend dependency for V1. Keeps the app usable offline and without accounts. |
| **Consequences** | Data layer must be designed to allow sync later without a full rewrite. No cloud infrastructure in V1. |
| **Date** | 2026-10 |

---

## DEC-007 — V1 Feature Scope

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | V1 includes tasks and reusable code snippets only. |
| **Reasoning** | Narrow scope ensures a completable, useful product for the target audience. |
| **Consequences** | See [SCOPE.md](SCOPE.md) for the full in/out/deferred breakdown. |
| **Date** | 2026-10 |

---

## DEC-008 — Theming

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Adaptive light and dark themes following system preference, using Material 3. |
| **Reasoning** | Standard expectation for modern Android apps. Material 3 ColorScheme.fromSeed provides a coherent palette from a single brand color. |
| **Consequences** | Theme configuration in S0.3. ThemeMode.system by default. No manual theme toggle in V1. Exact brand palette remains provisional until S0.3 visual review. |
| **Date** | 2026-10 (proposed), S0.1 (accepted) |

---

## DEC-009 — Brand Concept

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | Brand imagery combines modular pieces, a connecting trace, and an open endpoint representing continuity and resumability. |
| **Reasoning** | Visually communicates the product's core value proposition. |
| **Consequences** | Logo and visual identity to be reviewed and implemented in S0.3. The existing concept is a direction, not a finalized production asset. |
| **Date** | 2026-10 |

---

## DEC-010 — Repository Structure

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Worktrace lives in its own dedicated directory (Worktrace/) within the parent workspace, with its own Git repository. |
| **Reasoning** | Prevents entanglement with unrelated projects in the parent workspace. Clean ownership and history. |
| **Consequences** | Parent directory (Anti-grav) is not version-controlled as part of this project. |
| **Date** | 2026-10 |

---

## DEC-011 — Application Structure

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Feature-first directory structure inside lib/ with app/, features/, and shared/ top-level groups. |
| **Reasoning** | Lightweight enough for a small app, scales naturally as features are added. Avoids premature layering or empty abstractions. |
| **Consequences** | lib/main.dart as entry point. lib/app/ for MaterialApp config, theme, and navigation. lib/features/ for task and snippet modules (created when needed). lib/shared/ for genuinely shared widgets only — no speculative modules. |
| **Date** | S0.1 |

---

## DEC-012 — Sync-Readiness

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Maintain clean domain/data boundaries to preserve a future path to synchronization, without building sync infrastructure now. |
| **Reasoning** | Local-first is the product direction (DEC-006). Clean separation of domain models from persistence implementation makes future sync feasible without a rewrite. Premature sync abstractions add cost without current value. |
| **Consequences** | Domain models are plain Dart classes, not coupled to Drift-generated data classes. No network layer, auth, sync queue, or conflict resolution in Phase 0. Entity identifier strategy (UUID vs. other) deferred to the data-model design sprint when task/snippet schemas are defined. |
| **Date** | S0.1 |

---

## DEC-013 — Quality Baseline

| Field | Detail |
|-------|--------|
| **Status** | Accepted |
| **Decision** | Minimum per-sprint checks: dart format, flutter analyze, flutter test (where applicable), and a successful Android debug build. |
| **Reasoning** | Ensures each sprint leaves the codebase in a verifiable, working state without imposing heavyweight CI before it is needed. |
| **Consequences** | Formatting and analysis are mandatory every sprint. Tests required where applicable. Android build verified every sprint from S0.2 onward. Code generation (build_runner) run only when the project uses generated code. Generated Dart source required by the build (e.g., Drift .g.dart files) is committed to the repository for reproducible builds — see .gitignore policy. CI/CD pipeline deferred. |
| **Date** | S0.1 |

---

*Add new decisions at the bottom of this file using the same format.*
