import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worktrace/app/app.dart';
import 'package:worktrace/core/data/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = await openDatabase();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const WorktraceApp(),
    ),
  );
}
