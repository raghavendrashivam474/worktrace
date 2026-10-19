import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/snippets/snippets_screen.dart';

/// Reusable fake repository for widget tests.
class FakeSnippetRepository implements SnippetRepository {
  final List<Snippet> _snippets = [];
  bool shouldFail = false;

  @override
  Future<List<Snippet>> getAllSnippets() async {
    if (shouldFail) throw Exception('Simulated failure');
    return List.unmodifiable(_snippets);
  }

  @override
  Future<Snippet?> getSnippetById(String id) async {
    try {
      return _snippets.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createSnippet(Snippet snippet) async {
    if (shouldFail) throw Exception('Simulated failure');
    _snippets.add(snippet);
  }

  @override
  Future<void> updateSnippet(Snippet snippet) async {
    if (shouldFail) throw Exception('Simulated failure');
    final i = _snippets.indexWhere((s) => s.id == snippet.id);
    if (i != -1) _snippets[i] = snippet;
  }

  @override
  Future<void> deleteSnippet(String id) async {
    if (shouldFail) throw Exception('Simulated failure');
    _snippets.removeWhere((s) => s.id == id);
  }

  @override
  Stream<List<Snippet>> watchAllSnippets() =>
      Stream.value(List.unmodifiable(_snippets));
}

/// Fake repository that delays getAllSnippets until explicitly completed.
class _DelayedSnippetRepository implements SnippetRepository {
  final _completer = Completer<List<Snippet>>();

  void complete() => _completer.complete([]);

  @override
  Future<List<Snippet>> getAllSnippets() => _completer.future;

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

Widget buildTestApp(SnippetRepository repo) {
  return ProviderScope(
    overrides: [snippetRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: SnippetsScreen()),
  );
}

Snippet makeSnippet({
  String id = 'test-id-1',
  String title = 'Binary Search',
  String code = 'int search(List<int> a, int t) {}',
  String language = 'dart',
}) {
  return Snippet.create(id: id, title: title, code: code, language: language);
}

void main() {
  group('Empty state', () {
    testWidgets('shows empty state when no snippets exist', (tester) async {
      final repo = FakeSnippetRepository();
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('No snippets yet'), findsOneWidget);
      expect(
        find.text('Tap the + button to save your first code snippet.'),
        findsOneWidget,
      );
    });
  });

  group('Loading and error states', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final repo = _DelayedSnippetRepository();
      await tester.pumpWidget(buildTestApp(repo));
      // Pump once to start the build but don't let the future complete
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Now let it complete so the test can tear down cleanly
      repo.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows error state with retry when load fails', (tester) async {
      final repo = FakeSnippetRepository()..shouldFail = true;
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Could not load snippets.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('List rendering', () {
    testWidgets('renders persisted snippets', (tester) async {
      final repo = FakeSnippetRepository();
      final s1 = makeSnippet(id: '1', title: 'Quick Sort', language: 'python');
      final s2 = makeSnippet(id: '2', title: 'Fibonacci', language: 'dart');
      await repo.createSnippet(s1);
      await repo.createSnippet(s2);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Quick Sort'), findsOneWidget);
      expect(find.text('Fibonacci'), findsOneWidget);
      expect(find.text('python'), findsOneWidget);
      expect(find.text('dart'), findsOneWidget);
    });
  });

  group('Create snippet', () {
    testWidgets('create form validates required inputs', (tester) async {
      final repo = FakeSnippetRepository();
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Open create dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('New Snippet'), findsOneWidget);

      // Submit empty form
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('successful creation appears in the workspace', (tester) async {
      final repo = FakeSnippetRepository();
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Open create dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'My Snippet',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Language'),
        'python',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Code'),
        'print("hello")',
      );

      // Submit
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Snippet should appear in the list
      expect(find.text('My Snippet'), findsOneWidget);
      expect(find.text('python'), findsOneWidget);
    });
  });

  group('Edit snippet', () {
    testWidgets('edit prepopulates and saves existing values', (tester) async {
      final repo = FakeSnippetRepository();
      final snippet = makeSnippet(
        title: 'Old Title',
        code: 'old code',
        language: 'java',
      );
      await repo.createSnippet(snippet);

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap edit icon
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Snippet'), findsOneWidget);

      // Verify prepopulated values
      final titleField = find.widgetWithText(TextFormField, 'Old Title');
      expect(titleField, findsOneWidget);

      // Change title
      await tester.enterText(titleField, 'New Title');

      // Submit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('New Title'), findsOneWidget);
      expect(find.text('Old Title'), findsNothing);
    });
  });

  group('Delete snippet', () {
    testWidgets('canceling deletion preserves the snippet', (tester) async {
      final repo = FakeSnippetRepository();
      await repo.createSnippet(makeSnippet(title: 'Keep Me'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete snippet?'), findsOneWidget);

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Keep Me'), findsOneWidget);
    });

    testWidgets('confirming deletion removes the snippet', (tester) async {
      final repo = FakeSnippetRepository();
      await repo.createSnippet(makeSnippet(title: 'Delete Me'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete Me'), findsNothing);
      expect(find.text('No snippets yet'), findsOneWidget);
    });
  });

  group('Mutation errors', () {
    testWidgets('shows SnackBar when create fails', (tester) async {
      final repo = FakeSnippetRepository();
      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Open create dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Title'),
        'Test',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Language'),
        'dart',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Code'),
        'void main() {}',
      );

      // Enable failure mode before submitting
      repo.shouldFail = true;
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Failed to create snippet.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when delete fails', (tester) async {
      final repo = FakeSnippetRepository();
      await repo.createSnippet(makeSnippet(title: 'Fragile'));

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Enable failure mode
      repo.shouldFail = true;

      // Confirm
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('Failed to delete snippet.'), findsOneWidget);
      // Snippet should still be visible
      expect(find.text('Fragile'), findsOneWidget);
    });
  });

  group('Detail view', () {
    testWidgets('tapping a snippet opens detail dialog', (tester) async {
      final repo = FakeSnippetRepository();
      await repo.createSnippet(
        makeSnippet(
          title: 'Detail Test',
          code: 'final x = 42;',
          language: 'dart',
        ),
      );

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // Tap the card (not the edit/delete buttons)
      await tester.tap(find.text('Detail Test'));
      await tester.pumpAndSettle();

      // Detail dialog should show full code and language
      // Title appears in both the list card and dialog, so check >= 2
      expect(find.text('Detail Test'), findsWidgets);
      expect(find.text('final x = 42;'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('small screen does not overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final repo = FakeSnippetRepository();
      for (var i = 0; i < 10; i++) {
        await repo.createSnippet(
          makeSnippet(
            id: 'id-$i',
            title: 'Snippet $i with a very long title that might overflow',
            code: 'line1\nline2\nline3\nline4\nline5',
            language: 'javascript',
          ),
        );
      }

      await tester.pumpWidget(buildTestApp(repo));
      await tester.pumpAndSettle();

      // No overflow errors
      expect(tester.takeException(), isNull);
      // Verify list rendered with snippet cards
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });
  });
}
