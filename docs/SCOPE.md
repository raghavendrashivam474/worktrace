# Scope — Worktrace

## In Scope (V1 Baseline)

These capabilities are approved for the initial V1 release:

- **Task management** — create, edit, complete, and delete small
  development tasks.
- **Code snippet storage** — save, tag, search, and retrieve reusable
  code snippets.
- **Local-first data** — all data stored on the user's device using
  SQLite (via Drift).
- **Adaptive theming** — light and dark theme support following the
  system preference.
- **Resumability cues** — clear indicators of where the user left off
  (e.g., recently active tasks/snippets).
- **Foundation for future sync** — data layer designed so that
  synchronization can be added later without a full rewrite.

## Out of Scope (V1)

These are explicitly **not** part of V1 unless separately approved:

- Cloud synchronization implementation.
- Multi-user collaboration or shared workspaces.
- Backend services or server infrastructure.
- AI-assisted features (code generation, summarization, etc.).
- Complex project execution or IDE-like capabilities.
- iOS, desktop, or web platform targets.
- Plugin or extension system.
- Real-time notifications or push messaging.
- Social features (profiles, feeds, sharing).

## Deferred (Future Consideration)

These ideas are acknowledged but have no committed timeline:

- Cloud sync (architecture should not block it).
- Cross-platform support (iOS, desktop, web).
- Snippet sharing between users.
- Integration with external services (GitHub, GitLab, etc.).
- Advanced search (full-text, regex, semantic).
- Backup and export/import of local data.
- Custom tags, categories, or folder hierarchies beyond basic tagging.

## Scope Change Policy

Any item moving from *Deferred* or *Out of Scope* into *In Scope* must be:

1. Proposed with a clear rationale.
2. Recorded in [DECISIONS.md](DECISIONS.md) with status *Accepted*.
3. Reflected in an updated version of this document.

Do not silently promote deferred ideas into requirements.
