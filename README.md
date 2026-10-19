# Worktrace

**Personal developer workspace for students and beginner developers.**

> **Status:** Phase 0 (Application Foundation) - **Complete**.
> A fully configured, branded, themed Android application shell exists with local state management and a design system baseline.

## What is Worktrace?

Worktrace is a local-first Android app designed to keep small units of
development work and reusable knowledge close at hand. It helps students
and beginner developers resume work without reconstructing everything
from memory.

## Initial V1 Scope

- Create and manage **tasks**
- Save and retrieve **reusable code snippets**
- **Local-first** operation (data stays on your device)

## Technology Stack

| Area | Choice | Status |
|------|--------|--------|
| Platform | Android (API 21+) | Accepted (DEC-002) |
| Framework | Flutter 3.44 / Dart 3.12 | Accepted (DEC-003) |
| Local persistence | SQLite via Drift | Accepted (DEC-004) |
| State management | Riverpod (`flutter_riverpod`) | Accepted (DEC-005) |
| Theming | Adaptive light & dark (Material 3) | Accepted (DEC-008) |

See [docs/DECISIONS.md](docs/DECISIONS.md) for the complete decision record.

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.44+)
- Android SDK (API 36, Build tools 36.1.0)
- Java 21 (bundled with Android Studio)
- An Android emulator or physical device

### Setup & Run

```bash
# Clone the repository
git clone https://github.com/raghavendrashivam474/worktrace.git
cd worktrace

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run
Build Debug APK

flutter build apk --debug

#Quality Verification


dart format .
flutter analyze
flutter test
```

## Project Structure

```text
lib/
|-- main.dart              # Entry point (ProviderScope + runApp)
|-- app/
|   |-- app.dart           # MaterialApp configuration
|   |-- theme/             # Theme configuration & design tokens
|   |-- navigation/        # App shell and navigation UI
|-- features/              # Feature modules (Phase 1: tasks/, snippets/)
|-- shared/                # Shared widgets (WtCard, WtPrimaryButton, etc.)
```

## Documentation Index

| Document | Purpose |
|---|---|
| **Project Overview** | Problem statement, users, principles |
| **Scope** | In-scope, out-of-scope, deferred features |
| **Roadmap** | Phase sequence and milestone progress |
| **Decisions** | Architectural & product decisions |
| **Architecture Baseline** | S0.1 Architecture baseline contract |
| **Design System** | S0.3 Design tokens, typography, and theme guidelines |
| **Quality Guide** | S0.5 Quality gates, CI workflow, and developer checks |


## License

>To be determined.
