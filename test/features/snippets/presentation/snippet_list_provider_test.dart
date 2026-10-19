import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/features/snippets/data/snippet_repository_provider.dart';
import 'package:worktrace/features/snippets/domain/snippet.dart';
import 'package:worktrace/features/snippets/domain/snippet_repository.dart';
import 'package:worktrace/features/snippets/presentation/snippet_list_provider.dart';

/// In-memory fake repository for testing application logic
/// without a real database.
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
    if (shouldFail) throw Exception('Simulated failure');
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
    final index = _snippets.indexWhere((s) => s.id == snippet.id);
    if (index != -1) _snippets[index] = snippet;
  }

  @override
  Future<void> deleteSnippet(String id) async {
    if (shouldFail) throw Exception('Simulated failure');
    _snippets.removeWhere((s) => s.id == id);
  }

  @override
  Stream<List<Snippet>> watchAllSnippets() {
    return Stream.value(List.unmodifiable(_snippets));
  }
}

void main() {
  late ProviderContainer container;
  late FakeSnippetRepository fakeRepo;

  setUp(() {
    fakeRepo = FakeSnippetRepository();
    container = ProviderContainer(
      overrides: [snippetRepositoryProvider.overrideWithValue(fakeRepo)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('initial load', () {
    test('loads empty list when no snippets exist', () async {
      final snippets = await container.read(snippetListProvider.future);
      expect(snippets, isEmpty);
    });

    test('exposes loading state before data arrives', () {
      final state = container.read(snippetListProvider);
      expect(state.isLoading, isTrue);
    });
  });

  group('createSnippet', () {
    test('creates a snippet and reloads the list', () async {
      await container.read(snippetListProvider.future);

      await container
          .read(snippetListProvider.notifier)
          .createSnippet(
            title: 'Hello World',
            code: 'print("hi")',
            language: 'dart',
          );

      final snippets = await container.read(snippetListProvider.future);
      expect(snippets, hasLength(1));
      expect(snippets.first.title, 'Hello World');
      expect(snippets.first.code, 'print("hi")');
      expect(snippets.first.language, 'dart');
    });

    test('rejects empty title', () async {
      await container.read(snippetListProvider.future);

      expect(
        () => container
            .read(snippetListProvider.notifier)
            .createSnippet(title: '   ', code: 'code', language: 'dart'),
        throwsArgumentError,
      );
    });

    test('rejects empty code', () async {
      await container.read(snippetListProvider.future);

      expect(
        () => container
            .read(snippetListProvider.notifier)
            .createSnippet(title: 'Title', code: '', language: 'dart'),
        throwsArgumentError,
      );
    });

    test('creates multiple snippets', () async {
      await container.read(snippetListProvider.future);
      final notifier = container.read(snippetListProvider.notifier);

      await notifier.createSnippet(title: 'A', code: 'a()', language: 'dart');
      await notifier.createSnippet(title: 'B', code: 'b()', language: 'python');

      final snippets = await container.read(snippetListProvider.future);
      expect(snippets, hasLength(2));
    });
  });

  group('editSnippet', () {
    test('updates title and reloads the list', () async {
      await container.read(snippetListProvider.future);
      await container
          .read(snippetListProvider.notifier)
          .createSnippet(title: 'Original', code: 'code', language: 'dart');

      final snippets = await container.read(snippetListProvider.future);
      final snippetId = snippets.first.id;

      await container
          .read(snippetListProvider.notifier)
          .editSnippet(snippetId, title: 'Updated');

      final updated = await container.read(snippetListProvider.future);
      expect(updated.first.title, 'Updated');
      expect(updated.first.id, snippetId);
    });

    test('preserves createdAt through edit', () async {
      await container.read(snippetListProvider.future);
      await container
          .read(snippetListProvider.notifier)
          .createSnippet(title: 'Dated', code: 'code', language: 'dart');

      final snippets = await container.read(snippetListProvider.future);
      final originalCreatedAt = snippets.first.createdAt;
      final snippetId = snippets.first.id;

      await container
          .read(snippetListProvider.notifier)
          .editSnippet(snippetId, title: 'Renamed');

      final updated = await container.read(snippetListProvider.future);
      expect(updated.first.createdAt, originalCreatedAt);
    });

    test('throws StateError for missing snippet id', () async {
      await container.read(snippetListProvider.future);

      expect(
        () => container
            .read(snippetListProvider.notifier)
            .editSnippet('nonexistent', title: 'Title'),
        throwsStateError,
      );
    });
  });

  group('deleteSnippet', () {
    test('removes a snippet from the list', () async {
      await container.read(snippetListProvider.future);
      await container
          .read(snippetListProvider.notifier)
          .createSnippet(title: 'Delete me', code: 'code', language: 'dart');

      final snippets = await container.read(snippetListProvider.future);
      final snippetId = snippets.first.id;

      await container
          .read(snippetListProvider.notifier)
          .deleteSnippet(snippetId);

      final remaining = await container.read(snippetListProvider.future);
      expect(remaining, isEmpty);
    });
  });

  group('error handling', () {
    test('exposes error state when load fails', () async {
      fakeRepo.shouldFail = true;

      await expectLater(
        container.read(snippetListProvider.future),
        throwsException,
      );

      final state = container.read(snippetListProvider);
      expect(state.hasError, isTrue);
    });
  });
}
