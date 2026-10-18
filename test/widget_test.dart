import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worktrace/app/app.dart';

void main() {
  testWidgets('WorktraceApp launches and shows branded shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorktraceApp()));

    // Verify brand identity in AppBar
    expect(find.text('Worktrace'), findsWidgets);

    // Verify all three destination labels are present somewhere in the shell.
    // The specific navigation widget (NavigationBar vs NavigationRail)
    // depends on screen width and is tested in navigation_test.dart.
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Snippets'), findsWidgets);

    // Verify Home content is the initial screen
    expect(find.text('Keep your work traceable'), findsOneWidget);
  });
}
