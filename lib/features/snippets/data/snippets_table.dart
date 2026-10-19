import 'package:drift/drift.dart';

/// Drift table definition for snippets.
///
/// The generated data class is named [SnippetRow] to avoid
/// colliding with the domain [Snippet] model (DEC-012).
@DataClassName('SnippetRow')
class Snippets extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get code => text()();
  TextColumn get language => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
