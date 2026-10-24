import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import '../../features/links/data/task_snippet_links_table.dart';
import '../../features/snippets/data/snippets_table.dart';
import '../../features/tasks/data/tasks_table.dart';

part 'app_database.g.dart';

/// The application-wide Drift database.
///
/// Lives in lib/core/data/ because it hosts tables for
/// multiple features (tasks, snippets, and their associations).
///
/// Pass a [QueryExecutor] to the constructor:
/// - Production: NativeDatabase(File(dbPath))
/// - Testing:    NativeDatabase.memory()
@DriftDatabase(tables: [Tasks, Snippets, TaskSnippetLinks])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Convenience constructor for in-memory testing.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(snippets);
      }
      if (from < 3) {
        await m.createTable(taskSnippetLinks);
      }
    },
    beforeOpen: (details) async {
      // Enable foreign-key enforcement for cascade deletes.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
