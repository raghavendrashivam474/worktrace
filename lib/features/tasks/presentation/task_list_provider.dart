import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository_provider.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Reactive task list state backed by [TaskRepository].
///
/// Exposes loading, data, and error states through [AsyncValue].
/// All mutations reload the list from the repository to ensure
/// consistency with persisted data.
final taskListProvider = AsyncNotifierProvider<TaskListNotifier, List<Task>>(
  TaskListNotifier.new,
);

class TaskListNotifier extends AsyncNotifier<List<Task>> {
  TaskRepository get _repo => ref.read(taskRepositoryProvider);

  @override
  Future<List<Task>> build() async {
    return _repo.getAllTasks();
  }

  /// Creates a new task with the given [title].
  ///
  /// Throws [ArgumentError] if the title is invalid (empty/whitespace).
  /// Reloads the task list after successful persistence.
  Future<void> createTask(String title) async {
    final task = Task.create(id: const Uuid().v4(), title: title);
    await _repo.createTask(task);
    await _reload();
  }

  /// Toggles the completion state of the task with the given [id].
  Future<void> toggleTask(String id) async {
    final tasks = state.valueOrNull ?? [];
    final task = tasks.firstWhere((t) => t.id == id);
    final toggled = task.toggleCompletion();
    await _repo.updateTask(toggled);
    await _reload();
  }

  /// Deletes the task with the given [id].
  Future<void> deleteTask(String id) async {
    await _repo.deleteTask(id);
    await _reload();
  }

  /// Reloads the task list from the repository.
  Future<void> _reload() async {
    state = await AsyncValue.guard(() => _repo.getAllTasks());
  }
}
