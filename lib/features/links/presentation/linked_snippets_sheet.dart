import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/features/links/presentation/task_links_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/presentation/snippet_list_provider.dart';

/// Bottom sheet for managing snippets linked to a specific task.
///
/// Shows currently linked snippets with unlink buttons, and an
/// attach action that lets the user pick from all available snippets.
class LinkedSnippetsSheet extends ConsumerWidget {
  const LinkedSnippetsSheet({required this.taskId, super.key});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(taskLinksProvider(taskId));
    final snippetsAsync = ref.watch(snippetListProvider);
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Linked Snippets',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  snippetsAsync.whenOrNull(
                        data: (snippets) => linksAsync.whenOrNull(
                          data: (links) {
                            final linkedIds = links
                                .map((l) => l.snippetId)
                                .toSet();
                            final available = snippets
                                .where((s) => !linkedIds.contains(s.id))
                                .toList();
                            if (available.isEmpty) return const SizedBox();
                            return FilledButton.icon(
                              onPressed: () =>
                                  _showAttachPicker(context, ref, available),
                              icon: const Icon(
                                Icons.add_link_rounded,
                                size: 18,
                              ),
                              label: const Text('Attach'),
                            );
                          },
                        ),
                      ) ??
                      const SizedBox(),
                ],
              ),
            ),
            const Divider(),
            // Content
            Expanded(
              child: linksAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load links.'),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(taskLinksProvider(taskId)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (links) {
                  if (links.isEmpty) {
                    return Center(
                      child: Text(
                        'No snippets linked yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  // Resolve linked snippet details from the snippet list.
                  final allSnippets = snippetsAsync.valueOrNull ?? [];
                  final snippetMap = {for (final s in allSnippets) s.id: s};

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      final snippet = snippetMap[link.snippetId];

                      return ListTile(
                        leading: Icon(
                          Icons.code_rounded,
                          color: theme.colorScheme.secondary,
                        ),
                        title: Text(
                          snippet?.title ?? 'Unknown snippet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: snippet != null
                            ? Text(snippet.language)
                            : Text(
                                'Snippet no longer exists',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                        trailing: IconButton(
                          icon: const Icon(Icons.link_off_rounded),
                          tooltip: 'Unlink',
                          onPressed: () =>
                              _detach(context, ref, link.snippetId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _detach(
    BuildContext context,
    WidgetRef ref,
    String snippetId,
  ) async {
    try {
      await ref
          .read(taskLinksProvider(taskId).notifier)
          .detachSnippet(snippetId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlink snippet.')),
        );
      }
    }
  }

  Future<void> _showAttachPicker(
    BuildContext context,
    WidgetRef ref,
    List<Snippet> available,
  ) async {
    final selected = await showModalBottomSheet<Snippet>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Select a snippet to link',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              const Divider(height: 1),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (ctx, i) {
                    final s = available[i];
                    return ListTile(
                      leading: const Icon(Icons.code_rounded),
                      title: Text(s.title),
                      subtitle: Text(s.language),
                      onTap: () => Navigator.of(ctx).pop(s),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && context.mounted) {
      try {
        final created = await ref
            .read(taskLinksProvider(taskId).notifier)
            .attachSnippet(selected.id);
        if (!created && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Snippet is already linked.')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to link snippet.')),
          );
        }
      }
    }
  }
}

/// Opens the linked snippets sheet for the given task.
void showLinkedSnippetsSheet(BuildContext context, String taskId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => LinkedSnippetsSheet(taskId: taskId),
  );
}
