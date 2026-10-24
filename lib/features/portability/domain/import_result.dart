/// Result of an import operation.
class ImportResult {
  final int tasksImported;
  final int tasksSkipped;
  final int snippetsImported;
  final int snippetsSkipped;
  final int linksImported;
  final int linksSkipped;
  final List<String> errors;

  const ImportResult({
    required this.tasksImported,
    required this.tasksSkipped,
    required this.snippetsImported,
    required this.snippetsSkipped,
    required this.linksImported,
    required this.linksSkipped,
    this.errors = const [],
  });

  int get totalImported => tasksImported + snippetsImported + linksImported;

  int get totalSkipped => tasksSkipped + snippetsSkipped + linksSkipped;

  bool get hasErrors => errors.isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (tasksImported > 0) parts.add('$tasksImported tasks');
    if (snippetsImported > 0) parts.add('$snippetsImported snippets');
    if (linksImported > 0) parts.add('$linksImported links');
    final imported = parts.isEmpty ? 'Nothing' : parts.join(', ');

    final skipped = totalSkipped > 0 ? ', $totalSkipped skipped' : '';
    final errs = hasErrors ? ', ${errors.length} errors' : '';

    return 'Imported $imported$skipped$errs.';
  }
}
