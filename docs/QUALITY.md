# Quality Guide — Worktrace

**Phase:** S0.5 — Quality Baseline & CI Setup
**Status:** Active

---

## 1. Required Tooling

| Tool | Version | Purpose |
|------|---------|---------|
| Flutter SDK | 3.44+ | Application framework |
| Dart SDK | 3.12+ | Bundled with Flutter |
| Android SDK | API 36, Build tools 36.1.0 | Android compilation |
| Java | 17+ (Temurin recommended) | Gradle build system |

Verify your installation:

```bash
flutter doctor -v
```


## 2. Dependency Installation

```bash
flutter pub get
```

Dependencies are locked via pubspec.lock. Do not manually edit the lockfile.
To update dependencies intentionally, use flutter pub upgrade and review the diff.

## 3. Local Execution

```bash
flutter run
```

Requires a connected Android device or running emulator.

## 4. Quality Gates

Run these commands from the repository root before every commit.

### 4.1 Formatting Verification

```bash
dart format --output=none --set-exit-if-changed .
```

Exits with code 1 if any Dart file requires formatting.
Does not modify files — this is a check, not a fix.
To auto-format locally: dart format .

### 4.2 Static Analysis

```bash
flutter analyze
```

Must report 0 errors and 0 warnings.
Info-level hints are acceptable if they come from generated code or SDK constraints.
Lint rules are configured in analysis_options.yaml (extends flutter_lints).

### 4.3 Automated Tests

```bash
flutter test
```

Runs all tests in test/.
Tests are deterministic — no network, device, or credentials required.
Uses Flutter's widget test environment.


### 4.4 Android Debug Build

```bash
flutter build apk --debug
```

Produces build/app/outputs/flutter-apk/app-debug.apk.
Verifies the full compilation pipeline including Gradle and Android resources.
Build outputs are not committed to the repository.


### 4.5 Run All Gates (one-liner)

```bash
dart format --output=none --set-exit-if-changed . && flutter analyze && flutter test && flutter build apk --debug
```

## 5. Continuous Integration

### Workflow Location

`.github/workflows/flutter-ci.yml`

### Triggers

- Push to main
Pull requests targeting main


### CI Pipeline

| Step | Command | Fails on |
|------|---------|---------|
| Checkout | actions/checkout@v4 | — |
| Java setup | actions/setup-java@v4 (Temurin 17) | — |
| Flutter setup | subosito/flutter-action@v2 (3.44.2 stable) | — |
| Dependencies | flutter pub get | Resolution errors |
| Formatting | dart format --output=none --set-exit-if-changed . | Unformatted files |
| Analysis | flutter analyze | Errors or warnings |
| Tests | flutter test | Any test failure |
| Build | flutter build apk --debug | Compilation failure |

If any step fails, the workflow stops and reports the failure.

### CI Rules

- Flutter SDK version is pinned for reproducibility.
- Dependencies are resolved from the committed lockfile.
- No secrets, credentials, or deployment steps.
- No build artifacts are uploaded.
- No automatic dependency updates.


## 6. Current Test Coverage

| Area | Covered | Notes |
|------|---------|-------|
| App startup | Yes | widget_test.dart |
| Navigation destinations | Yes | navigation_test.dart |
| Tab switching | Yes | Home ↔ Tasks ↔ Snippets |
| Back navigation | Yes | PopScope behavior |
| Responsive layout | Yes | NavigationBar vs NavigationRail |
| Theme (light/dark) | Partial | Inherited via MaterialApp; no explicit theme-switch test yet |
| Task CRUD | No | Phase 1 — not yet implemented |
| Snippet CRUD | No | Phase 2 — not yet implemented |
| Database | No | No persistence layer yet |


## 7. Known Limitations

- No code coverage reporting. Coverage percentage tracking is deferred until a coverage service is approved.
- No integration tests. Widget tests cover shell behavior; full integration tests deferred to feature sprints.
- No iOS/desktop CI. Android-only per DEC-002.
- Theme toggle not tested. ThemeMode.system is configured but no manual toggle exists in V1.
- CI Flutter version may lag. If 3.44.2 is unavailable in the action, update the pinned version in the workflow file.


## 8. Adding New Quality Gates

When a future sprint requires a new check (e.g., code generation verification, integration tests):

   1. Add the command to this document.
   2. Add the step to .github/workflows/flutter-ci.yml.
   3. Verify it passes locally and in CI before merging.
   4. Update the test coverage table above.


This document is the quality contract for Worktrace. Changes require review.
