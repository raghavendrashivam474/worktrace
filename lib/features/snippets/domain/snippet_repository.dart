import '../domain/snippet.dart';

/// Contract for snippet persistence operations.
///
/// Implementations must not expose database-specific types.
/// All methods return or accept domain [Snippet] objects only.
abstract class SnippetRepository {
  /// Returns all snippets, ordered by creation date descending (newest first).
  Future<List<Snippet>> getAllSnippets();

  /// Returns a single snippet by its [id], or null if not found.
  Future<Snippet?> getSnippetById(String id);

  /// Persists a new snippet. The caller is responsible for validation.
  Future<void> createSnippet(Snippet snippet);

  /// Overwrites an existing snippet with the same id.
  Future<void> updateSnippet(Snippet snippet);

  /// Deletes the snippet with the given [id]. No-op if not found.
  Future<void> deleteSnippet(String id);

  /// Emits the current snippet list whenever it changes.
  Stream<List<Snippet>> watchAllSnippets();
}
