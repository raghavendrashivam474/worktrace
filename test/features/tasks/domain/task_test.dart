import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/features/tasks/domain/task.dart';

void main() {
  group('Task.create', () {
    test('creates a task with valid title', () {
      final task = Task.create(id: 'test-1', title: '  Write tests  ');

      expect(task.id, 'test-1');
      expect(task.title, 'Write tests'); // trimmed
      expect(task.isCompleted, false);
      expect(task.createdAt, isNotNull);
      expect(task.updatedAt, isNotNull);
    });

    test('throws ArgumentError for empty title', () {
      expect(() => Task.create(id: 'test-2', title: ''), throwsArgumentError);
    });

    test('throws ArgumentError for whitespace-only title', () {
      expect(
        () => Task.create(id: 'test-3', title: '   '),
        throwsArgumentError,
      );
    });

    test('preserves provided createdAt', () {
      final fixedDate = DateTime(2026, 1, 15);
      final task = Task.create(
        id: 'test-4',
        title: 'Dated task',
        createdAt: fixedDate,
      );

      expect(task.createdAt, fixedDate);
    });
  });

  group('Task.toggleCompletion', () {
    test('toggles from incomplete to complete', () {
      final task = Task.create(id: 't1', title: 'Toggle me');
      final toggled = task.toggleCompletion();

      expect(toggled.isCompleted, true);
      expect(toggled.id, task.id);
      expect(toggled.title, task.title);
      expect(toggled.createdAt, task.createdAt);
    });

    test('toggles from complete back to incomplete', () {
      final task = Task.create(id: 't2', title: 'Toggle back');
      final toggled = task.toggleCompletion().toggleCompletion();

      expect(toggled.isCompleted, false);
    });
  });

  group('Task.updateTitle', () {
    test('updates title and preserves identity', () {
      final task = Task.create(id: 't3', title: 'Original');
      final updated = task.updateTitle('  Updated  ');

      expect(updated.id, task.id);
      expect(updated.title, 'Updated');
      expect(updated.createdAt, task.createdAt);
    });

    test('throws ArgumentError for empty new title', () {
      final task = Task.create(id: 't4', title: 'Valid');

      expect(() => task.updateTitle('   '), throwsArgumentError);
    });
  });

  group('Task equality', () {
    test('tasks with same id are equal', () {
      final a = Task.create(id: 'same', title: 'A');
      final b = Task.create(id: 'same', title: 'B');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('tasks with different ids are not equal', () {
      final a = Task.create(id: 'one', title: 'Same title');
      final b = Task.create(id: 'two', title: 'Same title');

      expect(a, isNot(equals(b)));
    });
  });
}
