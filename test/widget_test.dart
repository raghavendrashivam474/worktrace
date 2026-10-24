import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/app.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/tasks/data/task_repository_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';

class _FakeTaskRepo implements TaskRepository {
  @override
  Future<List<Task>> getAllTasks() async => [];
  @override
  Future<Task?> getTaskById(String id) async => null;
  @override
  Future<void> createTask(Task task) async {}
  @override
  Future<void> updateTask(Task task) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Stream<List<Task>> watchAllTasks() => Stream.value([]);
}

class _FakeSnippetRepo implements SnippetRepository {
  @override
  Future<List<Snippet>> getAllSnippets() async => [];
  @override
  Future<Snippet?> getSnippetById(String id) async => null;
  @override
  Future<void> createSnippet(Snippet snippet) async {}
  @override
  Future<void> updateSnippet(Snippet snippet) async {}
  @override
  Future<void> deleteSnippet(String id) async {}
  @override
  Stream<List<Snippet>> watchAllSnippets() => Stream.value([]);
}

void main() {
  testWidgets('WorktraceApp launches and shows branded shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepo()),
          snippetRepositoryProvider.overrideWithValue(_FakeSnippetRepo()),
        ],
        child: const WorktraceApp(),
      ),
    );

    // Verify brand identity in AppBar
    expect(find.text('Worktrace'), findsWidgets);

    // Verify all three destination labels are present somewhere in the shell.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Snippets'), findsWidgets);

    // Verify Home content is the initial screen
    expect(find.text('Workspace'), findsOneWidget);
  });
}
