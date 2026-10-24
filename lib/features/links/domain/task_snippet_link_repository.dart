import 'task_snippet_link.dart';

/// Contract for task-snippet association persistence.
///
/// Implementations must not expose database-specific types.
/// All methods return or accept domain [TaskSnippetLink] objects only.
abstract class TaskSnippetLinkRepository {
  /// Creates a link between a task and a snippet.
  ///
  /// Returns `true` if the link was created, `false` if it already existed.
  /// Throws [ArgumentError] if [taskId] or [snippetId] is empty.
  Future<bool> attach(String taskId, String snippetId);

  /// Removes the link between a task and a snippet.
  ///
  /// Does NOT delete the task or snippet. Returns `true` if a link
  /// was removed, `false` if no link existed.
  Future<bool> detach(String taskId, String snippetId);

  /// Returns all snippet IDs linked to the given task.
  Future<List<TaskSnippetLink>> getByTask(String taskId);

  /// Returns all task IDs linked to the given snippet.
  Future<List<TaskSnippetLink>> getBySnippet(String snippetId);
}
