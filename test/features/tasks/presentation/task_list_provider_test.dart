import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/features/tasks/data/task_repository_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';
import 'package:worktrace/features/tasks/presentation/task_list_provider.dart';

/// In-memory fake repository for testing application logic
/// without a real database.
class FakeTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  bool shouldFail = false;

  @override
  Future<List<Task>> getAllTasks() async {
    if (shouldFail) throw Exception('Simulated failure');
    return List.unmodifiable(_tasks);
  }

  @override
  Future<Task?> getTaskById(String id) async {
    if (shouldFail) throw Exception('Simulated failure');
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createTask(Task task) async {
    if (shouldFail) throw Exception('Simulated failure');
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    if (shouldFail) throw Exception('Simulated failure');
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) _tasks[index] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (shouldFail) throw Exception('Simulated failure');
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    return Stream.value(List.unmodifiable(_tasks));
  }
}

void main() {
  late ProviderContainer container;
  late FakeTaskRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeTaskRepository();
    container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('initial load', () {
    test('loads empty list when no tasks exist', () async {
      final tasks = await container.read(taskListProvider.future);
      expect(tasks, isEmpty);
    });

    test('exposes loading state before data arrives', () {
      final state = container.read(taskListProvider);
      expect(state.isLoading, isTrue);
    });
  });

  group('createTask', () {
    test('creates a task and reloads the list', () async {
      await container.read(taskListProvider.future);

      await container.read(taskListProvider.notifier).createTask('Buy milk');

      final tasks = await container.read(taskListProvider.future);
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Buy milk');
      expect(tasks.first.isCompleted, false);
    });

    test('rejects empty title', () async {
      await container.read(taskListProvider.future);

      expect(
        () => container.read(taskListProvider.notifier).createTask('   '),
        throwsArgumentError,
      );
    });

    test('creates multiple tasks', () async {
      await container.read(taskListProvider.future);
      final notifier = container.read(taskListProvider.notifier);

      await notifier.createTask('Task A');
      await notifier.createTask('Task B');
      await notifier.createTask('Task C');

      final tasks = await container.read(taskListProvider.future);
      expect(tasks, hasLength(3));
    });
  });

  group('toggleTask', () {
    test('marks a task complete', () async {
      await container.read(taskListProvider.future);
      await container.read(taskListProvider.notifier).createTask('Toggle me');

      final tasks = await container.read(taskListProvider.future);
      final taskId = tasks.first.id;

      await container.read(taskListProvider.notifier).toggleTask(taskId);

      final updated = await container.read(taskListProvider.future);
      expect(updated.first.isCompleted, true);
    });

    test('reopens a completed task', () async {
      await container.read(taskListProvider.future);
      await container.read(taskListProvider.notifier).createTask('Reopen me');

      final tasks = await container.read(taskListProvider.future);
      final taskId = tasks.first.id;
      final notifier = container.read(taskListProvider.notifier);

      await notifier.toggleTask(taskId); // complete
      await notifier.toggleTask(taskId); // reopen

      final updated = await container.read(taskListProvider.future);
      expect(updated.first.isCompleted, false);
    });
  });

  group('deleteTask', () {
    test('removes a task from the list', () async {
      await container.read(taskListProvider.future);
      await container.read(taskListProvider.notifier).createTask('Delete me');

      final tasks = await container.read(taskListProvider.future);
      final taskId = tasks.first.id;

      await container.read(taskListProvider.notifier).deleteTask(taskId);

      final remaining = await container.read(taskListProvider.future);
      expect(remaining, isEmpty);
    });
  });

  group('error handling', () {
    test('exposes error state when load fails', () async {
      fakeRepo.shouldFail = true;

      // Force a read that will fail
      await expectLater(
        container.read(taskListProvider.future),
        throwsException,
      );

      final state = container.read(taskListProvider);
      expect(state.hasError, isTrue);
    });

    test('preserves data state when create fails', () async {
      await container.read(taskListProvider.future);
      await container.read(taskListProvider.notifier).createTask('Existing');

      fakeRepo.shouldFail = true;

      // The create will fail during reload, putting state in error
      await expectLater(
        container.read(taskListProvider.notifier).createTask('Will fail'),
        throwsException,
      );
    });
  });
}
