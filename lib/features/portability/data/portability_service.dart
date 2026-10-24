import 'dart:convert';

import 'package:worktrace/core/data/app_database.dart';
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
/// Uses existing repository contracts for reads and writes.
/// Import is atomic: all writes occur inside a single Drift transaction.
/// If any write fails, the entire import is rolled back.
class PortabilityService {
  final TaskRepository _taskRepo;
  final SnippetRepository _snippetRepo;
  final TaskSnippetLinkRepository _linkRepo;
  final AppDatabase _db;

  PortabilityService({
    required this._taskRepo,
    required this._snippetRepo,
    required this._linkRepo,
    required this._db,
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
  /// This is a pure parsing operation — no database access.
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

  /// Imports workspace data atomically using merge-without-overwrite strategy.
  ///
  /// All database writes occur inside a single transaction:
  /// - If any write fails, the entire import is rolled back.
  /// - Existing records are never modified.
  /// - Duplicate IDs are skipped (merge policy).
  /// - Links referencing missing entities are skipped.
  ///
  /// Throws on any persistence failure. The caller should catch and
  /// present a user-friendly message.
  Future<ImportResult> importWorkspace(WorktraceExport export) async {
    return await _db.transaction(() async {
      var tasksImported = 0;
      var tasksSkipped = 0;
      var snippetsImported = 0;
      var snippetsSkipped = 0;
      var linksImported = 0;
      var linksSkipped = 0;

      // Import tasks.
      for (final t in export.tasks) {
        final existing = await _taskRepo.getTaskById(t.id);
        if (existing != null) {
          tasksSkipped++;
          continue;
        }
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
      }

      // Import snippets.
      for (final s in export.snippets) {
        final existing = await _snippetRepo.getSnippetById(s.id);
        if (existing != null) {
          snippetsSkipped++;
          continue;
        }
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
      }

      // Import links (only if both entities exist in the final DB state).
      for (final l in export.links) {
        final taskExists = await _taskRepo.getTaskById(l.taskId) != null;
        final snippetExists =
            await _snippetRepo.getSnippetById(l.snippetId) != null;

        if (!taskExists || !snippetExists) {
          linksSkipped++;
          continue;
        }

        final created = await _linkRepo.attach(l.taskId, l.snippetId);
        if (created) {
          linksImported++;
        } else {
          linksSkipped++;
        }
      }

      return ImportResult(
        tasksImported: tasksImported,
        tasksSkipped: tasksSkipped,
        snippetsImported: snippetsImported,
        snippetsSkipped: snippetsSkipped,
        linksImported: linksImported,
        linksSkipped: linksSkipped,
      );
    });
  }
}
