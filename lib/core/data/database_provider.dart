import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

/// Provides the application-wide [AppDatabase] instance.
///
/// Must be overridden in [ProviderScope] after async initialization.
/// Throws if accessed before initialization — this catches wiring bugs early.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'databaseProvider must be overridden in ProviderScope. '
    'Call openDatabase() in main() and pass via overrideWithValue.',
  );
});

/// Opens the production database file in the app documents directory.
///
/// Call once during startup, before [runApp].
Future<AppDatabase> openDatabase() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, 'worktrace.db'));
  return AppDatabase(NativeDatabase(file));
}
