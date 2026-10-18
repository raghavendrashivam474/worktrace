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
| **Status** | Proposed |
| **Decision** | Android is the initial target platform. |
| **Reasoning** | Aligns with the primary user base (students) and allows focused development. |
| **Consequences** | Flutter is configured for Android output first. iOS/desktop deferred. |
| **Date** | 2026-10 |

---

## DEC-003 — Application Framework

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | Flutter and Dart for the application framework. |
| **Reasoning** | Cross-platform capable, strong ecosystem, suitable for a single-developer project. |
| **Consequences** | All application code will be Dart. Platform-specific code minimized. |
| **Date** | 2026-10 |

---

## DEC-004 — Local Persistence

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | SQLite via the Drift package for local data storage. |
| **Reasoning** | Drift provides type-safe queries, reactive streams, and migration support on top of SQLite. Well-suited for local-first apps. |
| **Consequences** | Database schema defined in Dart. Migration strategy required from S0 onward. |
| **Date** | 2026-10 |

---

## DEC-005 — State Management

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | Riverpod for state management. |
| **Reasoning** | Compile-safe, testable, and widely adopted in the Flutter ecosystem. Scales well from simple to complex state. |
| **Consequences** | Provider architecture established in S0. No Provider or Bloc usage. |
| **Date** | 2026-10 |

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
| **Status** | Proposed |
| **Decision** | Adaptive light and dark themes following system preference. |
| **Reasoning** | Standard expectation for modern Android apps. Minimal additional effort with Flutter's Material 3 support. |
| **Consequences** | Theme configuration in S0. No custom theme editor in V1. |
| **Date** | 2026-10 |

---

## DEC-009 — Brand Concept

| Field | Detail |
|-------|--------|
| **Status** | Proposed |
| **Decision** | Brand imagery combines modular pieces, a connecting trace, and an open endpoint representing continuity and resumability. |
| **Reasoning** | Visually communicates the product's core value proposition. |
| **Consequences** | Logo and visual identity to be designed in a future sprint. |
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

*Add new decisions at the bottom of this file using the same format.*
