import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/snippet_repository_provider.dart';
import '../domain/snippet.dart';
import '../domain/snippet_repository.dart';

/// Reactive snippet list state backed by [SnippetRepository].
///
/// Exposes loading, data, and error states through [AsyncValue].
/// All mutations reload the list from the repository to ensure
/// consistency with persisted data.
final snippetListProvider =
    AsyncNotifierProvider<SnippetListNotifier, List<Snippet>>(
      SnippetListNotifier.new,
    );

class SnippetListNotifier extends AsyncNotifier<List<Snippet>> {
  SnippetRepository get _repo => ref.read(snippetRepositoryProvider);

  @override
  Future<List<Snippet>> build() async {
    return _repo.getAllSnippets();
  }

  /// Creates a new snippet.
  ///
  /// Throws [ArgumentError] if any field is invalid.
  /// Reloads the snippet list after successful persistence.
  Future<void> createSnippet({
    required String title,
    required String code,
    required String language,
  }) async {
    final snippet = Snippet.create(
      id: const Uuid().v4(),
      title: title,
      code: code,
      language: language,
    );
    await _repo.createSnippet(snippet);
    await _reload();
  }

  /// Updates an existing snippet.
  ///
  /// Throws [ArgumentError] if any field is invalid.
  /// Throws [StateError] if no snippet with [id] exists.
  /// Reloads the snippet list after successful persistence.
  Future<void> editSnippet(
    String id, {
    String? title,
    String? code,
    String? language,
  }) async {
    final snippets = state.valueOrNull ?? [];
    final snippet = snippets.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Snippet not found: $id'),
    );
    final updated = snippet.update(
      title: title,
      code: code,
      language: language,
    );
    await _repo.updateSnippet(updated);
    await _reload();
  }

  /// Deletes the snippet with the given [id].
  Future<void> deleteSnippet(String id) async {
    await _repo.deleteSnippet(id);
    await _reload();
  }

  /// Reloads the snippet list from the repository.
  Future<void> _reload() async {
    state = await AsyncValue.guard(() => _repo.getAllSnippets());
  }
}
