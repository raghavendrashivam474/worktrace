import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/app.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/tasks/data/task_repository_provider.dart';
import 'package:worktrace/features/tasks/domain/task.dart';
import 'package:worktrace/features/tasks/domain/task_repository.dart';

/// Minimal fake repository so navigation tests can render TasksScreen
/// without a real database.
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

/// Minimal fake repository so navigation tests can render SnippetsScreen
/// without a real database.
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
  /// Pump the full app inside a ProviderScope with fake repos.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepo()),
          snippetRepositoryProvider.overrideWithValue(_FakeSnippetRepo()),
        ],
        child: const WorktraceApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Tap a navigation destination by label, scoped to the navigation widget
  /// to avoid ambiguity with screen content that shares the same text.
  Future<void> tapDestination(WidgetTester tester, String label) async {
    final navBar = find.byType(NavigationBar);
    final navRail = find.byType(NavigationRail);

    final scope = navBar.evaluate().isNotEmpty ? navBar : navRail;
    final target = find.descendant(of: scope, matching: find.text(label));

    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('Initial state', () {
    testWidgets('Home is the initial destination', (tester) async {
      await pumpApp(tester);

      // Home content is visible
      expect(find.text('Workspace'), findsOneWidget);

      // Tasks and Snippets empty states are NOT visible
      expect(find.text('No tasks yet'), findsNothing);
      expect(find.text('No snippets yet'), findsNothing);
    });
  });

  group('Tab navigation', () {
    testWidgets('Navigate to Tasks and back', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');

      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Workspace'), findsNothing);

      await tapDestination(tester, 'Home');

      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('Navigate to Snippets', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Snippets');

      expect(find.text('No snippets yet'), findsOneWidget);
      expect(find.text('Workspace'), findsNothing);
    });

    testWidgets('Repeated taps do not duplicate content', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');
      await tapDestination(tester, 'Tasks');

      expect(find.text('No tasks yet'), findsOneWidget);
    });
  });

  group('Back navigation', () {
    testWidgets('Back from Tasks returns to Home', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');
      expect(find.text('No tasks yet'), findsOneWidget);

      // Simulate Android back button
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Workspace'), findsOneWidget);
    });

    testWidgets('Back from Snippets returns to Home', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Snippets');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Workspace'), findsOneWidget);
    });
  });

  group('Responsive shell', () {
    testWidgets('Compact layout shows NavigationBar', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('Wide layout shows NavigationRail', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpApp(tester);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}
