# Roadmap — Worktrace

> This roadmap records high-level milestones and phase boundaries. Detailed sprint tasks are defined in their respective sprint briefs once approved.

## Milestone & Phase Sequence

### Pre-S0 — Repository & Documentation Baseline ✅ *(Completed)*
- Establish project root and Git repository.
- Create essential project documentation (`PROJECT_OVERVIEW.md`, `SCOPE.md`, `ROADMAP.md`, `DECISIONS.md`).
- Define initial scope, architectural decisions, and product direction.

---

### Phase 0 — Application Foundation ✅ *(Completed)*
**Goal:** Turn the repository into a properly structured, runnable Android application.

| Sprint | Focus | Deliverable | Status |
|--------|-------|-------------|--------|
| **S0.1** | Architecture decisions & technical baseline | Approved architecture decisions (DEC-002–DEC-013) & documented technical baseline | ✅ Complete |
| **S0.2** | Flutter project scaffold | Flutter scaffold, Riverpod setup, builds and launches on physical Android phone | ✅ Complete |
| **S0.3** | Design system & Worktrace identity | Colors, typography, spacing, brand logo, launcher icons, adaptive light/dark themes | ✅ Complete |
| **S0.4** | Navigation & application shell | Branded home screen, shell layout, navigation placeholders, empty states | ✅ Complete |
| **S0.5** | Quality baseline | Formatting, linting (0 issues), smoke tests, APK build verification, setup documentation | ✅ Complete |

**Phase 0 Showcase:** Installed and launched on physical Android device, displaying real identity, adaptive theme, and clean shell without false functionality.

---

### Phase 1 — Task Workspace *(Next)*
**Goal:** Deliver the first genuinely useful feature, fully backed by local persistence.

| Sprint | Focus | Deliverable | Status |
|--------|-------|-------------|--------|
| **S1.1** | Task domain & storage | Task model, repository contract, Drift database persistence | Pending |
| **S1.2** | Create & view tasks | Add tasks and display them in a structured list | Pending |
| **S1.3** | Edit & complete tasks | Update details, mark complete, reopen where appropriate | Pending |
| **S1.4** | Task organization | Basic status filters and sensible sorting | Pending |
| **S1.5** | Reliability & recovery | Validation, persistence tests, empty states, error handling | Pending |

**Phase 1 Showcase:** Create several tasks, organize them, complete one, force-close the app, reopen it, and verify that the data remains correct.

---

### Phase 2 — Snippet Library *(Future)*
**Goal:** Make Worktrace useful as a personal store of reusable developer knowledge.

| Sprint | Focus | Deliverable | Status |
|--------|-------|-------------|--------|
| **S2.1** | Snippet domain & persistence | Snippet model and database integration | Pending |
| **S2.2** | Create & edit snippets | Title, code content, language, optional description | Pending |
| **S2.3** | Browse & retrieve | Snippet list, detail view, language filters | Pending |
| **S2.4** | Search & copy | Search snippets and copy code to clipboard | Pending |
| **S2.5** | Reliability & usability | Validation, long-code handling, persistence & interaction tests | Pending |

**Phase 2 Showcase:** Save Dart, Python, and SQL snippets, retrieve one through search, copy its contents, and verify the copied code.

---

### Phase 3 — Continuity & Polish *(Future)*
**Goal:** Connect the features around Worktrace's central promise: picking up where you left off.

| Sprint | Focus | Deliverable | Status |
|--------|-------|-------------|--------|
| **S3.1** | Workspace home | Useful overview of pending tasks and recent snippets | Pending |
| **S3.2** | Resume-oriented interactions | Clear next actions and quick access to unfinished work | Pending |
| **S3.3** | Cross-feature navigation | Navigate naturally between tasks and relevant snippets | Pending |
| **S3.4** | Interaction & accessibility polish | Consistent loading, empty and error states; accessible controls | Pending |
| **S3.5** | Integrated regression | Verify combined workflows, persistence, navigation, and theme behavior | Pending |

**Phase 3 Showcase:** Open the app, identify the next unfinished task, find a relevant snippet, copy it, and return to the task seamlessly.

---

### Phase 4 — Release Readiness *(Future)*
**Goal:** Make the MVP dependable enough to distribute and evaluate with real users.

| Sprint | Focus | Deliverable | Status |
|--------|-------|-------------|--------|
| **S4.1** | End-to-end verification | Automated and manual checks for critical workflows | Pending |
| **S4.2** | Performance & data integrity | Responsiveness, database behavior, and migration checks | Pending |
| **S4.3** | Privacy & release configuration | Permissions review, sensitive data check, signing config, release settings | Pending |
| **S4.4** | Release docs & packaging | Versioned APK, installation guide, known limitations, release notes | Pending |
| **S4.5** | Release-candidate acceptance | Final acceptance checklist and reproducible release evidence | Pending |

**Phase 4 Showcase:** A versioned release-candidate APK that can be installed on a clean Android device with verified principal workflows.

---

## Cross-Phase Engineering Rules

1. **Preserve the baseline:** Build on `v-Pre-S0`; never recreate the repository to start a phase.
2. **Document decisions:** Material architectural improvements require rationale, impact assessment, and a recorded decision in `DECISIONS.md`.
3. **No premature sync:** Design local data access cleanly, but don't build a backend or sync engine into the MVP without an approved requirement.
4. **Test each increment:** Tests accompany each feature sprint rather than being postponed entirely until release.
5. **Show evidence:** Each phase closes with a working demonstration, verification results, updated documentation, and a versioned milestone.
6. **Keep scope small:** A sprint delivers one coherent, reviewable increment.

---

## Progress Benchmarks

* **Phase 0 — It runs** ✅ *(Current)*
* **Phase 1 — It remembers tasks**
* **Phase 2 — It retains knowledge**
* **Phase 3 — It connects the workflow**
* **Phase 4 — It's ready to distribute**
