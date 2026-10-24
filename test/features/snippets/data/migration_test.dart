import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/links/data/task_snippet_link_repository_impl.dart';
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

  group('database migration v2 -> v3', () {
    test('real v2 database upgrades to v3 preserving all data', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'worktrace_v2v3_test_',
      );
      final dbPath = p.join(tempDir.path, 'v2_to_v3.db');

      // Step 1: Create a genuine v2 schema (tasks + snippets, no links).
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
      rawDb.execute('''
          CREATE TABLE snippets (
            id TEXT NOT NULL PRIMARY KEY,
            title TEXT NOT NULL,
            code TEXT NOT NULL,
            language TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');

      // Insert representative data with realistic timestamps.
      final ts1 =
          DateTime(2026, 1, 15, 10, 0, 0).millisecondsSinceEpoch ~/ 1000;
      final ts2 =
          DateTime(2026, 2, 20, 14, 30, 0).millisecondsSinceEpoch ~/ 1000;
      final ts3 = DateTime(2026, 3, 5, 9, 15, 0).millisecondsSinceEpoch ~/ 1000;

      rawDb.execute(
        'INSERT INTO tasks (id, title, is_completed, created_at, updated_at) '
        "VALUES ('v2-task-1', 'Pre-migration task', 0, $ts1, $ts1)",
      );
      rawDb.execute(
        'INSERT INTO tasks (id, title, is_completed, created_at, updated_at) '
        "VALUES ('v2-task-2', 'Completed task', 1, $ts2, $ts2)",
      );
      rawDb.execute(
        'INSERT INTO snippets (id, title, code, language, created_at, updated_at) '
        "VALUES ('v2-snippet-1', 'Helper function', 'void help() {}', 'dart', $ts1, $ts1)",
      );
      rawDb.execute(
        'INSERT INTO snippets (id, title, code, language, created_at, updated_at) '
        "VALUES ('v2-snippet-2', 'API call', 'fetch(url)', 'dart', $ts3, $ts3)",
      );

      // Set user_version to 2 (v2 schema — no links table).
      rawDb.execute('PRAGMA user_version = 2');
      rawDb.close();

      // Step 2: Open with current AppDatabase (v3) — triggers migration.
      final dbV3 = AppDatabase(NativeDatabase(File(dbPath)));
      final taskRepo = DriftTaskRepository(dbV3);
      final snippetRepo = DriftSnippetRepository(dbV3);
      final linkRepo = DriftTaskSnippetLinkRepository(dbV3);

      // Step 3: Verify all pre-existing data survived.
      final tasks = await taskRepo.getAllTasks();
      expect(tasks, hasLength(2));
      expect(tasks.any((t) => t.id == 'v2-task-1'), isTrue);
      expect(tasks.any((t) => t.title == 'Pre-migration task'), isTrue);
      expect(tasks.any((t) => t.id == 'v2-task-2' && t.isCompleted), isTrue);

      final snippets = await snippetRepo.getAllSnippets();
      expect(snippets, hasLength(2));
      expect(snippets.any((s) => s.id == 'v2-snippet-1'), isTrue);
      expect(snippets.any((s) => s.code == 'void help() {}'), isTrue);
      expect(snippets.any((s) => s.id == 'v2-snippet-2'), isTrue);

      // Step 4: Verify the new links table exists and works.
      final created = await linkRepo.attach('v2-task-1', 'v2-snippet-1');
      expect(created, isTrue);

      final links = await linkRepo.getByTask('v2-task-1');
      expect(links, hasLength(1));
      expect(links.first.snippetId, 'v2-snippet-1');

      // Step 5: Verify FK enforcement and cascade behavior.
      // Delete a task — its association rows should cascade.
      await taskRepo.deleteTask('v2-task-1');
      final linksAfterDelete = await linkRepo.getByTask('v2-task-1');
      expect(
        linksAfterDelete,
        isEmpty,
        reason: 'Cascade delete should remove task associations.',
      );

      // Create a new link, then delete the snippet — cascade.
      await linkRepo.attach('v2-task-2', 'v2-snippet-2');
      await snippetRepo.deleteSnippet('v2-snippet-2');
      final linksAfterSnippetDelete = await linkRepo.getBySnippet(
        'v2-snippet-2',
      );
      expect(
        linksAfterSnippetDelete,
        isEmpty,
        reason: 'Cascade delete should remove snippet associations.',
      );

      // Step 6: Verify duplicate associations are prevented.
      await linkRepo.attach('v2-task-2', 'v2-snippet-1');
      final duplicate = await linkRepo.attach('v2-task-2', 'v2-snippet-1');
      expect(
        duplicate,
        isFalse,
        reason: 'Duplicate (taskId, snippetId) should be rejected.',
      );

      // Step 7: Verify invalid FK references are rejected.
      expect(
        () => linkRepo.attach('nonexistent-task', 'v2-snippet-1'),
        throwsA(isA<Exception>()),
        reason: 'FK enforcement should prevent dangling task references.',
      );

      expect(
        () => linkRepo.attach('v2-task-2', 'nonexistent-snippet'),
        throwsA(isA<Exception>()),
        reason: 'FK enforcement should prevent dangling snippet references.',
      );

      // Step 8: Verify the database operates normally after migration.
      final newTask = Task.create(id: 'post-v3', title: 'After v3');
      await taskRepo.createTask(newTask);
      final allTasks = await taskRepo.getAllTasks();
      expect(allTasks.any((t) => t.id == 'post-v3'), isTrue);

      await dbV3.close();
      await tempDir.delete(recursive: true);
    });
  });
}
