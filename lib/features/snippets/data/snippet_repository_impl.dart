import 'package:drift/drift.dart';

import '../../../core/data/app_database.dart';
import '../domain/snippet.dart';
import '../domain/snippet_repository.dart';

/// Drift-backed implementation of [SnippetRepository].
///
/// Maps between domain [Snippet] objects and Drift [SnippetRow] types.
/// No Drift types leak through the public interface.
class DriftSnippetRepository implements SnippetRepository {
  final AppDatabase _db;

  DriftSnippetRepository(this._db);

  @override
  Future<List<Snippet>> getAllSnippets() async {
    final rows = await (_db.select(
      _db.snippets,
    )..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Snippet?> getSnippetById(String id) async {
    final query = _db.select(_db.snippets)..where((s) => s.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> createSnippet(Snippet snippet) async {
    await _db
        .into(_db.snippets)
        .insert(
          SnippetsCompanion.insert(
            id: snippet.id,
            title: snippet.title,
            code: snippet.code,
            language: snippet.language,
            createdAt: snippet.createdAt,
            updatedAt: snippet.updatedAt,
          ),
        );
  }

  @override
  Future<void> updateSnippet(Snippet snippet) async {
    await (_db.update(
      _db.snippets,
    )..where((s) => s.id.equals(snippet.id))).write(
      SnippetsCompanion(
        title: Value(snippet.title),
        code: Value(snippet.code),
        language: Value(snippet.language),
        updatedAt: Value(snippet.updatedAt),
      ),
    );
  }

  @override
  Future<void> deleteSnippet(String id) async {
    await (_db.delete(_db.snippets)..where((s) => s.id.equals(id))).go();
  }

  @override
  Stream<List<Snippet>> watchAllSnippets() {
    final query = _db.select(_db.snippets)
      ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Snippet _toDomain(SnippetRow row) {
    return Snippet(
      id: row.id,
      title: row.title,
      code: row.code,
      language: row.language,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
