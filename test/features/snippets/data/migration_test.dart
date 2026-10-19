import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_impl.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/tasks/data/task_repository_impl.dart';
import 'package:worktrace/features/tasks/domain/task.dart';

void main() {
  group('database migration v1 -> v2', () {
    test('fresh database creates both tables', () async {
      final db = AppDatabase.inMemory();

      // Verify tasks table works
      final taskRepo = DriftTaskRepository(db);
      final task = Task.create(id: 't1', title: 'Test task');
      await taskRepo.createTask(task);
      final tasks = await taskRepo.getAllTasks();
      expect(tasks, hasLength(1));

      // Verify snippets table works
      final snippetRepo = DriftSnippetRepository(db);
      final snippet = Snippet.create(
        id: 's1',
        title: 'Test snippet',
        code: 'code',
        language: 'dart',
      );
      await snippetRepo.createSnippet(snippet);
      final snippets = await snippetRepo.getAllSnippets();
      expect(snippets, hasLength(1));

      await db.close();
    });

    test('migration from v1 preserves existing task data', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'worktrace_migration_test_',
      );
      final dbPath = p.join(tempDir.path, 'migration.db');

      // Step 1: Manually create a v1 database with task data
      // using raw sqlite3 to simulate the old schema.
      final rawDb = sqlite3.sqlite3.open(dbPath);
      rawDb.execute('''
        CREATE TABLE tasks (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
      ''');
      // Insert two tasks using Drift's DateTime encoding
      // (seconds since epoch, stored as INTEGER).
      final ts1 = DateTime(2026, 1, 1, 12, 0, 0).millisecondsSinceEpoch ~/ 1000;
      final ts2 =
          DateTime(2026, 3, 15, 8, 30, 0).millisecondsSinceEpoch ~/ 1000;
      rawDb.execute(
        'INSERT INTO tasks (id, title, is_completed, created_at, updated_at) '
        "VALUES ('migrate-1', 'Surviving task', 0, $ts1, $ts1)",
      );
      rawDb.execute(
        'INSERT INTO tasks (id, title, is_completed, created_at, updated_at) '
        "VALUES ('migrate-2', 'Another task', 0, $ts2, $ts2)",
      );
      // Set user_version to 1 (v1 schema).
      rawDb.execute('PRAGMA user_version = 1');
      rawDb.close();

      // Step 2: Open with current AppDatabase (v2) — triggers migration.
      final dbV2 = AppDatabase(NativeDatabase(File(dbPath)));
      final taskRepoV2 = DriftTaskRepository(dbV2);
      final snippetRepoV2 = DriftSnippetRepository(dbV2);

      // Verify task data survived the migration.
      final tasks = await taskRepoV2.getAllTasks();
      expect(tasks, hasLength(2));
      expect(tasks.any((t) => t.id == 'migrate-1'), isTrue);
      expect(tasks.any((t) => t.title == 'Surviving task'), isTrue);
      expect(tasks.any((t) => t.id == 'migrate-2'), isTrue);

      // Verify snippets table is now available after migration.
      final snippets = await snippetRepoV2.getAllSnippets();
      expect(snippets, isEmpty);

      // Verify we can create snippets in the migrated database.
      final newSnippet = Snippet.create(
        id: 'post-migrate',
        title: 'After migration',
        code: 'print("works")',
        language: 'dart',
      );
      await snippetRepoV2.createSnippet(newSnippet);
      final afterCreate = await snippetRepoV2.getAllSnippets();
      expect(afterCreate, hasLength(1));

      await dbV2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
