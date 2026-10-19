import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_provider.dart';
import '../domain/snippet_repository.dart';
import 'snippet_repository_impl.dart';

/// Provides the [SnippetRepository] backed by the application database.
final snippetRepositoryProvider = Provider<SnippetRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftSnippetRepository(db);
});
