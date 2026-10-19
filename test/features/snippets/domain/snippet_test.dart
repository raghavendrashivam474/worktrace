import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';

void main() {
  group('Snippet.create', () {
    test('creates a snippet with valid fields', () {
      final snippet = Snippet.create(
        id: 's1',
        title: '  Hello World  ',
        code: '  print("hi");  ',
        language: '  Dart  ',
      );

      expect(snippet.id, 's1');
      expect(snippet.title, 'Hello World');
      expect(snippet.code, 'print("hi");');
      expect(snippet.language, 'dart'); // lowercased
      expect(snippet.createdAt, isNotNull);
      expect(snippet.updatedAt, isNotNull);
    });

    test('throws ArgumentError for empty title', () {
      expect(
        () =>
            Snippet.create(id: 's2', title: '', code: 'code', language: 'dart'),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for whitespace-only title', () {
      expect(
        () => Snippet.create(
          id: 's3',
          title: '   ',
          code: 'code',
          language: 'dart',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty code', () {
      expect(
        () => Snippet.create(
          id: 's4',
          title: 'Title',
          code: '',
          language: 'dart',
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for empty language', () {
      expect(
        () => Snippet.create(
          id: 's5',
          title: 'Title',
          code: 'code',
          language: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('preserves provided createdAt', () {
      final fixedDate = DateTime(2026, 3, 15);
      final snippet = Snippet.create(
        id: 's6',
        title: 'Dated',
        code: 'code',
        language: 'dart',
        createdAt: fixedDate,
      );

      expect(snippet.createdAt, fixedDate);
    });

    test('normalizes language to lowercase', () {
      final snippet = Snippet.create(
        id: 's7',
        title: 'Test',
        code: 'SELECT 1',
        language: 'SQL',
      );

      expect(snippet.language, 'sql');
    });
  });

  group('Snippet.update', () {
    test('updates title and preserves identity', () {
      final original = Snippet.create(
        id: 'u1',
        title: 'Original',
        code: 'code',
        language: 'dart',
      );
      final updated = original.update(title: '  Updated  ');

      expect(updated.id, original.id);
      expect(updated.title, 'Updated');
      expect(updated.code, original.code);
      expect(updated.language, original.language);
      expect(updated.createdAt, original.createdAt);
    });

    test('updates code content', () {
      final original = Snippet.create(
        id: 'u2',
        title: 'Test',
        code: 'old code',
        language: 'python',
      );
      final updated = original.update(code: 'new code');

      expect(updated.code, 'new code');
      expect(updated.title, original.title);
    });

    test('updates language', () {
      final original = Snippet.create(
        id: 'u3',
        title: 'Test',
        code: 'code',
        language: 'dart',
      );
      final updated = original.update(language: 'Kotlin');

      expect(updated.language, 'kotlin');
    });

    test('preserves createdAt through update', () {
      final fixedDate = DateTime(2026, 1, 1);
      final original = Snippet.create(
        id: 'u4',
        title: 'Dated',
        code: 'code',
        language: 'dart',
        createdAt: fixedDate,
      );
      final updated = original.update(title: 'Renamed');

      expect(updated.createdAt, fixedDate);
    });

    test('throws ArgumentError for empty new title', () {
      final original = Snippet.create(
        id: 'u5',
        title: 'Valid',
        code: 'code',
        language: 'dart',
      );

      expect(() => original.update(title: '   '), throwsArgumentError);
    });

    test('throws ArgumentError for empty new code', () {
      final original = Snippet.create(
        id: 'u6',
        title: 'Valid',
        code: 'code',
        language: 'dart',
      );

      expect(() => original.update(code: ''), throwsArgumentError);
    });
  });

  group('Snippet equality', () {
    test('snippets with same id are equal', () {
      final a = Snippet.create(
        id: 'same',
        title: 'A',
        code: 'code',
        language: 'dart',
      );
      final b = Snippet.create(
        id: 'same',
        title: 'B',
        code: 'other',
        language: 'python',
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('snippets with different ids are not equal', () {
      final a = Snippet.create(
        id: 'one',
        title: 'Same',
        code: 'code',
        language: 'dart',
      );
      final b = Snippet.create(
        id: 'two',
        title: 'Same',
        code: 'code',
        language: 'dart',
      );

      expect(a, isNot(equals(b)));
    });
  });
}
