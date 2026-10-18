import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/app.dart';

void main() {
  /// Pump the full app inside a ProviderScope.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorktraceApp()));
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
      expect(find.text('Keep your work traceable'), findsOneWidget);

      // Tasks and Snippets placeholder messages are NOT visible
      expect(
        find.text('Task management will be available in a future update.'),
        findsNothing,
      );
      expect(
        find.text('Snippet storage will be available in a future update.'),
        findsNothing,
      );
    });
  });

  group('Tab navigation', () {
    testWidgets('Navigate to Tasks and back', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');

      expect(
        find.text('Task management will be available in a future update.'),
        findsOneWidget,
      );
      expect(find.text('Keep your work traceable'), findsNothing);

      await tapDestination(tester, 'Home');

      expect(find.text('Keep your work traceable'), findsOneWidget);
    });

    testWidgets('Navigate to Snippets', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Snippets');

      expect(
        find.text('Snippet storage will be available in a future update.'),
        findsOneWidget,
      );
      expect(find.text('Keep your work traceable'), findsNothing);
    });

    testWidgets('Repeated taps do not duplicate content', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');
      await tapDestination(tester, 'Tasks');

      expect(
        find.text('Task management will be available in a future update.'),
        findsOneWidget,
      );
    });
  });

  group('Back navigation', () {
    testWidgets('Back from Tasks returns to Home', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Tasks');
      expect(
        find.text('Task management will be available in a future update.'),
        findsOneWidget,
      );

      // Simulate Android back button
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Keep your work traceable'), findsOneWidget);
    });

    testWidgets('Back from Snippets returns to Home', (tester) async {
      await pumpApp(tester);

      await tapDestination(tester, 'Snippets');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Keep your work traceable'), findsOneWidget);
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
