import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worktrace/core/data/database_provider.dart';
import 'package:worktrace/features/links/data/task_snippet_link_repository_provider.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/tasks/data/task_repository_provider.dart';

import 'portability_service.dart';

/// Provides the [PortabilityService] wired to all repositories and the database.
final portabilityServiceProvider = Provider<PortabilityService>((ref) {
  return PortabilityService(
    taskRepo: ref.watch(taskRepositoryProvider),
    snippetRepo: ref.watch(snippetRepositoryProvider),
    linkRepo: ref.watch(taskSnippetLinkRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});
