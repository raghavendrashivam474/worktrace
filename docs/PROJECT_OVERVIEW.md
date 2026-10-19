# Project Overview - Worktrace

## The Problem

Students and beginner developers frequently lose momentum between coding
sessions. Small but important pieces of work - a half-finished task, a
useful code snippet, a solution to a tricky bug - get buried in chat
histories, scattered notes, or forgotten browser tabs. Resuming work then
requires reconstructing context from memory, which is slow and
error-prone.

## Target Users

- **Primary:** Students learning to code (university, bootcamp,
  self-taught).
- **Secondary:** Beginner developers in their first 1-2 years who juggle
  multiple small projects and learning goals.

## Core Product Promise

**Keep your work traceable.** Every small unit of development effort and
every reusable piece of knowledge should be easy to find, easy to resume,
and easy to build on - without relying on cloud services or complex
tooling.

## Product Principles

1. **Local-first.** Data lives on the user's device by default. No
   account required to get value.
2. **Small units.** Optimize for tasks and snippets, not large-scale
   project management.
3. **Low friction.** Capturing a task or saving a snippet should take
   seconds, not minutes.
4. **Resumability.** The app should make it obvious where you left off.
5. **Honest scope.** Do not promise capabilities the app cannot reliably
   deliver at its current stage.

## Current Direction

- Android application built with Flutter and Dart.
- Two core features for V1: tasks and code snippets.
- SQLite (via Drift) for local persistence.
- Riverpod for state management.
- Adaptive light and dark themes.

## Known Limitations

- No cloud synchronization in V1 (architecture should not prevent it
  later).
- No multi-user or collaboration features planned.
- No backend services.
- iOS and desktop are out of scope for the initial release.
- All technology choices remain provisional until validated during S0.
