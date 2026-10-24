import 'dart:convert';

import 'package:worktrace/features/links/domain/task_snippet_link.dart';
import 'package:worktrace/features/links/domain/task_snippet_link_repository.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';

import '../domain/export_schema.dart';
import '../domain/import_result.dart';

/// Service for exporting and importing Worktrace workspace data.
///
/// Uses existing repository contracts — no direct database access.
/// Export produces versioned JSON. Import validates before mutating
/// and uses a merge-without-overwrite strategy.
class PortabilityService {
  final TaskRepository _taskRepo;
  final SnippetRepository _snippetRepo;
  final TaskSnippetLinkRepository _linkRepo;

  PortabilityService({
    required this._taskRepo,
    required this._snippetRepo,
    required this._linkRepo,
  });

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Collects all workspace data and returns a versioned JSON string.
  Future<String> exportWorkspace() async {
    final tasks = await _taskRepo.getAllTasks();
    final snippets = await _snippetRepo.getAllSnippets();

    // Collect links for all tasks.
    final allLinks = <TaskSnippetLink>[];
    for (final task in tasks) {
      final links = await _linkRepo.getByTask(task.id);
      allLinks.addAll(links);
    }

    final export = WorktraceExport(
      format: WorktraceExport.formatId,
      version: WorktraceExport.currentVersion,
      exportedAt: DateTime.now(),
      tasks: tasks
          .map(
            (t) => ExportTask(
              id: t.id,
              title: t.title,
              isCompleted: t.isCompleted,
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
            ),
          )
          .toList(),
      snippets: snippets
          .map(
            (s) => ExportSnippet(
              id: s.id,
              title: s.title,
              code: s.code,
              language: s.language,
              createdAt: s.createdAt,
              updatedAt: s.updatedAt,
            ),
          )
          .toList(),
      links: allLinks
          .map(
            (l) => ExportLink(
              taskId: l.taskId,
              snippetId: l.snippetId,
              linkedAt: l.linkedAt,
            ),
          )
          .toList(),
    );

    return const JsonEncoder.withIndent('  ').convert(export.toJson());
  }

  // ---------------------------------------------------------------------------
  // Import
  // ---------------------------------------------------------------------------

  /// Validates a JSON string and returns the parsed export if valid.
  ///
  /// Throws [FormatException] for malformed JSON or unsupported format.
  WorktraceExport validateExport(String json) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const FormatException('Invalid JSON.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Export must be a JSON object.');
    }

    final format = decoded['format'];
    if (format != WorktraceExport.formatId) {
      throw FormatException(
        'Unsupported format: "$format". '
        'Expected "${WorktraceExport.formatId}".',
      );
    }

    final version = decoded['version'];
    if (version is! int || version > WorktraceExport.currentVersion) {
      throw FormatException(
        'Unsupported version: $version. '
        'Maximum supported: ${WorktraceExport.currentVersion}.',
      );
    }

    try {
      return WorktraceExport.fromJson(decoded);
    } catch (e) {
      throw FormatException('Malformed export data: $e');
    }
  }

  /// Imports workspace data using merge-without-overwrite strategy.
  ///
  /// - Existing records are never modified.
  /// - New records are inserted.
  /// - Duplicate IDs are skipped.
  /// - Links referencing missing entities are skipped.
  /// - Returns a summary of what was imported and skipped.
  Future<ImportResult> importWorkspace(WorktraceExport export) async {
    var tasksImported = 0;
    var tasksSkipped = 0;
    var snippetsImported = 0;
    var snippetsSkipped = 0;
    var linksImported = 0;
    var linksSkipped = 0;
    final errors = <String>[];

    // Import tasks.
    for (final t in export.tasks) {
      final existing = await _taskRepo.getTaskById(t.id);
      if (existing != null) {
        tasksSkipped++;
        continue;
      }
      try {
        await _taskRepo.createTask(
          Task(
            id: t.id,
            title: t.title,
            isCompleted: t.isCompleted,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
          ),
        );
        tasksImported++;
      } catch (e) {
        tasksSkipped++;
        errors.add('Task "${t.id}": $e');
      }
    }

    // Import snippets.
    for (final s in export.snippets) {
      final existing = await _snippetRepo.getSnippetById(s.id);
      if (existing != null) {
        snippetsSkipped++;
        continue;
      }
      try {
        await _snippetRepo.createSnippet(
          Snippet(
            id: s.id,
            title: s.title,
            code: s.code,
            language: s.language,
            createdAt: s.createdAt,
            updatedAt: s.updatedAt,
          ),
        );
        snippetsImported++;
      } catch (e) {
        snippetsSkipped++;
        errors.add('Snippet "${s.id}": $e');
      }
    }

    // Import links (only if both entities exist).
    for (final l in export.links) {
      final taskExists = await _taskRepo.getTaskById(l.taskId) != null;
      final snippetExists =
          await _snippetRepo.getSnippetById(l.snippetId) != null;

      if (!taskExists || !snippetExists) {
        linksSkipped++;
        continue;
      }

      try {
        final created = await _linkRepo.attach(l.taskId, l.snippetId);
        if (created) {
          linksImported++;
        } else {
          linksSkipped++;
        }
      } catch (e) {
        linksSkipped++;
        errors.add('Link ${l.taskId}->${l.snippetId}: $e');
      }
    }

    return ImportResult(
      tasksImported: tasksImported,
      tasksSkipped: tasksSkipped,
      snippetsImported: snippetsImported,
      snippetsSkipped: snippetsSkipped,
      linksImported: linksImported,
      linksSkipped: linksSkipped,
      errors: errors,
    );
  }
}
