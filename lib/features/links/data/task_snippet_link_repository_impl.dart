import 'package:drift/drift.dart';

import '../../../core/data/app_database.dart';
import '../domain/task_snippet_link.dart';
import '../domain/task_snippet_link_repository.dart';

/// Drift-backed implementation of [TaskSnippetLinkRepository].
///
/// Maps between domain [TaskSnippetLink] objects and Drift row types.
/// No Drift types leak through the public interface.
class DriftTaskSnippetLinkRepository implements TaskSnippetLinkRepository {
  final AppDatabase _db;

  DriftTaskSnippetLinkRepository(this._db);

  @override
  Future<bool> attach(String taskId, String snippetId) async {
    _validateId(taskId, 'taskId');
    _validateId(snippetId, 'snippetId');

    // Check for existing link before inserting.
    // Safe for local-first single-user app with no concurrent writers.
    final existing =
        await (_db.select(_db.taskSnippetLinks)..where(
              (l) => l.taskId.equals(taskId) & l.snippetId.equals(snippetId),
            ))
            .getSingleOrNull();
    if (existing != null) return false;

    await _db
        .into(_db.taskSnippetLinks)
        .insert(
          TaskSnippetLinksCompanion.insert(
            taskId: taskId,
            snippetId: snippetId,
            linkedAt: DateTime.now(),
          ),
        );
    return true;
  }

  @override
  Future<bool> detach(String taskId, String snippetId) async {
    _validateId(taskId, 'taskId');
    _validateId(snippetId, 'snippetId');

    final deleted =
        await (_db.delete(_db.taskSnippetLinks)..where(
              (l) => l.taskId.equals(taskId) & l.snippetId.equals(snippetId),
            ))
            .go();
    return deleted > 0;
  }

  @override
  Future<List<TaskSnippetLink>> getByTask(String taskId) async {
    _validateId(taskId, 'taskId');

    final rows =
        await (_db.select(_db.taskSnippetLinks)
              ..where((l) => l.taskId.equals(taskId))
              ..orderBy([(l) => OrderingTerm.desc(l.linkedAt)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<TaskSnippetLink>> getBySnippet(String snippetId) async {
    _validateId(snippetId, 'snippetId');

    final rows =
        await (_db.select(_db.taskSnippetLinks)
              ..where((l) => l.snippetId.equals(snippetId))
              ..orderBy([(l) => OrderingTerm.desc(l.linkedAt)]))
            .get();
    return rows.map(_toDomain).toList();
  }

  void _validateId(String id, String name) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, name, 'Must not be empty.');
    }
  }

  TaskSnippetLink _toDomain(TaskSnippetLinkRow row) {
    return TaskSnippetLink(
      taskId: row.taskId,
      snippetId: row.snippetId,
      linkedAt: row.linkedAt,
    );
  }
}
