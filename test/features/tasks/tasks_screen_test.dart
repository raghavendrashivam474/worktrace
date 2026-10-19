import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worktrace/features/tasks/data/task_repository_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';
import 'package:worktrace/features/tasks/tasks_screen.dart';

/// Reusable fake repository for widget tests.
class FakeTaskRepository implements TaskRepository {
  final List<Task> _tasks = [];
  bool shouldFail = false;

  @override
  Future<List<Task>> getAllTasks() async {
    if (shouldFail) throw Exception('Simulated failure');
    return List.unmodifiable(_tasks);
  }

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createTask(Task task) async {
    if (shouldFail) throw Exception('Simulated failure');
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    if (shouldFail) throw Exception('Simulated failure');
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i != -1) _tasks[i] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    if (shouldFail) throw Exception('Simulated failure');
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Stream<List<Task>> watchAllTasks() => Stream.value(List.unmodifiable(_tasks));
}

Widget buildTestApp(FakeTaskRepository repo) {
  return ProviderScope(
    overrides: [taskRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: TasksScreen()),
  );
}

/// Pumps past dialog animations and async state changes.
Future<void> settleAfterDialog(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Seeds the repo with deterministic tasks for search/filter/sort tests.
Future<void> seedTasks(FakeTaskRepository repo) async {
  await repo.createTask(
    Task.create(
      id: 't1',
      title: 'Buy groceries',
      createdAt: DateTime(2026, 1, 10),
    ),
  );
  await repo.createTask(
    Task.create(
      id: 't2',
      title: 'Write unit tests',
      createdAt: DateTime(2026, 3, 15),
    ),
  );
  await repo.createTask(
    Task.create(
      id: 't3',
      title: 'Deploy app',
      createdAt: DateTime(2026, 2, 20),
    ),
  );
}

/// Finds the TextField inside an open AlertDialog (avoids matching the
/// search bar when both are on screen).
Finder findDialogTextField() {
  return find.descendant(
    of: find.byType(AlertDialog),
    matching: find.byType(TextField),
  );
}

/// Finds the search bar TextField on the main screen.
Finder findSearchField() {
  return find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.hintText == 'Search tasks...',
  );
}

void main() {
  // Ã¢â€â‚¬Ã¢â€â‚¬ Existing tests (preserved) Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('Existing: create, complete, delete, error', () {
    testWidgets('shows empty state when no tasks exist', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(
        find.text('Tap the + button to create your first task.'),
        findsOneWidget,
      );
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('creating a task makes it visible in the list', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), 'Write unit tests');
      await tester.pump();

      await tester.tap(find.text('Create'));
      await settleAfterDialog(tester);

      expect(find.text('Write unit tests'), findsOneWidget);
      expect(find.text('No tasks yet'), findsNothing);
    });

    testWidgets('rejects whitespace-only title in dialog', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), '   ');
      await tester.pump();

      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Title cannot be empty.'), findsOneWidget);
    });

    testWidgets('completing a task shows strikethrough', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 't1', title: 'Complete me'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Complete me'), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
    });

    testWidgets('deleting a task removes it from the list', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 't1', title: 'Delete me'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Delete me'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete').last);
      await settleAfterDialog(tester);

      expect(find.text('Delete me'), findsNothing);
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('shows error state when load fails', (tester) async {
      final repo = FakeTaskRepository()..shouldFail = true;

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Could not load tasks.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('cancelling create dialog does not add a task', (tester) async {
      await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), 'Cancelled task');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await settleAfterDialog(tester);

      expect(find.text('Cancelled task'), findsNothing);
      expect(find.text('No tasks yet'), findsOneWidget);
    });
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ S1.4-A: Edit tests Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('S1.4-A: Edit task', () {
    testWidgets('edit icon is visible on each task', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(3));
    });

    testWidgets('edit dialog opens pre-filled with current title', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 'e1', title: 'Original title'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
      final textField = tester.widget<TextField>(findDialogTextField());
      expect(textField.controller?.text, 'Original title');
    });

    testWidgets('saving edit updates the task title', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 'e2', title: 'Old name'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), 'New name');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await settleAfterDialog(tester);

      expect(find.text('New name'), findsOneWidget);
      expect(find.text('Old name'), findsNothing);
    });

    testWidgets('edit rejects empty title', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 'e3', title: 'Keep me'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), '   ');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title cannot be empty.'), findsOneWidget);
      expect(find.text('Edit Task'), findsOneWidget);
    });

    testWidgets('cancelling edit leaves title unchanged', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 'e4', title: 'Unchanged'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      await tester.enterText(findDialogTextField(), 'Modified');
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await settleAfterDialog(tester);

      expect(find.text('Unchanged'), findsOneWidget);
      expect(find.text('Modified'), findsNothing);
    });
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ S1.4-B: Search tests Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('S1.4-B: Search tasks', () {
    testWidgets('search bar is visible when tasks exist', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Search tasks...'), findsOneWidget);
    });

    testWidgets('search filters tasks by title (case-insensitive)', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(findSearchField(), 'buy');
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Write unit tests'), findsNothing);
      expect(find.text('Deploy app'), findsNothing);
    });

    testWidgets('clearing search restores all tasks', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(findSearchField(), 'deploy');
      await tester.pumpAndSettle();
      expect(find.text('Deploy app'), findsOneWidget);
      expect(find.text('Buy groceries'), findsNothing);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
      expect(find.text('Write unit tests'), findsOneWidget);
      expect(find.text('Deploy app'), findsOneWidget);
    });

    testWidgets('no-match state is distinct from empty database', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.enterText(findSearchField(), 'nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No matching tasks'), findsOneWidget);
      expect(
        find.text('Try adjusting your search or filters.'),
        findsOneWidget,
      );
      expect(find.text('No tasks yet'), findsNothing);
    });
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ S1.4-C: Filter tests Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('S1.4-C: Completion filter', () {
    testWidgets('filter buttons are visible', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Active filter hides completed tasks', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);
      final tasks = await repo.getAllTasks();
      final completed = tasks.first.toggleCompletion();
      await repo.updateTask(completed);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();

      expect(find.text(completed.title), findsNothing);
      expect(find.text('Write unit tests'), findsOneWidget);
    });

    testWidgets('Done filter shows only completed tasks', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);
      final tasks = await repo.getAllTasks();
      final completed = tasks.first.toggleCompletion();
      await repo.updateTask(completed);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text(completed.title), findsOneWidget);
      expect(find.text('Write unit tests'), findsNothing);
      expect(find.text('Deploy app'), findsNothing);
    });

    testWidgets('filter shows no-match state when no tasks match', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('No matching tasks'), findsOneWidget);
    });
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ S1.4-D: Sort tests Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('S1.4-D: Sorting', () {
    testWidgets('sort button is visible', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sort), findsOneWidget);
    });

    testWidgets('sort by title A-Z orders correctly', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Title A-Z'));
      await tester.pumpAndSettle();

      final listItems = tester.widgetList<ListTile>(find.byType(ListTile));
      final titles = listItems.map((li) => (li.title as Text).data).toList();
      expect(titles, ['Buy groceries', 'Deploy app', 'Write unit tests']);
    });

    testWidgets('sort by oldest first orders correctly', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oldest first'));
      await tester.pumpAndSettle();

      // t1=Jan, t3=Feb, t2=Mar
      final listItems = tester.widgetList<ListTile>(find.byType(ListTile));
      final titles = listItems.map((li) => (li.title as Text).data).toList();
      expect(titles, ['Buy groceries', 'Deploy app', 'Write unit tests']);
    });
  });

  // Ã¢â€â‚¬Ã¢â€â‚¬ S1.4-E: Combined interactions Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬Ã¢â€â‚¬

  group('S1.4-E: Search + Filter + Sort combined', () {
    testWidgets('search and filter compose correctly', (tester) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);
      final tasks = await repo.getAllTasks();
      final buyTask = tasks.firstWhere((t) => t.id == 't1');
      await repo.updateTask(buyTask.toggleCompletion());

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Buy groceries'), findsOneWidget);

      await tester.enterText(findSearchField(), 'buy');
      await tester.pumpAndSettle();
      expect(find.text('Buy groceries'), findsOneWidget);

      await tester.enterText(findSearchField(), 'deploy');
      await tester.pumpAndSettle();
      expect(find.text('No matching tasks'), findsOneWidget);
    });

    testWidgets('completing a task updates active filter membership', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await seedTasks(repo);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.text('Buy groceries'), findsOneWidget);

      // Target the checkbox inside the "Buy groceries" row specifically
      final buyCheckbox = find.descendant(
        of: find.byKey(const ValueKey('t1')),
        matching: find.byType(Checkbox),
      );
      await tester.tap(buyCheckbox);
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsNothing);
    });
  });

  // â”€â”€ S1.5: Hardening, Error Recovery & Lifecycle Tests â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  group('S1.5: Hardening & Error Recovery', () {
    testWidgets('shows SnackBar when task creation fails in repository', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Trigger failure on next operation
      repo.shouldFail = true;

      await tester.enterText(findDialogTextField(), 'Fail task');
      await tester.pump();

      await tester.tap(find.text('Create'));
      await settleAfterDialog(tester);

      expect(find.text('Failed to create task.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when task edit fails in repository', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await repo.createTask(Task.create(id: 'err1', title: 'Edit fail target'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      repo.shouldFail = true;

      await tester.enterText(findDialogTextField(), 'New title');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await settleAfterDialog(tester);

      expect(find.text('Failed to update task.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when toggle completion fails', (tester) async {
      final repo = FakeTaskRepository();
      await repo.createTask(
        Task.create(id: 'err2', title: 'Toggle fail target'),
      );

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      repo.shouldFail = true;

      await tester.tap(find.byType(Checkbox));
      await settleAfterDialog(tester);

      expect(find.text('Failed to update task state.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when delete fails in repository', (
      tester,
    ) async {
      final repo = FakeTaskRepository();
      await repo.createTask(
        Task.create(id: 'err3', title: 'Delete fail target'),
      );

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      repo.shouldFail = true;

      await tester.tap(find.text('Delete').last);
      await settleAfterDialog(tester);

      expect(find.text('Failed to delete task.'), findsOneWidget);
    });
  });
}
