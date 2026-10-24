import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/features/links/domain/task_snippet_link.dart';

void main() {
  group('TaskSnippetLink', () {
    test('equality is based on taskId and snippetId', () {
      final a = TaskSnippetLink(
        taskId: 't1',
        snippetId: 's1',
        linkedAt: DateTime(2025, 1, 1),
      );
      final b = TaskSnippetLink(
        taskId: 't1',
        snippetId: 's1',
        linkedAt: DateTime(2025, 6, 1), // different time
      );
      final c = TaskSnippetLink(
        taskId: 't1',
        snippetId: 's2',
        linkedAt: DateTime(2025, 1, 1),
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = TaskSnippetLink(
        taskId: 't1',
        snippetId: 's1',
        linkedAt: DateTime(2025, 1, 1),
      );
      final b = TaskSnippetLink(
        taskId: 't1',
        snippetId: 's1',
        linkedAt: DateTime(2025, 6, 1),
      );

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
