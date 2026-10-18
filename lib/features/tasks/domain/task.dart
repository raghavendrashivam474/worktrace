/// Domain model for a Worktrace task.
///
/// This is a plain Dart class (DEC-012) — it has no dependency
/// on Drift, Flutter, or any persistence framework.
class Task {
  /// Unique identifier (UUID v4). Immutable after creation.
  final String id;

  /// Human-readable task title. Trimmed, never empty.
  final String title;

  /// Whether the task has been marked complete.
  final bool isCompleted;

  /// When the task was first created. Immutable after creation.
  final DateTime createdAt;

  /// When the task was last modified.
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new task with validated input.
  ///
  /// Throws [ArgumentError] if [title] is empty or whitespace-only.
  factory Task.create({
    required String id,
    required String title,
    DateTime? createdAt,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Task title must not be empty or whitespace-only.',
      );
    }

    final now = DateTime.now();
    return Task(
      id: id,
      title: normalizedTitle,
      isCompleted: false,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Returns a copy with the completion state toggled.
  Task toggleCompletion() {
    return Task(
      id: id,
      title: title,
      isCompleted: !isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a copy with an updated title.
  ///
  /// Throws [ArgumentError] if [newTitle] is empty or whitespace-only.
  Task updateTitle(String newTitle) {
    final normalized = newTitle.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        newTitle,
        'newTitle',
        'Task title must not be empty or whitespace-only.',
      );
    }

    return Task(
      id: id,
      title: normalized,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted)';
}
