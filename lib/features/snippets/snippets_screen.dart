import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/snippet.dart';
import 'presentation/snippet_list_provider.dart';
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/shared/widgets/wt_primitives.dart';

/// Sort order for the snippet list.
enum SnippetSort { recentlyUpdated, recentlyCreated, titleAZ }

/// Snippet workspace screen with search, language filtering, and sorting.
///
/// Displays the user's code snippets with create, view, edit, delete,
/// search, filter, and sort interactions. Backed by [snippetListProvider].
class SnippetsScreen extends ConsumerStatefulWidget {
  const SnippetsScreen({super.key});

  @override
  ConsumerState<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends ConsumerState<SnippetsScreen> {
  final _searchController = TextEditingController();
  String? _languageFilter;
  SnippetSort _sort = SnippetSort.recentlyUpdated;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snippetsAsync = ref.watch(snippetListProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        tooltip: 'Create snippet',
        child: const Icon(Icons.add),
      ),
      body: snippetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            _ErrorState(onRetry: () => ref.invalidate(snippetListProvider)),
        data: (snippets) {
          if (snippets.isEmpty) {
            return const WtEmptyState(
              icon: Icons.code_rounded,
              title: 'No snippets yet',
              message: 'Tap the + button to save your first code snippet.',
            );
          }

          // Derive available languages from the full collection
          final languages = snippets.map((s) => s.language).toSet().toList()
            ..sort();

          // Apply search, filter, sort pipeline
          final query = _searchController.text.trim().toLowerCase();
          final filtered = _applySearchAndFilter(snippets, query);
          final sorted = _applySort(filtered);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search snippets...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Language filter + Sort row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    PopupMenuButton<String?>(
                      tooltip: 'Filter by language',
                      onSelected: (v) => setState(() => _languageFilter = v),
                      child: Chip(
                        avatar: const Icon(Icons.filter_list, size: 18),
                        label: Text(_languageFilter ?? 'All languages'),
                        visualDensity: VisualDensity.compact,
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('All languages'),
                        ),
                        ...languages.map(
                          (lang) =>
                              PopupMenuItem(value: lang, child: Text(lang)),
                        ),
                      ],
                    ),
                    const Spacer(),
                    PopupMenuButton<SnippetSort>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort snippets',
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: SnippetSort.recentlyUpdated,
                          child: Text('Recently updated'),
                        ),
                        PopupMenuItem(
                          value: SnippetSort.recentlyCreated,
                          child: Text('Recently created'),
                        ),
                        PopupMenuItem(
                          value: SnippetSort.titleAZ,
                          child: Text('Title A-Z'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Active filters indicator
              if (query.isNotEmpty || _languageFilter != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${sorted.length} of ${snippets.length}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _languageFilter = null);
                        },
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                ),
              // Snippet list or no-match state
              Expanded(
                child: sorted.isEmpty
                    ? const WtEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching snippets',
                        message: 'Try adjusting your search or filters.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        itemBuilder: (context, index) {
                          final snippet = sorted[index];
                          return _SnippetListItem(
                            snippet: snippet,
                            onTap: () => _showDetailDialog(context, snippet),
                            onEdit: () => _showEditDialog(context, snippet),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // -- Search & Filter ------------------------------------------------

  List<Snippet> _applySearchAndFilter(List<Snippet> snippets, String query) {
    var result = snippets;

    // Language filter
    if (_languageFilter != null) {
      result = result.where((s) => s.language == _languageFilter).toList();
    }

    // Search across title, code, and language
    if (query.isNotEmpty) {
      result = result.where((s) {
        return s.title.toLowerCase().contains(query) ||
            s.code.toLowerCase().contains(query) ||
            s.language.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  // -- Sort -----------------------------------------------------------

  List<Snippet> _applySort(List<Snippet> snippets) {
    final sorted = List<Snippet>.of(snippets);
    switch (_sort) {
      case SnippetSort.recentlyUpdated:
        sorted.sort((a, b) {
          final cmp = b.updatedAt.compareTo(a.updatedAt);
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
        });
      case SnippetSort.recentlyCreated:
        sorted.sort((a, b) {
          final cmp = b.createdAt.compareTo(a.createdAt);
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
        });
      case SnippetSort.titleAZ:
        sorted.sort((a, b) {
          final cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          return cmp != 0 ? cmp : a.id.compareTo(b.id);
        });
    }
    return sorted;
  }

  // -- Create ---------------------------------------------------------

  Future<void> _showCreateDialog(BuildContext context) async {
    final result = await showDialog<_SnippetFormData>(
      context: context,
      builder: (_) =>
          const _SnippetFormDialog(title: 'New Snippet', actionLabel: 'Create'),
    );

    if (result != null && context.mounted) {
      try {
        await ref
            .read(snippetListProvider.notifier)
            .createSnippet(
              title: result.title,
              code: result.code,
              language: result.language,
            );
      } on ArgumentError {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid snippet fields.')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create snippet.')),
          );
        }
      }
    }
  }

  // -- Edit -----------------------------------------------------------

  Future<void> _showEditDialog(BuildContext context, Snippet snippet) async {
    final result = await showDialog<_SnippetFormData>(
      context: context,
      builder: (_) => _SnippetFormDialog(
        title: 'Edit Snippet',
        actionLabel: 'Save',
        initialTitle: snippet.title,
        initialCode: snippet.code,
        initialLanguage: snippet.language,
      ),
    );

    if (result != null && context.mounted) {
      try {
        await ref
            .read(snippetListProvider.notifier)
            .editSnippet(
              snippet.id,
              title: result.title,
              code: result.code,
              language: result.language,
            );
      } on ArgumentError {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid snippet fields.')),
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update snippet.')),
          );
        }
      }
    }
  }

  // -- Detail ---------------------------------------------------------

  Future<void> _showDetailDialog(BuildContext context, Snippet snippet) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SnippetDetailDialog(snippet: snippet),
    );
  }
}

// -- Form Data --------------------------------------------------------

class _SnippetFormData {
  const _SnippetFormData({
    required this.title,
    required this.code,
    required this.language,
  });

  final String title;
  final String code;
  final String language;
}

// -- Snippet Form Dialog ----------------------------------------------

class _SnippetFormDialog extends StatefulWidget {
  const _SnippetFormDialog({
    required this.title,
    required this.actionLabel,
    this.initialTitle = '',
    this.initialCode = '',
    this.initialLanguage = '',
  });

  final String title;
  final String actionLabel;
  final String initialTitle;
  final String initialCode;
  final String initialLanguage;

  @override
  State<_SnippetFormDialog> createState() => _SnippetFormDialogState();
}

class _SnippetFormDialogState extends State<_SnippetFormDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _codeController;
  late final TextEditingController _languageController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _codeController = TextEditingController(text: widget.initialCode);
    _languageController = TextEditingController(text: widget.initialLanguage);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    Navigator.of(context).pop(
      _SnippetFormData(
        title: _titleController.text,
        code: _codeController.text,
        language: _languageController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Binary search',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _languageController,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    hintText: 'e.g. dart, python, sql',
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                  minLines: 4,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  textInputAction: TextInputAction.newline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.actionLabel),
        ),
      ],
    );
  }
}

// -- Snippet Detail Dialog --------------------------------------------

class _SnippetDetailDialog extends StatelessWidget {
  const _SnippetDetailDialog({required this.snippet});

  final Snippet snippet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(snippet.title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Chip(
                label: Text(snippet.language),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Updated ${_formatDate(snippet.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppShapes.radiusSm),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    snippet.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// -- Snippet List Item ------------------------------------------------

class _SnippetListItem extends ConsumerWidget {
  const _SnippetListItem({
    required this.snippet,
    required this.onTap,
    required this.onEdit,
  });

  final Snippet snippet;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codePreview = snippet.code.length > 80
        ? '${snippet.code.substring(0, 80)}...'
        : snippet.code;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppShapes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      snippet.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      snippet.language,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                codePreview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: 'Edit snippet',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    tooltip: 'Delete snippet',
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete snippet?'),
        content: Text('Delete "${snippet.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(snippetListProvider.notifier).deleteSnippet(snippet.id);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete snippet.')),
          );
        }
      }
    }
  }
}

// -- Error State ------------------------------------------------------

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Could not load snippets.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
