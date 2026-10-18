import 'package:flutter/material.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Placeholder screen for the Tasks module.
///
/// Task management will be implemented in Phase 1.
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WtEmptyState(
      icon: Icons.checklist_rounded,
      title: 'Tasks',
      message: 'Task management will be available in a future update.',
    );
  }
}
