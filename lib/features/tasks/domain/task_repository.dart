import '../domain/task.dart';

/// Contract for task persistence operations.
///
/// Implementations must not expose database-specific types.
/// All methods return or accept domain [Task] objects only.
abstract class TaskRepository {
  /// Returns all tasks, ordered by creation date descending (newest first).
  Future<List<Task>> getAllTasks();

  /// Returns a single task by its [id], or null if not found.
  Future<Task?> getTaskById(String id);

  /// Persists a new task. The caller is responsible for validation.
  Future<void> createTask(Task task);

  /// Overwrites an existing task with the same id.
  Future<void> updateTask(Task task);

  /// Deletes the task with the given [id]. No-op if not found.
  Future<void> deleteTask(String id);

  /// Emits the current task list whenever it changes.
  Stream<List<Task>> watchAllTasks();
}
