import 'package:flutter/material.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Main Worktrace application shell.
///
/// Displays the brand identity, logo, and placeholder destinations
/// for the future Task Workspace and Snippet Library features.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/WorkTrace.png',
              height: 28,
              width: 28,
              errorBuilder: (_, _, _) =>
                  Icon(Icons.route_rounded, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Worktrace', style: theme.textTheme.titleLarge),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€ Hero section â”€â”€
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
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
                    Text(
                      'Keep your work traceable',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Tasks, snippets, and continuity - all on your device.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // â”€â”€ Feature cards â”€â”€
              Text(
                'Workspace',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              WtCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tasks', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Track small units of development work',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text('Soon', style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              WtCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      color: AppColors.secondary,
                      size: 32,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Snippets', style: theme.textTheme.titleMedium),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Save and retrieve reusable code',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text('Soon', style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // â”€â”€ Footer hint â”€â”€
              Center(
                child: Text(
                  'v0.1.0 - Foundation',
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
        ),
      ),
    );
  }
}
