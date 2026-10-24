import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/links/data/task_snippet_link_repository_impl.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_impl.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/tasks/data/task_repository_impl.dart';
import 'package:worktrace/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository taskRepo;
  late DriftSnippetRepository snippetRepo;
  late DriftTaskSnippetLinkRepository linkRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = DriftTaskRepository(db);
    snippetRepo = DriftSnippetRepository(db);
    linkRepo = DriftTaskSnippetLinkRepository(db);
  });

  tearDown(() => db.close());

  Task makeTask(String id) => Task(
    id: id,
    title: 'Task $id',
    isCompleted: false,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  Snippet makeSnippet(String id) => Snippet(
    id: id,
    title: 'Snippet $id',
    code: 'void main() {}',
    language: 'dart',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  group('Database schema v3', () {
    test('fresh database creates all three tables', () async {
      final tasks = await taskRepo.getAllTasks();
      final snippets = await snippetRepo.getAllSnippets();
      final links = await linkRepo.getByTask('any');

      expect(tasks, isEmpty);
      expect(snippets, isEmpty);
      expect(links, isEmpty);
    });

    test('schema version is 3', () {
      expect(db.schemaVersion, 3);
    });

    test('foreign key enforcement is enabled', () async {
      final result = await db.customSelect('PRAGMA foreign_keys').get();
      expect(result.first.read<int>('foreign_keys'), 1);
    });
  });

  group('TaskSnippetLinkRepository', () {
    test('attach creates a link', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));

      final created = await linkRepo.attach('t1', 's1');
      expect(created, isTrue);

      final links = await linkRepo.getByTask('t1');
      expect(links, hasLength(1));
      expect(links.first.snippetId, 's1');
    });

    test('attach returns false for duplicate link', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));

      await linkRepo.attach('t1', 's1');
      final second = await linkRepo.attach('t1', 's1');
      expect(second, isFalse);
    });

    test('attach rejects empty taskId', () async {
      expect(() => linkRepo.attach('', 's1'), throwsArgumentError);
    });

    test('attach rejects empty snippetId', () async {
      expect(() => linkRepo.attach('t1', '  '), throwsArgumentError);
    });

    test('detach removes link without deleting entities', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await linkRepo.attach('t1', 's1');

      final removed = await linkRepo.detach('t1', 's1');
      expect(removed, isTrue);

      expect(await linkRepo.getByTask('t1'), isEmpty);
      expect(await taskRepo.getTaskById('t1'), isNotNull);
      expect(await snippetRepo.getSnippetById('s1'), isNotNull);
    });

    test('detach returns false when no link exists', () async {
      final removed = await linkRepo.detach('t1', 's1');
      expect(removed, isFalse);
    });

    test('getByTask returns only links for that task', () async {
      await taskRepo.createTask(makeTask('t1'));
      await taskRepo.createTask(makeTask('t2'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await snippetRepo.createSnippet(makeSnippet('s2'));

      await linkRepo.attach('t1', 's1');
      await linkRepo.attach('t1', 's2');
      await linkRepo.attach('t2', 's1');

      expect(await linkRepo.getByTask('t1'), hasLength(2));
      expect(await linkRepo.getByTask('t2'), hasLength(1));
    });

    test('getBySnippet returns only links for that snippet', () async {
      await taskRepo.createTask(makeTask('t1'));
      await taskRepo.createTask(makeTask('t2'));
      await snippetRepo.createSnippet(makeSnippet('s1'));

      await linkRepo.attach('t1', 's1');
      await linkRepo.attach('t2', 's1');

      expect(await linkRepo.getBySnippet('s1'), hasLength(2));
    });

    test('deleting a task cascades and removes its links', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await linkRepo.attach('t1', 's1');

      await taskRepo.deleteTask('t1');

      expect(await linkRepo.getByTask('t1'), isEmpty);
      expect(await snippetRepo.getSnippetById('s1'), isNotNull);
    });

    test('deleting a snippet cascades and removes its links', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await linkRepo.attach('t1', 's1');

      await snippetRepo.deleteSnippet('s1');

      expect(await linkRepo.getByTask('t1'), isEmpty);
      expect(await taskRepo.getTaskById('t1'), isNotNull);
    });
  });
}
