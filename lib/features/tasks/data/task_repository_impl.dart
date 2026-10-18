import 'package:drift/drift.dart';

import '../../../core/data/app_database.dart';
import '../domain/task.dart';
import '../domain/task_repository.dart';

/// Drift-backed implementation of [TaskRepository].
///
/// Maps between domain [Task] objects and Drift [TaskRow] types.
/// No Drift types leak through the public interface.
class DriftTaskRepository implements TaskRepository {
  final AppDatabase _db;

  DriftTaskRepository(this._db);

  @override
  Future<List<Task>> getAllTasks() async {
    final rows = await (_db.select(
      _db.tasks,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<Task?> getTaskById(String id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> createTask(Task task) async {
    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: task.id,
            title: task.title,
            isCompleted: Value(task.isCompleted),
            createdAt: task.createdAt,
            updatedAt: task.updatedAt,
          ),
        );
  }

  @override
  Future<void> updateTask(Task task) async {
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        title: Value(task.title),
        isCompleted: Value(task.isCompleted),
        updatedAt: Value(task.updatedAt),
      ),
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    final query = _db.select(_db.tasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Task _toDomain(TaskRow row) {
    return Task(
      id: row.id,
      title: row.title,
      isCompleted: row.isCompleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
