import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/navigation/navigation_provider.dart';
import 'package:worktrace/features/home/home_screen.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/tasks/data/task_repository_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeTaskRepo implements TaskRepository {
  List<Task> tasks;
  bool shouldFail;

  _FakeTaskRepo({this.tasks = const [], this.shouldFail = false});

  @override
  Future<List<Task>> getAllTasks() async {
    if (shouldFail) throw Exception('Task load failed');
    return tasks;
  }

  @override
  Future<Task?> getTaskById(String id) async => null;
  @override
  Future<void> createTask(Task task) async {}
  @override
  Future<void> updateTask(Task task) async {}
  @override
  Future<void> deleteTask(String id) async {}
  @override
  Stream<List<Task>> watchAllTasks() => Stream.value(tasks);
}

class _FakeSnippetRepo implements SnippetRepository {
  List<Snippet> snippets;
  bool shouldFail;

  _FakeSnippetRepo({this.snippets = const [], this.shouldFail = false});

  @override
  Future<List<Snippet>> getAllSnippets() async {
    if (shouldFail) throw Exception('Snippet load failed');
    return snippets;
  }

  @override
  Future<Snippet?> getSnippetById(String id) async => null;
  @override
  Future<void> createSnippet(Snippet snippet) async {}
  @override
  Future<void> updateSnippet(Snippet snippet) async {}
  @override
  Future<void> deleteSnippet(String id) async {}
  @override
  Stream<List<Snippet>> watchAllSnippets() => Stream.value(snippets);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Task _task(String title, {bool completed = false}) {
  return Task(
    id: 'task-$title',
    title: title,
    isCompleted: completed,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );
}

Snippet _snippet(String title, {String language = 'dart'}) {
  return Snippet(
    id: 'snippet-$title',
    title: title,
    code: 'void main() {}',
    language: language,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 6, 1),
  );
}

Future<void> _pumpHome(
  WidgetTester tester, {
  _FakeTaskRepo? taskRepo,
  _FakeSnippetRepo? snippetRepo,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(taskRepo ?? _FakeTaskRepo()),
        snippetRepositoryProvider.overrideWithValue(
          snippetRepo ?? _FakeSnippetRepo(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Workspace header', () {
    testWidgets('shows title and subtitle', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Workspace'), findsOneWidget);
      expect(find.text('Your tasks and snippets at a glance.'), findsOneWidget);
    });
  });

  group('Quick actions', () {
    testWidgets('all four buttons are present', (tester) async {
      await _pumpHome(tester);

      expect(find.text('New Task'), findsOneWidget);
      expect(find.text('New Snippet'), findsOneWidget);
      expect(find.text('All Tasks'), findsOneWidget);
      expect(find.text('All Snippets'), findsOneWidget);
    });

    testWidgets('All Tasks navigates to tab 1', (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('All Tasks'));
      await tester.pump();

      // Read the provider from the widget tree
      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      expect(container.read(navigationIndexProvider), 1);
    });

    testWidgets('All Snippets navigates to tab 2', (tester) async {
      await _pumpHome(tester);

      await tester.tap(find.text('All Snippets'));
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(HomeScreen)),
      );
      expect(container.read(navigationIndexProvider), 2);
    });
  });

  group('Active tasks section', () {
    testWidgets('shows empty state when no tasks exist', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Active Tasks'), findsOneWidget);
      expect(
        find.text('No tasks yet. Create one to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows active tasks and hides completed', (tester) async {
      await _pumpHome(
        tester,
        taskRepo: _FakeTaskRepo(
          tasks: [
            _task('Buy groceries'),
            _task('Write tests'),
            _task('Old task', completed: true),
          ],
        ),
      );

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Write tests'), findsOneWidget);
      expect(find.text('Old task'), findsNothing);
    });

    testWidgets('shows all-done message when all completed', (tester) async {
      await _pumpHome(
        tester,
        taskRepo: _FakeTaskRepo(tasks: [_task('Done task', completed: true)]),
      );

      expect(find.text('All tasks are completed!'), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await _pumpHome(tester, taskRepo: _FakeTaskRepo(shouldFail: true));

      expect(find.text('Could not load tasks.'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });
  });

  group('Recent snippets section', () {
    testWidgets('shows empty state when no snippets exist', (tester) async {
      await _pumpHome(tester);

      expect(find.text('Recent Snippets'), findsOneWidget);
      expect(
        find.text('No snippets yet. Create one to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('shows snippet titles and language badges', (tester) async {
      await _pumpHome(
        tester,
        snippetRepo: _FakeSnippetRepo(
          snippets: [
            _snippet('Auth helper', language: 'dart'),
            _snippet('SQL query', language: 'sql'),
          ],
        ),
      );

      expect(find.text('Auth helper'), findsOneWidget);
      expect(find.text('SQL query'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
      expect(find.text('sql'), findsOneWidget);
    });

    testWidgets('shows error state with retry', (tester) async {
      await _pumpHome(tester, snippetRepo: _FakeSnippetRepo(shouldFail: true));

      expect(find.text('Could not load snippets.'), findsOneWidget);
      expect(find.text('Retry'), findsWidgets);
    });
  });

  group('Independent section failure', () {
    testWidgets('task failure does not suppress snippets', (tester) async {
      await _pumpHome(
        tester,
        taskRepo: _FakeTaskRepo(shouldFail: true),
        snippetRepo: _FakeSnippetRepo(snippets: [_snippet('Visible snippet')]),
      );

      // Tasks section shows error
      expect(find.text('Could not load tasks.'), findsOneWidget);

      // Snippets section still shows data
      expect(find.text('Visible snippet'), findsOneWidget);
    });

    testWidgets('snippet failure does not suppress tasks', (tester) async {
      await _pumpHome(
        tester,
        taskRepo: _FakeTaskRepo(tasks: [_task('Visible task')]),
        snippetRepo: _FakeSnippetRepo(shouldFail: true),
      );

      // Tasks section shows data
      expect(find.text('Visible task'), findsOneWidget);

      // Snippets section shows error
      expect(find.text('Could not load snippets.'), findsOneWidget);
    });
  });
}
