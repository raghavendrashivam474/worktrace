/// Domain model for a task-snippet association.
///
/// Plain Dart class — no dependency on Drift or Flutter.
/// Identity is the composite (taskId, snippetId) pair.
class TaskSnippetLink {
  /// The task this link belongs to.
  final String taskId;

  /// The snippet this link refers to.
  final String snippetId;

  /// When the association was created.
  final DateTime linkedAt;

  const TaskSnippetLink({
    required this.taskId,
    required this.snippetId,
    required this.linkedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskSnippetLink &&
          taskId == other.taskId &&
          snippetId == other.snippetId;

  @override
  int get hashCode => Object.hash(taskId, snippetId);

  @override
  String toString() =>
      'TaskSnippetLink(taskId: $taskId, snippetId: $snippetId)';
}
