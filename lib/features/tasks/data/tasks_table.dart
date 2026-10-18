import 'package:drift/drift.dart';

/// Drift table definition for tasks.
///
/// The generated data class is named [TaskRow] to avoid
/// colliding with the domain [Task] model (DEC-012).
@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
