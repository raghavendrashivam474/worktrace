import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:worktrace/core/data/app_database.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_impl.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';

void main() {
  late AppDatabase db;
  late SnippetRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = DriftSnippetRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('getAllSnippets', () {
    test('returns empty list when no snippets exist', () async {
      final snippets = await repo.getAllSnippets();
      expect(snippets, isEmpty);
    });

    test('returns all created snippets', () async {
      final s1 = Snippet.create(
        id: '1',
        title: 'First',
        code: 'code1',
        language: 'dart',
      );
      final s2 = Snippet.create(
        id: '2',
        title: 'Second',
        code: 'code2',
        language: 'python',
      );
      await repo.createSnippet(s1);
      await repo.createSnippet(s2);

      final snippets = await repo.getAllSnippets();
      expect(snippets, hasLength(2));
    });

    test('orders by createdAt descending (newest first)', () async {
      final old = Snippet.create(
        id: 'old',
        title: 'Old',
        code: 'old()',
        language: 'dart',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final newer = Snippet.create(
        id: 'new',
        title: 'New',
        code: 'new()',
        language: 'dart',
        createdAt: DateTime.utc(2026, 6, 1),
      );
      await repo.createSnippet(old);
      await repo.createSnippet(newer);

      final snippets = await repo.getAllSnippets();
      expect(snippets.first.id, 'new');
      expect(snippets.last.id, 'old');
    });
  });

  group('getSnippetById', () {
    test('returns snippet when found', () async {
      final snippet = Snippet.create(
        id: 'find-me',
        title: 'Findable',
        code: 'code',
        language: 'dart',
      );
      await repo.createSnippet(snippet);

      final found = await repo.getSnippetById('find-me');
      expect(found, isNotNull);
      expect(found!.title, 'Findable');
      expect(found.code, 'code');
      expect(found.language, 'dart');
    });

    test('returns null when not found', () async {
      final found = await repo.getSnippetById('nonexistent');
      expect(found, isNull);
    });
  });

  group('createSnippet', () {
    test('persists a snippet that can be retrieved', () async {
      final snippet = Snippet.create(
        id: 'c1',
        title: 'Created',
        code: 'print("hi")',
        language: 'dart',
      );
      await repo.createSnippet(snippet);

      final retrieved = await repo.getSnippetById('c1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'c1');
      expect(retrieved.title, 'Created');
      expect(retrieved.code, 'print("hi")');
      expect(retrieved.language, 'dart');
    });
  });

  group('updateSnippet', () {
    test('updates title and preserves createdAt', () async {
      final fixedDate = DateTime(2026, 6, 15, 12, 0, 0);
      final snippet = Snippet.create(
        id: 'u1',
        title: 'Original',
        code: 'code',
        language: 'dart',
        createdAt: fixedDate,
      );
      await repo.createSnippet(snippet);

      final updated = snippet.update(title: 'Updated');
      await repo.updateSnippet(updated);

      final retrieved = await repo.getSnippetById('u1');
      expect(retrieved!.title, 'Updated');
      expect(retrieved.createdAt, fixedDate);
    });

    test('updates code content', () async {
      final snippet = Snippet.create(
        id: 'u2',
        title: 'Test',
        code: 'old code',
        language: 'python',
      );
      await repo.createSnippet(snippet);

      final updated = snippet.update(code: 'new code');
      await repo.updateSnippet(updated);

      final retrieved = await repo.getSnippetById('u2');
      expect(retrieved!.code, 'new code');
    });

    test('updates language', () async {
      final snippet = Snippet.create(
        id: 'u3',
        title: 'Test',
        code: 'code',
        language: 'dart',
      );
      await repo.createSnippet(snippet);

      final updated = snippet.update(language: 'kotlin');
      await repo.updateSnippet(updated);

      final retrieved = await repo.getSnippetById('u3');
      expect(retrieved!.language, 'kotlin');
    });
  });

  group('deleteSnippet', () {
    test('removes a snippet', () async {
      final snippet = Snippet.create(
        id: 'd1',
        title: 'Delete me',
        code: 'code',
        language: 'dart',
      );
      await repo.createSnippet(snippet);
      await repo.deleteSnippet('d1');

      final found = await repo.getSnippetById('d1');
      expect(found, isNull);
    });

    test('does not throw when deleting nonexistent snippet', () async {
      expect(() => repo.deleteSnippet('ghost'), returnsNormally);
    });
  });

  group('watchAllSnippets', () {
    test('emits updated list after creation', () async {
      final emissions = <List<Snippet>>[];
      final sub = repo.watchAllSnippets().listen(emissions.add);

      await Future.delayed(const Duration(milliseconds: 100));

      final snippet = Snippet.create(
        id: 'w1',
        title: 'Watched',
        code: 'code',
        language: 'dart',
      );
      await repo.createSnippet(snippet);

      await Future.delayed(const Duration(milliseconds: 100));

      expect(emissions.last, hasLength(1));
      expect(emissions.last.first.title, 'Watched');

      await sub.cancel();
    });
  });

  group('persistence across reconnection', () {
    test('data survives closing and reopening the database', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      addTearDown(
        () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = false,
      );

      final tempDir = await Directory.systemTemp.createTemp(
        'worktrace_snippet_test_',
      );
      final dbPath = p.join(tempDir.path, 'reconnect.db');

      final db1 = AppDatabase(NativeDatabase(File(dbPath)));
      final repo1 = DriftSnippetRepository(db1);
      final snippet = Snippet.create(
        id: 'persist-1',
        title: 'Survive reconnect',
        code: 'code',
        language: 'dart',
      );
      await repo1.createSnippet(snippet);
      await db1.close();

      final db2 = AppDatabase(NativeDatabase(File(dbPath)));
      final repo2 = DriftSnippetRepository(db2);
      final snippets = await repo2.getAllSnippets();

      expect(snippets, hasLength(1));
      expect(snippets.first.id, 'persist-1');
      expect(snippets.first.title, 'Survive reconnect');

      await db2.close();
      await tempDir.delete(recursive: true);
    });
  });
}
