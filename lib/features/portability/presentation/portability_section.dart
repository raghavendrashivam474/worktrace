import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// ignore_for_file: deprecated_member_use
import 'package:worktrace/app/theme/app_tokens.dart';
import 'package:worktrace/features/portability/data/portability_service_provider.dart';
import 'package:worktrace/features/tasks/presentation/task_list_provider.dart';
import 'package:worktrace/features/snippets/presentation/snippet_list_provider.dart';

/// Section widget for data export and import.
///
/// Provides two actions:
/// - Export: saves workspace data as versioned JSON and shares it.
/// - Import: lets the user pick a JSON file, validates it, and
///   merges data without overwriting existing records.
class PortabilitySection extends ConsumerWidget {
  const PortabilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Portability', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Export or import your workspace data.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _export(context, ref),
                    icon: const Icon(Icons.upload_rounded, size: 18),
                    label: const Text('Export'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _import(context, ref),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final service = ref.read(portabilityServiceProvider);
      final json = await service.exportWorkspace();

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File('${dir.path}/worktrace-$timestamp.json');
      await file.writeAsString(json);

      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/json'),
      ], subject: 'Worktrace Export');
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Pick file.
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;

    final path = files.single.path;
    if (path == null) return;

    // 2. Read file.
    final String json;
    try {
      json = await File(path).readAsString();
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not read file.')),
        );
      }
      return;
    }

    // 3. Validate format (catch malformed or unsupported files).
    final service = ref.read(portabilityServiceProvider);
    final export = service.validateExport(json);

    // 4. Confirm with user.
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: Text(
          'This file contains ${export.tasks.length} tasks, '
          '${export.snippets.length} snippets, and '
          '${export.links.length} links.\n\n'
          'Existing records will not be overwritten. '
          'New records will be added.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 5. Import atomically.
    try {
      final importResult = await service.importWorkspace(export);

      // Refresh providers so the home screen updates.
      ref.invalidate(taskListProvider);
      ref.invalidate(snippetListProvider);

      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(importResult.summary)));
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Import failed. No data was changed.')),
        );
      }
    }
  }
}
