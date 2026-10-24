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

  group('Import', () {
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
      );

      final result = await freshService.importWorkspace(export);
      expect(result.tasksImported, 1);
      expect(result.snippetsImported, 1);
      expect(result.errors, isEmpty, reason: 'Import errors: {result.errors}');
      expect(result.linksImported, 1);
      expect(result.totalSkipped, 0);

      await freshDb.close();
    });

    test('skips duplicate tasks and snippets', () async {
      await taskRepo.createTask(makeTask('t1'));
      await snippetRepo.createSnippet(makeSnippet('s1'));
      final json = await service.exportWorkspace();
      final export = service.validateExport(json);

      // Import into the same database (all records already exist).
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
  });
}
