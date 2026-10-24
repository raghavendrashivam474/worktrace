import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/task_snippet_link_repository_provider.dart';
import '../domain/task_snippet_link.dart';
import '../domain/task_snippet_link_repository.dart';

/// Provides the list of snippet IDs linked to a specific task.
///
/// Family provider keyed by taskId. Invalidates when mutations occur.
final taskLinksProvider =
    AsyncNotifierProviderFamily<
      TaskLinksNotifier,
      List<TaskSnippetLink>,
      String
    >(TaskLinksNotifier.new);

class TaskLinksNotifier
    extends FamilyAsyncNotifier<List<TaskSnippetLink>, String> {
  TaskSnippetLinkRepository get _repo =>
      ref.read(taskSnippetLinkRepositoryProvider);

  @override
  Future<List<TaskSnippetLink>> build(String taskId) async {
    return _repo.getByTask(taskId);
  }

  /// Attaches a snippet to this task.
  ///
  /// Returns `true` if a new link was created, `false` if it already existed.
  Future<bool> attachSnippet(String snippetId) async {
    final created = await _repo.attach(arg, snippetId);
    if (created) await _reload();
    return created;
  }

  /// Detaches a snippet from this task.
  ///
  /// Does NOT delete the snippet. Returns `true` if a link was removed.
  Future<bool> detachSnippet(String snippetId) async {
    final removed = await _repo.detach(arg, snippetId);
    if (removed) await _reload();
    return removed;
  }

  Future<void> _reload() async {
    state = await AsyncValue.guard(() => _repo.getByTask(arg));
  }
}
