import 'package:drift/drift.dart';

import '../../snippets/data/snippets_table.dart';
import '../../tasks/data/tasks_table.dart';

/// Drift table for task-snippet associations.
///
/// Uses a composite primary key (taskId, snippetId) to prevent
/// duplicate links. Foreign keys cascade on delete so that
/// removing a task or snippet automatically cleans up orphan links.
@DataClassName('TaskSnippetLinkRow')
class TaskSnippetLinks extends Table {
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  TextColumn get snippetId =>
      text().references(Snippets, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get linkedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {taskId, snippetId};
}
