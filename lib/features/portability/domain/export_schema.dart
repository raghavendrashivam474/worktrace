/// Versioned export format for Worktrace workspace data.
///
/// This is a plain Dart model used for JSON serialization.
/// It does not depend on Drift or Flutter.
class WorktraceExport {
  static const String formatId = 'worktrace-export';
  static const int currentVersion = 1;

  final String format;
  final int version;
  final DateTime exportedAt;
  final List<ExportTask> tasks;
  final List<ExportSnippet> snippets;
  final List<ExportLink> links;

  const WorktraceExport({
    required this.format,
    required this.version,
    required this.exportedAt,
    required this.tasks,
    required this.snippets,
    required this.links,
  });

  Map<String, dynamic> toJson() => {
    'format': format,
    'version': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'snippets': snippets.map((s) => s.toJson()).toList(),
    'links': links.map((l) => l.toJson()).toList(),
  };

  factory WorktraceExport.fromJson(Map<String, dynamic> json) {
    return WorktraceExport(
      format: json['format'] as String,
      version: json['version'] as int,
      exportedAt: DateTime.parse(json['exportedAt'] as String),
      tasks: (json['tasks'] as List)
          .map((e) => ExportTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      snippets: (json['snippets'] as List)
          .map((e) => ExportSnippet.fromJson(e as Map<String, dynamic>))
          .toList(),
      links:
          (json['links'] as List?)
              ?.map((e) => ExportLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ExportTask {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExportTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory ExportTask.fromJson(Map<String, dynamic> json) {
    return ExportTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ExportSnippet {
  final String id;
  final String title;
  final String code;
  final String language;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExportSnippet({
    required this.id,
    required this.title,
    required this.code,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'code': code,
    'language': language,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory ExportSnippet.fromJson(Map<String, dynamic> json) {
    return ExportSnippet(
      id: json['id'] as String,
      title: json['title'] as String,
      code: json['code'] as String,
      language: json['language'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ExportLink {
  final String taskId;
  final String snippetId;
  final DateTime linkedAt;

  const ExportLink({
    required this.taskId,
    required this.snippetId,
    required this.linkedAt,
  });

  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'snippetId': snippetId,
    'linkedAt': linkedAt.toUtc().toIso8601String(),
  };

  factory ExportLink.fromJson(Map<String, dynamic> json) {
    return ExportLink(
      taskId: json['taskId'] as String,
      snippetId: json['snippetId'] as String,
      linkedAt: DateTime.parse(json['linkedAt'] as String),
    );
  }
}
