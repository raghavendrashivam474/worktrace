import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worktrace/app/navigation/navigation_provider.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/presentation/snippet_list_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/portability/presentation/portability_section.dart';
import 'package:worktrace/features/tasks/presentation/task_list_provider.dart';

/// Unified workspace home screen.
///
/// Composes previews of existing Tasks and Snippets using the
/// same providers as the full feature screens. Each section
/// loads and fails independently — a Task failure does not
/// suppress successfully loaded Snippets, and vice versa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WorkspaceHeader(),
          SizedBox(height: AppSpacing.lg),
          _QuickActions(),
          SizedBox(height: AppSpacing.xl),
          _ActiveTasksSection(),
          SizedBox(height: AppSpacing.xl),
          _RecentSnippetsSection(),
          SizedBox(height: AppSpacing.xl),
          PortabilitySection(),
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A. Workspace header
// ---------------------------------------------------------------------------

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workspace', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Your tasks and snippets at a glance.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// B. Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  void _goToTab(WidgetRef ref, int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            FilledButton.icon(
              onPressed: () => _goToTab(ref, 1),
              icon: const Icon(Icons.add_task_rounded, size: 18),
              label: const Text('New Task'),
            ),
            FilledButton.icon(
              onPressed: () => _goToTab(ref, 2),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Snippet'),
            ),
            OutlinedButton.icon(
              onPressed: () => _goToTab(ref, 1),
              icon: const Icon(Icons.checklist_rounded, size: 18),
              label: const Text('All Tasks'),
            ),
            OutlinedButton.icon(
              onPressed: () => _goToTab(ref, 2),
              icon: const Icon(Icons.code_rounded, size: 18),
              label: const Text('All Snippets'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// C. Active tasks preview
// ---------------------------------------------------------------------------

/// Maximum number of items shown in each preview section.
const int _previewLimit = 5;

class _ActiveTasksSection extends ConsumerWidget {
  const _ActiveTasksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Active Tasks',
      onViewAll: () => ref.read(navigationIndexProvider.notifier).state = 1,
      child: taskState.when(
        loading: () => const _SectionLoading(),
        error: (error, _) => _SectionError(
          message: 'Could not load tasks.',
          onRetry: () => ref.invalidate(taskListProvider),
        ),
        data: (tasks) {
          final active = tasks
              .where((t) => !t.isCompleted)
              .take(_previewLimit)
              .toList();

          if (active.isEmpty) {
            return _SectionEmpty(
              icon: Icons.check_circle_outline_rounded,
              message: tasks.isEmpty
                  ? 'No tasks yet. Create one to get started.'
                  : 'All tasks are completed!',
            );
          }

          return Column(
            children: [
              ...active.map((t) => _TaskPreviewTile(task: t)),
              if (tasks.where((t) => !t.isCompleted).length > _previewLimit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '+ ${tasks.where((t) => !t.isCompleted).length - _previewLimit} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _TaskPreviewTile extends StatelessWidget {
  const _TaskPreviewTile({required this.task});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.radio_button_unchecked_rounded,
        color: theme.colorScheme.primary,
        size: 20,
      ),
      title: Text(
        task.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// D. Recent snippets preview
// ---------------------------------------------------------------------------

class _RecentSnippetsSection extends ConsumerWidget {
  const _RecentSnippetsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippetState = ref.watch(snippetListProvider);
    final theme = Theme.of(context);

    return _SectionCard(
      title: 'Recent Snippets',
      onViewAll: () => ref.read(navigationIndexProvider.notifier).state = 2,
      child: snippetState.when(
        loading: () => const _SectionLoading(),
        error: (error, _) => _SectionError(
          message: 'Could not load snippets.',
          onRetry: () => ref.invalidate(snippetListProvider),
        ),
        data: (snippets) {
          if (snippets.isEmpty) {
            return const _SectionEmpty(
              icon: Icons.code_outlined,
              message: 'No snippets yet. Create one to get started.',
            );
          }

          // Sort by updatedAt descending at presentation level.
          final recent = snippets.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final preview = recent.take(_previewLimit).toList();

          return Column(
            children: [
              ...preview.map((s) => _SnippetPreviewTile(snippet: s)),
              if (snippets.length > _previewLimit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    '+ ${snippets.length - _previewLimit} more',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SnippetPreviewTile extends StatelessWidget {
  const _SnippetPreviewTile({required this.snippet});
  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.code_rounded,
        color: theme.colorScheme.secondary,
        size: 20,
      ),
      title: Text(
        snippet.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          snippet.language,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// E. Shared section chrome
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.onViewAll,
  });

  final String title;
  final Widget child;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                if (onViewAll != null)
                  TextButton(
                    onPressed: onViewAll,
                    child: const Text('View all'),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            child,
          ],
        ),
      ),
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(child: CircularProgressIndicator.adaptive()),
    );
  }
}

class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
