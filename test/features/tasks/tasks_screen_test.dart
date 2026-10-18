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

void main() {
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
    // First frame should show loading before async resolves
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('creating a task makes it visible in the list', (tester) async {
    await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
    await tester.pumpAndSettle();

    // Tap FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter title
    await tester.enterText(find.byType(TextField), 'Write unit tests');
    await tester.pump();

    // Tap Create
    await tester.tap(find.text('Create'));
    await settleAfterDialog(tester);

    // Task should appear
    expect(find.text('Write unit tests'), findsOneWidget);
    expect(find.text('No tasks yet'), findsNothing);
  });

  testWidgets('rejects whitespace-only title in dialog', (tester) async {
    await tester.pumpWidget(buildTestApp(FakeTaskRepository()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Dialog should still be open with error text
    expect(find.text('Title cannot be empty.'), findsOneWidget);
  });

  testWidgets('completing a task shows strikethrough', (tester) async {
    final repo = FakeTaskRepository();
    await repo.createTask(Task.create(id: 't1', title: 'Complete me'));

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('Complete me'), findsOneWidget);

    // Tap checkbox
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    // Verify checkbox is now checked
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, true);
  });

  testWidgets('deleting a task removes it from the list', (tester) async {
    final repo = FakeTaskRepository();
    await repo.createTask(Task.create(id: 't1', title: 'Delete me'));

    await tester.pumpWidget(buildTestApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('Delete me'), findsOneWidget);

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirm deletion
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

    await tester.enterText(find.byType(TextField), 'Cancelled task');
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await settleAfterDialog(tester);

    expect(find.text('Cancelled task'), findsNothing);
    expect(find.text('No tasks yet'), findsOneWidget);
  });
}
