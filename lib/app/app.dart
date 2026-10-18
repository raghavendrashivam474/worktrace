import 'package:flutter/material.dart';
import 'package:worktrace/app/navigation/app_shell.dart';
import 'package:worktrace/app/theme/app_theme.dart';

/// Root Worktrace application widget.
///
/// Configures theming, localization, and the initial route.
/// State management (ProviderScope) is initialized in main.dart.
class WorktraceApp extends StatelessWidget {
  const WorktraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worktrace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
