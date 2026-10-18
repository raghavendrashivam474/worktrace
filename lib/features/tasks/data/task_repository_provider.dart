import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_provider.dart';
import '../domain/task_repository.dart';
import 'task_repository_impl.dart';

/// Provides the [TaskRepository] backed by the application database.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftTaskRepository(db);
});
