import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_provider.dart';
import '../domain/task_snippet_link_repository.dart';
import 'task_snippet_link_repository_impl.dart';

/// Provides the [TaskSnippetLinkRepository] backed by the application database.
final taskSnippetLinkRepositoryProvider = Provider<TaskSnippetLinkRepository>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  return DriftTaskSnippetLinkRepository(db);
});
