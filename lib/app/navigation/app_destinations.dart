import 'package:flutter/material.dart';

/// Identifies each top-level destination in the Worktrace shell.
enum AppDestination { home, tasks, snippets }

/// Metadata for a single Worktrace navigation destination.
class WorktraceDestination {
  const WorktraceDestination({
    required this.destination,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final AppDestination destination;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// The ordered list of destinations shown in the application shell.
const List<WorktraceDestination> appDestinations = [
  WorktraceDestination(
    destination: AppDestination.home,
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  WorktraceDestination(
    destination: AppDestination.tasks,
    label: 'Tasks',
    icon: Icons.checklist_outlined,
    selectedIcon: Icons.checklist_rounded,
  ),
  WorktraceDestination(
    destination: AppDestination.snippets,
    label: 'Snippets',
    icon: Icons.code_outlined,
    selectedIcon: Icons.code_rounded,
  ),
];
