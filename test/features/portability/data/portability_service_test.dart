import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/links/data/task_snippet_link_repository_impl.dart';
import 'package:worktrace/features/portability/data/portability_service.dart';
import 'package:worktrace/features/portability/domain/export_schema.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_impl.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/tasks/data/task_repository_impl.dart';
import 'package:worktrace/features/tasks/domain/task.dart';

void main() {
  late AppDatabase db;
  late DriftTaskRepository taskRepo;
  late DriftSnippetRepository snippetRepo;
  late DriftTaskSnippetLinkRepository linkRepo;
  late PortabilityService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    taskRepo = DriftTaskRepository(db);
    snippetRepo = DriftSnippetRepository(db);
    linkRepo = DriftTaskSnippetLinkRepository(db);
    service = PortabilityService(
      taskRepo: taskRepo,
      snippetRepo: snippetRepo,
      linkRepo: linkRepo,
      db: db,
    );
  });

  tearDown(() => db.close());

  Task makeTask(String id, {String title = 'Test'}) => Task(
    id: id,
    title: title,
    isCompleted: false,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 2),
  );

  Snippet makeSnippet(String id, {String title = 'Code'}) => Snippet(
    id: id,
    title: title,
    code: 'void main() {}',
    language: 'dart',
    createdAt: DateTime.utc(2025, 2, 1),
    updatedAt: DateTime.utc(2025, 2, 2),
  );

  group('Export', () {
    test('produces valid JSON with correct format and version', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await linkRepo.attach('t1', 's1');

      final json = await service.exportWorkspace();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['format'], 'worktrace-export');
      expect(decoded['version'], 1);
      expect(decoded['tasks'], hasLength(1));
      expect(decoded['snippets'], hasLength(1));
      expect(decoded['links'], hasLength(1));
    });

    test('preserves all task fields', () async {
      await taskRepo.createTask(makeTask('t1', title: 'My Task'));

      final json = await service.exportWorkspace();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final task = (decoded['tasks'] as List).first as Map<String, dynamic>;

      expect(task['id'], 't1');
      expect(task['title'], 'My Task');
      expect(task['isCompleted'], false);
      expect(task['createdAt'], isNotNull);
      expect(task['updatedAt'], isNotNull);
    });

    test('preserves all snippet fields', () async {
      await snippetRepo.createSnippet(makeSnippet('s1', title: 'Helper'));

      final json = await service.exportWorkspace();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final snippet =
          (decoded['snippets'] as List).first as Map<String, dynamic>;

      expect(snippet['id'], 's1');
      expect(snippet['title'], 'Helper');
      expect(snippet['code'], 'void main() {}');
      expect(snippet['language'], 'dart');
    });

    test('empty workspace exports cleanly', () async {
      final json = await service.exportWorkspace();
      final decoded = jsonDecode(json) as Map<String, dynamic>;

      expect(decoded['tasks'], isEmpty);
      expect(decoded['snippets'], isEmpty);
      expect(decoded['links'], isEmpty);
    });
  });

  group('Validation', () {
    test('rejects invalid JSON', () {
      expect(() => service.validateExport('not json'), throwsFormatException);
    });

    test('rejects wrong format', () {
      final json = jsonEncode({'format': 'other', 'version': 1});
      expect(() => service.validateExport(json), throwsFormatException);
    });

    test('rejects unsupported version', () {
      final json = jsonEncode({
        'format': 'worktrace-export',
        'version': 999,
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': [],
        'snippets': [],
        'links': [],
      });
      expect(() => service.validateExport(json), throwsFormatException);
    });

    test('rejects non-object JSON', () {
      expect(() => service.validateExport('[1, 2, 3]'), throwsFormatException);
    });

    test('accepts valid export', () async {
      await taskRepo.createTask(makeTask('t1'));
      final json = await service.exportWorkspace();

      final export = service.validateExport(json);
      expect(export.format, 'worktrace-export');
      expect(export.version, 1);
      expect(export.tasks, hasLength(1));
    });
  });

  group('Import — successful cases', () {
    test('imports new tasks and snippets', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      await linkRepo.attach('t1', 's1');
      final json = await service.exportWorkspace();
      final export = service.validateExport(json);

      // Import into a fresh database.
      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshService = PortabilityService(
        taskRepo: DriftTaskRepository(freshDb),
        snippetRepo: DriftSnippetRepository(freshDb),
        linkRepo: DriftTaskSnippetLinkRepository(freshDb),
        db: freshDb,
      );

      final result = await freshService.importWorkspace(export);
      expect(result.tasksImported, 1);
      expect(result.snippetsImported, 1);
      expect(result.linksImported, 1);
      expect(result.totalSkipped, 0);

      await freshDb.close();
    });

    test('skips duplicate tasks and snippets', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      final json = await service.exportWorkspace();
      final export = service.validateExport(json);

      final result = await service.importWorkspace(export);
      expect(result.tasksImported, 0);
      expect(result.tasksSkipped, 1);
      expect(result.snippetsImported, 0);
      expect(result.snippetsSkipped, 1);
    });

    test('skips links with missing entities', () async {
      final export = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [],
        snippets: [],
        links: [
          ExportLink(
            taskId: 'nonexistent',
            snippetId: 'also-missing',
            linkedAt: DateTime.now(),
          ),
        ],
      );

      final result = await service.importWorkspace(export);
      expect(result.linksImported, 0);
      expect(result.linksSkipped, 1);
    });

    test('round-trip preserves data', () async {
      await taskRepo.createTask(makeTask('t1', title: 'Round Trip'));
      await snippetRepo.createSnippet(makeSnippet('s1', title: 'Helper'));
      await linkRepo.attach('t1', 's1');

      final json = await service.exportWorkspace();
      final export = service.validateExport(json);

      final freshDb = AppDatabase(NativeDatabase.memory());
      final freshTaskRepo = DriftTaskRepository(freshDb);
      final freshSnippetRepo = DriftSnippetRepository(freshDb);
      final freshLinkRepo = DriftTaskSnippetLinkRepository(freshDb);
      final freshService = PortabilityService(
        taskRepo: freshTaskRepo,
        snippetRepo: freshSnippetRepo,
        linkRepo: freshLinkRepo,
        db: freshDb,
      );

      await freshService.importWorkspace(export);

      final task = await freshTaskRepo.getTaskById('t1');
      expect(task, isNotNull);
      expect(task!.title, 'Round Trip');

      final snippet = await freshSnippetRepo.getSnippetById('s1');
      expect(snippet, isNotNull);
      expect(snippet!.title, 'Helper');

      final links = await freshLinkRepo.getByTask('t1');
      expect(links, hasLength(1));

      await freshDb.close();
    });

    test('import summary accurately describes the operation', () async {
      final export = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [
          ExportTask(
            id: 't1',
            title: 'T1',
            isCompleted: false,
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
          ExportTask(
            id: 't2',
            title: 'T2',
            isCompleted: true,
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        snippets: [
          ExportSnippet(
            id: 's1',
            title: 'S1',
            code: 'x',
            language: 'dart',
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        links: [],
      );

      final result = await service.importWorkspace(export);
      expect(result.tasksImported, 2);
      expect(result.snippetsImported, 1);
      expect(result.linksImported, 0);
      expect(result.totalImported, 3);
      expect(result.summary, contains('2 tasks'));
      expect(result.summary, contains('1 snippets'));
    });
  });

  group('Import — validation prevents writes', () {
    test('malformed file causes zero database writes', () async {
      await taskRepo.createTask(makeTask('existing'));
      expect(() => service.validateExport('not json'), throwsFormatException);

      final tasks = await taskRepo.getAllTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.id, 'existing');
    });

    test('unsupported format version causes zero database writes', () async {
      await taskRepo.createTask(makeTask('existing'));

      final json = jsonEncode({
        'format': 'worktrace-export',
        'version': 999,
        'exportedAt': DateTime.now().toIso8601String(),
        'tasks': [
          {
            'id': 'new-t',
            'title': 'Should not appear',
            'isCompleted': false,
            'createdAt': DateTime.utc(2025, 1, 1).toIso8601String(),
            'updatedAt': DateTime.utc(2025, 1, 1).toIso8601String(),
          },
        ],
        'snippets': [],
        'links': [],
      });
      expect(() => service.validateExport(json), throwsFormatException);

      final tasks = await taskRepo.getAllTasks();
      expect(tasks, hasLength(1));
    });
  });

  group('Import — transactional rollback', () {
    /// Helper: creates a DB, forces schema init, then installs a trigger
    /// that ABORTs when a snippet with [failSnippetId] is inserted.
    Future<AppDatabase> createDbWithSnippetTrigger(String failSnippetId) async {
      final testDb = AppDatabase(NativeDatabase.memory());
      // Force Drift to create all tables by running a trivial query.
      await testDb.customSelect('SELECT 1').get();
      // Now the snippets table exists — install the trigger.
      await testDb.customStatement('''
        CREATE TRIGGER fail_on_specific_snippet
        BEFORE INSERT ON snippets
        WHEN NEW.id = '$failSnippetId'
        BEGIN
          SELECT RAISE(ABORT, 'Simulated DB failure');
        END;
      ''');
      return testDb;
    }

    test('real DB failure mid-import rolls back all writes', () async {
      final failDb = await createDbWithSnippetTrigger('fail-s1');
      final failTaskRepo = DriftTaskRepository(failDb);
      final failSnippetRepo = DriftSnippetRepository(failDb);
      final failLinkRepo = DriftTaskSnippetLinkRepository(failDb);
      final failService = PortabilityService(
        taskRepo: failTaskRepo,
        snippetRepo: failSnippetRepo,
        linkRepo: failLinkRepo,
        db: failDb,
      );

      // Pre-populate with original data.
      await failTaskRepo.createTask(makeTask('original-t1'));

      // Import: task 'new-t1' inserts first, then snippet 'fail-s1' ABORTs.
      final export = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [
          ExportTask(
            id: 'new-t1',
            title: 'Should be rolled back',
            isCompleted: false,
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        snippets: [
          ExportSnippet(
            id: 'fail-s1',
            title: 'Triggers failure',
            code: 'x',
            language: 'dart',
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        links: [],
      );

      expect(
        () => failService.importWorkspace(export),
        throwsA(isA<Exception>()),
      );

      // CRITICAL: 'new-t1' must NOT exist — rolled back.
      final newTask = await failTaskRepo.getTaskById('new-t1');
      expect(
        newTask,
        isNull,
        reason: 'Task inserted before the failure must be rolled back.',
      );

      // Original data must be intact.
      final originalTask = await failTaskRepo.getTaskById('original-t1');
      expect(
        originalTask,
        isNotNull,
        reason: 'Pre-existing data must survive the rollback.',
      );

      await failDb.close();
    });

    test('original database contents remain intact after rollback', () async {
      final failDb = await createDbWithSnippetTrigger('boom');
      final fTaskRepo = DriftTaskRepository(failDb);
      final fSnippetRepo = DriftSnippetRepository(failDb);
      final fLinkRepo = DriftTaskSnippetLinkRepository(failDb);
      final fService = PortabilityService(
        taskRepo: fTaskRepo,
        snippetRepo: fSnippetRepo,
        linkRepo: fLinkRepo,
        db: failDb,
      );

      // Pre-populate with multiple records.
      await fTaskRepo.createTask(makeTask('keep-t1', title: 'Keep Me'));
      await fTaskRepo.createTask(makeTask('keep-t2', title: 'Keep Me Too'));
      await fSnippetRepo.createSnippet(
        makeSnippet('keep-s1', title: 'Original Snippet'),
      );
      await fLinkRepo.attach('keep-t1', 'keep-s1');

      // Attempt import that will fail mid-way.
      final export = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [
          ExportTask(
            id: 'intruder-t',
            title: 'Should vanish',
            isCompleted: false,
            createdAt: DateTime.utc(2025, 6, 1),
            updatedAt: DateTime.utc(2025, 6, 1),
          ),
        ],
        snippets: [
          ExportSnippet(
            id: 'boom',
            title: 'Causes rollback',
            code: 'x',
            language: 'dart',
            createdAt: DateTime.utc(2025, 6, 1),
            updatedAt: DateTime.utc(2025, 6, 1),
          ),
        ],
        links: [],
      );

      expect(() => fService.importWorkspace(export), throwsA(isA<Exception>()));

      // Verify all original records are untouched.
      final tasks = await fTaskRepo.getAllTasks();
      expect(tasks, hasLength(2));
      expect(tasks.map((t) => t.id), containsAll(['keep-t1', 'keep-t2']));

      final snippets = await fSnippetRepo.getAllSnippets();
      expect(snippets, hasLength(1));
      expect(snippets.first.title, 'Original Snippet');

      final links = await fLinkRepo.getByTask('keep-t1');
      expect(links, hasLength(1));

      // Verify the intruder was rolled back.
      expect(await fTaskRepo.getTaskById('intruder-t'), isNull);

      await failDb.close();
    });

    test('subsequent valid import succeeds after a failed attempt', () async {
      final failDb = await createDbWithSnippetTrigger('poison-s1');
      final fTaskRepo = DriftTaskRepository(failDb);
      final fSnippetRepo = DriftSnippetRepository(failDb);
      final fLinkRepo = DriftTaskSnippetLinkRepository(failDb);
      final fService = PortabilityService(
        taskRepo: fTaskRepo,
        snippetRepo: fSnippetRepo,
        linkRepo: fLinkRepo,
        db: failDb,
      );

      // First import: will fail.
      final poisonExport = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [
          ExportTask(
            id: 't-fail',
            title: 'Will rollback',
            isCompleted: false,
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        snippets: [
          ExportSnippet(
            id: 'poison-s1',
            title: 'Poison',
            code: 'x',
            language: 'dart',
            createdAt: DateTime.utc(2025, 1, 1),
            updatedAt: DateTime.utc(2025, 1, 1),
          ),
        ],
        links: [],
      );

      expect(
        () => fService.importWorkspace(poisonExport),
        throwsA(isA<Exception>()),
      );

      // Second import: clean data, should succeed.
      final cleanExport = WorktraceExport(
        format: 'worktrace-export',
        version: 1,
        exportedAt: DateTime.now(),
        tasks: [
          ExportTask(
            id: 't-clean',
            title: 'Clean Import',
            isCompleted: false,
            createdAt: DateTime.utc(2025, 3, 1),
            updatedAt: DateTime.utc(2025, 3, 1),
          ),
        ],
        snippets: [
          ExportSnippet(
            id: 's-clean',
            title: 'Clean Snippet',
            code: 'print("ok");',
            language: 'dart',
            createdAt: DateTime.utc(2025, 3, 1),
            updatedAt: DateTime.utc(2025, 3, 1),
          ),
        ],
        links: [
          ExportLink(
            taskId: 't-clean',
            snippetId: 's-clean',
            linkedAt: DateTime.utc(2025, 3, 1),
          ),
        ],
      );

      final result = await fService.importWorkspace(cleanExport);
      expect(result.tasksImported, 1);
      expect(result.snippetsImported, 1);
      expect(result.linksImported, 1);

      // Verify clean data persisted.
      expect(await fTaskRepo.getTaskById('t-clean'), isNotNull);
      expect(await fSnippetRepo.getSnippetById('s-clean'), isNotNull);

      // Verify poison data was NOT persisted from the first attempt.
      expect(await fTaskRepo.getTaskById('t-fail'), isNull);

      await failDb.close();
    });
  });
}
