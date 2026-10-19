# Architecture Baseline - Worktrace

**Phase:** S0.1 - Architecture Decisions & Technical Baseline
**Date:** S0.1
**Status:** Accepted (see DECISIONS.md)

---

## 1. Application Identity

Worktrace is a local-first Android application built with Flutter and Dart.
It serves students and beginner developers who need to keep small units of
work and reusable code snippets traceable across sessions.

## 2. Technology Stack

| Layer | Technology | Decision |
|-------|-----------|----------|
| Platform | Android (API 21+, verify in S0.2) | DEC-002 |
| Framework | Flutter 3.44 / Dart 3.12 | DEC-003 |
| State | flutter_riverpod | DEC-005 |
| Persistence | SQLite via Drift | DEC-004 |
| Theming | Material 3, adaptive light/dark | DEC-008 |

## 3. Project Structure

```text
lib/
|-- main.dart # Entry point: ProviderScope + runApp
|-- app/
| |-- app.dart # MaterialApp, theme, routing
| |-- theme/ # ColorScheme, TextTheme, spacing tokens
| |-- navigation/ # Shell, routes (when needed)
|-- features/ # Feature modules (tasks/, snippets/)
|-- shared/ # Genuinely shared widgets/utilities only
```


**Principle:** Create directories and files when they have an actual purpose.
No speculative modules, no empty layers.

## 4. Dependency Direction
UI (widgets, screens)
↓ reads from
State (Riverpod providers)
↓ orchestrates
Domain (plain Dart models, rules)
↓ persisted by
Data (Drift database, repositories)

text


- UI depends on state, not directly on data.
- Domain models are plain Dart classes, independent of Drift and Riverpod.
- Data layer implements persistence behind repository interfaces.
- No layer reaches upward.

## 5. State Management

- `ProviderScope` wraps the application at `main.dart`.
- UI widgets use `ConsumerWidget` or `ConsumerStatefulWidget`.
- Code generation (`riverpod_generator`) is optional - introduced only
  when a real need justifies it.
- No mixing with Provider, Bloc, GetX, or other state systems.

## 6. Local Persistence

- Drift provides type-safe SQLite access.
- Schema defined in Dart using Drift table DSL.
- Migrations via Drift `MigrationStrategy`.
- Generated code produced by `drift_dev` + `build_runner`.
- Database file stored in the app's documents directory (`path_provider`).
- **Current status:** Tool selected, approach documented. Schema and
  initialization deferred to feature sprints.

## 7. Generated Code Policy

- Generated Dart files required for builds (e.g., `*.g.dart`, `*.freezed.dart`)
  are **committed** to the repository for reproducible builds.
- `build_runner` is run locally when schema or provider definitions change.
- `*.mocks.dart` remains ignored (regenerated per test run).
- See `.gitignore` for the current rules.

## 8. Sync-Readiness

- Domain models are decoupled from Drift-generated data classes.
- Business logic does not depend on database implementation details.
- No network layer, authentication, sync queue, or conflict resolution
  exists in Phase 0.
- Entity identifier strategy deferred to the data-model design sprint.
- This is a **design constraint**, not infrastructure.

## 9. Theming

- Material 3 with `ColorScheme.fromSeed()` using a Worktrace brand color.
- Light and dark themes from the same seed.
- `ThemeMode.system` - follows device preference.
- Semantic color tokens in `lib/app/theme/`.
- Exact palette provisional until S0.3 visual review.

## 10. Quality Baseline

| Check | Command | When |
|-------|---------|------|
| Formatting | `dart format .` | Every sprint |
| Analysis | `flutter analyze` | Every sprint |
| Tests | `flutter test` | Every sprint (where applicable) |
| Android build | `flutter build apk --debug` | Every sprint from S0.2 |
| Code generation | `dart run build_runner build` | When generated code changes |

CI/CD pipeline deferred.

## 11. Phase 0 Boundaries

**Included:** App shell, navigation, theme, design system, project structure.
**Excluded:** Task CRUD, snippet storage, database schema, search, sync,
authentication, backend, CI/CD, release automation.

---

*This document is the implementation contract for S0.2 and S0.3.
Changes require the architectural improvement protocol (see brief Section 7).*
