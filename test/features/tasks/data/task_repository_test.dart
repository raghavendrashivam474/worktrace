import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/tasks/data/task_repository_impl.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = DriftTaskRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('getAllTasks', () {
    test('returns empty list when no tasks exist', () async {
      final tasks = await repo.getAllTasks();
      expect(tasks, isEmpty);
    });

    test('returns all created tasks', () async {
      final t1 = Task.create(id: '1', title: 'First');
      final t2 = Task.create(id: '2', title: 'Second');
      await repo.createTask(t1);
      await repo.createTask(t2);

      final tasks = await repo.getAllTasks();
      expect(tasks, hasLength(2));
    });

    test('orders by createdAt descending (newest first)', () async {
      final old = Task.create(
        id: 'old',
        title: 'Old',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = Task.create(
        id: 'new',
        title: 'New',
        createdAt: DateTime.utc(2026, 6, 1),
      );
      await repo.createTask(old);
      await repo.createTask(newer);

      final tasks = await repo.getAllTasks();
      expect(tasks.first.id, 'new');
      expect(tasks.last.id, 'old');
    });
  });

  group('getTaskById', () {
    test('returns task when found', () async {
      final task = Task.create(id: 'find-me', title: 'Findable');
      await repo.createTask(task);

      final found = await repo.getTaskById('find-me');
      expect(found, isNotNull);
      expect(found!.title, 'Findable');
    });

    test('returns null when not found', () async {
      final found = await repo.getTaskById('nonexistent');
      expect(found, isNull);
    });
  });

  group('createTask', () {
    test('persists a task that can be retrieved', () async {
      final task = Task.create(id: 'c1', title: 'Created');
      await repo.createTask(task);

      final retrieved = await repo.getTaskById('c1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'c1');
      expect(retrieved.title, 'Created');
      expect(retrieved.isCompleted, false);
    });
  });

  group('updateTask', () {
    test('updates title and preserves createdAt', () async {
      // Use a microsecond-free DateTime because SQLite truncates
      // sub-second precision on storage.
      final fixedDate = DateTime(2026, 6, 15, 12, 0, 0);
      final task = Task.create(
        id: 'u1',
        title: 'Original',
        createdAt: fixedDate,
      );
      await repo.createTask(task);

      final updated = task.updateTitle('Updated');
      await repo.updateTask(updated);

      final retrieved = await repo.getTaskById('u1');
      expect(retrieved!.title, 'Updated');
      expect(retrieved.createdAt, fixedDate);
    });

    test('persists completion state change', () async {
      final task = Task.create(id: 'u2', title: 'Complete me');
      await repo.createTask(task);

      final completed = task.toggleCompletion();
      await repo.updateTask(completed);

      final retrieved = await repo.getTaskById('u2');
      expect(retrieved!.isCompleted, true);
    });

    test('persists reopening a completed task', () async {
      final task = Task.create(id: 'u3', title: 'Reopen me');
      await repo.createTask(task);

      final completed = task.toggleCompletion();
      await repo.updateTask(completed);

      final reopened = completed.toggleCompletion();
      await repo.updateTask(reopened);

      final retrieved = await repo.getTaskById('u3');
      expect(retrieved!.isCompleted, false);
    });
  });

  group('deleteTask', () {
    test('removes a task', () async {
      final task = Task.create(id: 'd1', title: 'Delete me');
      await repo.createTask(task);
      await repo.deleteTask('d1');

      final found = await repo.getTaskById('d1');
      expect(found, isNull);
    });

    test('does not throw when deleting nonexistent task', () async {
      expect(() => repo.deleteTask('ghost'), returnsNormally);
    });
  });

  group('watchAllTasks', () {
    test('emits updated list after creation', () async {
      final emissions = <List<Task>>[];
      final sub = repo.watchAllTasks().listen(emissions.add);

      // Allow initial empty emission
      await Future.delayed(const Duration(milliseconds: 100));

      final task = Task.create(id: 'w1', title: 'Watched');
      await repo.createTask(task);

      // Allow stream to emit
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.title, 'Watched');

      await sub.cancel();
    });
  });

  group('persistence across reconnection', () {
    test('data survives closing and reopening the database', () async {
      // Suppress expected warning: we intentionally open the same
      // file twice to test reconnection behavior.
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );

      final tempDir = await Directory.systemTemp.createTemp('worktrace_test_');
      final dbPath = p.join(tempDir.path, 'reconnect.db');

      // First connection: create a task
      final db1 = AppDatabase(NativeDatabase(File(dbPath)));
      final repo1 = DriftTaskRepository(db1);
      final task = Task.create(id: 'persist-1', title: 'Survive reconnect');
      await repo1.createTask(task);
      await db1.close();

      // Second connection: verify task exists
      final db2 = AppDatabase(NativeDatabase(File(dbPath)));
      final repo2 = DriftTaskRepository(db2);
      final tasks = await repo2.getAllTasks();

      expect(tasks, hasLength(1));
      expect(tasks.first.id, 'persist-1');
      expect(tasks.first.title, 'Survive reconnect');
      expect(tasks.first.isCompleted, false);

      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
