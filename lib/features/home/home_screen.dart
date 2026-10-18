import 'package:flutter/material.dart';
import 'package:worktrace/app/theme/app_tokens.dart';

/// Home destination for the Worktrace application shell.
///
/// Displays the brand identity and a brief orientation hint.
/// Feature content will be added in later phases.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),

          // Brand logo
          Image.asset(
            'assets/images/WorkTrace.png',
            height: 80,
            width: 80,
            errorBuilder: (_, _, _) => Icon(
              Icons.route_rounded,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Tagline
          Text(
            'Keep your work traceable',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tasks, snippets, and continuity — all on your device.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Orientation hint
          Text(
            'Use the navigation below to explore your workspace.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Version footer
          Center(
            child: Text(
              'v0.1.0 — Foundation',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
