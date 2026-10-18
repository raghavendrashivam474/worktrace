import 'package:flutter/material.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Placeholder screen for the Snippets module.
///
/// Snippet storage will be implemented in Phase 2.
class SnippetsScreen extends StatelessWidget {
  const SnippetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WtEmptyState(
      icon: Icons.code_rounded,
      title: 'Snippets',
      message: 'Snippet storage will be available in a future update.',
    );
  }
}
