/// Domain model for a Worktrace code snippet.
///
/// Plain Dart class (DEC-012) — no dependency on Drift, Flutter,
/// or any persistence framework.
class Snippet {
  /// Unique identifier (UUID v4). Immutable after creation.
  final String id;

  /// Human-readable snippet title. Trimmed, never empty.
  final String title;

  /// The code content. Trimmed, never empty.
  final String code;

  /// Programming language identifier (e.g. 'dart', 'python', 'sql').
  /// Trimmed, never empty.
  final String language;

  /// When the snippet was first created. Immutable after creation.
  final DateTime createdAt;

  /// When the snippet was last modified.
  final DateTime updatedAt;

  const Snippet({
    required this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new snippet with validated input.
  ///
  /// Throws [ArgumentError] if [title], [code], or [language]
  /// is empty or whitespace-only.
  factory Snippet.create({
    required String id,
    required String title,
    required String code,
    required String language,
    DateTime? createdAt,
  }) {
    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Snippet title must not be empty or whitespace-only.',
      );
    }

    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(
        code,
        'code',
        'Snippet code must not be empty or whitespace-only.',
      );
    }

    final normalizedLanguage = language.trim();
    if (normalizedLanguage.isEmpty) {
      throw ArgumentError.value(
        language,
        'language',
        'Snippet language must not be empty or whitespace-only.',
      );
    }

    final now = DateTime.now();
    return Snippet(
      id: id,
      title: normalizedTitle,
      code: normalizedCode,
      language: normalizedLanguage.toLowerCase(),
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  /// Returns a copy with updated fields.
  ///
  /// Preserves [id] and [createdAt]. Updates [updatedAt].
  /// Throws [ArgumentError] if any provided field is empty/whitespace.
  Snippet update({String? title, String? code, String? language}) {
    final newTitle = title != null ? title.trim() : this.title;
    if (newTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'Snippet title must not be empty or whitespace-only.',
      );
    }

    final newCode = code != null ? code.trim() : this.code;
    if (newCode.isEmpty) {
      throw ArgumentError.value(
        code,
        'code',
        'Snippet code must not be empty or whitespace-only.',
      );
    }

    final newLanguage = language != null ? language.trim() : this.language;
    if (newLanguage.isEmpty) {
      throw ArgumentError.value(
        language,
        'language',
        'Snippet language must not be empty or whitespace-only.',
      );
    }

    return Snippet(
      id: id,
      title: newTitle,
      code: newCode,
      language: newLanguage.toLowerCase(),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Snippet && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Snippet(id: $id, title: $title, language: $language)';
}
